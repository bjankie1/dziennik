const axios = require("axios");
const admin = require("firebase-admin");

function escapeHtml(str = "") {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
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
    case "message":
    case "announcement":
      return (
        `📬 <b>Nowa wiadomość w Librusie</b> (${safeStudent})\n\n` +
        `📌 <b>${safeTitle}</b>\n` +
        (safeBody ? `👤 ${safeBody}\n` : "") +
        `\n🔗 <a href="https://lepsza-szkola.web.app/wiadomosci">Otwórz Wiadomości w EduSync</a>`
      );
    case "exam":
      return (
        `📅 <b>Nadchodzący sprawdzian!</b> (${safeStudent})\n\n` +
        `📌 <b>${safeTitle}</b>\n` +
        (safeBody ? `📝 ${safeBody}\n` : "") +
        `\n🔗 <a href="https://lepsza-szkola.web.app/plan-lekcji">Zobacz w Planie Lekcji</a>`
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
  formatNotificationForTelegram,
  sendTelegramMessage,
  dispatchTelegramNotificationsForStudent,
  verifyAndPairCodeFromUpdates,
};
