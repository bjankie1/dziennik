const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}
admin.firestore().settings({ ignoreUndefinedProperties: true });

const { syncStudentData } = require("./src/sync_service");
const { evaluateScheduleWindow } = require("./src/schedule_evaluator");

/**
 * On-demand sync HTTP endpoint.
 */
exports.syncNow = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 60,
    memory: "512MiB"
  },
  async (req, res) => {
    try {
      const login = req.query.login || req.body?.login || process.env.LIBRUS_LOGIN;
      const pass = req.query.password || req.body?.password || process.env.LIBRUS_PASSWORD;
      const role = req.query.role || req.body?.role || "parent";
      const primaryLogin = req.query.primaryLogin || req.body?.primaryLogin;

      if (role === "student") {
        const result = await syncStudentData(login, pass, { trigger: "manual", role: "student", primaryLogin });
        return res.status(200).json(result);
      }

      if (!login || !pass) {
        return res.status(400).json({
          success: false,
          error: "Brak danych logowania (login / password)."
        });
      }

      const result = await syncStudentData(login, pass, { trigger: "manual", role: "parent", primaryLogin });
      res.status(200).json(result);
    } catch (error) {
      console.error("syncNow error:", error);
      res.status(500).json({
        success: false,
        error: error.message || "Błąd podczas synchronizacji z Librus Synergia"
      });
    }
  }
);

/**
 * Retrieve cached student data directly from Firestore as clean JSON.
 */
