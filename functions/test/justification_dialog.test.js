const { describe, it } = require("node:test");
const assert = require("node:assert");
const {
  JUSTIFICATION_STATUS,
  processParentReview,
  processStudentResponse
} = require("../src/justification_service");
const {
  CHAT_MESSAGE_TYPE,
  buildJustificationChatCard
} = require("../src/chat_service");

describe("Justification Dialogue & Q&A Flow (justification_dialog.test.js)", () => {
  const baseRequest = {
    id: "req_test_001",
    studentLogin: "1234567u",
    studentName: "Oskar Jankiewicz",
    primaryLogin: "7654321r",
    familyId: "jankiewicz_family",
    recordIds: ["rec_101"],
    lessonNumbers: [3],
    subjectNames: ["Geografia"],
    date: "2026-09-23",
    reason: "Spóźnienie autobusu",
    status: JUSTIFICATION_STATUS.PENDING_PARENT_APPROVAL,
    requestedAt: "2026-09-23T07:00:00.000Z",
    dialogHistory: []
  };

  describe("Parent Rejection with Comment & Dialog History (REQ-ROLE-04, D-03)", () => {
    it("should reject request, record rejectionReason, and append parent entry to dialogHistory", () => {
      const result = processParentReview(baseRequest, {
        action: "reject",
        rejectionReason: "Dlaczego spóźniłeś się aż 45 minut?",
        parentLogin: "7654321r"
      });

      assert.strictEqual(result.success, true);
      assert.strictEqual(result.statusCode, 200);
      assert.strictEqual(result.updatedRequest.status, JUSTIFICATION_STATUS.REJECTED);
      assert.strictEqual(result.updatedRequest.rejectionReason, "Dlaczego spóźniłeś się aż 45 minut?");
      assert.strictEqual(result.updatedRequest.reviewedBy, "7654321r");
      assert.ok(result.updatedRequest.reviewedAt);

      assert.strictEqual(result.updatedRequest.dialogHistory.length, 1);
      const entry = result.updatedRequest.dialogHistory[0];
      assert.strictEqual(entry.senderRole, "parent");
      assert.strictEqual(entry.senderName, "7654321r");
      assert.strictEqual(entry.message, "Dlaczego spóźniłeś się aż 45 minut?");
      assert.ok(entry.timestamp);
    });

    it("should fallback to default rejection reason if none provided", () => {
      const result = processParentReview(baseRequest, {
        action: "reject",
        parentLogin: "7654321r"
      });

      assert.strictEqual(result.success, true);
      assert.strictEqual(result.updatedRequest.rejectionReason, "Odrzucone przez rodzica");
      assert.strictEqual(result.updatedRequest.dialogHistory[0].message, "Odrzucone przez rodzica");
    });
  });

  describe("Student Response to Rejection (REQ-ROLE-04, D-02)", () => {
    const rejectedRequest = {
      ...baseRequest,
      status: JUSTIFICATION_STATUS.REJECTED,
      rejectionReason: "Dlaczego spóźniłeś się aż 45 minut?",
      dialogHistory: [
        {
          senderRole: "parent",
          senderName: "Tata",
          message: "Dlaczego spóźniłeś się aż 45 minut?",
          timestamp: "2026-09-23T07:10:00.000Z"
        }
      ]
    };

    it("should allow student to answer, transition back to pending_parent_approval, and append entry", () => {
      const responseResult = processStudentResponse(rejectedRequest, {
        responseText: "Był wypadek na rondzie i utknęliśmy w korku, mam bilet.",
        studentLogin: "1234567u",
        studentName: "Oskar Jankiewicz"
      });

      assert.strictEqual(responseResult.success, true);
      assert.strictEqual(responseResult.statusCode, 200);
      assert.strictEqual(responseResult.updatedRequest.status, JUSTIFICATION_STATUS.PENDING_PARENT_APPROVAL);
      assert.strictEqual(responseResult.updatedRequest.reviewedAt, null);
      assert.strictEqual(responseResult.updatedRequest.reviewedBy, null);

      assert.strictEqual(responseResult.updatedRequest.dialogHistory.length, 2);
      const studentEntry = responseResult.updatedRequest.dialogHistory[1];
      assert.strictEqual(studentEntry.senderRole, "student");
      assert.strictEqual(studentEntry.senderName, "Oskar Jankiewicz");
      assert.strictEqual(studentEntry.message, "Był wypadek na rondzie i utknęliśmy w korku, mam bilet.");
      assert.ok(studentEntry.timestamp);
    });

    it("should prevent response if request is not in rejected status", () => {
      const pendingReq = { ...baseRequest, status: JUSTIFICATION_STATUS.PENDING_PARENT_APPROVAL };
      const res = processStudentResponse(pendingReq, {
        responseText: "Test"
      });

      assert.strictEqual(res.success, false);
      assert.strictEqual(res.statusCode, 400);
      assert.match(res.error, /tylko dla odrzuconych wniosków/i);
    });

    it("should reject empty or whitespace-only responseText", () => {
      const res = processStudentResponse(rejectedRequest, {
        responseText: "   "
      });

      assert.strictEqual(res.success, false);
      assert.strictEqual(res.statusCode, 400);
      assert.match(res.error, /nie może być pusta/i);
    });

    it("should reject responseText exceeding 500 characters", () => {
      const res = processStudentResponse(rejectedRequest, {
        responseText: "a".repeat(501)
      });

      assert.strictEqual(res.success, false);
      assert.strictEqual(res.statusCode, 400);
      assert.match(res.error, /nie może przekraczać 500 znaków/i);
    });
  });

  describe("Family Chat Card Generation for Rejection (D-02, REQ-CHAT-01)", () => {
    it("should format interactive chat card payload when justification is rejected", () => {
      const card = buildJustificationChatCard(baseRequest, "Brak zwolnienia lekarskiego", "Tata");

      assert.strictEqual(card.familyId, "jankiewicz_family");
      assert.strictEqual(card.senderRole, "parent");
      assert.strictEqual(card.senderName, "Tata");
      assert.strictEqual(card.type, CHAT_MESSAGE_TYPE.JUSTIFICATION_CARD);
      assert.strictEqual(card.text, "Brak zwolnienia lekarskiego");
      assert.strictEqual(card.isReadByStudent, false);
      assert.strictEqual(card.isReadByParent, true);

      assert.ok(card.metadata);
      assert.strictEqual(card.metadata.requestId, "req_test_001");
      assert.strictEqual(card.metadata.date, "2026-09-23");
      assert.deepStrictEqual(card.metadata.lessonNumbers, [3]);
      assert.deepStrictEqual(card.metadata.subjectNames, ["Geografia"]);
      assert.strictEqual(card.metadata.studentReason, "Spóźnienie autobusu");
    });
  });
});
