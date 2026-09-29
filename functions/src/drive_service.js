const axios = require("axios");

const MIME_BY_EXT = {
  ".pdf": "application/pdf",
  ".pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
  ".ppt": "application/vnd.ms-powerpoint",
  ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  ".doc": "application/msword",
  ".odt": "application/vnd.oasis.opendocument.text",
  ".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  ".xls": "application/vnd.ms-excel",
  ".csv": "text/csv",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".zip": "application/zip",
  ".rar": "application/vnd.rar",
  ".7z": "application/x-7z-compressed",
  ".txt": "text/plain"
};

function guessMimeType(fileName = "") {
  const lower = String(fileName).toLowerCase().trim();
  const dotIdx = lower.lastIndexOf(".");
  if (dotIdx !== -1) {
    const ext = lower.slice(dotIdx);
    if (MIME_BY_EXT[ext]) return MIME_BY_EXT[ext];
  }
  return "application/octet-stream";
}

function buildMultipartRelatedBody({
  metadata,
  fileBuffer,
  mimeType,
  boundary = "edusync_drive_boundary_22"
}) {
  const metadataJson = JSON.stringify(metadata || {});
  const preamble =
    `--${boundary}\r\n` +
    `Content-Type: application/json; charset=UTF-8\r\n\r\n` +
    `${metadataJson}\r\n` +
    `--${boundary}\r\n` +
    `Content-Type: ${mimeType || "application/octet-stream"}\r\n\r\n`;
  const epilogue = `\r\n--${boundary}--`;

  return {
    contentType: `multipart/related; boundary=${boundary}`,
    bodyBuffer: Buffer.concat([
      Buffer.from(preamble, "utf8"),
      Buffer.isBuffer(fileBuffer) ? fileBuffer : Buffer.from(fileBuffer || ""),
      Buffer.from(epilogue, "utf8")
    ])
  };
}

async function uploadBufferToDrive({
  accessToken,
  fileName,
  fileBuffer,
  mimeType,
  folderId = "root",
  folderName = "Mój dysk",
  httpClient = axios
}) {
  if (!accessToken) {
    throw new Error("Brak tokenu autoryzacji Google Drive (accessToken).");
  }
  const effectiveMime = mimeType || guessMimeType(fileName);
  const normalizedFolderId = String(folderId || "root").trim();
  const hasCustomFolder = normalizedFolderId !== "" && normalizedFolderId !== "root";
  const metadata = {
    name: fileName,
    ...(hasCustomFolder ? { parents: [normalizedFolderId] } : {})
  };

  const { contentType, bodyBuffer } = buildMultipartRelatedBody({
    metadata,
    fileBuffer,
    mimeType: effectiveMime
  });

  const uploadUrl =
    "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,mimeType,webViewLink,parents";

  try {
    const res = await httpClient.post(uploadUrl, bodyBuffer, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": contentType,
        "Content-Length": bodyBuffer.length
      },
      maxBodyLength: Infinity,
      maxContentLength: Infinity,
      timeout: 45000
    });
    const data = res.data || {};
    return {
      driveFileId: data.id,
      webViewLink: data.webViewLink || `https://drive.google.com/file/d/${data.id}/view`,
      folderId: hasCustomFolder ? normalizedFolderId : "root",
      folderName: hasCustomFolder ? folderName || "Folder Google Drive" : "Mój dysk",
      fallbackToRoot: false
    };
  } catch (err) {
    if (hasCustomFolder && err.response?.status === 404) {
      const fallbackRes = await uploadBufferToDrive({
        accessToken,
        fileName,
        fileBuffer,
        mimeType: effectiveMime,
        folderId: "root",
        folderName: "Mój dysk",
        httpClient
      });
      return {
        ...fallbackRes,
        fallbackToRoot: true
      };
    }
    throw err;
  }
}

async function listDriveFolders({ accessToken, httpClient = axios }) {
  if (!accessToken) {
    throw new Error("Brak tokenu autoryzacji Google Drive (accessToken).");
  }
  const res = await httpClient.get("https://www.googleapis.com/drive/v3/files", {
    headers: { Authorization: `Bearer ${accessToken}` },
    params: {
      q: "mimeType='application/vnd.google-apps.folder' and trashed=false",
      fields: "files(id,name,webViewLink)",
      orderBy: "name",
      pageSize: 50
    },
    timeout: 20000
  });
  const files = Array.isArray(res.data?.files) ? res.data.files : [];
  return files.map(f => ({
    id: String(f.id || ""),
    name: String(f.name || ""),
    webViewLink: f.webViewLink || `https://drive.google.com/drive/folders/${f.id}`
  }));
}

async function createDriveFolder({
  accessToken,
  folderName,
  parentId = "root",
  httpClient = axios
}) {
  if (!accessToken) {
    throw new Error("Brak tokenu autoryzacji Google Drive (accessToken).");
  }
  const cleanName = String(folderName || "").trim();
  if (!cleanName) {
    throw new Error("Nazwa folderu Google Drive nie może być pusta.");
  }
  const normalizedParent = String(parentId || "root").trim();
  const body = {
    name: cleanName,
    mimeType: "application/vnd.google-apps.folder",
    ...(normalizedParent && normalizedParent !== "root" ? { parents: [normalizedParent] } : {})
  };
  const res = await httpClient.post(
    "https://www.googleapis.com/drive/v3/files?fields=id,name,webViewLink",
    body,
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json"
      },
      timeout: 20000
    }
  );
  const data = res.data || {};
  return {
    id: String(data.id || ""),
    name: String(data.name || cleanName),
    webViewLink: data.webViewLink || `https://drive.google.com/drive/folders/${data.id}`
  };
}

