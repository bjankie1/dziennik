const admin = require("firebase-admin");
const { LibrusClient, deriveLibrusModule } = require("./librus_client");
const { dispatchTelegramNotificationsForStudent } = require("./telegram_service");

function resolveCacheDocumentId({ role, librusLogin, primaryLogin }) {
  const isStudent = role === "student";
  if (isStudent) {
    if (primaryLogin && primaryLogin.trim().length > 0) {
      return primaryLogin.trim();
    }
    const trimmed = (librusLogin || "").trim();
    if (/^\d+u$/i.test(trimmed)) {
      return trimmed.replace(/u$/i, "");
    }
    return process.env.LIBRUS_PRIMARY_LOGIN || process.env.LIBRUS_LOGIN || "11010033";
  }
  return (librusLogin || "").trim();
}

function shouldDispatchLibrusScrape({ role, isBackgroundCron, forceRefresh }) {
  if (role === "student") {
    return false;
  }
  if (isBackgroundCron || forceRefresh) {
    return true;
  }
  return false;
}

async function syncStudentData(login = process.env.LIBRUS_LOGIN, password = process.env.LIBRUS_PASSWORD, options = {}) {
  const role = options.role || "parent";
  const primaryLogin = options.primaryLogin;
  const db = admin.firestore();

  // If role is student, never dispatch scraping requests; serve directly from primary shared cache (D-05, REQ-ROLE-03)
  if (role === "student") {
    const defaultPrimary = process.env.LIBRUS_PRIMARY_LOGIN || process.env.LIBRUS_LOGIN || "11010033";
    const targetDocId = resolveCacheDocumentId({ role, librusLogin: login, primaryLogin }) || defaultPrimary;
    console.log(`[SyncService] Student account detected (${login}). Reading shared cache from students/${targetDocId}.`);
    let cachedDoc = await db.collection("students").doc(targetDocId).get();
    if (!cachedDoc.exists && targetDocId !== defaultPrimary) {
      cachedDoc = await db.collection("students").doc(defaultPrimary).get();
    }
    if (cachedDoc.exists) {
      return {
        success: true,
        fromCache: true,
        isSharedCache: true,
        primaryLogin: cachedDoc.id,
        ...cachedDoc.data()
      };
    }
  }

  if (!login || !password) {
    throw new Error("Brak danych logowania Librus. Ustaw zmienne LIBRUS_LOGIN i LIBRUS_PASSWORD.");
  }
  const trigger = options.trigger || "manual";
  const syncRunId = `${trigger}-${Date.now()}`;

  const handleQueryLog = (logEntry) => {
    try {
      const entry = {
        ...logEntry,
        trigger,
        syncRunId,
        module: deriveLibrusModule(logEntry.endpoint || logEntry.url),
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      };
      db.collection("librus_query_logs").add(entry).catch(err => {
        console.warn("[SyncService] Could not write query log to Firestore:", err.message);
      });
    } catch (err) {
      console.warn("[SyncService] Error handling query log:", err.message);
    }
  };

  const client = new LibrusClient(login, password, { onQueryLog: handleQueryLog });

  // 1. Check dynamic rate-limit backoff lock
  const rateLimitRef = db.collection("system_status").doc("librus_rate_limit");
  try {
    const rateLimitDoc = await rateLimitRef.get();
    if (rateLimitDoc.exists) {
      const limit = rateLimitDoc.data();
      if (limit.isLocked && limit.lockedUntil && limit.lockedUntil.toDate() > new Date()) {
        console.warn(`[SyncService] Rate limit active until ${limit.lockedUntil.toDate().toISOString()} (${limit.reason}). Serving cached data.`);
        const cachedDoc = await db.collection("students").doc(login).get();
        if (cachedDoc.exists) {
          db.collection("librus_query_logs").add({
            url: `cache://students/${login}`,
            endpoint: "/cache/students",
            method: "CACHE",
            status: 200,
            statusText: "Served from Cache (Rate limit lock active)",
            durationMs: 4,
            responseSizeBytes: 0,
            login,
            trigger,
            syncRunId,
            module: "Cache",
            timestamp: admin.firestore.FieldValue.serverTimestamp()
          }).catch(() => {});

          return {
            success: true,
            fromCache: true,
            rateLimited: true,
            lockedUntil: limit.lockedUntil.toDate().toISOString(),
            reason: limit.reason,
            ...cachedDoc.data()
          };
        }
      }
    }
  } catch (limitErr) {
    console.warn("[SyncService] Error checking rate limit lock:", limitErr.message);
  }

  // 2. Restore cached session cookies if available
  const sessionRef = db.collection("librus_sessions").doc(login);
  try {
    const sessionDoc = await sessionRef.get();
    if (sessionDoc.exists && sessionDoc.data()?.serializedJar) {
      client.importCookies(sessionDoc.data().serializedJar);
      console.log(`[SyncService] Restored cached session cookies for ${login}.`);
    }
  } catch (sessErr) {
    console.warn("[SyncService] Could not read cached session:", sessErr.message);
  }

  let freshData;
  try {
    console.log(`Starting sync for student: ${login}...`);
    freshData = await client.fetchAll();

    // Persist updated session cookies to Firestore
    try {
      await sessionRef.set({
        serializedJar: client.exportCookies(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      console.log(`[SyncService] Saved updated session cookies for ${login}.`);
    } catch (saveErr) {
      console.warn("[SyncService] Could not save updated session cookies:", saveErr.message);
    }
  } catch (error) {
    const status = error.response?.status || error.status;
    const msg = error.message || "";
    const isRateLimitOrBlocked =
      status === 429 ||
      status === 503 ||
      msg.includes("429") ||
      msg.includes("503") ||
      msg.toLowerCase().includes("rate limit") ||
      msg.toLowerCase().includes("zbyt wiele") ||
      msg.toLowerCase().includes("captcha");

    if (isRateLimitOrBlocked) {
      console.error(`[SyncService] Rate limit or service unavailable detected (${status || msg}). Activating 20-minute backoff lock.`);
      const lockedUntil = new Date(Date.now() + 20 * 60 * 1000);
      try {
        await rateLimitRef.set({
          isLocked: true,
          lockedUntil: admin.firestore.Timestamp.fromDate(lockedUntil),
          reason: msg || `HTTP error ${status}`,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      } catch (lockErr) {
        console.warn("[SyncService] Could not set rate limit lock in Firestore:", lockErr.message);
      }

      const cachedDoc = await db.collection("students").doc(login).get();
      if (cachedDoc.exists) {
        return {
          success: true,
          fromCache: true,
          rateLimited: true,
          lockedUntil: lockedUntil.toISOString(),
          reason: msg,
          ...cachedDoc.data()
        };
      }
    }
    throw error;
  }


  const studentRef = db.collection("students").doc(login);
  const prevDoc = await studentRef.get();
  const prevData = prevDoc.exists ? prevDoc.data() : null;

  // Phase 20 (D-05) & Phase 25 (D-03): Preserve previously cached full message bodies, archive overrides, and auto-archive justification confirmations
  if (Array.isArray(freshData.messages)) {
    freshData.messages = await mergeAndIndexMessages({
      freshMessages: freshData.messages,
      prevMessages: prevData?.messages || [],
      prevArchivedOverrides: prevData?.archivedMessageOverrides || {},
      client
    });
  }

  const newNotifications = [];

  if (prevData && prevData.subjects) {
    // Detect new grades
    const prevGradeIds = new Set();
    (prevData.subjects || []).forEach(s => {
      (s.grades || []).forEach(g => prevGradeIds.add(g.id));
    });

    (freshData.subjects || []).forEach(s => {
      (s.grades || []).forEach(g => {
        if (!prevGradeIds.has(g.id)) {
          newNotifications.push({
            id: `grade_${String(g.id).replace(/[^a-zA-Z0-9_-]/g, "_")}`,
            type: "grade",
            title: `Nowa ocena: ${g.value} (${s.name})`,
            body: `${g.category} • Waga: ${g.weight} • ${g.teacher}`,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false
          });
        }
      });
    });

    // Detect new announcements
    const prevAnnIds = new Set((prevData.announcements || []).map(a => a.id));
    (freshData.announcements || []).forEach(a => {
      if (!prevAnnIds.has(a.id)) {
        newNotifications.push({
          id: `ann_${String(a.id).replace(/[^a-zA-Z0-9_-]/g, "_")}`,
          type: "announcement",
          title: `Nowe ogłoszenie: ${a.title}`,
          body: `${a.author} (${a.date})`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false
        });
      }
    });

    // Detect new regular messages (excluding auto-archived justification confirmations, which become 'justification' notifications)
    const prevMsgIds = new Set((prevData.messages || []).map(m => m.id));
    (freshData.messages || []).forEach(m => {
      if (!prevMsgIds.has(m.id) && !isJustificationApprovalMessage(m)) {
        newNotifications.push({
          id: `msg_${String(m.id).replace(/[^a-zA-Z0-9_-]/g, "_")}`,
          type: "message",
          title: `Nowa wiadomość: ${m.subject}`,
          body: `${m.sender} • ${m.date}`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false
        });
      }
    });

    // Detect justification acceptances (from new system confirmation messages and attendance/justifications transitions - Phase 25 D-06)
    const justificationNotifs = detectJustificationNotifications({
      prevData,
      freshData,
      timestampValue: admin.firestore.FieldValue.serverTimestamp()
    });
    newNotifications.push(...justificationNotifs);

    // Detect new exams (Phase 18: REQ-NOTIF-02)
    const prevExamKeys = new Set(
      (prevData.exams || []).map(e => `${e.date || ""}_${e.subject || ""}_${e.category || ""}`)
    );
    (freshData.exams || []).forEach(e => {
      const examKey = `${e.date || ""}_${e.subject || ""}_${e.category || ""}`;
      if (!prevExamKeys.has(examKey)) {
        const safeExamSlug = examKey.toLowerCase().replace(/[^a-z0-9]+/g, "_");
        newNotifications.push({
          id: `exam_${safeExamSlug}`,
          type: "exam",
          title: `Nowy sprawdzian: ${e.subject || "Przedmiot"} (${e.date || ""})`,
          body: `${e.category || "Sprawdzian"}${e.description ? " • " + e.description : ""}`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false
        });
      }
    });
  } else {
    // First-time sync: create a welcome notification
    newNotifications.push({
      id: `welcome_${Date.now()}`,
      type: "system",
      title: `Konto ${freshData.student.name} połączone!`,
      body: `Pomyślnie zsynchronizowano dane ze szkoły ${freshData.student.schoolName}.`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false
    });
  }

  // Save new notifications to subcollection
  const notifBatch = db.batch();
  for (const notif of newNotifications) {
    const notifRef = studentRef.collection("notifications").doc(notif.id);
    notifBatch.set(notifRef, notif);
  }
  if (newNotifications.length > 0) {
    await notifBatch.commit();
    console.log(`Saved ${newNotifications.length} new notification(s).`);

    // Dispatch new notifications to paired Telegram Bot chats (Phase 18 & Phase 25)
    try {
      const tgResult = await dispatchTelegramNotificationsForStudent(
        db,
        login,
        freshData.student?.name || "Oskar",
        newNotifications
      );
      if (tgResult.sentCount > 0) {
        console.log(`[SyncService] Dispatched ${tgResult.sentCount} Telegram notification(s).`);
      }
    } catch (tgErr) {
      console.warn("[SyncService] Telegram dispatch warning:", tgErr.message);
    }
  }

  // Save student snapshot (D-04: exclude archived messages from unreadMessagesCount)
  const unreadMessagesCount = (freshData.messages || []).filter(m => !m.isRead && !m.isArchived).length;
  await studentRef.set({
    ...freshData,
    unreadMessagesCount,
    unreadNotificationsCount: newNotifications.length,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });

  console.log(`Sync completed successfully for ${freshData.student.name} at ${freshData.lastSyncTime}.`);
  return {
    success: true,
    student: freshData.student,
    luckyNumber: freshData.luckyNumber,
    newNotificationsCount: newNotifications.length,
    lastSyncTime: freshData.lastSyncTime
  };
}

/**
 * Phase 25 (D-03, REQ-MSG-ARCH-02): Detects Librus system messages confirming justification acceptance.
 */
function isJustificationApprovalMessage(msg) {
  if (!msg || typeof msg !== "object") return false;
  const sender = String(msg.sender || "").toLowerCase();
  const subject = String(msg.subject || "").toLowerCase();
  const body = String(msg.body || msg.preview || "").toLowerCase();

  const isSystemSender =
    sender.includes("usprawiedliwieni") || sender.includes("system librus");
  const hasAcceptancePhrase =
    subject.includes("zaakceptowano usprawiedliwienie") ||
    subject.includes("usprawiedliwienie zostało zaakceptowane") ||
    subject.includes("potwierdzenie usprawiedliwienia") ||
    subject.includes("usprawiedliwienie nieobecności") ||
    body.includes("zaakceptowano usprawiedliwienie") ||
    body.includes("usprawiedliwienie zostało zaakceptowane") ||
    body.includes("potwierdzenie usprawiedliwienia");

  if (sender.includes("usprawiedliwieni")) return true;
  if (isSystemSender && (hasAcceptancePhrase || subject.includes("usprawiedliwieni"))) {
    return true;
  }
  return hasAcceptancePhrase;
}

/**
 * Phase 25 (D-06, REQ-NOTIF-ACC-01): Detects newly accepted justifications from:
 * 1) New system confirmation messages in `freshData.messages`
 * 2) Attendance records transitioning from unexcused/requested to `excused`
 * 3) `justifications` entries transitioning to accepted status
 */
function detectJustificationNotifications({
  prevData,
  freshData,
  timestampValue = null
}) {
  if (!prevData || !freshData) return [];
  const ts =
    timestampValue !== null
      ? timestampValue
      : admin.firestore.FieldValue.serverTimestamp();
  const notifications = [];
  const notifiedDates = new Set();

  // 1. Check new justification confirmation messages
  const prevMsgIds = new Set((prevData.messages || []).map(m => String(m.id)));
  for (const m of freshData.messages || []) {
    if (!m || prevMsgIds.has(String(m.id))) continue;
    if (!isJustificationApprovalMessage(m)) continue;

    const safeId = String(m.id).replace(/[^a-zA-Z0-9_-]/g, "_");
    const dateMatch = String(`${m.subject || ""} ${m.body || ""}`).match(/\b(\d{4}-\d{2}-\d{2})\b/);
    if (dateMatch) {
      notifiedDates.add(dateMatch[1]);
    }
    notifications.push({
      id: `just_msg_${safeId}`,
      type: "justification",
      title: `Zaakceptowano usprawiedliwienie: ${m.subject || "Potwierdzenie"}`,
      body: `${m.sender || "System Librus"}${m.date ? " • " + m.date : ""}`,
      timestamp: ts,
      isRead: false
    });
  }

  // 2. Check attendance records transitioning from unexcused/absent/requested to excused
  const prevAttendance = Array.isArray(prevData.attendance) ? prevData.attendance : [];
  const freshAttendance = Array.isArray(freshData.attendance) ? freshData.attendance : [];
  if (prevAttendance.length > 0 && freshAttendance.length > 0) {
    const isRecordExcused = (r) => {
      if (!r) return false;
      const t = String(r.type || "").toLowerCase();
      const st = String(r.justificationStatus || "").toLowerCase();
      const sym = String(r.symbol || "").toLowerCase();
      return t === "excused" || st === "approved" || sym === "u" || sym.startsWith("u");
    };

    const prevNonExcusedKeys = new Set();
    for (const pr of prevAttendance) {
      if (!pr || isRecordExcused(pr)) continue;
      const key = `${pr.date || ""}_${pr.lessonNumber ?? ""}`;
      prevNonExcusedKeys.add(key);
      if (pr.id != null) prevNonExcusedKeys.add(String(pr.id));
    }

    const newlyExcusedByDate = new Map();
    for (const fr of freshAttendance) {
      if (!fr || !isRecordExcused(fr)) continue;
      const key = `${fr.date || ""}_${fr.lessonNumber ?? ""}`;
      const wasNonExcused =
        prevNonExcusedKeys.has(key) ||
        (fr.id != null && prevNonExcusedKeys.has(String(fr.id)));
      if (!wasNonExcused) continue;

      const dateStr = String(fr.date || "Nieobecność");
      if (!newlyExcusedByDate.has(dateStr)) {
        newlyExcusedByDate.set(dateStr, []);
      }
      newlyExcusedByDate.get(dateStr).push(fr);
    }

    for (const [dateStr, recs] of newlyExcusedByDate.entries()) {
      if (notifiedDates.has(dateStr)) continue;
      notifiedDates.add(dateStr);
      const safeDateSlug = dateStr.replace(/[^a-zA-Z0-9_-]/g, "_");
      const lessons = recs
        .map(r => r.lessonNumber)
        .filter(n => n != null)
        .sort((a, b) => Number(a) - Number(b));
      const subjects = [
        ...new Set(
          recs
            .map(r => (r.subjectName || r.subject || "").trim())
            .filter(Boolean)
        )
      ];
      const lessonsLabel =
        lessons.length > 0 ? ` (lekcje: ${lessons.join(", ")})` : "";
      const subjectsLabel =
        subjects.length > 0 ? ` • ${subjects.join(", ")}` : "";

      notifications.push({
        id: `just_att_${safeDateSlug}`,
        type: "justification",
        title: `Zaakceptowano usprawiedliwienie (${dateStr})`,
        body: `Usprawiedliwiono ${recs.length} godz.${lessonsLabel}${subjectsLabel}`,
        timestamp: ts,
        isRead: false
      });
    }
  }

  // 3. Check e-Usprawiedliwienia table entries transitioning to accepted
  const prevJusts = Array.isArray(prevData.justifications) ? prevData.justifications : [];
  const freshJusts = Array.isArray(freshData.justifications) ? freshData.justifications : [];
  if (freshJusts.length > 0) {
    const isJustApproved = (j) => {
      const st = String(j?.status || "").toLowerCase();
      return st.includes("uspr") || st.includes("zaakcept");
    };
    const prevApprovedPeriods = new Set(
      prevJusts.filter(isJustApproved).map(j => String(j.period || "").trim())
    );
    for (const fj of freshJusts) {
      if (!fj || !isJustApproved(fj)) continue;
      const period = String(fj.period || "").trim();
      if (!period || prevApprovedPeriods.has(period)) continue;

      const dateMatch = period.match(/\b(\d{4}-\d{2}-\d{2})\b/);
      if (dateMatch && notifiedDates.has(dateMatch[1])) continue;
      if (dateMatch) notifiedDates.add(dateMatch[1]);

      const safeSlug = period.toLowerCase().replace(/[^a-z0-9]+/g, "_").substring(0, 48);
      notifications.push({
        id: `just_req_${safeSlug}`,
        type: "justification",
        title: `Zaakceptowano usprawiedliwienie (${period})`,
        body: fj.content ? `Powód: ${fj.content}` : "Wniosek zaakceptowany przez wychowawcę",
        timestamp: ts,
        isRead: false
      });
    }
  }

  return notifications;
}

const defaultSleep = (minMs, maxMs) => new Promise(resolve => {
  const ms = Math.floor(Math.random() * (maxMs - minMs + 1)) + minMs;
  setTimeout(resolve, ms);
});

/**
 * Phase 20 (D-05) & Phase 25 (D-03): Preserves already-fetched full message bodies across sync cycles,
 * applies auto-archive & auto-read rules to system justification confirmations,
 * and incrementally fetches full bodies for up to `maxIncrementalFetch` unindexed
 * messages per sync cycle (within the top `maxIndexDepth` messages).
 */
async function mergeAndIndexMessages({
  freshMessages = [],
  prevMessages = [],
  prevArchivedOverrides = {},
  client = null,
  maxIncrementalFetch = 4,
  maxIndexDepth = 40,
  jitterMinMs = 1200,
  jitterMaxMs = 2200,
  sleepFn = defaultSleep
}) {
  if (!Array.isArray(freshMessages) || freshMessages.length === 0) {
    return [];
  }

  const prevById = new Map();
  if (Array.isArray(prevMessages)) {
    for (const pm of prevMessages) {
      if (pm && pm.id != null) {
        prevById.set(String(pm.id), pm);
      }
    }
  }

  const merged = freshMessages.map(m => ({ ...m }));

  // Step 1: Preserve already-loaded full message bodies and Drive attachment metadata from previous Firestore snapshot
  for (const m of merged) {
    const prev = prevById.get(String(m.id));
    if (prev) {
      if (prev.driveAttachments && typeof prev.driveAttachments === "object") {
        m.driveAttachments = {
          ...prev.driveAttachments,
          ...(m.driveAttachments || {})
        };
      }
      if (
        (!Array.isArray(m.attachmentFiles) || m.attachmentFiles.length === 0) &&
        Array.isArray(prev.attachmentFiles) &&
        prev.attachmentFiles.length > 0
      ) {
        m.attachmentFiles = prev.attachmentFiles;
        m.attachments = prev.attachments || prev.attachmentFiles.map(a => a.name);
        m.hasAttachments = true;
      }
      if (typeof prev.isRead === "boolean" && prev.isRead === true) {
        m.isRead = true;
        m.unread = false;
      }
    }
    if (m.bodyLoaded !== true && prev) {
      const hasCachedFullBody =
        prev.bodyLoaded === true ||
        (typeof prev.body === "string" &&
          prev.body.trim().length > 0 &&
          prev.body.trim() !== (prev.subject || "").trim());

      if (hasCachedFullBody) {
        m.body = prev.body;
        m.preview =
          prev.preview && prev.preview !== prev.subject
            ? prev.preview
            : prev.body.replace(/\s+/g, " ").substring(0, 90);
        m.bodyLoaded = true;
      } else {
        m.bodyLoaded = false;
      }
    }
  }

  // Step 2: Incrementally fetch full bodies for up to `maxIncrementalFetch` unindexed messages within top `maxIndexDepth`
  if (client && typeof client.fetchMessageDetails === "function" && maxIncrementalFetch > 0) {
    let fetchedCount = 0;
    const limit = Math.min(merged.length, maxIndexDepth);

    for (let i = 0; i < limit; i++) {
      if (fetchedCount >= maxIncrementalFetch) break;
      const m = merged[i];
      if (m.bodyLoaded === true || !m.librusUrl) continue;

      try {
        if (jitterMaxMs > 0 && typeof sleepFn === "function") {
          await sleepFn(jitterMinMs, jitterMaxMs);
        }
        const details = await client.fetchMessageDetails(m.id, m.librusUrl);
        if (details && typeof details.body === "string" && details.body.trim().length > 0) {
          m.body = details.body.trim();
          m.preview = m.body.replace(/\s+/g, " ").substring(0, 90);
        }
        m.bodyLoaded = true;
        fetchedCount++;
      } catch (err) {
        console.warn(`[SyncService] Incremental message detail fetch failed for ${m.id}:`, err.message);
      }
    }

    if (fetchedCount > 0) {
      console.log(`[SyncService] Incrementally indexed full bodies for ${fetchedCount} message(s) for AI Assistant.`);
    }
  }

  // Step 3 (Phase 25 D-03): Apply auto-archive & auto-read rules and preserve manual archive overrides
  for (const m of merged) {
    const idStr = String(m.id);
    const prev = prevById.get(idStr);
    const autoArch = isJustificationApprovalMessage(m);
    if (autoArch) {
      m.isAutoArchived = true;
    }
    const explicitOverride =
      prevArchivedOverrides && typeof prevArchivedOverrides[idStr] === "boolean"
        ? prevArchivedOverrides[idStr]
        : typeof prev?.isArchived === "boolean" && !autoArch
          ? prev.isArchived
          : typeof prev?.isArchived === "boolean" && prev.isArchived === false
            ? false
            : undefined;

    if (typeof explicitOverride === "boolean") {
      m.isArchived = explicitOverride;
    } else if (autoArch) {
      m.isArchived = true;
    } else {
      m.isArchived = false;
    }

    if (autoArch && m.isArchived) {
      m.isRead = true;
      m.unread = false;
    }
  }

  return merged;
}

module.exports = {
  syncStudentData,
  resolveCacheDocumentId,
  shouldDispatchLibrusScrape,
  mergeAndIndexMessages,
  isJustificationApprovalMessage,
  detectJustificationNotifications
};
