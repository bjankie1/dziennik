const test = require("node:test");
const assert = require("node:assert/strict");
const {
  guessMimeType,
  buildMultipartRelatedBody,
  uploadBufferToDrive,
  listDriveFolders,
  createDriveFolder,
  moveDriveFileToFolder,
  updateMessageDriveAttachmentInFirestore
} = require("../src/drive_service");

test("guessMimeType resolves common school attachment extensions and falls back to application/octet-stream", () => {
  assert.equal(guessMimeType("matura2027.pdf"), "application/pdf");
  assert.equal(
    guessMimeType("Prezentacja.PPTX"),
    "application/vnd.openxmlformats-officedocument.presentationml.presentation"
  );
  assert.equal(
    guessMimeType("Zgoda_rodzica.docx"),
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  );
  assert.equal(
    guessMimeType("Plan_lekcji.xlsx"),
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  );
  assert.equal(guessMimeType("skan.png"), "image/png");
  assert.equal(guessMimeType("zdjecie.jpg"), "image/jpeg");
  assert.equal(guessMimeType("archiwum.zip"), "application/zip");
  assert.equal(guessMimeType("plik_bez_rozszerzenia"), "application/octet-stream");
});

test("buildMultipartRelatedBody preserves arbitrary binary bytes without UTF-8 corruption", () => {
  // Include non-UTF8 byte sequences (0x80, 0xFE, 0xFF, 0x00) typical in PDF/ZIP/PPTX streams
  const rawBinary = Buffer.from([0x25, 0x50, 0x44, 0x46, 0x2d, 0x80, 0xfe, 0xff, 0x00, 0x42]);
  const { contentType, bodyBuffer } = buildMultipartRelatedBody({
    metadata: { name: "matura2027.pdf", parents: ["folder_123"] },
    fileBuffer: rawBinary,
    mimeType: "application/pdf",
    boundary: "test_boundary_22"
  });

  assert.equal(contentType, "multipart/related; boundary=test_boundary_22");
  assert.ok(Buffer.isBuffer(bodyBuffer));

  const idx = bodyBuffer.indexOf(rawBinary);
  assert.notEqual(idx, -1, "Exact binary sequence must be preserved inside multipart bodyBuffer");

  const textView = bodyBuffer.toString("latin1");
  assert.match(textView, /"name":"matura2027\.pdf"/);
  assert.match(textView, /"parents":\["folder_123"\]/);
  assert.match(textView, /Content-Type: application\/pdf/);
});

test("uploadBufferToDrive uploads to root when folderId is 'root' and includes parents when custom folderId is provided", async () => {
  const calls = [];
  const mockHttp = {
    post: async (url, body, config) => {
      calls.push({ url, body, config });
      return {
        data: {
          id: "drive_file_1",
          name: "matura2027.pdf",
          mimeType: "application/pdf",
          webViewLink: "https://drive.google.com/file/d/drive_file_1/view",
          parents: ["root"]
        }
      };
    }
  };

  const resRoot = await uploadBufferToDrive({
    accessToken: "token_abc",
    fileName: "matura2027.pdf",
    fileBuffer: Buffer.from("PDF-DATA"),
    folderId: "root",
    folderName: "Mój dysk",
    httpClient: mockHttp
  });

  assert.equal(calls.length, 1);
  assert.match(calls[0].url, /uploadType=multipart/);
  assert.equal(calls[0].config.headers.Authorization, "Bearer token_abc");
  assert.ok(!calls[0].body.toString("utf8").includes('"parents"'));
  assert.equal(resRoot.driveFileId, "drive_file_1");
  assert.equal(resRoot.folderId, "root");
  assert.equal(resRoot.folderName, "Mój dysk");
  assert.equal(resRoot.fallbackToRoot, false);

  const resCustom = await uploadBufferToDrive({
    accessToken: "token_abc",
    fileName: "matura2027.pdf",
    fileBuffer: Buffer.from("PDF-DATA"),
    folderId: "folder_szkola",
    folderName: "Szkoła",
    httpClient: mockHttp
  });

  assert.equal(calls.length, 2);
  assert.ok(calls[1].body.toString("utf8").includes('"parents":["folder_szkola"]'));
  assert.equal(resCustom.folderId, "folder_szkola");
  assert.equal(resCustom.folderName, "Szkoła");
  assert.equal(resCustom.fallbackToRoot, false);
});

