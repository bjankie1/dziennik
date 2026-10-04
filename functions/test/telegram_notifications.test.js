const test = require("node:test");
const assert = require("node:assert/strict");
const { LibrusClient } = require("../src/librus_client");
const { buildMessageAndAnnouncementNotifications } = require("../src/sync_service");
const {
  formatNotificationForTelegram,
  truncateTelegramContent,
  formatMessageAttachmentsForTelegram
} = require("../src/telegram_service");

test("LibrusClient extracts multiline message content from <br>, <p>, and bullet lists (D-03, REQ-NOTIF-TG-MSG-01)", async () => {
  const client = new LibrusClient("login_1", "pass_1");

  const detailHtml = `
    <div class="container-message-content">
      <p>Szanowni Rodzice,</p>
      Przypominam o ważnych sprawach:<br>
      • Punkt pierwszy<br />
      • Punkt drugi
      <p>Z poważaniem,<br>Wychowawca</p>
    </div>
    <table>
      <tr>
        <td>regulamin &amp; zgoda.pdf</td>
        <td><a onclick="otworz_w_nowym_oknie('/wiadomosci/pobierz_zalacznik/2027508/101','pobierz',420,250)">Pobierz</a></td>
      </tr>
    </table>
  `;

  client.client = {
    get: async () => ({ data: detailHtml })
  };

  const details = await client.fetchMessageDetails(
    "2027508",
    "https://synergia.librus.pl/wiadomosci/1/5/2027508"
  );

  assert.equal(details.id, "2027508");
  assert.equal(details.bodyLoaded, true);
  assert.ok(details.body.includes("Szanowni Rodzice,\n"));
  assert.ok(details.body.includes("• Punkt pierwszy\n• Punkt drugi"));
  assert.ok(details.body.includes("Z poważaniem,\nWychowawca"));
  assert.deepEqual(details.attachmentFiles, [
    {
      name: "regulamin & zgoda.pdf",
      path: "/wiadomosci/pobierz_zalacznik/2027508/101"
    }
  ]);
});

test("buildMessageAndAnnouncementNotifications hydrates missing body/attachments and formats Telegram notifications end-to-end (D-03, D-07)", async () => {
  const prevData = {
    announcements: [],
    messages: []
  };

  const freshData = {
    announcements: [
      {
        id: "ann_2026_10_04",
        title: "Dzień Edukacji Narodowej",
        author: "Dyrekcja Szkoły",
        date: "2026-10-04",
        content: "14 października jest dniem wolnym od zajęć dydaktycznych.\nŚwietlica czynna w godz. 7:00-16:00."
      }
    ],
    messages: [
      {
        id: "2027508",
        sender: "Sobota Łukasz [Wychowawca]",
        subject: "Wycieczka klasowa - dokumenty",
        date: "2026-10-04 08:30:00",
        preview: "Wycieczka klasowa - dokumenty",
        body: "Wycieczka klasowa - dokumenty",
        bodyLoaded: false,
        hasAttachments: true,
        attachments: [],
        attachmentFiles: [],
        librusUrl: "https://synergia.librus.pl/wiadomosci/1/5/2027508"
      }
    ]
  };

  const mockClient = {
    fetchMessageDetails: async (id, url) => ({
      id,
      body: "Dzień dobry,\nW załączeniu przesyłam kartę wycieczki oraz regulamin.\nProszę o zwrot do piątku.",
      bodyLoaded: true,
      hasAttachments: true,
      attachments: ["karta_wycieczki.pdf", "regulamin.docx"],
      attachmentFiles: [
        { name: "karta_wycieczki.pdf", path: "/wiadomosci/pobierz_zalacznik/2027508/1" },
        { name: "regulamin.docx", path: "/wiadomosci/pobierz_zalacznik/2027508/2" }
      ],
      librusUrl: url
    })
  };

  const notifications = await buildMessageAndAnnouncementNotifications({
    prevData,
    freshData,
    client: mockClient,
    timestampValue: "2026-10-04T08:35:00Z"
  });

  assert.equal(notifications.length, 2);

  const annNotif = notifications.find(n => n.type === "announcement");
  const msgNotif = notifications.find(n => n.type === "message");

  // D-07: compact body preserved for "Ostatnie alerty", full text in content
  assert.equal(annNotif.body, "Dyrekcja Szkoły (2026-10-04)");
  assert.ok(annNotif.content.includes("14 października jest dniem wolnym"));
  assert.equal(msgNotif.body, "Sobota Łukasz [Wychowawca] • 2026-10-04 08:30:00");
  assert.ok(msgNotif.content.includes("W załączeniu przesyłam kartę wycieczki"));
  assert.equal(msgNotif.messageId, "2027508");
  assert.equal(msgNotif.attachmentFiles.length, 2);
});

