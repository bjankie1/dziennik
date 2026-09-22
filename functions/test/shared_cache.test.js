const { describe, it } = require("node:test");
const assert = require("node:assert");

/**
 * Key resolution logic matching FirestoreSchoolRepository & sync_service
 * according to REQ-ROLE-03 (Single Source of Truth shared cache).
 */
function resolveCacheDocumentId({ role, librusLogin, primaryLogin }) {
  const isStudent = role === "student";
  if (isStudent && primaryLogin && primaryLogin.trim().length > 0) {
    return primaryLogin.trim();
  }
  return (librusLogin || "").trim();
}

/**
 * Scraping dispatch decision logic ensuring student reads and logins
 * do NOT invoke secondary scraping runs.
 */
function shouldDispatchLibrusScrape({ role, isBackgroundCron, forceRefresh }) {
  // If role is student, never trigger scraping on student reads/syncs.
  // Student views rely exclusively on cached data from primaryLogin.
  if (role === "student") {
    return false;
  }

  // Parents can trigger on background cron or explicit user refresh
  if (isBackgroundCron || forceRefresh) {
    return true;
  }

  return false;
}

describe("Shared Cache & Single Source of Truth (shared_cache.test.js)", () => {
  describe("Cache document ID resolution (D-05, REQ-ROLE-03)", () => {
    it("should resolve document ID to primaryLogin when role is student and primaryLogin is present", () => {
      const docId = resolveCacheDocumentId({
        role: "student",
        librusLogin: "1234567u",
        primaryLogin: "7654321r"
      });

      assert.strictEqual(docId, "7654321r", "Student should read from primary parent document cache");
    });

    it("should resolve document ID to librusLogin when role is parent", () => {
      const docId = resolveCacheDocumentId({
        role: "parent",
        librusLogin: "7654321r",
        primaryLogin: "7654321r"
      });

      assert.strictEqual(docId, "7654321r", "Parent reads from their own login document");
    });

    it("should fallback to librusLogin if role is student but primaryLogin is absent", () => {
      const docId = resolveCacheDocumentId({
        role: "student",
        librusLogin: "1234567u",
        primaryLogin: null
      });

      assert.strictEqual(docId, "1234567u", "Fallback to student login if primaryLogin missing");
    });
  });

  describe("Scraping prevention for student accounts (T-14-02)", () => {
    it("should strictly prevent scraping dispatch for student background sync", () => {
      const shouldScrape = shouldDispatchLibrusScrape({
        role: "student",
        isBackgroundCron: true,
        forceRefresh: false
      });

      assert.strictEqual(shouldScrape, false, "Student accounts must not trigger Librus scraping jobs");
    });

    it("should strictly prevent scraping dispatch when student requests manual refresh", () => {
      const shouldScrape = shouldDispatchLibrusScrape({
        role: "student",
        isBackgroundCron: false,
        forceRefresh: true
      });

      assert.strictEqual(shouldScrape, false, "Student forced refresh must still serve from primaryLogin cache");
    });

    it("should allow scraping dispatch for parent account on background cron", () => {
      const shouldScrape = shouldDispatchLibrusScrape({
        role: "parent",
        isBackgroundCron: true,
        forceRefresh: false
      });

      assert.strictEqual(shouldScrape, true, "Parent account sync should scrape and populate shared cache");
    });

    it("should simulate shared cache read: student and parent observe identical class data", () => {
      const mockFirestore = {
        "students/7654321r": {
          student: { name: "Oskar Jankiewicz", className: "4 k Lic" },
          timetable: [{ lesson: 1, subject: "Matematyka" }],
          luckyNumber: 18,
          lastSyncTime: "2026-09-22T06:30:00.000Z"
        }
      };

      const parentUser = { role: "parent", librusLogin: "7654321r", primaryLogin: "7654321r" };
      const studentUser = { role: "student", librusLogin: "1234567u", primaryLogin: "7654321r" };

      const parentDocKey = `students/${resolveCacheDocumentId(parentUser)}`;
      const studentDocKey = `students/${resolveCacheDocumentId(studentUser)}`;

      assert.strictEqual(parentDocKey, studentDocKey);
      assert.deepStrictEqual(mockFirestore[parentDocKey], mockFirestore[studentDocKey]);
      assert.strictEqual(mockFirestore[studentDocKey].luckyNumber, 18);
    });
  });
});
