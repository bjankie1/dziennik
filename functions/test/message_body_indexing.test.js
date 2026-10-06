const test = require("node:test");
const assert = require("node:assert/strict");
const { mergeAndIndexMessages } = require("../src/sync_service");

test("mergeAndIndexMessages preserves cached full bodies from prevMessages across sync cycles", async () => {
  const freshMessages = [
    {
      id: "101",
      sender: "Wychowawca",
      subject: "Informacja",
      date: "2026-05-10",
      preview: "Wycieczka klasy Oskara do Warszawy odbędzie się 18-20 maja.",
      body: "Wycieczka klasy Oskara do Warszawy odbędzie się 18-20 maja. Zbiórka o 6:45.",
      bodyLoaded: true,
      librusUrl: "https://synergia.librus.pl/wiadomosci/1/5/101"
    },
    {
      id: "102",
      sender: "Dyrekcja",
      subject: "Spotkanie",
      date: "2026-05-02",
      preview: "Spotkanie",
      body: "Spotkanie",
      bodyLoaded: false,
      librusUrl: "https://synergia.librus.pl/wiadomosci/1/5/102"
    }
  ];

  const prevMessages = [
    {
      id: "102",
      sender: "Dyrekcja",
      subject: "Spotkanie",
      date: "2026-05-02",
      preview: "Zebranie z rodzicami odbędzie się 28 maja o godz. 17:30 w sali 204.",
      body: "Szanowni Państwo, zebranie z rodzicami odbędzie się 28 maja o godz. 17:30 w sali 204.",
      bodyLoaded: true,
      librusUrl: "https://synergia.librus.pl/wiadomosci/1/5/102"
    }
  ];

  const merged = await mergeAndIndexMessages({
    freshMessages,
    prevMessages,
    client: null,
    maxIncrementalFetch: 0
  });

  assert.equal(merged.length, 2);
  assert.equal(merged[1].id, "102");
  assert.equal(merged[1].bodyLoaded, true);
  assert.match(merged[1].body, /zebranie z rodzicami odbędzie się 28 maja/i);
});

test("mergeAndIndexMessages incrementally fetches up to maxIncrementalFetch unindexed messages within maxIndexDepth", async () => {
  const freshMessages = [];
  for (let i = 1; i <= 16; i++) {
    const isTop10 = i <= 10;
    freshMessages.push({
      id: String(i),
      sender: "Nauczyciel",
      subject: `Temat ${i}`,
      date: "2026-05-01",
      preview: isTop10 ? `Pełny podgląd ${i}` : `Temat ${i}`,
      body: isTop10 ? `Pełna treść wiadomości nr ${i}` : `Temat ${i}`,
      bodyLoaded: isTop10,
      librusUrl: `https://synergia.librus.pl/wiadomosci/1/5/${i}`
    });
  }

  const fetchedIds = [];
  const sleepCalls = [];
  const mockClient = {
    fetchMessageDetails: async (id, url) => {
      fetchedIds.push(id);
      return {
        id,
        body: `Dociągnięta w tle treść wiadomości #${id} (wycieczka do Warszawy)`,
        bodyLoaded: true,
        librusUrl: url
      };
    }
  };

  const merged = await mergeAndIndexMessages({
    freshMessages,
    prevMessages: [],
    client: mockClient,
    maxIncrementalFetch: 4,
    maxIndexDepth: 40,
    jitterMinMs: 10,
    jitterMaxMs: 20,
    sleepFn: async (min, max) => {
      sleepCalls.push([min, max]);
    }
  });

  // Should have fetched exactly 4 unindexed messages: 11, 12, 13, 14
  assert.deepEqual(fetchedIds, ["11", "12", "13", "14"]);
  assert.equal(sleepCalls.length, 4);
  assert.equal(merged[10].bodyLoaded, true);
  assert.match(merged[10].body, /wycieczka do Warszawy/);
  assert.equal(merged[13].bodyLoaded, true);
  // Messages 15 and 16 remain unindexed until the next sync cycle
  assert.equal(merged[14].bodyLoaded, false);
  assert.equal(merged[15].bodyLoaded, false);
});

