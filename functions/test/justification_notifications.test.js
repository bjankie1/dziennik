const test = require("node:test");
const assert = require("node:assert/strict");
const {
  isJustificationApprovalMessage,
  detectJustificationNotifications,
  mergeAndIndexMessages
} = require("../src/sync_service");
const {
  formatNotificationForTelegram,
  isCategoryEnabled
} = require("../src/telegram_service");

test("isJustificationApprovalMessage identifies system justification confirmations", () => {
  assert.equal(
    isJustificationApprovalMessage({
      sender: "Usprawiedliwienia [System Librus]",
      subject: "Zaakceptowano usprawiedliwienie nieobecności",
      body: "Twoje usprawiedliwienie zostało zaakceptowane."
    }),
    true
  );

  assert.equal(
    isJustificationApprovalMessage({
      sender: "Sobota Łukasz [Wychowawca]",
      subject: "Usprawiedliwienie zostało zaakceptowane (2026-10-02)",
      body: "Wychowawca zaakceptował wniosek."
    }),
    true
  );

  assert.equal(
    isJustificationApprovalMessage({
      sender: "Sobota Łukasz [Wychowawca]",
      subject: "Wycieczka szkolna",
      body: "Proszę o wpłatę zaliczki."
    }),
    false
  );
});

test("mergeAndIndexMessages auto-archives and marks read justification confirmations while respecting manual overrides", async () => {
  const freshMessages = [
    {
      id: "msg_just_1",
      sender: "Usprawiedliwienia",
      subject: "Zaakceptowano usprawiedliwienie (2026-10-02)",
      body: "Potwierdzenie akceptacji.",
      isRead: false,
      bodyLoaded: true
    },
    {
      id: "msg_just_unarchived",
      sender: "Usprawiedliwienia",
      subject: "Zaakceptowano usprawiedliwienie (2026-09-25)",
      body: "Potwierdzenie akceptacji.",
      isRead: false,
      bodyLoaded: true
    },
    {
      id: "msg_reg_1",
      sender: "Kowalski Jan",
      subject: "Sprawdzian z matematyki",
      body: "W piątek sprawdzian.",
      isRead: false,
      bodyLoaded: true
    }
  ];

  const merged = await mergeAndIndexMessages({
    freshMessages,
    prevMessages: [],
    prevArchivedOverrides: {
      msg_just_unarchived: false,
      msg_reg_1: true
    },
    maxIncrementalFetch: 0
  });

  const just1 = merged.find(m => m.id === "msg_just_1");
  assert.equal(just1.isAutoArchived, true);
  assert.equal(just1.isArchived, true);
  assert.equal(just1.isRead, true);

  const justUnarchived = merged.find(m => m.id === "msg_just_unarchived");
  assert.equal(justUnarchived.isAutoArchived, true);
  assert.equal(justUnarchived.isArchived, false);

  const reg1 = merged.find(m => m.id === "msg_reg_1");
  assert.equal(reg1.isArchived, true);
});

test("detectJustificationNotifications detects new confirmation messages and attendance status transitions with deduplication", () => {
  const prevData = {
    messages: [],
    attendance: [
      {
        id: "att_1",
        date: "2026-10-02",
        lessonNumber: 1,
        subjectName: "Matematyka",
        type: "absent",
        justificationStatus: "requested"
      },
      {
        id: "att_2",
        date: "2026-10-03",
        lessonNumber: 2,
        subjectName: "Fizyka",
        type: "absent",
        justificationStatus: "requested"
      },
      {
        id: "att_3",
        date: "2026-10-03",
        lessonNumber: 3,
        subjectName: "Chemia",
        type: "absent",
        justificationStatus: "requested"
      }
    ],
    justifications: []
  };

  const freshData = {
    messages: [
      {
        id: "m_501",
        sender: "Usprawiedliwienia",
        subject: "Zaakceptowano usprawiedliwienie (2026-10-02)",
        body: "Wychowawca zaakceptował usprawiedliwienie za 2026-10-02.",
        date: "2026-10-04 07:30:00"
      }
    ],
    attendance: [
      {
        id: "att_1",
        date: "2026-10-02",
        lessonNumber: 1,
        subjectName: "Matematyka",
        type: "excused",
        justificationStatus: "approved"
      },
      {
        id: "att_2",
        date: "2026-10-03",
        lessonNumber: 2,
        subjectName: "Fizyka",
        type: "excused",
        justificationStatus: "approved"
      },
      {
        id: "att_3",
        date: "2026-10-03",
        lessonNumber: 3,
        subjectName: "Chemia",
        type: "excused",
        justificationStatus: "approved"
      }
    ],
    justifications: []
  };

  const notifs = detectJustificationNotifications({
    prevData,
    freshData,
    timestampValue: "2026-10-04T07:30:00Z"
  });

  // 2026-10-02 is covered by just_msg_m_501 (deduplicated), and 2026-10-03 produces just_att_2026-10-03
  assert.equal(notifs.length, 2);
  assert.equal(notifs[0].id, "just_msg_m_501");
  assert.equal(notifs[0].type, "justification");
  assert.equal(notifs[1].id, "just_att_2026-10-03");
  assert.equal(notifs[1].type, "justification");
  assert.match(notifs[1].body, /Usprawiedliwiono 2 godz\./);
  assert.match(notifs[1].body, /Fizyka, Chemia/);
});

test("formatNotificationForTelegram formats justification notifications and links to /frekwencja", () => {
  const html = formatNotificationForTelegram(
    {
      type: "justification",
      title: "Zaakceptowano usprawiedliwienie (2026-10-03)",
      body: "Usprawiedliwiono 2 godz. (lekcje: 2, 3) • Fizyka, Chemia"
    },
    "Oskar Jankiewicz"
  );

  assert.match(html, /Zaakceptowano usprawiedliwienie!/);
  assert.match(html, /Oskar Jankiewicz/);
  assert.match(html, /https:\/\/lepsza-szkola\.web\.app\/frekwencja/);
  assert.equal(isCategoryEnabled({ telegramEnabled: true }, "justification"), true);
});
