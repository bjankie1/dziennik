const axios = require("axios");
const admin = require("firebase-admin");

const TELEGRAM_MAX_MESSAGE_LENGTH = 4096;
const TELEGRAM_DEFAULT_CONTENT_BUDGET = 3500;
const TELEGRAM_TRUNCATION_SUFFIX = "… (pełna treść w aplikacji)";

function escapeHtml(str = "") {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

/**
 * Truncates raw plain text on a word/line boundary BEFORE calling escapeHtml()
 * so that the resulting HTML-escaped string never exceeds `maxEscapedChars`
 * and never cuts an HTML entity (`&amp;`, `&lt;`, `&gt;`) mid-token (D-01, D-02).
 */
function truncateTelegramContent(rawText = "", maxEscapedChars = TELEGRAM_DEFAULT_CONTENT_BUDGET) {
  const normalized = String(rawText || "")
    .replace(/\r\n?/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
  if (!normalized) return "";

  const fullEscaped = escapeHtml(normalized);
  if (fullEscaped.length <= maxEscapedChars) {
    return fullEscaped;
  }

  const targetEscapedLen = Math.max(80, maxEscapedChars - TELEGRAM_TRUNCATION_SUFFIX.length - 1);
  let candidate = normalized.slice(0, Math.min(normalized.length, targetEscapedLen));

  while (escapeHtml(candidate).length > targetEscapedLen && candidate.length > 1) {
    const excess = escapeHtml(candidate).length - targetEscapedLen;
    candidate = candidate.slice(0, Math.max(1, candidate.length - Math.max(1, excess)));
  }

  const minBreakPos = Math.floor(candidate.length * 0.6);
  const breakIdx = Math.max(candidate.lastIndexOf("\n"), candidate.lastIndexOf(" "));
  if (breakIdx >= minBreakPos) {
    candidate = candidate.slice(0, breakIdx);
  }

  return `${escapeHtml(candidate.trimEnd())}${TELEGRAM_TRUNCATION_SUFFIX}`;
}

/**
 * Formats message attachments into a Telegram HTML section with clickable
 * `/api/downloadAttachment?path=...` links (D-04, D-05, REQ-NOTIF-TG-ATT-01).
 */
function formatMessageAttachmentsForTelegram(notif) {
  const rawFiles =
    Array.isArray(notif?.attachmentFiles) && notif.attachmentFiles.length > 0
      ? notif.attachmentFiles
      : Array.isArray(notif?.attachments)
        ? notif.attachments
        : [];

  const normalized = rawFiles
    .map((item) => {
      if (!item) return null;
      if (typeof item === "string") {
        const name = item.trim();
        return name ? { name, path: "" } : null;
      }
      if (typeof item === "object") {
        const name = String(item.name || item.fileName || "Załącznik").trim();
        const path = String(item.path || item.downloadPath || "").trim();
        return name || path ? { name: name || "Załącznik", path } : null;
      }
      return null;
    })
    .filter(Boolean);

  if (normalized.length === 0) return "";

  const lines = normalized.map((att) => {
    const safeName = escapeHtml(att.name);
    if (att.path) {
      const href = /^https?:\/\//i.test(att.path)
        ? att.path
        : `https://lepsza-szkola.web.app/api/downloadAttachment?path=${encodeURIComponent(att.path)}`;
      return `• <a href="${href}">${safeName}</a>`;
    }
    return `• ${safeName}`;
  });

  return `\n📎 <b>Załączniki (${normalized.length}):</b>\n${lines.join("\n")}\n`;
}

/**
 * Formats an EduSync notification event into a rich HTML Telegram message.
 */
function formatNotificationForTelegram(notif, studentName = "Oskar") {
  const safeTitle = escapeHtml(notif.title || "Powiadomienie ze szkoły");
  const safeBody = escapeHtml(notif.body || "");
  const safeStudent = escapeHtml(studentName);

  switch (notif.type) {
    case "grade":
      return (
        `🎓 <b>Nowa ocena w dzienniku!</b> (${safeStudent})\n\n` +
        `📌 <b>${safeTitle}</b>\n` +
        (safeBody ? `📝 ${safeBody}\n` : "") +
        `\n🔗 <a href="https://lepsza-szkola.web.app/oceny">Otwórz Oceny w EduSync</a>`
      );
    case "message": {
      const rawTitle =
        notif.title ||
        (notif.subject ? `Nowa wiadomość: ${notif.subject}` : "Nowa wiadomość ze szkoły");
      const safeMsgTitle = escapeHtml(rawTitle);

      let rawMeta = "";
      let rawContent = "";
      if (typeof notif.content === "string") {
        rawMeta = notif.body || [notif.sender, notif.date].filter(Boolean).join(" • ");
        rawContent = notif.content;
      } else if (notif.sender) {
        rawMeta = [notif.sender, notif.date].filter(Boolean).join(" • ");
        rawContent = notif.body || "";
      } else {
        rawMeta = notif.body || "";
        rawContent = "";
      }
      if (rawContent.trim() === rawMeta.trim()) {
        rawContent = "";
      }

      const rawMsgId =
        notif.messageId ||
        (typeof notif.id === "string" && notif.id.startsWith("msg_")
          ? notif.id.slice(4)
          : "");
      const msgHref = rawMsgId
        ? `https://lepsza-szkola.web.app/wiadomosci/${encodeURIComponent(String(rawMsgId))}`
        : "https://lepsza-szkola.web.app/wiadomosci";

      const headerBlock =
        `📬 <b>Nowa wiadomość w Librusie</b> (${safeStudent})\n\n` +
        `📌 <b>${safeMsgTitle}</b>\n` +
        (rawMeta ? `👤 ${escapeHtml(rawMeta)}\n` : "");
      const attachmentsBlock = formatMessageAttachmentsForTelegram(notif);
      const footerBlock = `\n🔗 <a href="${msgHref}">Otwórz wiadomość w EduSync</a>`;

      const contentBudget = Math.max(
        120,
        Math.min(
          TELEGRAM_DEFAULT_CONTENT_BUDGET,
          TELEGRAM_MAX_MESSAGE_LENGTH -
            (headerBlock.length + attachmentsBlock.length + footerBlock.length + 4)
        )
      );
      const safeContent = truncateTelegramContent(rawContent, contentBudget);

      return (
        headerBlock +
        (safeContent ? `\n${safeContent}\n` : "") +
        attachmentsBlock +
        footerBlock
      );
    }
    case "announcement": {
      const rawTitle = notif.title || "Nowe ogłoszenie szkolne";
      const safeAnnTitle = escapeHtml(rawTitle);

      let rawMeta = "";
      let rawContent = "";
      if (typeof notif.content === "string") {
        rawMeta =
          notif.body ||
          (notif.author ? `${notif.author}${notif.date ? " (" + notif.date + ")" : ""}` : "");
        rawContent = notif.content;
      } else if (notif.author) {
        rawMeta = `${notif.author}${notif.date ? " (" + notif.date + ")" : ""}`;
        rawContent = notif.body || "";
      } else {
        rawMeta = notif.body || "";
        rawContent = "";
      }
      if (rawContent.trim() === rawMeta.trim()) {
        rawContent = "";
      }

      const headerBlock =
        `📢 <b>Nowe ogłoszenie szkolne</b> (${safeStudent})\n\n` +
        `📌 <b>${safeAnnTitle}</b>\n` +
        (rawMeta ? `👤 ${escapeHtml(rawMeta)}\n` : "");
      const footerBlock = `\n🔗 <a href="https://lepsza-szkola.web.app/wiadomosci">Otwórz ogłoszenia w EduSync</a>`;

      const contentBudget = Math.max(
        120,
        Math.min(
          TELEGRAM_DEFAULT_CONTENT_BUDGET,
          TELEGRAM_MAX_MESSAGE_LENGTH - (headerBlock.length + footerBlock.length + 4)
        )
      );
      const safeContent = truncateTelegramContent(rawContent, contentBudget);

      return headerBlock + (safeContent ? `\n${safeContent}\n` : "") + footerBlock;
    }
    case "exam":
      return (
        `📅 <b>Nadchodzący sprawdzian!</b> (${safeStudent})\n\n` +
        `📌 <b>${safeTitle}</b>\n` +
        (safeBody ? `📝 ${safeBody}\n` : "") +
        `\n🔗 <a href="https://lepsza-szkola.web.app/plan-lekcji">Zobacz w Planie Lekcji</a>`
      );
    case "justification":
      return (
        `✅ <b>Zaakceptowano usprawiedliwienie!</b> (${safeStudent})\n\n` +
        `📌 <b>${safeTitle}</b>\n` +
        (safeBody ? `📝 ${safeBody}\n` : "") +
        `\n🔗 <a href="https://lepsza-szkola.web.app/frekwencja">Zobacz w module Frekwencji</a>`
      );
    case "family_chat":
      return (
        `💬 <b>Czat rodzinny • EduSync</b>\n\n` +
        `📌 <b>${safeTitle}</b>\n` +
        (safeBody ? `📝 ${safeBody}\n` : "") +
        `\n🔗 <a href="https://lepsza-szkola.web.app/czat">Otwórz Czat Rodzinny</a>`
      );
    default:
      return (
        `🔔 <b>EduSync • Lepsza Szkoła</b> (${safeStudent})\n\n` +
        `📌 <b>${safeTitle}</b>\n` +
        (safeBody ? `📝 ${safeBody}\n` : "") +
        `\n🔗 <a href="https://lepsza-szkola.web.app/pulpit">Otwórz Pulpit EduSync</a>`
      );
  }
}

/**
 * Sends an HTML-formatted message via Telegram Bot API.
 */
async function sendTelegramMessage({ botToken, chatId, htmlText }) {
  const token = (botToken || process.env.TELEGRAM_BOT_TOKEN || "").trim();
  if (!token) {
    throw new Error("Brak skonfigurowanego tokenu bota Telegram (TELEGRAM_BOT_TOKEN).");
  }
  if (!chatId) {
    throw new Error("Brak identyfikatora czatu Telegram (chatId).");
  }

  const url = `https://api.telegram.org/bot${token}/sendMessage`;
  const response = await axios.post(
    url,
    {
      chat_id: String(chatId).trim(),
      text: htmlText,
      parse_mode: "HTML",
      disable_web_page_preview: true,
    },
    { timeout: 10000 }
  );

  return response.data;
}

/**
 * Checks if a notification type is enabled in the user's channel settings.
 */
function isCategoryEnabled(settings, notifType) {
  if (!settings) return false;
  switch (notifType) {
    case "grade":
      return settings.notifyGrades !== false;
    case "message":
    case "announcement":
      return settings.notifyMessages !== false;
    case "exam":
      return settings.notifyExams !== false;
    case "justification":
      return true;
    case "family_chat":
      return settings.notifyFamilyChat !== false;
    default:
      return true;
  }
}

/**
 * Dispatches newly detected school notifications to all paired Telegram channels for the student/family.
 */
async function dispatchTelegramNotificationsForStudent(db, studentId, studentName, notifications = []) {
  if (!notifications || notifications.length === 0) return { sentCount: 0 };

  let sentCount = 0;
  try {
    const settingsSnap = await db
      .collection("students")
      .doc(String(studentId))
      .collection("notification_settings")
      .get();

    const recipients = [];
    settingsSnap.forEach((doc) => {
      const data = doc.data();
      if (data && data.telegramEnabled && data.telegramChatId) {
        recipients.push({ id: doc.id, ref: doc.ref, ...data });
      }
    });

    if (recipients.length === 0) {
      return { sentCount: 0 };
    }

    for (const recipient of recipients) {
      const token = (recipient.telegramBotToken || process.env.TELEGRAM_BOT_TOKEN || "").trim();
      if (!token) continue;

      for (const notif of notifications) {
        if (notif.type === "system") continue;
        if (!isCategoryEnabled(recipient, notif.type)) continue;

        try {
          const htmlText = formatNotificationForTelegram(notif, studentName);
          await sendTelegramMessage({
            botToken: token,
            chatId: recipient.telegramChatId,
            htmlText,
          });
          sentCount++;
        } catch (sendErr) {
          console.warn(
            `[TelegramService] Failed sending ${notif.type} to chat ${recipient.telegramChatId}:`,
            sendErr.message
          );
        }
      }

      if (sentCount > 0) {
        await recipient.ref.set(
          {
            lastTelegramSentAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }
    }
  } catch (err) {
    console.warn("[TelegramService] Error dispatching Telegram notifications:", err.message);
  }

  return { sentCount };
}

/**
 * Polls Telegram getUpdates or handles webhook update to match a 6-digit pairing code.
 */
async function verifyAndPairCodeFromUpdates(db, { botToken, pairingCode, familyId, roleKey }) {
  const token = (botToken || process.env.TELEGRAM_BOT_TOKEN || "").trim();
  if (!token) {
    return {
      paired: false,
      error: "Wprowadź najpierw Token Bota Telegram (z @BotFather) lub skonfiguruj TELEGRAM_BOT_TOKEN.",
    };
  }

  const code = String(pairingCode || "").trim();
  if (!/^\d{6}$/.test(code)) {
    return { paired: false, error: "Nieprawidłowy 6-cyfrowy kod parowania." };
  }

  const settingsRef = db
    .collection("students")
    .doc(String(familyId))
    .collection("notification_settings")
    .doc(String(roleKey));

  const settingsDoc = await settingsRef.get();
  if (settingsDoc.exists) {
    const data = settingsDoc.data() || {};
    const expiresAt = data.pairingCodeExpiresAt?.toDate
      ? data.pairingCodeExpiresAt.toDate()
      : null;
    if (expiresAt && expiresAt < new Date()) {
      return {
        paired: false,
        error: "Kod parowania wygasł (ważność 15 minut). Wygeneruj nowy kod w ustawieniach.",
      };
    }
  }

  const url = `https://api.telegram.org/bot${token}/getUpdates?limit=50`;
  const resp = await axios.get(url, { timeout: 10000 });
  const updates = resp.data?.result || [];
  const nowUnix = Math.floor(Date.now() / 1000);

  let matchedChat = null;
  for (let i = updates.length - 1; i >= 0; i--) {
    const msg = updates[i].message || updates[i].edited_message;
    if (!msg || !msg.text || !msg.chat) continue;
    if (msg.date && nowUnix - msg.date > 20 * 60) continue;
    const text = msg.text.trim();
    if (text === `/start ${code}` || text === code || text.includes(code)) {
      matchedChat = {
        chatId: String(msg.chat.id),
        username: msg.from?.username || msg.from?.first_name || msg.chat.title || "Telegram User",
        firstName: msg.from?.first_name || "",
      };
      break;
    }
  }

  if (!matchedChat) {
    return {
      paired: false,
      error: `Nie znaleziono jeszcze wiadomości "/start ${code}" w czacie z botem. Wyślij komendę /start ${code} do bota na Telegramie i kliknij ponownie.`,
    };
  }

  const roleLabel = roleKey === "student" ? "Uczeń (Oskar)" : "Rodzic";

  await settingsRef.set(
    {
      telegramEnabled: true,
      telegramChatId: matchedChat.chatId,
      telegramUsername: matchedChat.username,
      telegramBotToken: token,
      pairingCode: null,
      telegramPairedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  // Send confirmation message to Telegram
  await sendTelegramMessage({
    botToken: token,
    chatId: matchedChat.chatId,
    htmlText:
      `✅ <b>EduSync (Lepsza Szkoła) — Połączono!</b>\n\n` +
      `Twój czat Telegram został pomyślnie powiązany z kontem: <b>${escapeHtml(roleLabel)}</b>.\n` +
      `Będziesz otrzymywać natychmiastowe powiadomienia o:\n` +
      `• 🎓 Nowych ocenach i wagach\n` +
      `• 📬 Wiadomościach od nauczycieli\n` +
      `• 📅 Sprawdzianach i kartkówkach\n` +
      `• 💬 Wiadomościach na czacie rodzinnym`,
  });

  return {
    paired: true,
    chatId: matchedChat.chatId,
    username: matchedChat.username,
  };
}

module.exports = {
  escapeHtml,
  truncateTelegramContent,
  formatMessageAttachmentsForTelegram,
  formatNotificationForTelegram,
  isCategoryEnabled,
  sendTelegramMessage,
  dispatchTelegramNotificationsForStudent,
  verifyAndPairCodeFromUpdates,
};

