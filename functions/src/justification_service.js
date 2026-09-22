/**
 * Justification service for Student-to-Parent approval workflows
 * (REQ-ROLE-02, D-03, D-04, T-14-03, T-14-04).
 */

const JUSTIFICATION_STATUS = {
  PENDING_PARENT_APPROVAL: "pending_parent_approval",
  APPROVED: "approved",
  REJECTED: "rejected"
};

const VALID_DEFAULT_PIN = "1234";

/**
 * Validates and sanitizes a student justification request submission.
 */
function sanitizeStudentRequest(payload) {
  if (!payload || typeof payload !== "object") {
    throw new Error("Nieprawidłowy format danych wniosku.");
  }

  const {
    studentLogin,
    studentName,
    primaryLogin,
    familyId,
    recordIds,
    lessonNumbers,
    subjectNames,
    date,
    reason
  } = payload;

  if (!studentLogin || typeof studentLogin !== "string" || !studentLogin.trim()) {
    throw new Error("Brak identyfikatora ucznia (studentLogin).");
  }

  if (!Array.isArray(recordIds) || recordIds.length === 0) {
    throw new Error("Należy wskazać co najmniej jedną lekcję do usprawiedliwienia.");
  }

  if (recordIds.length > 50) {
    throw new Error("Zbyt duża liczba lekcji w jednym wniosku (maksymalnie 50).");
  }

  const sanitizedRecordIds = recordIds.map(id => String(id).trim()).filter(Boolean);
  if (sanitizedRecordIds.length === 0) {
    throw new Error("Nieprawidłowe identyfikatory wybranych lekcji.");
  }

  const trimmedReason = typeof reason === "string" ? reason.trim() : "";
  if (!trimmedReason) {
    throw new Error("Powód usprawiedliwienia jest wymagany.");
  }
  if (trimmedReason.length > 250) {
    throw new Error("Powód usprawiedliwienia nie może przekraczać 250 znaków.");
  }

  const sanitizedLessonNumbers = Array.isArray(lessonNumbers)
    ? lessonNumbers.map(n => Number(n)).filter(n => Number.isInteger(n) && n >= 0 && n <= 15)
    : [];

  const sanitizedSubjectNames = Array.isArray(subjectNames)
    ? subjectNames.map(s => String(s).trim()).filter(Boolean)
    : [];

  return {
    studentLogin: studentLogin.trim(),
    studentName: (studentName && String(studentName).trim()) || "Oskar Jankiewicz",
    primaryLogin: (primaryLogin && String(primaryLogin).trim()) || "7654321r",
    familyId: (familyId && String(familyId).trim()) || "jankiewicz_family",
    recordIds: sanitizedRecordIds,
    lessonNumbers: sanitizedLessonNumbers,
    subjectNames: sanitizedSubjectNames,
    date: date ? String(date).trim() : null,
    reason: trimmedReason,
    status: JUSTIFICATION_STATUS.PENDING_PARENT_APPROVAL,
    requestedAt: new Date().toISOString()
  };
}

/**
 * Validates parental review action and PIN authorization (REQ-ROLE-02, T-14-03, T-14-04).
 */
function processParentReview(requestDoc, reviewData) {
  if (!requestDoc || typeof requestDoc !== "object") {
    return {
      success: false,
      statusCode: 404,
      error: "Wniosek o usprawiedliwienie nie istnieje."
    };
  }

  // T-14-04: Prevent duplicate approval / processing
  if (requestDoc.status !== JUSTIFICATION_STATUS.PENDING_PARENT_APPROVAL) {
    return {
      success: false,
      statusCode: 409,
      error: `Wniosek został już rozpatrzony (aktualny status: ${requestDoc.status}).`
    };
  }

  const { action, pin, rejectionReason, parentLogin } = reviewData || {};

  if (action === "approve") {
    // T-14-03: Validate parental PIN
    const isValidPin = typeof pin === "string" && /^\d{4}$/.test(pin) && pin === VALID_DEFAULT_PIN;
    if (!isValidPin) {
      return {
        success: false,
        statusCode: 401,
        error: "Niepoprawny kod PIN rodzica (wymagane 4 cyfry, np. 1234)."
      };
    }

    return {
      success: true,
      statusCode: 200,
      updatedRequest: {
        ...requestDoc,
        status: JUSTIFICATION_STATUS.APPROVED,
        reviewedAt: new Date().toISOString(),
        reviewedBy: (parentLogin && String(parentLogin).trim()) || "parent",
        pinVerified: true
      }
    };
  }

  if (action === "reject") {
    return {
      success: true,
      statusCode: 200,
      updatedRequest: {
        ...requestDoc,
        status: JUSTIFICATION_STATUS.REJECTED,
        rejectionReason: (rejectionReason && String(rejectionReason).trim()) || "Odrzucone przez rodzica",
        reviewedAt: new Date().toISOString(),
        reviewedBy: (parentLogin && String(parentLogin).trim()) || "parent"
      }
    };
  }

  return {
    success: false,
    statusCode: 400,
    error: "Nieobsługiwana akcja (dozwolone: 'approve' lub 'reject')."
  };
}

/**
 * Formats justification parameters for LibrusClient.submitJustification.
 */
function formatLibrusJustificationPayload(requestDoc) {
  const dateStr = requestDoc.date || new Date().toISOString().split("T")[0];
  const lessonNumbers = Array.isArray(requestDoc.lessonNumbers) && requestDoc.lessonNumbers.length > 0
    ? requestDoc.lessonNumbers
    : [1];

  return {
    reason: requestDoc.reason,
    dateFrom: dateStr,
    dateTo: dateStr,
    isByHours: true,
    hoursByDate: {
      [dateStr]: lessonNumbers
    },
    notifyOthers: true
  };
}

module.exports = {
  JUSTIFICATION_STATUS,
  VALID_DEFAULT_PIN,
  sanitizeStudentRequest,
  processParentReview,
  formatLibrusJustificationPayload
};