test("mergeAndIndexMessages respects maxIndexDepth and continues gracefully on single message fetch error", async () => {
  const freshMessages = [
    {
      id: "201",
      sender: "Nauczyciel",
      subject: "Błąd sieci",
      date: "2026-05-01",
      preview: "Błąd sieci",
      body: "Błąd sieci",
      bodyLoaded: false,
      librusUrl: "https://synergia.librus.pl/wiadomosci/1/5/201"
    },
    {
      id: "202",
      sender: "Wychowawca",
      subject: "Wycieczka",
      date: "2026-05-01",
      preview: "Wycieczka",
      body: "Wycieczka",
      bodyLoaded: false,
      librusUrl: "https://synergia.librus.pl/wiadomosci/1/5/202"
    },
    {
      id: "203",
      sender: "Poza limitem",
      subject: "Stara wiadomość",
      date: "2026-01-01",
      preview: "Stara wiadomość",
      body: "Stara wiadomość",
      bodyLoaded: false,
      librusUrl: "https://synergia.librus.pl/wiadomosci/1/5/203"
    }
  ];

  const mockClient = {
    fetchMessageDetails: async (id) => {
      if (id === "201") {
        throw new Error("Simulated timeout");
      }
      return {
        id,
        body: `Treść dla ${id}`,
        bodyLoaded: true
      };
    }
  };

  const merged = await mergeAndIndexMessages({
    freshMessages,
    prevMessages: [],
    client: mockClient,
    maxIncrementalFetch: 4,
    maxIndexDepth: 2, // Only top 2 inspected
    jitterMaxMs: 0
  });

  assert.equal(merged[0].bodyLoaded, false); // Failed gracefully
  assert.equal(merged[1].bodyLoaded, true);
  assert.equal(merged[1].body, "Treść dla 202");
  assert.equal(merged[2].bodyLoaded, false); // Beyond maxIndexDepth=2
});

test("mergeAndIndexMessages preserves driveAttachments and attachmentFiles for both top-10 (bodyLoaded=true) and older messages across sync cycles", async () => {
  const freshMessages = [
    {
      id: "301",
      sender: "Dyrekcja",
      subject: "Harmonogram matury",
      date: "2026-05-12",
      preview: "Pełna treść w top 10",
      body: "Pełna treść w top 10",
      bodyLoaded: true,
      hasAttachments: true,
      attachments: ["matura2027.pdf", "matura2027.pptx"],
      attachmentFiles: [
        { name: "matura2027.pdf", path: "/wiadomosci/pobierz_zalacznik/301/1" },
        { name: "matura2027.pptx", path: "/wiadomosci/pobierz_zalacznik/301/2" }
      ],
      librusUrl: "https://synergia.librus.pl/wiadomosci/1/5/301"
    },
    {
      id: "302",
      sender: "Wychowawca",
      subject: "Starsza wiadomość z załącznikiem",
      date: "2026-04-10",
      preview: "Starsza wiadomość z załącznikiem",
      body: "Starsza wiadomość z załącznikiem",
      bodyLoaded: false,
      hasAttachments: true,
      attachments: [],
      librusUrl: "https://synergia.librus.pl/wiadomosci/1/5/302"
    }
  ];

  const prevMessages = [
    {
      id: "301",
      sender: "Dyrekcja",
      subject: "Harmonogram matury",
      date: "2026-05-12",
      body: "Pełna treść w top 10",
      bodyLoaded: true,
      driveAttachments: {
        "matura2027.pdf": {
          driveFileId: "drive_301_1",
          webViewLink: "https://drive.google.com/file/d/drive_301_1/view",
          folderId: "root",
          folderName: "Mój dysk",
          savedAt: "2026-09-28T10:00:00.000Z",
          savedBy: "Rodzic"
        }
      }
    },
    {
      id: "302",
      sender: "Wychowawca",
      subject: "Starsza wiadomość z załącznikiem",
      date: "2026-04-10",
      body: "Pełna treść starszej wiadomości",
      bodyLoaded: true,
      hasAttachments: true,
      attachments: ["zgoda.pdf"],
      attachmentFiles: [
        { name: "zgoda.pdf", path: "/wiadomosci/pobierz_zalacznik/302/1" }
      ],
      driveAttachments: {
        "zgoda.pdf": {
          driveFileId: "drive_302_1",
          webViewLink: "https://drive.google.com/file/d/drive_302_1/view",
          folderId: "folder_szkola",
          folderName: "Szkoła",
          savedAt: "2026-09-28T11:00:00.000Z",
          savedBy: "Oskar"
        }
      }
    }
  ];

  const merged = await mergeAndIndexMessages({
    freshMessages,
    prevMessages,
    client: null,
    maxIncrementalFetch: 0
  });

  assert.equal(merged.length, 2);
  assert.ok(merged[0].driveAttachments);
  assert.equal(merged[0].driveAttachments["matura2027.pdf"].driveFileId, "drive_301_1");

  assert.equal(merged[1].bodyLoaded, true);
  assert.deepEqual(merged[1].attachments, ["zgoda.pdf"]);
  assert.equal(merged[1].attachmentFiles.length, 1);
  assert.equal(merged[1].attachmentFiles[0].path, "/wiadomosci/pobierz_zalacznik/302/1");
  assert.ok(merged[1].driveAttachments);
  assert.equal(merged[1].driveAttachments["zgoda.pdf"].folderName, "Szkoła");
});