test("uploadBufferToDrive automatically falls back to 'root' (Mój dysk) when custom folderId returns HTTP 404", async () => {
  const calls = [];
  const mockHttp = {
    post: async (url, body, config) => {
      calls.push({ url, bodyStr: body.toString("utf8"), config });
      if (calls.length === 1) {
        const err = new Error("Request failed with status code 404");
        err.response = { status: 404, data: { error: { message: "File not found: deleted_folder" } } };
        throw err;
      }
      return {
        data: {
          id: "drive_file_fallback",
          name: "matura2027.pdf",
          webViewLink: "https://drive.google.com/file/d/drive_file_fallback/view"
        }
      };
    }
  };

  const result = await uploadBufferToDrive({
    accessToken: "token_abc",
    fileName: "matura2027.pdf",
    fileBuffer: Buffer.from("PDF-DATA"),
    folderId: "deleted_folder",
    folderName: "Usunięty folder",
    httpClient: mockHttp
  });

  assert.equal(calls.length, 2);
  assert.ok(calls[0].bodyStr.includes('"parents":["deleted_folder"]'));
  assert.ok(!calls[1].bodyStr.includes('"parents"'));
  assert.equal(result.driveFileId, "drive_file_fallback");
  assert.equal(result.folderId, "root");
  assert.equal(result.folderName, "Mój dysk");
  assert.equal(result.fallbackToRoot, true);
});

test("listDriveFolders, createDriveFolder, and moveDriveFileToFolder call Drive REST API v3 endpoints", async () => {
  const requests = [];
  const mockHttp = {
    get: async (url, config) => {
      requests.push({ method: "GET", url, config });
      return {
        data: {
          files: [
            { id: "f1", name: "Szkoła", webViewLink: "https://drive.google.com/drive/folders/f1" }
          ]
        }
      };
    },
    post: async (url, body, config) => {
      requests.push({ method: "POST", url, body, config });
      return {
        data: {
          id: "f_new",
          name: body.name,
          webViewLink: "https://drive.google.com/drive/folders/f_new"
        }
      };
    },
    patch: async (url, body, config) => {
      requests.push({ method: "PATCH", url, body, config });
      return {
        data: {
          id: "file_1",
          name: "matura2027.pdf",
          webViewLink: "https://drive.google.com/file/d/file_1/view",
          parents: ["f_new"]
        }
      };
    }
  };

  const folders = await listDriveFolders({ accessToken: "tok", httpClient: mockHttp });
  assert.equal(folders.length, 1);
  assert.equal(folders[0].id, "f1");
  assert.equal(folders[0].name, "Szkoła");

  const created = await createDriveFolder({
    accessToken: "tok",
    folderName: "Matura 2027",
    httpClient: mockHttp
  });
  assert.equal(created.id, "f_new");
  assert.equal(created.name, "Matura 2027");
  assert.equal(requests[1].body.mimeType, "application/vnd.google-apps.folder");

  const moved = await moveDriveFileToFolder({
    accessToken: "tok",
    fileId: "file_1",
    targetFolderId: "f_new",
    previousFolderId: "root",
    httpClient: mockHttp
  });
  assert.equal(moved.id, "file_1");
  assert.match(requests[2].url, /addParents=f_new/);
  assert.match(requests[2].url, /removeParents=root/);
});

test("updateMessageDriveAttachmentInFirestore persists driveAttachments on matching message in students/{studentId}", async () => {
  let updatedData = null;
  const mockDb = {
    collection: (colName) => {
      assert.equal(colName, "students");
      return {
        doc: (docId) => {
          assert.equal(docId, "11010033");
          return {
            get: async () => ({
              exists: true,
              data: () => ({
                messages: [
                  { id: "2125823", subject: "Matura", attachments: ["matura2027.pdf"] }
                ]
              })
            }),
            update: async (payload) => {
              updatedData = payload;
            }
          };
        }
      };
    }
  };

  const driveInfo = {
    driveFileId: "df_99",
    webViewLink: "https://drive.google.com/file/d/df_99/view",
    folderId: "root",
    folderName: "Mój dysk",
    savedAt: "2026-09-28T12:00:00.000Z",
    savedBy: "Rodzic"
  };

  const updated = await updateMessageDriveAttachmentInFirestore({
    db: mockDb,
    studentId: "11010033",
    msgId: "2125823",
    attachmentName: "matura2027.pdf",
    driveAttachmentInfo: driveInfo
  });

  assert.equal(updated, true);
  assert.ok(updatedData);
  assert.deepEqual(updatedData.messages[0].driveAttachments["matura2027.pdf"], driveInfo);
});