test("formatNotificationForTelegram renders message template with full multiline content, attachment download links, and deep link (D-01, D-04, D-05, D-06, REQ-NOTIF-TG-MSG-01, REQ-NOTIF-TG-ATT-01)", () => {
  const notif = {
    id: "msg_2027508",
    type: "message",
    messageId: "2027508",
    title: "Nowa wiadomość: Wycieczka klasowa",
    body: "Sobota Łukasz • 2026-10-04 08:30:00",
    content: "Dzień dobry,\nZbiórka o 7:15 przed szkołą.\nProszę zabrać legitymację.",
    attachmentFiles: [
      { name: "harmonogram.pdf", path: "/wiadomosci/pobierz_zalacznik/2027508/1" },
      { name: "zgoda_rodzica.pdf", path: "" }
    ]
  };

  const html = formatNotificationForTelegram(notif, "Oskar Jankiewicz");

  assert.match(html, /^📬 <b>Nowa wiadomość w Librusie<\/b> \(Oskar Jankiewicz\)/);
  assert.match(html, /📌 <b>Nowa wiadomość: Wycieczka klasowa<\/b>/);
  assert.match(html, /👤 Sobota Łukasz • 2026-10-04 08:30:00/);
  assert.ok(
    html.includes("Dzień dobry,\nZbiórka o 7:15 przed szkołą.\nProszę zabrać legitymację."),
    "Expected multiline message content with preserved newlines"
  );
  assert.match(html, /📎 <b>Załączniki \(2\):<\/b>/);
  assert.ok(
    html.includes(
      '• <a href="https://lepsza-szkola.web.app/api/downloadAttachment?path=%2Fwiadomosci%2Fpobierz_zalacznik%2F2027508%2F1">harmonogram.pdf</a>'
    ),
    "Expected clickable downloadAttachment link with URL-encoded path"
  );
  assert.ok(
    html.includes("• zgoda_rodzica.pdf"),
    "Expected plain filename fallback when attachment path is empty"
  );
  assert.ok(
    html.includes(
      '🔗 <a href="https://lepsza-szkola.web.app/wiadomosci/2027508">Otwórz wiadomość w EduSync</a>'
    ),
    "Expected deep link to specific message thread /wiadomosci/2027508"
  );
});

test("formatNotificationForTelegram renders distinct announcement template with full multiline content (D-01, D-06, REQ-NOTIF-TG-ANN-01)", () => {
  const notif = {
    id: "ann_1",
    type: "announcement",
    title: "Nowe ogłoszenie: Zmiana organizacji ruchu",
    body: "Dyrekcja (2026-10-04)",
    content: "Uwaga uczniowie i rodzice!\nOd poniedziałku wejście główne będzie zamknięte.\n• Klasy 1-2 wchodzą wejściem B\n• Klasy 3-4 wchodzą wejściem C"
  };

  const html = formatNotificationForTelegram(notif, "Oskar");

  assert.match(html, /^📢 <b>Nowe ogłoszenie szkolne<\/b> \(Oskar\)/);
  assert.match(html, /📌 <b>Nowe ogłoszenie: Zmiana organizacji ruchu<\/b>/);
  assert.match(html, /👤 Dyrekcja \(2026-10-04\)/);
  assert.ok(
    html.includes(
      "Uwaga uczniowie i rodzice!\nOd poniedziałku wejście główne będzie zamknięte.\n• Klasy 1-2 wchodzą wejściem B\n• Klasy 3-4 wchodzą wejściem C"
    )
  );
  assert.ok(
    html.includes(
      '🔗 <a href="https://lepsza-szkola.web.app/wiadomosci">Otwórz ogłoszenia w EduSync</a>'
    )
  );
});