test("LibrusClient.fetchMessages and fetchMessageDetails preserve multiline line breaks via _extractMultilineElementText", async () => {
  const { LibrusClient } = require("../src/librus_client");
  const client = new LibrusClient("test_login", "test_pass");

  const listHtml = `
    <table class="decorated">
      <tr class="line0 bold">
        <td><input type="checkbox" /></td>
        <td><img src="/images/nieprzeczytana.png" alt="nieprzeczytana" /></td>
        <td>Sobota Łukasz (Sobota Łukasz) [Wychowawca]</td>
        <td><a href="/wiadomosci/1/5/2027508">Wycieczka i materiały</a></td>
        <td>2026-10-04 08:15:00</td>
      </tr>
    </table>
  `;
  const detailHtml = `
    <div class="container-message-content">
      <p>Dzień dobry,</p>
      przesyłam harmonogram wycieczki:<br />
      • Dzień 1: Zwiedzanie zamku • Dzień 2: Warsztaty terenowe<br/>
      <p>Proszę o podpisanie zgody.</p>
    </div>
    <table>
      <tr>
        <td>harmonogram.pdf</td>
        <td><a href="/wiadomosci/pobierz_zalacznik/2027508/4410">Pobierz</a></td>
      </tr>
    </table>
  `;

  client.client = {
    get: async (url) => {
      if (url.endsWith("/wiadomosci/1/5")) {
        return { data: listHtml };
      }
      return { data: detailHtml };
    }
  };

  const { messages } = await client.fetchMessages();
  assert.equal(messages.length, 1);
  assert.equal(messages[0].id, "2027508");
  assert.ok(messages[0].body.includes("Dzień dobry,\nprzesyłam harmonogram wycieczki:\n• Dzień 1: Zwiedzanie zamku\n• Dzień 2: Warsztaty terenowe"));
  assert.ok(messages[0].body.includes("\nProszę o podpisanie zgody."));
  assert.ok(!messages[0].preview.includes("\n"));

  const details = await client.fetchMessageDetails("2027508", "https://synergia.librus.pl/wiadomosci/1/5/2027508");
  assert.equal(details.body, messages[0].body);
  assert.deepEqual(details.attachmentFiles, [
    { name: "harmonogram.pdf", path: "/wiadomosci/pobierz_zalacznik/2027508/4410" }
  ]);
});

test("mergeAndIndexMessages copies attachmentFiles and attachments from fetchMessageDetails during incremental indexing", async () => {
  const freshMessages = [
    {
      id: "401",
      sender: "Nauczyciel",
      subject: "Materiały do sprawdzianu",
      date: "2026-10-04",
      preview: "Materiały do sprawdzianu",
      body: "Materiały do sprawdzianu",
      bodyLoaded: false,
      hasAttachments: true,
      attachments: [],
      attachmentFiles: [],
      librusUrl: "https://synergia.librus.pl/wiadomosci/1/5/401"
    }
  ];

  const mockClient = {
    fetchMessageDetails: async (id, url) => ({
      id,
      body: "W załączniku zestaw zadań.\nPowodzenia!",
      bodyLoaded: true,
      hasAttachments: true,
      attachments: ["zadania.pdf"],
      attachmentFiles: [
        { name: "zadania.pdf", path: "/wiadomosci/pobierz_zalacznik/401/99" }
      ],
      librusUrl: url
    })
  };

  const merged = await mergeAndIndexMessages({
    freshMessages,
    prevMessages: [],
    client: mockClient,
    maxIncrementalFetch: 4,
    jitterMaxMs: 0
  });

  assert.equal(merged[0].bodyLoaded, true);
  assert.equal(merged[0].body, "W załączniku zestaw zadań.\nPowodzenia!");
  assert.equal(merged[0].hasAttachments, true);
  assert.deepEqual(merged[0].attachments, ["zadania.pdf"]);
  assert.deepEqual(merged[0].attachmentFiles, [
    { name: "zadania.pdf", path: "/wiadomosci/pobierz_zalacznik/401/99" }
  ]);
});