exports.getStudentData = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const defaultPrimary = process.env.LIBRUS_PRIMARY_LOGIN || process.env.LIBRUS_LOGIN || "11010033";
      let login = req.query.login || defaultPrimary;
      const role = req.query.role || "parent";
      const primaryLogin = req.query.primaryLogin;

      // If user is student, resolve target document from primaryLogin / defaultPrimary (D-05, REQ-ROLE-03)
      if (role === "student") {
        if (primaryLogin && primaryLogin.trim() && primaryLogin.trim() !== "7654321r") {
          login = primaryLogin.trim();
        } else if (login && /^\d+u$/i.test(login.trim())) {
          login = login.trim().replace(/u$/i, "");
        } else {
          login = defaultPrimary;
        }
      }

      if (!login) {
        login = defaultPrimary;
      }

      let doc = await admin.firestore().collection("students").doc(login).get();
      if (!doc.exists && login !== defaultPrimary) {
        doc = await admin.firestore().collection("students").doc(defaultPrimary).get();
      }
      if (!doc.exists) {
        const snap = await admin.firestore().collection("students").limit(1).get();
        if (!snap.empty) {
          doc = snap.docs[0];
        }
      }
      if (!doc.exists) {
        // If not yet synced, run sync once for parent only
        const pass = process.env.LIBRUS_PASSWORD;
        if (!pass || role === "student") {
          return res.status(404).json({ error: "Dane ucznia nie zostały jeszcze zsynchronizowane." });
        }
        await syncStudentData(login, pass);
        const freshDoc = await admin.firestore().collection("students").doc(login).get();
        return res.status(200).json(freshDoc.data());
      }
      res.status(200).json(doc.data());
    } catch (error) {
      console.error("getStudentData error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * Save user connection to Firestore so it persists across logouts and devices.
 */
exports.saveConnection = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 15,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const userId = req.query.userId || req.body?.userId;
      const unbind = req.query.unbind === "true" || req.body?.unbind === true;

      if (!userId) {
        return res.status(400).json({ error: "Missing userId" });
      }

      if (unbind) {
        await admin.firestore().collection("users").doc(userId).set({
          connected: false,
          librusLogin: null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        return res.status(200).json({ success: true, unbind: true });
      }

      const defaultPrimary = process.env.LIBRUS_PRIMARY_LOGIN || process.env.LIBRUS_LOGIN || "11010033";
      const login = req.query.login || req.body?.login || defaultPrimary;
      const email = req.query.email || req.body?.email || "";
      const rawRole = req.query.role || req.body?.role || "parent";
      const role = String(rawRole).trim().toLowerCase() === "student" ? "student" : "parent";
      const rawStudentLogin = req.query.studentLogin || req.body?.studentLogin;
      const rawPrimaryLogin = req.query.primaryLogin || req.body?.primaryLogin;
      const rawFamilyId = req.query.familyId || req.body?.familyId || "jankiewicz_family";

      let studentLogin = rawStudentLogin || null;
      let primaryLogin = (rawPrimaryLogin && rawPrimaryLogin !== "7654321r") ? rawPrimaryLogin : null;

      if (role === "student") {
        studentLogin = login || studentLogin || null;
        if (!primaryLogin) {
          primaryLogin = (/^\d+u$/i.test(login) ? login.replace(/u$/i, "") : null) || defaultPrimary;
        }
      } else {
        primaryLogin = (/^\d+$/.test(login) ? login : null) || primaryLogin || defaultPrimary;
      }

      await admin.firestore().collection("users").doc(userId).set({
        userId,
        email,
        role,
        studentLogin,
        primaryLogin,
        familyId: rawFamilyId,
        connected: true,
        librusLogin: login,
        isDemoMode: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      res.status(200).json({
        success: true,
        userId,
        librusLogin: login,
        role,
        studentLogin,
        primaryLogin,
        familyId: rawFamilyId
      });
    } catch (error) {
      console.error("saveConnection error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * Get user connection from Firestore.
 */
exports.getConnection = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 15,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const userId = req.query.userId;
      if (!userId) {
        return res.status(400).json({ error: "Missing userId" });
      }

      const doc = await admin.firestore().collection("users").doc(userId).get();
      if (!doc.exists) {
        return res.status(200).json({ connected: false });
      }

      const data = doc.data();
      if (data.connected === false || !data.librusLogin) {
        return res.status(200).json({ connected: false });
      }

      res.status(200).json({
        connected: true,
        librusLogin: data.librusLogin,
        isDemoMode: data.isDemoMode || false,
        role: data.role || "parent",
        studentLogin: data.studentLogin || null,
        primaryLogin: data.primaryLogin || data.librusLogin,
        familyId: data.familyId || "jankiewicz_family"
      });
    } catch (error) {
      console.error("getConnection error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * Scheduled background sync every 15 minutes with Europe/Warsaw schedule evaluation.
 * Enforces night silence (22:30 - 06:30), weekday intervals with jitter, and weekend slots (11:00 & 19:00).
 */
exports.scheduledLibrusSync = onSchedule(
  {
    region: "europe-west3",
    schedule: "every 15 minutes",
    timeZone: "Europe/Warsaw",
    timeoutSeconds: 300,
    memory: "512MiB"
  },
  async (event) => {
    const decision = evaluateScheduleWindow(new Date());
    if (!decision.shouldRun) {
      console.log(`[scheduledLibrusSync] Sync skipped: ${decision.reason}`);
      return;
    }

    if (decision.jitterMaxMs && decision.jitterMaxMs > 0) {
      const jitterMs = Math.floor(Math.random() * decision.jitterMaxMs);
      console.log(`[scheduledLibrusSync] Applying pre-fetch jitter: ${jitterMs}ms (${decision.reason})`);
      await new Promise(r => setTimeout(r, jitterMs));
    }

    console.log(`[scheduledLibrusSync] Starting scheduled sync job (${decision.reason})...`);
    try {
      const login = process.env.LIBRUS_LOGIN;
      const pass = process.env.LIBRUS_PASSWORD;
      if (!login || !pass) {
        console.warn("scheduledLibrusSync: Brak skonfigurowanych zmiennych LIBRUS_LOGIN / LIBRUS_PASSWORD.");
        return;
      }
      const result = await syncStudentData(login, pass, { trigger: "cron" });
      console.log("Scheduled sync finished successfully:", result);
    } catch (error) {
      console.error("Scheduled sync error:", error);
    }
  }
);

/**
 * Return recent Librus query access logs.
 */
exports.getLibrusLogs = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const limitCount = parseInt(req.query.limit || "50", 10);
      const snapshot = await admin.firestore()
        .collection("librus_query_logs")
        .orderBy("timestamp", "desc")
        .limit(Math.min(limitCount, 100))
        .get();

      const logs = snapshot.docs.map(doc => {
        const data = doc.data();
        let timestampIso = null;
        if (data.timestamp && typeof data.timestamp.toDate === "function") {
          timestampIso = data.timestamp.toDate().toISOString();
        } else if (typeof data.timestamp === "string") {
          timestampIso = data.timestamp;
        } else {
          timestampIso = new Date().toISOString();
        }
        return {
          id: doc.id,
          ...data,
          timestamp: timestampIso
        };
      });

      res.status(200).json({
        success: true,
        count: logs.length,
        logs
      });
    } catch (error) {
      console.error("getLibrusLogs error:", error);
      res.status(500).json({ success: false, error: error.message });
    }
  }
);

/**
 * Send a message or reply to Librus Synergia.
 */
exports.sendMessage = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const { LibrusClient } = require("./src/librus_client");
      const { resolveMessageSession, buildMessageResponse } = require("./src/message_service");

      const role = req.query.role || req.body?.role;
      const studentLogin = req.query.studentLogin || req.body?.studentLogin;
      const login = req.query.login || req.body?.login;
      const pass =
        req.body?.password ||
        req.body?.pass ||
        req.query?.password ||
        req.query?.pass ||
        process.env.LIBRUS_PASSWORD;
      const recipients = req.body?.recipients || req.query.recipients || [];
      const subject = String(req.body?.subject || req.query.subject || "").trim();
      const rawBody = req.body?.body ?? req.query.body ?? "";
      const body = typeof rawBody === "string" ? rawBody.trim().slice(0, 10000) : "";
      const replyToMsgId =
        req.body?.replyToMsgId ||
        req.body?.replyToId ||
        req.query.replyToMsgId ||
        req.query.replyToId ||
        null;
      const senderName = req.body?.senderName || req.query.senderName;
      const senderRole = req.body?.senderRole || req.query.senderRole;
      const replyId = req.body?.replyId || req.query.replyId;
      const date = req.body?.date || req.query.date;

      if (!subject || !body) {
        return res.status(400).json({ error: "Brak tematu lub treści wiadomości." });
      }

      const sessionInfo = resolveMessageSession({
        role,
        studentLogin,
        login,
        defaultParentLogin: process.env.LIBRUS_LOGIN
      });

      // Attempt to restore isolated session cookies from Firestore
      let client = null;
      let restoredSession = false;

      if (sessionInfo.sessionKey) {
        try {
          const sessionDoc = await admin
            .firestore()
            .collection("librus_sessions")
            .doc(sessionInfo.sessionKey)
            .get();

          if (sessionDoc.exists && sessionDoc.data()?.serializedJar) {
            client = new LibrusClient(sessionInfo.sessionKey, pass || "cached_pass");
            client.importCookies(sessionDoc.data().serializedJar);
            restoredSession = true;
          }
        } catch (sessErr) {
          console.warn("[sendMessage] Could not load cached session:", sessErr.message);
        }
      }

      let result = null;
      let simulated = true;

      if (client && restoredSession) {
        try {
          result = await client.sendMessage({
            recipients,
            subject,
            body,
            replyToMsgId
          });
          simulated = Boolean(result?.simulated);
        } catch (sendErr) {
          console.warn("[sendMessage] Restored session sendMessage error:", sendErr.message);
        }
      }

      if (!result && sessionInfo.sessionKey && pass) {
        try {
          client = new LibrusClient(sessionInfo.sessionKey, pass);
          await client.authenticate();
          result = await client.sendMessage({
            recipients,
            subject,
            body,
            replyToMsgId
          });
          simulated = Boolean(result?.simulated);
        } catch (authSendErr) {
          console.warn("[sendMessage] Fresh auth sendMessage error:", authSendErr.message);
        }
      }

      let replyPersisted = false;
      if (replyToMsgId) {
        try {
          const db = admin.firestore();
          const defaultPrimary =
            process.env.LIBRUS_PRIMARY_LOGIN || process.env.LIBRUS_LOGIN || "11010033";
          const rawTarget =
            req.body?.primaryLogin ||
            req.query.primaryLogin ||
            login ||
            studentLogin ||
            sessionInfo.sessionKey ||
            defaultPrimary;
          const targetStudentId =
            String(rawTarget).replace(/u$/i, "").trim() || defaultPrimary;

          let studentRef = db.collection("students").doc(targetStudentId);
          let studentDoc = await studentRef.get();
          if (!studentDoc.exists && targetStudentId !== defaultPrimary) {
            studentRef = db.collection("students").doc(defaultPrimary);
            studentDoc = await studentRef.get();
          }

          if (studentDoc.exists) {
            const docData = studentDoc.data() || {};
            const msgs = Array.isArray(docData.messages) ? [...docData.messages] : [];
            const targetIdx = msgs.findIndex(
              m => m && String(m.id) === String(replyToMsgId)
            );
            if (targetIdx !== -1) {
              const targetMsg = { ...msgs[targetIdx] };
              const existingReplies = Array.isArray(targetMsg.replies)
                ? [...targetMsg.replies]
                : [];
              const resolvedReplyId = String(replyId || `reply_${Date.now()}`);
              const resolvedSenderName = String(
                senderName || sessionInfo.senderName || "Rodzic"
              );
              const resolvedSenderRole = String(
                senderRole || (sessionInfo.isStudent ? "Uczeń" : "Rodzic")
              );
              const resolvedDate = String(date || new Date().toISOString());

              if (!existingReplies.some(r => String(r?.id) === resolvedReplyId)) {
                existingReplies.push({
                  id: resolvedReplyId,
                  senderName: resolvedSenderName,
                  senderRole: resolvedSenderRole,
                  content: body,
                  date: resolvedDate,
                  isMe: true
                });
              }

              targetMsg.replies = existingReplies;
              msgs[targetIdx] = targetMsg;
              await studentRef.set({ messages: msgs }, { merge: true });
              replyPersisted = true;
            }
          }
        } catch (persistErr) {
          console.warn("[sendMessage] Could not persist reply to Firestore:", persistErr.message);
        }
      }

      return res.status(200).json({
        status: "sent",
        details: result || { simulated: true },
        replyPersisted,
        ...buildMessageResponse({
          success: true,
          simulated,
          recipients,
          subject,
          sessionInfo,
          result: result || {}
        })
      });
    } catch (error) {
      console.error("sendMessage error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * Retrieve full message details (including body) from Librus Synergia.
 */
exports.getMessageDetails = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const { LibrusClient } = require("./src/librus_client");
      const msgId = req.query.msgId || req.body?.msgId;
      const url = req.query.url || req.body?.url;
      const rawLogin = req.query.login || req.body?.login || process.env.LIBRUS_LOGIN || "11010033";
      const login = process.env.LIBRUS_LOGIN || String(rawLogin).replace(/u$/i, "");
      const pass = process.env.LIBRUS_PASSWORD;

      if (!msgId && !url) {
        return res.status(400).json({ error: "Missing msgId or url" });
      }

      if (login && pass) {
        const client = new LibrusClient(login, pass);
        await client.authenticate();
        const details = await client.fetchMessageDetails(msgId, url);

        // Update Firestore cached messages if present
        let matchedMessage = null;
        try {
          const studentRef = admin.firestore().collection("students").doc(login);
          const studentDoc = await studentRef.get();
          if (studentDoc.exists) {
            const data = studentDoc.data();
            const msgs = data.messages || [];
            let changed = false;
            for (const m of msgs) {
              if (String(m.id) === String(msgId)) {
                m.body = details.body;
                m.bodyLoaded = true;
                if (details.body) {
                  m.preview = details.body.replace(/\s+/g, " ").substring(0, 90);
                }
                if (Array.isArray(details.attachments)) {
                  m.attachments = details.attachments;
                  m.hasAttachments = details.attachments.length > 0;
                }
                if (Array.isArray(details.attachmentFiles)) {
                  m.attachmentFiles = details.attachmentFiles;
                }
                matchedMessage = m;
                changed = true;
                break;
              }
            }
            if (changed) {
              await studentRef.update({ messages: msgs });
            }
          }
        } catch (cacheErr) {
          console.warn("Could not cache message details in Firestore:", cacheErr.message);
        }

        return res.status(200).json({
          ...details,
          driveAttachments: matchedMessage?.driveAttachments || {}
        });
      }

      return res.status(200).json({
        id: msgId,
        body: "Treść wiadomości pobrana w trybie demonstracyjnym.",
        attachments: [],
        attachmentFiles: [],
        driveAttachments: {}
      });
    } catch (error) {
      console.error("getMessageDetails error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * Download a Librus message attachment server-side and upload it directly to the user's Google Drive (Phase 22, D-01, D-07, D-10).
 */
async function handleSaveAttachmentToDrive(req, res) {
  try {
    const { LibrusClient } = require("./src/librus_client");
    const {
      guessMimeType,
      uploadBufferToDrive,
      updateMessageDriveAttachmentInFirestore
    } = require("./src/drive_service");

    const {
      studentId,
      login: reqLogin,
      msgId,
      attachmentName,
      downloadPath,
      accessToken,
      folderId,
      folderName,
      savedBy
    } = req.body || {};

    if (!msgId || !attachmentName || !downloadPath || !accessToken) {
      return res.status(400).json({
        error: "Brak wymaganych parametrów (msgId, attachmentName, downloadPath, accessToken)."
      });
    }

    const targetStudentId = String(
      studentId || reqLogin || process.env.LIBRUS_LOGIN || "11010033"
    ).replace(/u$/i, "");

    const db = admin.firestore();
    let effectiveFolderId = folderId ? String(folderId).trim() : "";
    let effectiveFolderName = folderName ? String(folderName).trim() : "";

    if (!effectiveFolderId) {
      try {
        const studentDoc = await db.collection("students").doc(targetStudentId).get();
        if (studentDoc.exists) {
          const sData = studentDoc.data() || {};
          effectiveFolderId = String(sData.driveDefaultFolderId || "root").trim();
          effectiveFolderName = String(sData.driveDefaultFolderName || "Mój dysk").trim();
        }
      } catch (prefErr) {
        console.warn("[saveAttachmentToDrive] Could not read default Drive folder from Firestore:", prefErr.message);
      }
    }
    if (!effectiveFolderId) effectiveFolderId = "root";
    if (!effectiveFolderName) effectiveFolderName = effectiveFolderId === "root" ? "Mój dysk" : "Folder Google Drive";

    const librusLogin = process.env.LIBRUS_LOGIN || targetStudentId;
    const librusPass = process.env.LIBRUS_PASSWORD;

    let fileBuffer;
    let mimeType = guessMimeType(attachmentName);

    if (librusLogin && librusPass) {
      const client = new LibrusClient(librusLogin, librusPass);
      await client.authenticate();
      const downloaded = await client.downloadAttachmentBuffer(downloadPath);
      fileBuffer = downloaded.buffer;
      if (
        downloaded.contentType &&
        downloaded.contentType !== "application/octet-stream" &&
        !downloaded.contentType.includes("text/html")
      ) {
        mimeType = downloaded.contentType.split(";")[0].trim();
      }
    } else {
      // Fallback buffer for local emulator when LIBRUS_PASSWORD is not configured
      fileBuffer = Buffer.from(`Załącznik demonstracyjny EduSync: ${attachmentName}`, "utf8");
    }

    const uploadRes = await uploadBufferToDrive({
      accessToken,
      fileName: attachmentName,
      fileBuffer,
      mimeType,
      folderId: effectiveFolderId,
      folderName: effectiveFolderName
    });

    const driveAttachmentInfo = {
      driveFileId: uploadRes.driveFileId,
      webViewLink: uploadRes.webViewLink,
      folderId: uploadRes.folderId,
      folderName: uploadRes.folderName,
      savedAt: new Date().toISOString(),
      savedBy: savedBy || "Rodzic"
    };

    await updateMessageDriveAttachmentInFirestore({
      db,
      studentId: targetStudentId,
      msgId,
      attachmentName,
      driveAttachmentInfo
    });

    return res.status(200).json({
      success: true,
      attachmentName,
      driveAttachment: driveAttachmentInfo,
      fallbackToRoot: Boolean(uploadRes.fallbackToRoot)
    });
  } catch (error) {
    const { classifyDriveError } = require("./src/drive_service");
    console.error(
      "saveAttachmentToDrive error:",
      error.message,
      error.config?.url || "",
      JSON.stringify(error.response?.data || {})
    );
    const { status, body } = classifyDriveError(error);
    return res.status(status).json(body);
  }
}

/**
 * Manage Google Drive folders (list, create, move saved attachments, set default folder) (Phase 22, D-01, D-02, D-03).
 */
async function handleManageDriveFolders(req, res) {
  try {
    const {
      listDriveFolders,
      createDriveFolder,
      moveDriveFileToFolder
    } = require("./src/drive_service");

    const action = String(req.query.action || req.body?.action || "list").trim();
    const accessToken = req.body?.accessToken || req.headers?.authorization?.replace(/^Bearer\s+/i, "");
    const rawStudentId =
      req.body?.studentId || req.query.studentId || req.body?.login || process.env.LIBRUS_LOGIN || "11010033";
    const targetStudentId = String(rawStudentId).replace(/u$/i, "");
    const db = admin.firestore();

    if (action === "setDefault") {
      const folderId = String(req.body?.folderId || "root").trim() || "root";
      const folderName =
        String(req.body?.folderName || (folderId === "root" ? "Mój dysk" : "Folder Google Drive")).trim();

      await db.collection("students").doc(targetStudentId).set(
        {
          driveDefaultFolderId: folderId,
          driveDefaultFolderName: folderName
        },
        { merge: true }
      );
      return res.status(200).json({
        success: true,
        folderId,
        folderName
      });
    }

    if (!accessToken) {
      return res.status(400).json({
        error: "Brak tokenu autoryzacji Google Drive (accessToken)."
      });
    }

    if (action === "list") {
      const folders = await listDriveFolders({ accessToken });
      return res.status(200).json({ success: true, folders });
    }

    if (action === "create") {
      const folderName = req.body?.folderName;
      const parentId = req.body?.parentId || "root";
      const setAsDefault = Boolean(req.body?.setAsDefault);
      const folder = await createDriveFolder({
        accessToken,
        folderName,
        parentId
      });

      if (setAsDefault) {
        await db.collection("students").doc(targetStudentId).set(
          {
            driveDefaultFolderId: folder.id,
            driveDefaultFolderName: folder.name
          },
          { merge: true }
        );
      }

      return res.status(200).json({ success: true, folder });
    }

    if (action === "move") {
      const msgId = req.body?.msgId;
      const items = Array.isArray(req.body?.items) ? req.body.items : [];
      const targetFolderId = String(req.body?.targetFolderId || "root").trim() || "root";
      const targetFolderName =
        String(req.body?.targetFolderName || (targetFolderId === "root" ? "Mój dysk" : "Folder Google Drive")).trim();
      const setAsDefault = req.body?.setAsDefault !== false;

      let movedCount = 0;
      for (const item of items) {
        if (!item || !item.fileId) continue;
        await moveDriveFileToFolder({
          accessToken,
          fileId: item.fileId,
          targetFolderId,
          previousFolderId: item.previousFolderId || "root"
        });
        movedCount++;
      }

      const studentRef = db.collection("students").doc(targetStudentId);
      const studentDoc = await studentRef.get();
      if (studentDoc.exists) {
        const data = studentDoc.data() || {};
        const msgs = Array.isArray(data.messages) ? data.messages : [];
        let msgsChanged = false;
        if (msgId && items.length > 0) {
          for (const m of msgs) {
            if (String(m.id) === String(msgId) && m.driveAttachments && typeof m.driveAttachments === "object") {
              for (const item of items) {
                const attName = item.attachmentName;
                if (attName && m.driveAttachments[attName]) {
                  m.driveAttachments[attName] = {
                    ...m.driveAttachments[attName],
                    folderId: targetFolderId,
                    folderName: targetFolderName
                  };
                  msgsChanged = true;
                }
              }
            }
          }
        }
        const updatePayload = {};
        if (msgsChanged) {
          updatePayload.messages = msgs;
        }
        if (setAsDefault) {
          updatePayload.driveDefaultFolderId = targetFolderId;
          updatePayload.driveDefaultFolderName = targetFolderName;
        }
        if (Object.keys(updatePayload).length > 0) {
          await studentRef.update(updatePayload);
        }
      } else if (setAsDefault) {
        await studentRef.set(
          {
            driveDefaultFolderId: targetFolderId,
            driveDefaultFolderName: targetFolderName
          },
          { merge: true }
        );
      }

      return res.status(200).json({
        success: true,
        movedCount,
        targetFolderId,
        targetFolderName
      });
    }

    return res.status(400).json({ error: `Nieobsługiwana akcja: ${action}` });
  } catch (error) {
    const { classifyDriveError } = require("./src/drive_service");
    console.error(
      "manageDriveFolders error:",
      error.message,
      error.config?.url || "",
      JSON.stringify(error.response?.data || {})
    );
    const { status, body } = classifyDriveError(error);
    return res.status(status).json(body);
  }
}

/**
 * Resolve and redirect to a Librus Synergia message attachment download URL,
 * or handle /api/saveAttachmentToDrive and /api/driveFolder requests.
 */
exports.downloadAttachment = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 60,
    memory: "512MiB"
  },
  async (req, res) => {
    try {
      const urlPath = String(req.path || req.originalUrl || req.url || "");
      if (urlPath.includes("saveAttachmentToDrive") || (req.body && req.body.attachmentName && req.body.downloadPath)) {
        return await handleSaveAttachmentToDrive(req, res);
      }
      if (urlPath.includes("driveFolder") || req.query?.action || req.body?.action) {
        return await handleManageDriveFolders(req, res);
      }

      const { LibrusClient } = require("./src/librus_client");
      const downloadPath = req.query.path || req.body?.path;
      const msgId = req.query.msgId || req.body?.msgId;
      const attId = req.query.attId || req.body?.attId;
      const targetPath = downloadPath || (msgId && attId ? `/wiadomosci/pobierz_zalacznik/${msgId}/${attId}` : null);

      if (!targetPath) {
        return res.status(400).json({ error: "Brak ścieżki załącznika (path)." });
      }

      const login = process.env.LIBRUS_LOGIN || "11010033";
      const pass = process.env.LIBRUS_PASSWORD;

      if (!login || !pass) {
        return res.status(503).json({ error: "Brak skonfigurowanych poświadczeń Librus." });
      }

      const client = new LibrusClient(login, pass);
      await client.authenticate();
      const directUrl = await client.resolveAttachmentDownloadUrl(targetPath);

      if (req.query.json === "1" || req.query.json === "true") {
        return res.status(200).json({ success: true, downloadUrl: directUrl });
      }

      return res.redirect(302, directUrl);
    } catch (error) {
      console.error("downloadAttachment error:", error);
      res.status(500).json({ error: error.message || "Nie udało się pobrać załącznika z Librusa." });
    }
  }
);

exports.saveAttachmentToDrive = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 60,
    memory: "512MiB"
  },
  handleSaveAttachmentToDrive
);

exports.manageDriveFolders = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  handleManageDriveFolders
);


/**
 * Submit an e-Justification to Librus Synergia.
 */
exports.submitJustification = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 45,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const { LibrusClient } = require("./src/librus_client");
      const login = req.query.login || req.body?.login || process.env.LIBRUS_LOGIN;
      const pass = process.env.LIBRUS_PASSWORD;
      const { dateFrom, dateTo, reason, isByHours, hoursByDate, notifyOthers } = req.body || {};

      if (!reason || (!dateFrom && !hoursByDate)) {
        return res.status(400).json({ error: "Brak wymaganych parametrów (powód, zakres dat lub lekcje)." });
      }

      if (login && pass) {
        const client = new LibrusClient(login, pass);
        const result = await client.submitJustification({
          dateFrom,
          dateTo,
          reason,
          isByHours: Boolean(isByHours),
          hoursByDate: hoursByDate || {},
          notifyOthers: notifyOthers !== false
        });
        return res.status(200).json(result);
      }

      return res.status(200).json({
        success: true,
        simulated: true,
        message: "Wniosek o usprawiedliwienie zarejestrowany w trybie demonstracyjnym."
      });
    } catch (error) {
      console.error("submitJustification error:", error);
      res.status(500).json({ error: error.message || "Błąd wysyłania e-Usprawiedliwienia do Librusa." });
    }
  }
);

