const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const { syncStudentData } = require("./src/sync_service");

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

      if (!login || !pass) {
        return res.status(400).json({
          success: false,
          error: "Brak danych logowania (login / password)."
        });
      }

      const result = await syncStudentData(login, pass);
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
      const login = req.query.login || process.env.LIBRUS_LOGIN;
      if (!login) {
        return res.status(400).json({ error: "Brak parametru login" });
      }
      const doc = await admin.firestore().collection("students").doc(login).get();
      if (!doc.exists) {
        // If not yet synced, run sync once
        const pass = process.env.LIBRUS_PASSWORD;
        if (!pass) {
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

      await admin.firestore().collection("users").doc(userId).set({
        userId,
        email,
        connected: true,
        librusLogin: login,
        isDemoMode: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      res.status(200).json({ success: true, userId, librusLogin: login });
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
        isDemoMode: data.isDemoMode || false
      });
    } catch (error) {
      console.error("getConnection error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * Scheduled background sync every 30 minutes.
 */
exports.scheduledLibrusSync = onSchedule(
  {
    region: "europe-west3",
    schedule: "every 30 minutes",
    timeZone: "Europe/Warsaw",
    timeoutSeconds: 60,
    memory: "512MiB"
  },
  async (event) => {
    console.log("Starting scheduled 30-minute Librus sync job...");
    try {
      const login = process.env.LIBRUS_LOGIN;
      const pass = process.env.LIBRUS_PASSWORD;
      if (!login || !pass) {
        console.warn("scheduledLibrusSync: Brak skonfigurowanych zmiennych LIBRUS_LOGIN / LIBRUS_PASSWORD.");
        return;
      }
      const result = await syncStudentData(login, pass);
      console.log("Scheduled sync finished successfully:", result);
    } catch (error) {
      console.error("Scheduled sync error:", error);
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