test("buildMessageAndAnnouncementNotifications hydrates unindexed new messages and populates content, messageId, and attachmentFiles while keeping body compact", async () => {
  const { buildMessageAndAnnouncementNotifications } = require("../src/sync_service");
  assert.equal(typeof buildMessageAndAnnouncementNotifications, "function");

  const prevData = {
    announcements: [{ id: "ann_old", title: "Stare" }],
    messages: [{ id: "100", subject: "Stara wiadomość" }]
  };

  const freshData = {
    announcements: [
      { id: "ann_old", title: "Stare", author: "Dyrekcja", date: "2026-09-01", content: "Stara treść" },
      {
        id: "2026_10_04_Konkurs",
        title: "Konkurs matematyczny",
        author: "Kowalski Jan",
        date: "2026-10-04",
        content: "Zapraszamy do udziału w konkursie.\nZapisy w sali 12."
      }
    ],
    messages: [
      {
        id: "915",
        sender: "Sobota Łukasz",
        subject: "Zebranie z rodzicami",
        date: "2026-10-04 09:30:00",
        preview: "Zebranie z rodzicami",
        body: "Zebranie z rodzicami",
        bodyLoaded: false,
        hasAttachments: true,
        attachments: [],
        attachmentFiles: [],
        librusUrl: "https://synergia.librus.pl/wiadomosci/1/5/915"
      }
    ]
  };

  const fetchedIds = [];
  const mockClient = {
    fetchMessageDetails: async (id, url) => {
      fetchedIds.push(id);
      return {
        id,
        body: "Szanowni Państwo,\nZebranie odbędzie się w czwartek o 17:30.\nPozdrawiam",
        bodyLoaded: true,
        hasAttachments: true,
        attachments: ["agenda.pdf"],
        attachmentFiles: [
          { name: "agenda.pdf", path: "/wiadomosci/pobierz_zalacznik/915/12" }
        ],
        librusUrl: url
      };
    }
  };

  const notifs = await buildMessageAndAnnouncementNotifications({
    prevData,
    freshData,
    client: mockClient,
    timestampValue: "2026-10-04T10:00:00Z"
  });

  assert.deepEqual(fetchedIds, ["915"]);
  assert.equal(notifs.length, 2);

  const annNotif = notifs.find(n => n.type === "announcement");
  assert.ok(annNotif);
  assert.equal(annNotif.title, "Nowe ogłoszenie: Konkurs matematyczny");
  assert.equal(annNotif.body, "Kowalski Jan (2026-10-04)");
  assert.equal(annNotif.content, "Zapraszamy do udziału w konkursie.\nZapisy w sali 12.");

  const msgNotif = notifs.find(n => n.type === "message");
  assert.ok(msgNotif);
  assert.equal(msgNotif.messageId, "915");
  assert.equal(msgNotif.title, "Nowa wiadomość: Zebranie z rodzicami");
  assert.equal(msgNotif.body, "Sobota Łukasz • 2026-10-04 09:30:00");
  assert.equal(msgNotif.content, "Szanowni Państwo,\nZebranie odbędzie się w czwartek o 17:30.\nPozdrawiam");
  assert.deepEqual(msgNotif.attachmentFiles, [
    { name: "agenda.pdf", path: "/wiadomosci/pobierz_zalacznik/915/12" }
  ]);
  assert.equal(freshData.messages[0].bodyLoaded, true);
  assert.equal(freshData.messages[0].attachmentFiles.length, 1);
});