/**
 * Endpoint for students to submit a justification request awaiting parental approval (REQ-ROLE-02, D-03).
 */
exports.createJustificationRequest = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const { sanitizeStudentRequest } = require("./src/justification_service");
      const payload = req.body || {};

      const sanitized = sanitizeStudentRequest(payload);
      const docRef = await admin.firestore().collection("justification_requests").add(sanitized);

      return res.status(201).json({
        success: true,
        id: docRef.id,
        request: {
          id: docRef.id,
          ...sanitized
        }
      });
    } catch (error) {
      console.error("createJustificationRequest error:", error);
      return res.status(400).json({ error: error.message });
    }
  }
);

/**
 * Endpoint for parents to review (approve with PIN or reject) student justification request (REQ-ROLE-02, D-04, T-14-03).
 */
exports.reviewJustificationRequest = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 45,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const { processParentReview, formatLibrusJustificationPayload } = require("./src/justification_service");
      const { LibrusClient } = require("./src/librus_client");

      const {
        requestId,
        action,
        pin,
        rejectionReason,
        parentLogin,
        selectedRecordIds,
        selectedLessonNumbers,
        hoursByDate,
        dateFrom,
        dateTo
      } = req.body || {};

      if (!requestId) {
        return res.status(400).json({ error: "Brak identyfikatora wniosku (requestId)." });
      }

      const docRef = admin.firestore().collection("justification_requests").doc(requestId);
      const snap = await docRef.get();

      if (!snap.exists) {
        return res.status(404).json({ error: "Wniosek o podanym identyfikatorze nie istnieje." });
      }

      const existingData = snap.data();
      const reviewResult = processParentReview(existingData, {
        action,
        pin,
        rejectionReason,
        parentLogin,
        selectedRecordIds,
        selectedLessonNumbers,
        hoursByDate,
        dateFrom,
        dateTo
      });

      if (!reviewResult.success) {
        return res.status(reviewResult.statusCode).json({ error: reviewResult.error });
      }

      // If approved, forward to Librus if credentials available
      if (action === "approve") {
        const parentLog = parentLogin || process.env.LIBRUS_LOGIN;
        const parentPass = process.env.LIBRUS_PASSWORD;

        if (parentLog && parentPass) {
          try {
            const librusPayload = formatLibrusJustificationPayload(reviewResult.updatedRequest);
            const client = new LibrusClient(parentLog, parentPass);
            await client.submitJustification(librusPayload);
          } catch (librusErr) {
            console.warn("Librus dispatch warning during parental approval:", librusErr.message);
          }
        }
      }

      // If rejected, automatically publish justification card into family chat (D-02)
      if (action === "reject") {
        try {
          const { buildJustificationChatCard } = require("./src/chat_service");
          const cardPayload = buildJustificationChatCard(
            { id: snap.id, ...reviewResult.updatedRequest },
            reviewResult.updatedRequest.rejectionReason,
            parentLogin || "Rodzic"
          );
          const familyId = existingData.familyId || "jankiewicz_family";
          await admin
            .firestore()
            .collection("family_chats")
            .doc(familyId)
            .collection("messages")
            .add(cardPayload);
        } catch (chatCardErr) {
          console.warn("Failed to publish justification card to family chat:", chatCardErr.message);
        }
      }

      await docRef.update(reviewResult.updatedRequest);

      return res.status(200).json({
        success: true,
        request: {
          id: snap.id,
          ...reviewResult.updatedRequest
        }
      });
    } catch (error) {
      console.error("reviewJustificationRequest error:", error);
      return res.status(500).json({ error: error.message || "Błąd podczas rozpatrywania wniosku." });
    }
  }
);

