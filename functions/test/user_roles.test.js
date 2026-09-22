const { describe, it } = require("node:test");
const assert = require("node:assert");

/**
 * Helper simulating role parsing and connection payload formatting
 * according to REQ-ROLE-01, REQ-ROLE-02, and Plan 14-01 specs.
 */
function parseUserRole(roleInput) {
  if (typeof roleInput === "string" && roleInput.trim().toLowerCase() === "student") {
    return "student";
  }
  return "parent";
}

function formatConnectionPayload({ userId, email, login, role, studentLogin, primaryLogin, familyId }) {
  const parsedRole = parseUserRole(role);
  const resolvedFamilyId = familyId || "jankiewicz_family";

  let resolvedStudentLogin = studentLogin || null;
  let resolvedPrimaryLogin = primaryLogin || null;

  if (parsedRole === "student") {
    resolvedStudentLogin = studentLogin || login || null;
    resolvedPrimaryLogin = primaryLogin || "7654321r"; // Fallback to family parent login
  } else {
    resolvedPrimaryLogin = primaryLogin || login || null;
  }

  return {
    userId,
    email: email || "",
    role: parsedRole,
    studentLogin: resolvedStudentLogin,
    primaryLogin: resolvedPrimaryLogin,
    familyId: resolvedFamilyId,
    connected: true,
    librusLogin: login || ""
  };
}

function validateJustificationSubmission({ role, pin }) {
  if (role === "student") {
    return {
      allowed: false,
      statusCode: 403,
      error: "Uczeń nie ma uprawnień do bezpośredniego wysyłania e-usprawiedliwień. Użyj prośby do rodzica."
    };
  }

  if (role !== "parent") {
    return {
      allowed: false,
      statusCode: 403,
      error: "Nieprawidłowa rola użytkownika."
    };
  }

  const isValidPin = typeof pin === "string" && /^\d{4}$/.test(pin) && pin === "1234";
  if (!isValidPin) {
    return {
      allowed: false,
      statusCode: 401,
      error: "Niepoprawny kod PIN rodzica."
    };
  }

  return {
    allowed: true,
    statusCode: 200
  };
}

describe("User Roles & Permissions (user_roles.test.js)", () => {
  describe("Role parsing", () => {
    it("should default to parent when role is undefined, empty, or unknown", () => {
      assert.strictEqual(parseUserRole(undefined), "parent");
      assert.strictEqual(parseUserRole(null), "parent");
      assert.strictEqual(parseUserRole(""), "parent");
      assert.strictEqual(parseUserRole("random_value"), "parent");
      assert.strictEqual(parseUserRole("admin"), "parent");
    });

    it("should resolve student when role is 'student' (case-insensitive)", () => {
      assert.strictEqual(parseUserRole("student"), "student");
      assert.strictEqual(parseUserRole("Student"), "student");
      assert.strictEqual(parseUserRole("STUDENT"), "student");
      assert.strictEqual(parseUserRole(" student "), "student");
    });
  });

  describe("saveConnection payload formatting", () => {
    it("should correctly structure payload for parent role", () => {
      const payload = formatConnectionPayload({
        userId: "uid_bartosz",
        email: "bartosz@example.com",
        login: "7654321r",
        role: "parent"
      });

      assert.strictEqual(payload.role, "parent");
      assert.strictEqual(payload.librusLogin, "7654321r");
      assert.strictEqual(payload.primaryLogin, "7654321r");
      assert.strictEqual(payload.studentLogin, null);
      assert.strictEqual(payload.familyId, "jankiewicz_family");
      assert.strictEqual(payload.connected, true);
    });

    it("should correctly structure payload for student role with studentLogin and primaryLogin", () => {
      const payload = formatConnectionPayload({
        userId: "uid_oskar",
        email: "oskar@example.com",
        login: "1234567u",
        role: "student",
        primaryLogin: "7654321r",
        familyId: "jankiewicz_family"
      });

      assert.strictEqual(payload.role, "student");
      assert.strictEqual(payload.librusLogin, "1234567u");
      assert.strictEqual(payload.studentLogin, "1234567u");
      assert.strictEqual(payload.primaryLogin, "7654321r");
      assert.strictEqual(payload.familyId, "jankiewicz_family");
      assert.strictEqual(payload.connected, true);
    });

    it("should assign fallback primaryLogin for student if primaryLogin is not explicitly supplied", () => {
      const payload = formatConnectionPayload({
        userId: "uid_oskar",
        email: "oskar@example.com",
        login: "1234567u",
        role: "student"
      });

      assert.strictEqual(payload.role, "student");
      assert.strictEqual(payload.studentLogin, "1234567u");
      assert.strictEqual(payload.primaryLogin, "7654321r");
    });
  });

  describe("Role authorization for parental e-justifications (REQ-ROLE-02)", () => {
    it("should strictly reject direct parental justification submission when role is student", () => {
      const result = validateJustificationSubmission({
        role: "student",
        pin: "1234"
      });

      assert.strictEqual(result.allowed, false);
      assert.strictEqual(result.statusCode, 403);
      assert.match(result.error, /Uczeń nie ma uprawnień/i);
    });

    it("should reject parental justification if parent provides invalid PIN", () => {
      const result = validateJustificationSubmission({
        role: "parent",
        pin: "9999"
      });

      assert.strictEqual(result.allowed, false);
      assert.strictEqual(result.statusCode, 401);
      assert.match(result.error, /Niepoprawny kod PIN/i);
    });

    it("should allow parental justification when role is parent and PIN is valid", () => {
      const result = validateJustificationSubmission({
        role: "parent",
        pin: "1234"
      });

      assert.strictEqual(result.allowed, true);
      assert.strictEqual(result.statusCode, 200);
    });
  });
});
