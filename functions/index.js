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
      let login = req.query.login || process.env.LIBRUS_LOGIN;
      const role = req.query.role || "parent";
      const primaryLogin = req.query.primaryLogin;

      // If user is student, resolve target document from primaryLogin (D-05, REQ-ROLE-03)
      if (role === "student" && primaryLogin) {
        login = primaryLogin;
      }

      if (!login) {
        return res.status(400).json({ error: "Brak parametru login" });
      }
      const doc = await admin.firestore().collection("students").doc(login).get();
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

      const login = req.query.login || req.body?.login || process.env.LIBRUS_LOGIN || "";
      const email = req.query.email || req.body?.email || "";
      const rawRole = req.query.role || req.body?.role || "parent";
      const role = String(rawRole).trim().toLowerCase() === "student" ? "student" : "parent";
      const rawStudentLogin = req.query.studentLogin || req.body?.studentLogin;
      const rawPrimaryLogin = req.query.primaryLogin || req.body?.primaryLogin;
      const rawFamilyId = req.query.familyId || req.body?.familyId || "jankiewicz_family";

      let studentLogin = rawStudentLogin || null;
      let primaryLogin = rawPrimaryLogin || null;

      if (role === "student") {
        studentLogin = login || studentLogin || null;
        if (!primaryLogin) {
          primaryLogin = process.env.LIBRUS_PRIMARY_LOGIN || process.env.LIBRUS_LOGIN || "7654321r";
        }
      } else {
        primaryLogin = login || primaryLogin || null;
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
      const login = req.query.login || req.body?.login || process.env.LIBRUS_LOGIN;
      const pass = process.env.LIBRUS_PASSWORD;
      const recipients = req.body?.recipients || req.query.recipients || [];
      const subject = req.body?.subject || req.query.subject || "";
      const body = req.body?.body || req.query.body || "";
      const replyToId = req.body?.replyToId || req.query.replyToId || null;

      if (!subject || !body) {
        return res.status(400).json({ error: "Brak tematu lub treści wiadomości." });
      }

      if (login && pass) {
        const client = new LibrusClient(login, pass);
        await client.authenticate();
        const result = await client.sendMessage({ recipients, subject, body, replyToMsgId: replyToId });
        return res.status(200).json(result);
      }

      return res.status(200).json({
        success: true,
        simulated: true,
        sentAt: new Date().toISOString(),
        recipients,
        subject
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
      const login = req.query.login || req.body?.login || process.env.LIBRUS_LOGIN;
      const pass = process.env.LIBRUS_PASSWORD;

      if (!msgId && !url) {
        return res.status(400).json({ error: "Missing msgId or url" });
      }

      if (login && pass) {
        const client = new LibrusClient(login, pass);
        await client.authenticate();
        const details = await client.fetchMessageDetails(msgId, url);

        // Update Firestore cached messages if present
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
                if (details.body) {
                  m.preview = details.body.replace(/\s+/g, " ").substring(0, 90);
                }
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

        return res.status(200).json(details);
      }

      return res.status(200).json({
        id: msgId,
        body: "Treść wiadomości pobrana w trybie demonstracyjnym."
      });
    } catch (error) {
      console.error("getMessageDetails error:", error);
      res.status(500).json({ error: error.message });
    }
  }
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

      const { requestId, action, pin, rejectionReason, parentLogin } = req.body || {};

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
        parentLogin
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
            const librusPayload = formatLibrusJustificationPayload(existingData);
            const client = new LibrusClient(parentLog, parentPass);
            await client.submitJustification(librusPayload);
          } catch (librusErr) {
            console.warn("Librus dispatch warning during parental approval:", librusErr.message);
          }
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