/**
 * Endpoint for students to respond to a rejected justification request (REQ-ROLE-04, D-02).
 * Re-submits the request for parental approval with extra explanations.
 */
exports.respondJustificationRequest = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const { processStudentResponse } = require("./src/justification_service");
      const { requestId, responseText, studentLogin, studentName } = req.body || {};

      if (!requestId) {
        return res.status(400).json({ error: "Brak identyfikatora wniosku (requestId)." });
      }

      const docRef = admin.firestore().collection("justification_requests").doc(requestId);
      const snap = await docRef.get();

      if (!snap.exists) {
        return res.status(404).json({ error: "Wniosek o podanym identyfikatorze nie istnieje." });
      }

      const existingData = snap.data();
      const responseResult = processStudentResponse(existingData, {
        responseText,
        studentLogin,
        studentName
      });

      if (!responseResult.success) {
        return res.status(responseResult.statusCode).json({ error: responseResult.error });
      }

      await docRef.update(responseResult.updatedRequest);

      // Post student clarification directly into family chat (D-02)
      try {
        const { buildChatMessagePayload, CHAT_MESSAGE_TYPE } = require("./src/chat_service");
        const familyId = existingData.familyId || "jankiewicz_family";
        const replyPayload = buildChatMessagePayload({
          familyId,
          senderId: studentLogin || "student_oskar",
          senderName: studentName || "Oskar",
          senderRole: "student",
          text: `Wyjaśnienie do prośby o usprawiedliwienie: ${responseText.trim()}`,
          type: CHAT_MESSAGE_TYPE.TEXT,
          metadata: {
            requestId,
            action: "student_justification_response"
          }
        });
        await admin
          .firestore()
          .collection("family_chats")
          .doc(familyId)
          .collection("messages")
          .add(replyPayload);
      } catch (chatErr) {
        console.warn("Failed to publish student clarification to family chat:", chatErr.message);
      }

      return res.status(200).json({
        success: true,
        request: {
          id: snap.id,
          ...responseResult.updatedRequest
        }
      });
    } catch (error) {
      console.error("respondJustificationRequest error:", error);
      return res.status(500).json({ error: error.message || "Błąd podczas odpowiadania na wniosek." });
    }
  }
);

