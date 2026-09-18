const { describe, it } = require("node:test");
const assert = require("node:assert");

describe("Librus Rate Limiting & Backoff Guard", () => {
  it("should evaluate locked status correctly when backoffUntil is in the future", () => {
    const futureDate = new Date(Date.now() + 15 * 60 * 1000);
    const mockLimitDoc = {
      isLocked: true,
      lockedUntil: { toDate: () => futureDate },
      reason: "HTTP 429 Too Many Requests"
    };

    const isCurrentlyLocked = mockLimitDoc.isLocked && mockLimitDoc.lockedUntil.toDate() > new Date();
    assert.strictEqual(isCurrentlyLocked, true, "Lock should be active when lockedUntil is in future");
  });

  it("should evaluate lock as expired when backoffUntil is in the past", () => {
    const pastDate = new Date(Date.now() - 5 * 60 * 1000);
    const mockLimitDoc = {
      isLocked: true,
      lockedUntil: { toDate: () => pastDate },
      reason: "HTTP 429 Too Many Requests"
    };

    const isCurrentlyLocked = mockLimitDoc.isLocked && mockLimitDoc.lockedUntil.toDate() > new Date();
    assert.strictEqual(isCurrentlyLocked, false, "Lock should be inactive when lockedUntil is in past");
  });

  it("should identify rate limit and server overload error indicators", () => {
    const rateLimitErrors = [
      { status: 429, message: "Too many requests" },
      { status: 503, message: "Service Unavailable" },
      { status: 200, message: "Wykryto zbyt wiele zapytań z Twojego adresu IP" },
      { status: 403, message: "Cloudflare captcha challenge required" }
    ];

    for (const err of rateLimitErrors) {
      const isRateLimit =
        err.status === 429 ||
        err.status === 503 ||
        err.message.includes("429") ||
        err.message.includes("503") ||
        err.message.toLowerCase().includes("rate limit") ||
        err.message.toLowerCase().includes("zbyt wiele") ||
        err.message.toLowerCase().includes("captcha");

      assert.strictEqual(isRateLimit, true, `Should detect rate limit for: ${err.message}`);
    }
  });
});