test("mergeAndIndexMessages preserves and deduplicates replies from prevMessages and freshMessages across sync cycles", async () => {
  const prevMessages = [
    {
      id: "2722626",
      sender: "Sobota Łukasz [Wychowawca]",
      subject: "składka 21 zł na maturę próbną z Operonem",
      date: "2026-10-01 10:00:00",
      body: "Proszę o wpłatę 21 zł na maturę próbną z Operonem.",
      bodyLoaded: true,
      replies: [
        {
          id: "reply_1728000001",
          senderName: "Bartosz Jankiewicz",
          senderRole: "Rodzic",
          content: "Dzień dobry, przelałem dzisiaj 21 zł.",
          date: "2026-10-02T14:20:00.000Z",
          isMe: true
        },
        {
          id: "reply_1728000002",
          senderName: "Bartosz Jankiewicz",
          senderRole: "Rodzic",
          content: "Potwierdzenie w załączeniu.",
          date: "2026-10-03T09:15:00.000Z",
          isMe: true
        }
      ]
    }
  ];

  const freshMessages = [
    {
      id: "2722626",
      sender: "Sobota Łukasz [Wychowawca]",
      subject: "składka 21 zł na maturę próbną z Operonem",
      date: "2026-10-01 10:00:00",
      body: "Proszę o wpłatę 21 zł na maturę próbną z Operonem.",
      bodyLoaded: true,
      replies: [
        {
          id: "550011",
          senderName: "Ty",
          senderRole: "Rodzic",
          content: "Dzień dobry, przelałem dzisiaj 21 zł.",
          date: "2026-10-02 14:20:15",
          isMe: true
        }
      ]
    }
  ];

  const merged = await mergeAndIndexMessages({
    freshMessages,
    prevMessages,
    client: null,
    maxIncrementalFetch: 0
  });

  assert.equal(merged.length, 1);
  assert.ok(Array.isArray(merged[0].replies));
  assert.equal(merged[0].replies.length, 2);
  assert.equal(merged[0].replies[0].content, "Dzień dobry, przelałem dzisiaj 21 zł.");
  assert.equal(merged[0].replies[0].senderName, "Bartosz Jankiewicz");
  assert.equal(merged[0].replies[1].content, "Potwierdzenie w załączeniu.");
});

test("LibrusClient.fetchMessages scrapes /wiadomosci/6 (Wysłane), strips quoted original message text, and attaches sent replies to matching inbox thread", async () => {
  const { LibrusClient } = require("../src/librus_client");
  const client = new LibrusClient("test_login", "test_pass");

  const inboxHtml = `
    <table class="decorated">
      <tr class="line0">
        <td><input type="checkbox" /></td>
        <td><img src="/images/przeczytana.png" alt="przeczytana" /></td>
        <td>Sobota Łukasz (Sobota Łukasz) [Wychowawca]</td>
        <td><a href="/wiadomosci/1/5/2722626">składka 21 zł na maturę próbną z Operonem</a></td>
        <td>2026-10-01 10:00:00</td>
      </tr>
    </table>
  `;

  const inboxDetailHtml = `
    <div class="container-message-content">
      Dzień dobry,<br/>proszę o wpłatę 21 zł na maturę próbną z Operonem do piątku.
    </div>
  `;

  const sentListHtml = `
    <table class="decorated">
      <tr class="line0">
        <td><input type="checkbox" /></td>
        <td></td>
        <td>Sobota Łukasz (Sobota Łukasz) [Nauczyciel]</td>
        <td><a href="/wiadomosci/1/6/88002">Re: składka 21 zł na maturę próbną z Operonem</a></td>
        <td>2026-10-03 11:30:00</td>
      </tr>
      <tr class="line1">
        <td><input type="checkbox" /></td>
        <td></td>
        <td>Sobota Łukasz (Sobota Łukasz) [Nauczyciel]</td>
        <td><a href="/wiadomosci/1/6/88001">Re: składka 21 zł na maturę próbną z Operonem</a></td>
        <td>2026-10-02 09:15:00</td>
      </tr>
    </table>
  `;

  const sentDetail88001 = `
    <div class="container-message-content">
      Dzień dobry,<br/>wpłata 21 zł została zlecona przelewem.<br/><br/>----- Wiadomość oryginalna -----<br/>Użytkownik Sobota Łukasz napisał:<br/>proszę o wpłatę 21 zł na maturę próbną z Operonem do piątku.
    </div>
  `;

  const sentDetail88002 = `
    <div class="container-message-content">
      Potwierdzam również udział Oskara w części rozszerzonej.<br/>Użytkownik Sobota Łukasz (2026-10-01) napisał:<br/>proszę o wpłatę 21 zł
    </div>
  `;

  client.client = {
    get: async (url) => {
      if (url.endsWith("/wiadomosci/1/5")) return { data: inboxHtml };
      if (url.endsWith("/wiadomosci/1/5/2722626")) return { data: inboxDetailHtml };
      if (url.endsWith("/wiadomosci/6")) return { data: sentListHtml };
      if (url.endsWith("/wiadomosci/1/6/88001")) return { data: sentDetail88001 };
      if (url.endsWith("/wiadomosci/1/6/88002")) return { data: sentDetail88002 };
      throw new Error("Unexpected URL: " + url);
    }
  };

  const { messages } = await client.fetchMessages();
  assert.equal(messages.length, 1);
  assert.equal(messages[0].id, "2722626");
  assert.ok(Array.isArray(messages[0].replies));
  assert.equal(messages[0].replies.length, 2);
  // Sorted chronologically: 88001 (Oct 2) then 88002 (Oct 3)
  assert.equal(messages[0].replies[0].id, "88001");
  assert.equal(messages[0].replies[0].content, "Dzień dobry,\nwpłata 21 zł została zlecona przelewem.");
  assert.equal(messages[0].replies[0].isMe, true);
  assert.equal(messages[0].replies[1].id, "88002");
  assert.equal(messages[0].replies[1].content, "Potwierdzam również udział Oskara w części rozszerzonej.");
});