/**
 * Endpoint to send a real-time message in the family chat (REQ-CHAT-01, D-01).
 */
exports.sendFamilyChatMessage = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const { buildChatMessagePayload } = require("./src/chat_service");
      const { familyId, senderId, senderName, senderRole, text, type, metadata } = req.body || {};

      const payload = buildChatMessagePayload({
        familyId,
        senderId,
        senderName,
        senderRole,
        text,
        type,
        metadata
      });

      const docRef = await admin
        .firestore()
        .collection("family_chats")
        .doc(payload.familyId)
        .collection("messages")
        .add(payload);

      return res.status(201).json({
        success: true,
        message: {
          id: docRef.id,
          ...payload
        }
      });
    } catch (error) {
      console.error("sendFamilyChatMessage error:", error);
      return res.status(400).json({ error: error.message || "Błąd wysyłania wiadomości w czacie rodzinnym." });
    }
  }
);

/**
 * Retrieve messages for a given family chat thread (REQ-CHAT-01).
 */
exports.getFamilyChatMessages = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const familyId = req.query.familyId || req.body?.familyId || "jankiewicz_family";
      const limitVal = Math.min(100, Math.max(1, parseInt(req.query.limit || req.body?.limit || "50", 10)));

      const snap = await admin
        .firestore()
        .collection("family_chats")
        .doc(familyId)
        .collection("messages")
        .orderBy("createdAt", "asc")
        .limitToLast(limitVal)
        .get();

      const messages = snap.docs.map(d => ({
        id: d.id,
        ...d.data()
      }));

      return res.status(200).json({ messages });
    } catch (error) {
      console.error("getFamilyChatMessages error:", error);
      return res.status(500).json({ error: error.message || "Błąd pobierania wiadomości czatu." });
    }
  }
);

