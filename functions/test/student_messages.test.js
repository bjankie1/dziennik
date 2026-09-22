const { describe, it } = require("node:test");
const assert = require("node:assert");
const { resolveMessageSession, buildMessageResponse } = require("../src/message_service");

describe("Plan 14-03: Student Message Session & Sender Attribution (REQ-ROLE-01, D-01, T-14-05, T-14-06)", () => {
  describe("Session Resolution", () => {
    it("should select student session when caller role is student with studentLogin", () => {
      const session = resolveMessageSession({
        role: "student",
        studentLogin: "1122334u",
        login: "7654321r"
      });

      assert.strictEqual(session.isStudent, true);
      assert.strictEqual(session.senderRole, "student");
      assert.strictEqual(session.senderName, "Oskar Jankiewicz");
      assert.strictEqual(session.sessionKey, "1122334u");
    });

    it("should select parent session when caller role is parent", () => {
      const session = resolveMessageSession({
        role: "parent",
        studentLogin: "1122334u",
        login: "7654321r"
      });

      assert.strictEqual(session.isStudent, false);
      assert.strictEqual(session.senderRole, "parent");
      assert.strictEqual(session.senderName, "Bartosz Jankiewicz");
      assert.strictEqual(session.sessionKey, "7654321r");
    });

    it("should fallback to environment or default parent login when role is parent and login is not provided", () => {
      const session = resolveMessageSession({
        role: "parent",
        defaultParentLogin: "env_parent_login"
      });

      assert.strictEqual(session.isStudent, false);
      assert.strictEqual(session.senderRole, "parent");
      assert.strictEqual(session.sessionKey, "env_parent_login");
    });

    it("should select student session if role is omitted but studentLogin is explicitly passed", () => {
      const session = resolveMessageSession({
        studentLogin: "998877u"
      });

      assert.strictEqual(session.isStudent, true);
      assert.strictEqual(session.senderRole, "student");
      assert.strictEqual(session.sessionKey, "998877u");
    });
  });

  describe("Response Metadata & Sender Attribution", () => {
    it("should attribute message response to Oskar Jankiewicz (uczeń) in simulated student mode", () => {
      const session = resolveMessageSession({
        role: "student",
        studentLogin: "1122334u"
      });

      const response = buildMessageResponse({
        success: true,
        simulated: true,
        recipients: ["Nauczyciel Matematyki"],
        subject: "Pytanie o zadanie domowe",
        sessionInfo: session
      });

      assert.strictEqual(response.success, true);
      assert.strictEqual(response.simulated, true);
      assert.strictEqual(response.senderRole, "student");
      assert.strictEqual(response.senderName, "Oskar Jankiewicz");
      assert.strictEqual(response.senderLogin, "1122334u");
      assert.deepStrictEqual(response.recipients, ["Nauczyciel Matematyki"]);
      assert.strictEqual(response.subject, "Pytanie o zadanie domowe");
      assert.ok(response.sentAt);
    });

    it("should attribute message response to Bartosz Jankiewicz in simulated parent mode", () => {
      const session = resolveMessageSession({
        role: "parent",
        login: "7654321r"
      });

      const response = buildMessageResponse({
        success: true,
        simulated: true,
        recipients: ["Wychowawca"],
        subject: "Zawiadomienie",
        sessionInfo: session
      });

      assert.strictEqual(response.success, true);
      assert.strictEqual(response.simulated, true);
      assert.strictEqual(response.senderRole, "parent");
      assert.strictEqual(response.senderName, "Bartosz Jankiewicz");
      assert.strictEqual(response.senderLogin, "7654321r");
      assert.deepStrictEqual(response.recipients, ["Wychowawca"]);
    });

    it("should include underlying client result properties when dispatch is real", () => {
      const session = resolveMessageSession({
        role: "student",
        studentLogin: "1122334u"
      });

      const response = buildMessageResponse({
        success: true,
        simulated: false,
        recipients: ["Pedagog"],
        subject: "Wizyta",
        sessionInfo: session,
        result: { librusMessageId: "987654" }
      });

      assert.strictEqual(response.success, true);
      assert.strictEqual(response.simulated, false);
      assert.strictEqual(response.librusMessageId, "987654");
      assert.strictEqual(response.senderRole, "student");
    });
  });
});
