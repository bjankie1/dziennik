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