test("LibrusClient.sendMessage submits /wiadomosci/3/5/:id reply form via POST /wiadomosci with CSRF requestkey and DoKogo", async () => {
  const { LibrusClient } = require("../src/librus_client");
  const client = new LibrusClient("test_login", "test_pass");

  const replyFormHtml = `
    <form id="formWiadomosci" method="post" action="/wiadomosci">
      <input type="hidden" name="requestkey" value="rk_secret_123" />
      <input type="hidden" name="filtrUzytkownikow" value="0" />
      <input type="hidden" name="idPojemnika" value="5" />
      <input type="hidden" name="poprzednia" value="6" />
      <input type="hidden" name="DoKogo" value="445566" />
      <input type="hidden" name="Wid" value="2722626" />
      <input type="hidden" name="idWiadomosciOrg" value="2722626" />
      <input type="hidden" name="idOdpowiadajacego" value="0" />
      <input type="hidden" name="typ" value="odpowiedz" />
      <input type="hidden" name="fileStorageIdentifier" value="fs_abc_999" />
      <input type="text" name="temat" value="Re: składka 21 zł na maturę próbną z Operonem" />
      <textarea name="tresc">----- Wiadomość oryginalna -----
Proszę o wpłatę 21 zł.</textarea>
    </form>
  `;

  const getCalls = [];
  const postCalls = [];
  client.client = {
    get: async (url) => {
      getCalls.push(url);
      return { data: replyFormHtml };
    },
    post: async (url, data, config) => {
      postCalls.push({ url, data, config });
      return { status: 200, data: "Wysłano wiadomość" };
    }
  };

  const res = await client.sendMessage({
    recipients: ["Sobota Łukasz"],
    subject: "Re: składka 21 zł na maturę próbną z Operonem",
    body: "Dziękuję, opłacone.",
    replyToMsgId: "2722626"
  });

  assert.equal(res.success, true);
  assert.equal(res.sentViaLibrus, true);
  assert.deepEqual(getCalls, ["https://synergia.librus.pl/wiadomosci/3/5/2722626"]);
  assert.equal(postCalls.length, 1);
  assert.equal(postCalls[0].url, "https://synergia.librus.pl/wiadomosci");
  assert.equal(
    postCalls[0].config?.headers?.Referer,
    "https://synergia.librus.pl/wiadomosci/3/5/2722626"
  );

  const params = new URLSearchParams(postCalls[0].data);
  assert.equal(params.get("requestkey"), "rk_secret_123");
  assert.equal(params.get("DoKogo"), "445566");
  assert.equal(params.get("Wid"), "2722626");
  assert.equal(params.get("idWiadomosciOrg"), "2722626");
  assert.equal(params.get("fileStorageIdentifier"), "fs_abc_999");
  assert.equal(params.get("wyslij"), "Wyślij");
  assert.ok(params.get("tresc").startsWith("Dziękuję, opłacone."));
  assert.ok(params.get("tresc").includes("----- Wiadomość oryginalna -----"));
});



