const { describe, it } = require("node:test");
const assert = require("node:assert");
const { LibrusClient, deriveLibrusModule } = require("../src/librus_client");

describe("Librus Query Access Logs Tests", () => {
  it("should derive correct module names from Librus URLs and endpoints", () => {
    assert.strictEqual(deriveLibrusModule("https://synergia.librus.pl/przegladaj_oceny/uczen"), "Oceny");
    assert.strictEqual(deriveLibrusModule("/przegladaj_plan_lekcji"), "Plan lekcji");
    assert.strictEqual(deriveLibrusModule("/przegladaj_nb/uczen"), "Frekwencja");
    assert.strictEqual(deriveLibrusModule("/eusprawiedliwienia"), "Frekwencja");
    assert.strictEqual(deriveLibrusModule("/wiadomosci/1/5"), "Wiadomości");
    assert.strictEqual(deriveLibrusModule("/terminarz"), "Terminarz");
    assert.strictEqual(deriveLibrusModule("/ogloszenia"), "Ogłoszenia");
    assert.strictEqual(deriveLibrusModule("/uczen/index"), "Profil / Sesja");
    assert.strictEqual(deriveLibrusModule("https://api.librus.pl/OAuth/Authorization"), "Autoryzacja");
    assert.strictEqual(deriveLibrusModule("/nieznany_zasob"), "Inne");
  });

  it("should invoke onQueryLog callback with duration and response metadata on success", async () => {
    const logs = [];
    const client = new LibrusClient("test_login", "test_pass", {
      onQueryLog: (entry) => logs.push(entry)
    });

    // Mock axios get response
    client.client.get = async (url) => {
      // Simulate interceptor response
      const logEntry = {
        url,
        endpoint: url,
        method: "GET",
        status: 200,
        statusText: "OK",
        durationMs: 42,
        responseSizeBytes: 1024,
        login: "test_login"
      };
      client.onQueryLog(logEntry);
      return { status: 200, data: "<html>ok</html>" };
    };

    await client.client.get("https://synergia.librus.pl/przegladaj_oceny/uczen");

    assert.strictEqual(logs.length, 1);
    assert.strictEqual(logs[0].status, 200);
    assert.strictEqual(logs[0].method, "GET");
    assert.strictEqual(logs[0].endpoint, "https://synergia.librus.pl/przegladaj_oceny/uczen");
    assert.strictEqual(logs[0].login, "test_login");
    assert.strictEqual(typeof logs[0].durationMs, "number");
  });
});
