const { describe, it } = require("node:test");
const assert = require("node:assert");
const {
  JUSTIFICATION_STATUS,
  VALID_DEFAULT_PIN,
  sanitizeStudentRequest,
  processParentReview,
  formatLibrusJustificationPayload
} = require("../src/justification_service");

describe("Justification Requests Flow (justification_requests.test.js)", () => {
  describe("Student request sanitization & validation (Wave 0 / Task 1)", () => {
    it("should sanitize valid student request and initialize status to pending_parent_approval", () => {
      const payload = {
        studentLogin: "1234567u",
        studentName: "Oskar Jankiewicz",
        primaryLogin: "7654321r",
        familyId: "jankiewicz_family",
        recordIds: ["rec_001", "rec_002"],
        lessonNumbers: [2, 3],
        subjectNames: ["Matematyka", "Język polski"],
        date: "2026-09-22",
        reason: "Wizyta u ortodonty"
      };

      const sanitized = sanitizeStudentRequest(payload);
      assert.strictEqual(sanitized.studentLogin, "1234567u");
      assert.strictEqual(sanitized.studentName, "Oskar Jankiewicz");
      assert.strictEqual(sanitized.primaryLogin, "7654321r");
      assert.strictEqual(sanitized.familyId, "jankiewicz_family");
      assert.deepStrictEqual(sanitized.recordIds, ["rec_001", "rec_002"]);
      assert.deepStrictEqual(sanitized.lessonNumbers, [2, 3]);
      assert.deepStrictEqual(sanitized.subjectNames, ["Matematyka", "Język polski"]);
      assert.strictEqual(sanitized.date, "2026-09-22");
      assert.strictEqual(sanitized.reason, "Wizyta u ortodonty");
      assert.strictEqual(sanitized.status, JUSTIFICATION_STATUS.PENDING_PARENT_APPROVAL);
      assert.ok(sanitized.requestedAt);
    });

    it("should reject payload without studentLogin", () => {
      assert.throws(() => {
        sanitizeStudentRequest({
          recordIds: ["rec_1"],
          reason: "Choroba"
        });
      }, /Brak identyfikatora ucznia/i);
    });

    it("should reject payload without recordIds or with empty recordIds", () => {
      assert.throws(() => {
        sanitizeStudentRequest({
          studentLogin: "1234567u",
          recordIds: [],
          reason: "Choroba"
        });
      }, /Należy wskazać co najmniej jedną lekcję/i);

      assert.throws(() => {
        sanitizeStudentRequest({
          studentLogin: "1234567u",
          recordIds: null,
          reason: "Choroba"
        });
      }, /Należy wskazać co najmniej jedną lekcję/i);
    });

    it("should reject payload with empty reason or reason exceeding 250 chars", () => {
      assert.throws(() => {
        sanitizeStudentRequest({
          studentLogin: "1234567u",
          recordIds: ["rec_1"],
          reason: "   "
        });
      }, /Powód usprawiedliwienia jest wymagany/i);

      const longReason = "a".repeat(251);
      assert.throws(() => {
        sanitizeStudentRequest({
          studentLogin: "1234567u",
          recordIds: ["rec_1"],
          reason: longReason
        });
      }, /nie może przekraczać 250 znaków/i);
    });

    it("should sanitize and filter invalid lesson numbers", () => {
      const sanitized = sanitizeStudentRequest({
        studentLogin: "1234567u",
        recordIds: ["rec_1"],
        lessonNumbers: [1, "invalid", 99, 4, -1],
        reason: "Sprawy rodzinne"
      });
      assert.deepStrictEqual(sanitized.lessonNumbers, [1, 4]);
    });
  });

  describe("Parent review & PIN verification state transitions (REQ-ROLE-02, T-14-03, T-14-04)", () => {
    const baseRequest = {
      id: "req_123",
      studentLogin: "1234567u",
      studentName: "Oskar Jankiewicz",
      primaryLogin: "7654321r",
      familyId: "jankiewicz_family",
      recordIds: ["rec_001"],
      lessonNumbers: [3],
      subjectNames: ["Historia"],
      date: "2026-09-22",
      reason: "Wizyta lekarska",
      status: JUSTIFICATION_STATUS.PENDING_PARENT_APPROVAL,
      requestedAt: "2026-09-22T07:00:00.000Z"
    };

    it("should approve request when valid 4-digit PIN ('1234') is provided", () => {
      const reviewResult = processParentReview(baseRequest, {
        action: "approve",
        pin: VALID_DEFAULT_PIN,
        parentLogin: "7654321r"
      });

      assert.strictEqual(reviewResult.success, true);
      assert.strictEqual(reviewResult.statusCode, 200);
      assert.strictEqual(reviewResult.updatedRequest.status, JUSTIFICATION_STATUS.APPROVED);
      assert.strictEqual(reviewResult.updatedRequest.reviewedBy, "7654321r");
      assert.strictEqual(reviewResult.updatedRequest.pinVerified, true);
      assert.ok(reviewResult.updatedRequest.reviewedAt);
    });

    it("should reject approval when invalid PIN is provided and preserve pending state", () => {
      const reviewResult = processParentReview(baseRequest, {
        action: "approve",
        pin: "9999",
        parentLogin: "7654321r"
      });

      assert.strictEqual(reviewResult.success, false);
      assert.strictEqual(reviewResult.statusCode, 401);
      assert.match(reviewResult.error, /Niepoprawny kod PIN rodzica/i);
      // Ensure baseRequest was not mutated
      assert.strictEqual(baseRequest.status, JUSTIFICATION_STATUS.PENDING_PARENT_APPROVAL);
    });

    it("should reject approval when PIN has wrong format (letters or wrong length)", () => {
      const reviewResult1 = processParentReview(baseRequest, {
        action: "approve",
        pin: "abcd"
      });
      assert.strictEqual(reviewResult1.success, false);
      assert.strictEqual(reviewResult1.statusCode, 401);

      const reviewResult2 = processParentReview(baseRequest, {
        action: "approve",
        pin: "123"
      });
      assert.strictEqual(reviewResult2.success, false);
      assert.strictEqual(reviewResult2.statusCode, 401);
    });

    it("should reject request when parent chooses rejection with optional reason", () => {
      const reviewResult = processParentReview(baseRequest, {
        action: "reject",
        rejectionReason: "Brak zwolnienia lekarskiego",
        parentLogin: "7654321r"
      });

      assert.strictEqual(reviewResult.success, true);
      assert.strictEqual(reviewResult.statusCode, 200);
      assert.strictEqual(reviewResult.updatedRequest.status, JUSTIFICATION_STATUS.REJECTED);
      assert.strictEqual(reviewResult.updatedRequest.rejectionReason, "Brak zwolnienia lekarskiego");
      assert.ok(reviewResult.updatedRequest.reviewedAt);
    });

    it("should prevent duplicate processing if request is already approved or rejected (T-14-04)", () => {
      const alreadyApproved = {
        ...baseRequest,
        status: JUSTIFICATION_STATUS.APPROVED
      };

      const result = processParentReview(alreadyApproved, {
        action: "approve",
        pin: "1234"
      });

      assert.strictEqual(result.success, false);
      assert.strictEqual(result.statusCode, 409);
      assert.match(result.error, /Wniosek został już rozpatrzony/i);
    });
  });

  describe("Librus justification formatting", () => {
    it("should format request into payload suitable for LibrusClient.submitJustification", () => {
      const req = {
        reason: "Wizyta lekarska",
        date: "2026-09-22",
        lessonNumbers: [1, 2]
      };

      const payload = formatLibrusJustificationPayload(req);
      assert.strictEqual(payload.reason, "Wizyta lekarska");
      assert.strictEqual(payload.dateFrom, "2026-09-22");
      assert.strictEqual(payload.dateTo, "2026-09-22");
      assert.strictEqual(payload.isByHours, true);
      assert.deepStrictEqual(payload.hoursByDate, {
        "2026-09-22": [1, 2]
      });
      assert.strictEqual(payload.notifyOthers, true);
    });
  });
});
