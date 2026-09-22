/**
 * Message session resolution and sender attribution service
 * according to REQ-ROLE-01, D-01, T-14-05, T-14-06.
 */

/**
 * Resolves session identifier and sender identity attribution for message dispatching.
 * Ensures student and parent sessions are cleanly isolated in librus_sessions.
 *
 * @param {Object} params
 * @param {string} [params.role]
 * @param {string} [params.studentLogin]
 * @param {string} [params.login]
 * @param {string} [params.parentLogin]
 * @param {string} [params.defaultParentLogin]
 * @returns {{ isStudent: boolean, senderRole: string, senderName: string, sessionKey: string }}
 */
function resolveMessageSession({ role, studentLogin, login, parentLogin, defaultParentLogin }) {
  const normalizedRole = (typeof role === "string" && role.trim().toLowerCase() === "student")
    ? "student"
    : "parent";
  const isStudent = normalizedRole === "student" || (!!studentLogin && !role);

  let sessionKey;
  let senderName;
  const senderRole = isStudent ? "student" : "parent";

  if (isStudent) {
    sessionKey = studentLogin || login || "student_user";
    senderName = "Oskar Jankiewicz";
  } else {
    sessionKey = login || parentLogin || defaultParentLogin || "parent_user";
    senderName = "Bartosz Jankiewicz";
  }

  return {
    isStudent,
    senderRole,
    senderName,
    sessionKey: String(sessionKey).trim()
  };
}

/**
 * Formats the response payload for sendMessage endpoint.
 */
function buildMessageResponse({
  success = true,
  simulated = false,
  recipients = [],
  subject = "",
  sessionInfo,
  result = {}
}) {
  return {
    success,
    simulated,
    sentAt: new Date().toISOString(),
    recipients: Array.isArray(recipients) ? recipients : [recipients],
    subject,
    senderRole: sessionInfo?.senderRole || "parent",
    senderLogin: sessionInfo?.sessionKey || "",
    senderName: sessionInfo?.senderName || "Bartosz Jankiewicz",
    ...result
  };
}

module.exports = {
  resolveMessageSession,
  buildMessageResponse
};
