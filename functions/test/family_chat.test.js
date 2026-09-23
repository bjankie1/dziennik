const { describe, it } = require("node:test");
const assert = require("node:assert");
const {
  CHAT_MESSAGE_TYPE,
  buildChatMessagePayload
} = require("../src/chat_service");

describe("Family Chat Service (family_chat.test.js)", () => {
  describe("Message payload construction & validation (REQ-CHAT-01)", () => {
    it("should build valid text message from student with proper read receipts", () => {
      const msg = buildChatMessagePayload({
        familyId: "jankiewicz_family",
        senderId: "student_oskar",
        senderName: "Oskar",
        senderRole: "student",
        text: "Cześć tato, spóźnię się 10 minut ze szkoły."
      });

      assert.strictEqual(msg.familyId, "jankiewicz_family");
      assert.strictEqual(msg.senderId, "student_oskar");
      assert.strictEqual(msg.senderName, "Oskar");
      assert.strictEqual(msg.senderRole, "student");
      assert.strictEqual(msg.text, "Cześć tato, spóźnię się 10 minut ze szkoły.");
      assert.strictEqual(msg.type, CHAT_MESSAGE_TYPE.TEXT);
      assert.strictEqual(msg.metadata, null);
      assert.strictEqual(msg.isReadByStudent, true);
      assert.strictEqual(msg.isReadByParent, false);
      assert.ok(msg.createdAt);
    });

    it("should build valid text message from parent with proper read receipts", () => {
      const msg = buildChatMessagePayload({
        familyId: "jankiewicz_family",
        senderId: "parent_tata",
        senderName: "Tata",
        senderRole: "parent",
        text: "Dobrze, uważaj na przejściu."
      });

      assert.strictEqual(msg.isReadByStudent, false);
      assert.strictEqual(msg.isReadByParent, true);
    });

    it("should reject message without familyId", () => {
      assert.throws(() => {
        buildChatMessagePayload({
          senderId: "user1",
          senderRole: "student",
          text: "Hej"
        });
      }, /Identyfikator rodziny \(familyId\) jest wymagany/i);
    });

    it("should reject message without senderId", () => {
      assert.throws(() => {
        buildChatMessagePayload({
          familyId: "fam1",
          senderRole: "student",
          text: "Hej"
        });
      }, /Identyfikator nadawcy \(senderId\) jest wymagany/i);
    });

    it("should reject invalid senderRole", () => {
      assert.throws(() => {
        buildChatMessagePayload({
          familyId: "fam1",
          senderId: "usr1",
          senderRole: "teacher",
          text: "Hej"
        });
      }, /Nieprawidłowa rola nadawcy/i);
    });

    it("should reject empty text for text type", () => {
      assert.throws(() => {
        buildChatMessagePayload({
          familyId: "fam1",
          senderId: "usr1",
          senderRole: "student",
          text: "   "
        });
      }, /Treść wiadomości tekstowej nie może być pusta/i);
    });

    it("should reject text exceeding 1000 characters", () => {
      assert.throws(() => {
        buildChatMessagePayload({
          familyId: "fam1",
          senderId: "usr1",
          senderRole: "parent",
          text: "x".repeat(1001)
        });
      }, /Wiadomość nie może przekraczać 1000 znaków/i);
    });

    it("should allow custom metadata for rich card types", () => {
      const msg = buildChatMessagePayload({
        familyId: "jankiewicz_family",
        senderId: "parent_1",
        senderRole: "parent",
        text: "Karta usprawiedliwienia",
        type: CHAT_MESSAGE_TYPE.JUSTIFICATION_CARD,
        metadata: { requestId: "req_999", action: "recheck" }
      });

      assert.strictEqual(msg.type, CHAT_MESSAGE_TYPE.JUSTIFICATION_CARD);
      assert.deepStrictEqual(msg.metadata, { requestId: "req_999", action: "recheck" });
    });
  });
});
