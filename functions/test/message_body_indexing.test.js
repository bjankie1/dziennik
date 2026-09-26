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
