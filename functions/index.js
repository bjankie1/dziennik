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
      const login = req.query.login || req.body?.login || process.env.LIBRUS_LOGIN || "";
      const email = req.query.email || req.body?.email || "";

      if (!userId) {
        return res.status(400).json({ error: "Missing userId" });
      }

      await admin.firestore().collection("users").doc(userId).set({
        userId,
        email,
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
