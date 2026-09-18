const { describe, it } = require("node:test");
const assert = require("node:assert");
const { LibrusClient } = require("../src/librus_client");

describe("LibrusClient Stealth & Session Tests", () => {
  it("should initialize with modern Chrome 133 headers and client hints", () => {
    const client = new LibrusClient("test_login", "test_pass");
    const headers = client.client.defaults.headers;

    assert.ok(headers["User-Agent"].includes("Chrome/133.0.0.0"), "User-Agent should be Chrome 133");
    assert.ok(!headers["User-Agent"].includes("Firefox/10.0"), "User-Agent must not be ancient Firefox");
    assert.ok(headers["Sec-Ch-Ua"].includes("Google Chrome"), "Sec-Ch-Ua should contain Google Chrome");
    assert.strictEqual(headers["Sec-Ch-Ua-Mobile"], "?0");
    assert.strictEqual(headers["Sec-Ch-Ua-Platform"], "\"Windows\"");
    assert.ok(headers["Accept-Language"].includes("pl-PL"), "Accept-Language should prioritize Polish");
    assert.strictEqual(headers["Upgrade-Insecure-Requests"], "1");
  });

  it("should serialize and deserialize CookieJar properly", () => {
    const client1 = new LibrusClient("test_login", "test_pass");
    client1.jar.setCookieSync("test_cookie=abc123xyz; Domain=synergia.librus.pl; Path=/", "https://synergia.librus.pl");

    const serialized = client1.exportCookies();
    assert.strictEqual(typeof serialized, "object");
    assert.ok(JSON.stringify(serialized).includes("test_cookie"), "Serialized jar should contain test_cookie");

    const client2 = new LibrusClient("test_login", "test_pass");
    client2.importCookies(serialized);

    const cookies = client2.jar.getCookiesSync("https://synergia.librus.pl");
    assert.strictEqual(cookies.length, 1);
    assert.strictEqual(cookies[0].key, "test_cookie");
    assert.strictEqual(cookies[0].value, "abc123xyz");
  });

  it("should detect expired session when isSessionAlive receives login form redirect", async () => {
    const client = new LibrusClient("test_login", "test_pass");
    // Mock client.client.get
    client.client.get = async () => ({
      status: 302,
      headers: { location: "https://synergia.librus.pl/loguj" },
      data: ""
    });

    const isAlive = await client.isSessionAlive();
    assert.strictEqual(isAlive, false, "Session should not be alive on 302 redirect to loguj");
  });

  it("should detect active session when isSessionAlive returns 200 without login form", async () => {
    const client = new LibrusClient("test_login", "test_pass");
    client.client.get = async () => ({
      status: 200,
      headers: {},
      data: "<html><body>Witaj w Synergia!</body></html>"
    });

    const isAlive = await client.isSessionAlive();
    assert.strictEqual(isAlive, true, "Session should be alive on 200 OK");
  });
});
