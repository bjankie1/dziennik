/**
 * Family Chat Service (REQ-CHAT-01, D-01, D-02, T-14.1-01)
 * Manages message payload construction, validation, read-receipts,
 * and justification card bridging for real-time family communication.
 */

const CHAT_MESSAGE_TYPE = {
  TEXT: "text",
  JUSTIFICATION_CARD: "justificationCard",
  SYSTEM_INFO: "systemInfo"
};

/**
 * Builds and validates a chat message payload for Firestore.
 */
function buildChatMessagePayload({
  familyId,
  senderId,
  senderName,
  senderRole,
  text,
  type = CHAT_MESSAGE_TYPE.TEXT,
  metadata = null
}) {
  if (!familyId || typeof familyId !== "string" || !familyId.trim()) {
    throw new Error("Identyfikator rodziny (familyId) jest wymagany.");
  }

  if (!senderId || typeof senderId !== "string" || !senderId.trim()) {
    throw new Error("Identyfikator nadawcy (senderId) jest wymagany.");
  }

  const validRoles = ["student", "parent", "system"];
  const normalizedRole = typeof senderRole === "string" ? senderRole.trim().toLowerCase() : "";
  if (!validRoles.includes(normalizedRole)) {
    throw new Error(`Nieprawidłowa rola nadawcy: ${senderRole} (dozwolone: 'student', 'parent', 'system').`);
  }

  const validTypes = Object.values(CHAT_MESSAGE_TYPE);
  if (!validTypes.includes(type)) {
    throw new Error(`Nieprawidłowy typ wiadomości: ${type}`);
  }

  const trimmedText = typeof text === "string" ? text.trim() : "";
  if (!trimmedText && type === CHAT_MESSAGE_TYPE.TEXT) {
    throw new Error("Treść wiadomości tekstowej nie może być pusta.");
  }
  if (trimmedText.length > 1000) {
    throw new Error("Wiadomość nie może przekraczać 1000 znaków.");
  }

  const now = new Date().toISOString();
  const isStudent = normalizedRole === "student";
  const isParent = normalizedRole === "parent";

  return {
    familyId: familyId.trim(),
    senderId: senderId.trim(),
    senderName: (senderName && String(senderName).trim()) || (isStudent ? "Oskar" : "Rodzic"),
    senderRole: normalizedRole,
    text: trimmedText,
    type,
    metadata: metadata && typeof metadata === "object" ? metadata : null,
    createdAt: now,
    // Read receipts: sender automatically marked as read
    isReadByStudent: isStudent,
    isReadByParent: isParent
  };
}

/**
 * Formats an interactive justification card message to be posted into the family chat thread (D-02).
 */
function buildJustificationChatCard(requestDoc, rejectionReason, parentName = "Tata") {
  if (!requestDoc || typeof requestDoc !== "object") {
    throw new Error("Brak danych wniosku o usprawiedliwienie.");
  }

  const familyId = requestDoc.familyId || "jankiewicz_family";
  const reasonText = (rejectionReason && String(rejectionReason).trim()) || requestDoc.rejectionReason || "Wymagane wyjaśnienie";

  return buildChatMessagePayload({
    familyId,
    senderId: "parent",
    senderName: parentName,
    senderRole: "parent",
    text: reasonText,
    type: CHAT_MESSAGE_TYPE.JUSTIFICATION_CARD,
    metadata: {
      requestId: requestDoc.id,
      date: requestDoc.date,
      recordIds: requestDoc.recordIds || [],
      lessonNumbers: requestDoc.lessonNumbers || [],
      subjectNames: requestDoc.subjectNames || [],
      studentReason: requestDoc.reason || "",
      rejectionReason: reasonText,
      status: requestDoc.status || "rejected"
    }
  });
}

module.exports = {
  CHAT_MESSAGE_TYPE,
  buildChatMessagePayload,
  buildJustificationChatCard
};
