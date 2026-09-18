const admin = require("firebase-admin");
const { LibrusClient, deriveLibrusModule } = require("./librus_client");

async function syncStudentData(login = process.env.LIBRUS_LOGIN, password = process.env.LIBRUS_PASSWORD, options = {}) {
  if (!login || !password) {
    throw new Error("Brak danych logowania Librus. Ustaw zmienne LIBRUS_LOGIN i LIBRUS_PASSWORD.");
  }
  const db = admin.firestore();
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
            id: `grade_${g.id}_${Date.now()}`,
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
          id: `ann_${a.id}_${Date.now()}`,
          type: "announcement",
          title: `Nowe ogłoszenie: ${a.title}`,
          body: `${a.author} (${a.date})`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false
        });
      }
    });

    // Detect new messages
    const prevMsgIds = new Set((prevData.messages || []).map(m => m.id));
    (freshData.messages || []).forEach(m => {
      if (!prevMsgIds.has(m.id)) {
        newNotifications.push({
          id: `msg_${m.id}_${Date.now()}`,
          type: "message",
          title: `Nowa wiadomość: ${m.subject}`,
          body: `${m.sender} • ${m.date}`,
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
  }

  // Save student snapshot
  await studentRef.set({
    ...freshData,
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

module.exports = { syncStudentData };