/**
 * Retrieve justification requests for a student or parent.
 */
exports.getJustificationRequests = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const familyId = req.query.familyId || req.body?.familyId;
      const primaryLogin = req.query.primaryLogin || req.body?.primaryLogin;
      const studentLogin = req.query.studentLogin || req.body?.studentLogin;

      let query = admin.firestore().collection("justification_requests");

      if (familyId) {
        query = query.where("familyId", "==", familyId);
      } else if (primaryLogin) {
        query = query.where("primaryLogin", "==", primaryLogin);
      } else if (studentLogin) {
        query = query.where("studentLogin", "==", studentLogin);
      }

      const snap = await query.get();
      const requests = snap.docs.map(d => ({
        id: d.id,
        ...d.data()
      }));

      return res.status(200).json({ requests });
    } catch (error) {
      console.error("getJustificationRequests error:", error);
      return res.status(500).json({ error: error.message || "Błąd pobierania wniosków." });
    }
  }
);

const {
  escapeHtml,
  verifyAndPairCodeFromUpdates,
  sendTelegramMessage,
} = require("./src/telegram_service");

/**
 * Verify a 6-digit Telegram pairing code via Bot API getUpdates and save paired chatId (Phase 18: REQ-NOTIF-01).
 */
exports.verifyTelegramPairing = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const botToken = req.body?.botToken || req.query.botToken || process.env.TELEGRAM_BOT_TOKEN;
      const pairingCode = req.body?.pairingCode || req.query.pairingCode;
      const familyId = req.body?.familyId || req.query.familyId || "11010033";
      const roleKey = req.body?.roleKey || req.query.roleKey || "parent";

      const result = await verifyAndPairCodeFromUpdates(admin.firestore(), {
        botToken,
        pairingCode,
        familyId,
        roleKey,
      });

      return res.status(200).json(result);
    } catch (error) {
      console.error("verifyTelegramPairing error:", error);
      return res.status(500).json({
        paired: false,
        error: error.message || "Błąd weryfikacji kodu parowania Telegram."
      });
    }
  }
);