test("formatMessageAttachmentsForTelegram handles null, empty array, single attachment, and string array cleanly (REQ-NOTIF-TG-ATT-01)", () => {
  assert.equal(formatMessageAttachmentsForTelegram(null), "");
  assert.equal(formatMessageAttachmentsForTelegram({ attachmentFiles: [] }), "");

  const singleHtml = formatMessageAttachmentsForTelegram({
    attachmentFiles: [
      { name: "Matura <2027> & arkusz.pdf", path: "/wiadomosci/pobierz_zalacznik/100/200" }
    ]
  });
  assert.match(singleHtml, /📎 <b>Załączniki \(1\):<\/b>/);
  assert.ok(
    singleHtml.includes(
      '• <a href="https://lepsza-szkola.web.app/api/downloadAttachment?path=%2Fwiadomosci%2Fpobierz_zalacznik%2F100%2F200">Matura &lt;2027&gt; &amp; arkusz.pdf</a>'
    )
  );

  const stringFallbackHtml = formatMessageAttachmentsForTelegram({
    attachments: ["plan_lekcji.pdf"]
  });
  assert.match(stringFallbackHtml, /📎 <b>Załączniki \(1\):<\/b>/);
  assert.ok(stringFallbackHtml.includes("• plan_lekcji.pdf"));
});

test("truncateTelegramContent and formatNotificationForTelegram safely truncate >5000-char content with HTML characters within 4096-char limit (D-02)", () => {
  const repeatedParagraph =
    "Informacja o sprawdzianie <script>alert(1)</script> & zadaniach domowych > dział 4.\n";
  const hugeContent = repeatedParagraph.repeat(85); // ~6800 chars raw, >7800 chars escaped

  const truncated = truncateTelegramContent(hugeContent, 3500);
  assert.ok(truncated.length <= 3500, `Expected truncated length <= 3500, got ${truncated.length}`);
  assert.ok(truncated.endsWith("… (pełna treść w aplikacji)"));
  assert.ok(!truncated.includes("<script>"), "Must escape HTML tags");
  assert.ok(!/&(?!(amp|lt|gt);)/.test(truncated), "Must not contain broken HTML entities");

  const notif = {
    id: "msg_999999",
    type: "message",
    messageId: "999999",
    title: "Nowa wiadomość: Bardzo długi komunikat <ważne> & pilne",
    body: "Nauczyciel Matematyki • 2026-10-04 12:00:00",
    content: hugeContent,
    attachmentFiles: [
      { name: "zestaw_zadan_1.pdf", path: "/wiadomosci/pobierz_zalacznik/999999/1" },
      { name: "zestaw_zadan_2.pdf", path: "/wiadomosci/pobierz_zalacznik/999999/2" }
    ]
  };

  const fullTelegramHtml = formatNotificationForTelegram(notif, "Oskar Jankiewicz");
  assert.ok(
    fullTelegramHtml.length <= 4096,
    `Expected total Telegram HTML <= 4096 chars, got ${fullTelegramHtml.length}`
  );

  const suffixIdx = fullTelegramHtml.indexOf("… (pełna treść w aplikacji)");
  const attachIdx = fullTelegramHtml.indexOf("📎 <b>Załączniki (2):</b>");
  const footerIdx = fullTelegramHtml.indexOf("🔗 <a href=");

  assert.ok(suffixIdx > 0, "Expected truncation suffix in message");
  assert.ok(attachIdx > suffixIdx, "Expected attachments section after truncation suffix");
  assert.ok(footerIdx > attachIdx, "Expected footer deep link after attachments section");
  assert.ok(!fullTelegramHtml.includes("<script>"), "Must not contain unescaped <script> tag");
});
