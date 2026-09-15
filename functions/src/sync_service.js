const admin = require("firebase-admin");
const { LibrusClient } = require("./librus_client");

async function syncStudentData(login = process.env.LIBRUS_LOGIN, password = process.env.LIBRUS_PASSWORD) {
  if (!login || !password) {
    throw new Error("Brak danych logowania Librus. Ustaw zmienne LIBRUS_LOGIN i LIBRUS_PASSWORD.");
  }
  const db = admin.firestore();
  const client = new LibrusClient(login, password);

  console.log(`Starting sync for student: ${login}...`);
  const freshData = await client.fetchAll();

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