async function moveDriveFileToFolder({
  accessToken,
  fileId,
  targetFolderId = "root",
  previousFolderId = "root",
  httpClient = axios
}) {
  if (!accessToken) {
    throw new Error("Brak tokenu autoryzacji Google Drive (accessToken).");
  }
  if (!fileId) {
    throw new Error("Brak identyfikatora pliku Google Drive (fileId).");
  }
  const addParents =
    targetFolderId && String(targetFolderId).trim() !== "" && targetFolderId !== "root"
      ? String(targetFolderId).trim()
      : "root";
  const removeParents =
    previousFolderId && String(previousFolderId).trim() !== "" && previousFolderId !== "root"
      ? String(previousFolderId).trim()
      : "root";

  const url =
    `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(fileId)}` +
    `?addParents=${encodeURIComponent(addParents)}` +
    `&removeParents=${encodeURIComponent(removeParents)}` +
    `&fields=id,name,webViewLink,parents`;

  const res = await httpClient.patch(
    url,
    {},
    {
      headers: { Authorization: `Bearer ${accessToken}` },
      timeout: 20000
    }
  );
  return res.data;
}

async function updateMessageDriveAttachmentInFirestore({
  db,
  studentId,
  msgId,
  attachmentName,
  driveAttachmentInfo
}) {
  if (!db || !studentId || !msgId || !attachmentName || !driveAttachmentInfo) {
    return false;
  }
  const cleanStudentId = String(studentId).replace(/u$/i, "");
  const studentRef = db.collection("students").doc(cleanStudentId);
  const studentDoc = await studentRef.get();
  if (!studentDoc.exists) {
    return false;
  }
  const data = studentDoc.data() || {};
  const msgs = Array.isArray(data.messages) ? data.messages : [];
  let changed = false;
  for (const m of msgs) {
    if (String(m.id) === String(msgId)) {
      if (!m.driveAttachments || typeof m.driveAttachments !== "object") {
        m.driveAttachments = {};
      }
      m.driveAttachments[attachmentName] = driveAttachmentInfo;
      changed = true;
      break;
    }
  }
  if (changed) {
    await studentRef.update({ messages: msgs });
  }
  return changed;
}

/**
 * Classify an error thrown while talking to Google Drive (or Librus) into an
 * HTTP response for the client. Only genuine token/scope problems are reported
 * as UNAUTHENTICATED_DRIVE (401) so the client re-prompts for consent; other
 * failures (Drive API disabled in the GCP project, forbidden folder, Librus
 * errors) are reported with their real reason instead of "session expired".
 */
function classifyDriveError(error) {
  const status = error?.response?.status;
  const url = String(error?.config?.url || "");
  const isGoogleApi = url.includes("googleapis.com");
  const gErr = error?.response?.data?.error || {};
  const reasons = [
    ...(Array.isArray(gErr.errors) ? gErr.errors.map(e => e?.reason) : []),
    ...(Array.isArray(gErr.details) ? gErr.details.map(d => d?.reason) : [])
  ].filter(Boolean).map(String);
  const googleMessage = typeof gErr.message === "string" ? gErr.message : "";

  if (!isGoogleApi || !status) {
    return {
      status: 502,
      body: {
        error: error?.message || "Nie udało się zapisać załącznika na Dysku Google.",
        code: "UPSTREAM_ERROR"
      }
    };
  }

  if (reasons.some(r => r === "SERVICE_DISABLED" || r === "accessNotConfigured")) {
    return {
      status: 503,
      body: {
        error: "DRIVE_API_DISABLED: Google Drive API jest wyłączone w projekcie Google Cloud aplikacji.",
        code: "DRIVE_API_DISABLED"
      }
    };
  }

  const isAuthProblem =
    status === 401 ||
    reasons.some(r =>
      ["authError", "insufficientPermissions", "ACCESS_TOKEN_SCOPE_INSUFFICIENT", "ACCESS_TOKEN_EXPIRED"].includes(r)
    );
  if (isAuthProblem) {
    return {
      status: 401,
      body: {
        error: "UNAUTHENTICATED_DRIVE",
        message: "Sesja Google Drive wygasła lub brakuje zgody na dostęp do Dysku."
      }
    };
  }

  return {
    status: 502,
    body: {
      error: `Google Drive (${status}): ${googleMessage || error.message}`,
      code: "DRIVE_ERROR"
    }
  };
}

module.exports = {
  guessMimeType,
  buildMultipartRelatedBody,
  uploadBufferToDrive,
  listDriveFolders,
  createDriveFolder,
  moveDriveFileToFolder,
  updateMessageDriveAttachmentInFirestore,
  classifyDriveError
};