/**
 * Send a test notification via Telegram Bot (Phase 18: REQ-NOTIF-02).
 */
exports.sendTestTelegramNotification = onRequest(
  {
    region: "europe-west3",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (req, res) => {
    try {
      const botToken = req.body?.botToken || req.query.botToken || process.env.TELEGRAM_BOT_TOKEN;
      const chatId = req.body?.chatId || req.query.chatId;
      const roleLabel = escapeHtml(req.body?.roleLabel || "Rodzic");
      const studentName = escapeHtml(req.body?.studentName || "Oskar");

      const htmlText =
        `🔔 <b>Test powiadomienia • EduSync (Lepsza Szkoła)</b>\n\n` +
        `Kanał Telegram dla konta <b>${roleLabel}</b> (uczeń: <b>${studentName}</b>) działa prawidłowo!\n\n` +
        `📌 Przykład powiadomienia:\n` +
        `🎓 <b>Nowa ocena: 5 (Język angielski)</b>\n` +
        `📝 Sprawdzian • Waga: 3 • Nauczyciel: M. Nowak\n\n` +
        `🔗 <a href="https://lepsza-szkola.web.app/pulpit">Otwórz Pulpit EduSync</a>`;

      const apiRes = await sendTelegramMessage({
        botToken,
        chatId,
        htmlText,
      });

      return res.status(200).json({ success: true, result: apiRes });
    } catch (error) {
      console.error("sendTestTelegramNotification error:", error);
      return res.status(500).json({
        success: false,
        error: error.message || "Nie udało się wysłać testowej wiadomości Telegram."
      });
    }
  }
);



