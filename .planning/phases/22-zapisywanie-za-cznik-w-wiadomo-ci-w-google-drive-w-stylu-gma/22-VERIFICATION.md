---
phase: 22-zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma
verified: 2026-09-29T05:41:00Z
status: passed
score: 11/11 must-haves verified
covered_files:
  - ".planning/phases/22-zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma/22-01-PLAN.md"
  - ".planning/phases/22-zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma/22-01-SUMMARY.md"
  - ".planning/phases/22-zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma/22-02-PLAN.md"
  - ".planning/phases/22-zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma/22-02-SUMMARY.md"
  - "firebase.json"
  - "functions/index.js"
  - "functions/src/drive_service.js"
  - "functions/src/librus_client.js"
  - "functions/src/sync_service.js"
  - "functions/test/drive_service.test.js"
  - "functions/test/message_body_indexing.test.js"
  - "lib/core/auth/firebase_auth_service.dart"
  - "lib/data/repositories/firestore_school_repository.dart"
  - "lib/data/repositories/mock_school_repository.dart"
  - "lib/data/repositories/school_repository.dart"
  - "lib/domain/models/message_thread.dart"
  - "lib/presentation/screens/main_navigation_screen.dart"
  - "lib/presentation/screens/messages/message_thread_screen.dart"
  - "lib/presentation/screens/messages/widgets/drive_folder_picker_modal.dart"
  - "test/message_attachments_test.dart"
covered_digest: "v1:sha256:e18a502361b57fc55f03e6a27502b0c7b602444fefaa64c4300be2dcb5364a61"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 22: Zapisywanie załączników wiadomości w Google Drive w stylu Gmail Verification Report

**Phase Goal:** Umożliwienie użytkownikowi zapisywania załączników wiadomości z Librus Synergia na własnym koncie Google Drive jednym kliknięciem („Dodaj do Dysku Google” / „Zapisz wszystkie na Dysku”), analogicznie do obsługi załączników w Gmailu — z automatycznym tworzeniem uporządkowanego folderu docelowego (np. `EduSync - Załączniki szkolne`), zapamiętywaniem stanu zapisania w Firestore oraz bezpośrednim przyciskiem „Otwórz w Google Drive”.
**Verified:** 2026-09-29T05:41:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Cloud Function `/api/saveAttachmentToDrive` resolves the Librus attachment URL server-side, downloads the binary buffer from `sandbox.librus.pl` without browser CORS issues, uploads it via `multipart/related` to Google Drive REST API v3 in the user's target folder (or `'root'` / `'Mój dysk'` with automatic 404 fallback), and persists `DriveAttachmentInfo` in `students/{studentId}.messages` (D-01, D-07, D-10) | ✓ VERIFIED | `functions/index.js` (`exports.saveAttachmentToDrive`, lines 559–685), `functions/src/librus_client.js` (`downloadAttachmentBuffer`, lines 797–808), and `functions/src/drive_service.js` (`buildMultipartRelatedBody`, `uploadBufferToDrive`, `updateMessageDriveAttachmentInFirestore`, lines 33–124, 225–258). Verified by unit tests in `functions/test/drive_service.test.js` (6/6 pass). |
| 2 | Cloud Function `/api/driveFolder` lists app-created Google Drive folders, creates new Drive folders, and moves saved attachments between folders via `PATCH /drive/v3/files/{fileId}?addParents=...&removeParents=...` while updating `students/{studentId}.messages` and default folder metadata in Firestore (D-01, D-02, D-03, D-07) | ✓ VERIFIED | `functions/index.js` (`exports.manageDriveFolders`, lines 690–850) and `functions/src/drive_service.js` (`listDriveFolders`, `createDriveFolder`, `moveDriveFileToFolder`, lines 126–223). Rewrites configured in `firebase.json` (lines 70–83). Verified by `functions/test/drive_service.test.js`. |
| 3 | `mergeAndIndexMessages` in `functions/src/sync_service.js` preserves `driveAttachments` and `attachmentFiles` on all messages across 15-minute scheduled and manual Librus sync cycles (D-07, REQ-DRIVE-02) | ✓ VERIFIED | `functions/src/sync_service.js` (lines 367–385) merges `prev.driveAttachments` and preserves `prev.attachmentFiles` before `bodyLoaded` short-circuiting. Verified by `functions/test/message_body_indexing.test.js` (4/4 pass). |
| 4 | `FirebaseAuthService.requestGoogleDriveAccessToken` acquires and caches in browser memory (50-minute TTL) a Google OAuth 2.0 `accessToken` scoped strictly to `https://www.googleapis.com/auth/drive.file` without persisting the token to Firestore or `localStorage` (D-09) | ✓ VERIFIED | `lib/core/auth/firebase_auth_service.dart` (lines 7–24, 90–141) defines `googleDriveFileScope = 'https://www.googleapis.com/auth/drive.file'`, caches `_cachedDriveAccessToken` in static memory for 50 minutes, and clears it on `signOut()`. |
| 5 | `MessageItem`, `MessageThread`, and `MessageDetailsResult` expose `driveAttachments` (`Map<String, DriveAttachmentInfo>`) and `SchoolRepository` / `FirestoreSchoolRepository` / `MockSchoolRepository` provide `saveAttachmentToDrive`, `listDriveFolders`, `createDriveFolder`, `moveDriveAttachment`, `getDefaultDriveFolder`, and `setDefaultDriveFolder` (D-01, D-02, D-03, D-07, D-08) | ✓ VERIFIED | `lib/domain/models/message_thread.dart` (lines 1–90, 97, 119, 179), `lib/data/repositories/school_repository.dart` (lines 40–67), `lib/data/repositories/firestore_school_repository.dart` (lines 1986–2372), and `lib/data/repositories/mock_school_repository.dart` (lines 457–614). Verified by unit tests in `test/message_attachments_test.dart`. |
| 6 | Every attachment chip in `MessageThreadScreen` displays two distinct action controls: `'Pobierz na urządzenie'` (`Icons.download_rounded`) and `'Zapisz na Dysku Google'` (`Icons.add_to_drive_rounded`) (D-04) | ✓ VERIFIED | `lib/presentation/screens/messages/message_thread_screen.dart` (lines 1208–1328) renders `download_attachment_$file` (`Icons.download_rounded`) on the left and `save_drive_$file` (`Icons.add_to_drive_rounded`) on the right. Verified by widget tests in `test/message_attachments_test.dart`. |
| 7 | When a message has 2 or more attachments, the attachments section header displays a bulk `'Zapisz wszystkie na Dysku'` button that uploads all unsaved attachments in the message to the target Google Drive folder (D-05) | ✓ VERIFIED | `lib/presentation/screens/messages/message_thread_screen.dart` (lines 1115–1182) conditionally renders `save_all_drive_button` (`'Zapisz wszystkie na Dysku'`) when `message.attachments.length >= 2` and `hasUnsaved` is true, and hides it for single-attachment messages. Verified by widget tests in `test/message_attachments_test.dart`. |
| 8 | While an attachment is being uploaded to Google Drive, its chip displays an inline loading spinner in place of the Drive action icon (D-06) | ✓ VERIFIED | `lib/presentation/screens/messages/message_thread_screen.dart` (lines 1254–1269) renders `SizedBox(key: ValueKey('drive_spinner_$file'), child: CircularProgressIndicator(...))` while `_savingDriveAttachments.contains('${message.id}::$file')`. Exercised and asserted in `test/message_attachments_test.dart` (lines 147–152). |
| 9 | Clicking `'Zapisz na Dysku Google'` or `'Zapisz wszystkie na Dysku'` immediately saves to the configured default Drive folder (or `'Mój dysk'` / `'root'` if none configured) and shows a confirmation `SnackBar` (`'Zapisano ... w: {folderName}'`) with a `'Zmień folder / Przenieś'` action button (D-01, D-02) | ✓ VERIFIED | `lib/presentation/screens/messages/message_thread_screen.dart` (`_saveAttachmentToDrive` lines 1499–1575, `_saveAllAttachmentsToDrive` lines 1577–1683). Exercised and asserted in `test/message_attachments_test.dart` (lines 166–170, 245–249). |
| 10 | Once saved in Firestore, the attachment chip switches its Drive action to `'Otwórz w Google Drive'` (`Icons.open_in_new_rounded`) visible to all family members, opening `webViewLink` directly on click without re-uploading (D-07, D-08) | ✓ VERIFIED | `lib/presentation/screens/messages/message_thread_screen.dart` (lines 1270–1305, `_openSavedDriveAttachment` lines 1685–1716) renders `open_drive_$file` with `'Otwórz w Google Drive'` and validates `https://drive.google.com/` or `https://docs.google.com/` before opening. Exercised in `test/message_attachments_test.dart`. |
| 11 | Clicking `'Zmień folder / Przenieś'` in the `SnackBar` or `'Google Drive — załączniki wiadomości'` in the Profile/Settings sheet opens `DriveFolderPickerModal` allowing the user to select an existing Drive folder, create a new folder, reset to `'Mój dysk'`, move just-saved files, and save the default folder preference (D-02, D-03) | ✓ VERIFIED | `lib/presentation/screens/messages/widgets/drive_folder_picker_modal.dart` (lines 13–600) and `lib/presentation/screens/main_navigation_screen.dart` (lines 504–522). Exercised in `test/message_attachments_test.dart` (lines 172–196). |

**Score:** 11/11 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `functions/src/drive_service.js` | Google Drive REST API v3 `multipart/related` binary uploader, MIME type resolver, folder list/create/move helpers, and Firestore `driveAttachments` updater | ✓ VERIFIED | Exists (269 LOC), exports all 7 functions (`guessMimeType`, `buildMultipartRelatedBody`, `uploadBufferToDrive`, `listDriveFolders`, `createDriveFolder`, `moveDriveFileToFolder`, `updateMessageDriveAttachmentInFirestore`), wired into `functions/index.js`. |
| `functions/test/drive_service.test.js` | Unit tests for binary multipart construction, MIME detection, upload fallback to root on 404, folder listing/creation/moving, and Firestore metadata update | ✓ VERIFIED | Exists (253 LOC), 6 unit tests passing via `node --test`. |
| `functions/src/sync_service.js` | `mergeAndIndexMessages` preserving `driveAttachments` and `attachmentFiles` across background Librus sync cycles | ✓ VERIFIED | Exists (447 LOC), preserves `prev.driveAttachments` and `prev.attachmentFiles`, tested in `functions/test/message_body_indexing.test.js`. |
| `lib/core/auth/firebase_auth_service.dart` | `requestGoogleDriveAccessToken` with `https://www.googleapis.com/auth/drive.file` scope and 50-minute in-memory token cache | ✓ VERIFIED | Exists (165 LOC), wired into `MessageThreadScreen` and `DriveFolderPickerModal`. |
| `lib/domain/models/message_thread.dart` | `DriveAttachmentInfo` and `DriveFolderOption` models plus `driveAttachments` map on `MessageItem`, `MessageThread`, and `MessageDetailsResult` | ✓ VERIFIED | Exists (298 LOC), full serialization/deserialization and `copyWith` propagation. |
| `lib/data/repositories/firestore_school_repository.dart` | Client repository methods calling `/api/saveAttachmentToDrive` and `/api/driveFolder` and persisting default Drive folder settings | ✓ VERIFIED | Exists (2381 LOC), implements all 6 Drive methods and parses `driveAttachments` from Firestore and `/api/messageDetails`. |
| `lib/presentation/screens/messages/widgets/drive_folder_picker_modal.dart` | Modal dialog for moving saved attachments (`Zmień folder / Przenieś`) and configuring the default Drive folder in Settings | ✓ VERIFIED | Exists (601 LOC), provides `showMoveDialog` and `showDefaultFolderSettings`, includes `EduSync - Załączniki szkolne` quick chip. |
| `lib/presentation/screens/messages/message_thread_screen.dart` | Gmail-style attachment chips with dual Download + Drive actions, per-chip loading spinner, `'Otwórz w Google Drive'` state, bulk `'Zapisz wszystkie na Dysku'` button, and confirmation `SnackBar` | ✓ VERIFIED | Exists (2059 LOC), full end-to-end UI and state transitions verified by widget tests. |
| `lib/presentation/screens/main_navigation_screen.dart` | Profile/Settings sheet entry for configuring the default Google Drive folder for school attachments | ✓ VERIFIED | Exists (579 LOC), includes `'Google Drive — załączniki wiadomości'` `ListTile` opening `DriveFolderPickerModal.showDefaultFolderSettings`. |
| `test/message_attachments_test.dart` | Widget and unit tests verifying dual icons, bulk save button visibility, single & bulk Drive save flow, `'Otwórz w Google Drive'` state transition, and `'Zmień folder / Przenieś'` modal | ✓ VERIFIED | Exists (378 LOC), 7/7 tests passing via `flutter test`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `functions/index.js` | `functions/src/drive_service.js` | `exports.saveAttachmentToDrive` and `exports.manageDriveFolders` invoking `uploadBufferToDrive`, `listDriveFolders`, `createDriveFolder`, and `moveDriveFileToFolder` | ✓ WIRED | Verified at `functions/index.js:569-573, 639-663, 699-703, 738-783`. |
| `functions/src/sync_service.js` | `functions/test/message_body_indexing.test.js` | `mergeAndIndexMessages` copying `prev.driveAttachments` and `prev.attachmentFiles` onto merged messages | ✓ WIRED | Verified at `functions/src/sync_service.js:368-385` and tested at `functions/test/message_body_indexing.test.js:171-264`. |
| `lib/data/repositories/firestore_school_repository.dart` | `functions/index.js` | HTTP POST to `/api/saveAttachmentToDrive` and `/api/driveFolder` | ✓ WIRED | Verified at `lib/data/repositories/firestore_school_repository.dart:2132, 2183, 2243, 2330` and `firebase.json:70-83`. |
| `lib/presentation/screens/messages/message_thread_screen.dart` | `lib/data/repositories/school_repository.dart` | `_saveAttachmentToDrive` and `_saveAllAttachmentsToDrive` calling `saveAttachmentToDrive` and opening `DriveFolderPickerModal` | ✓ WIRED | Verified at `lib/presentation/screens/messages/message_thread_screen.dart:1474, 1554, 1658, 1724`. |
| `lib/presentation/screens/messages/widgets/drive_folder_picker_modal.dart` | `lib/data/repositories/school_repository.dart` | `listDriveFolders`, `createDriveFolder`, `moveDriveAttachment`, and `setDefaultDriveFolder` | ✓ WIRED | Verified at `lib/presentation/screens/messages/widgets/drive_folder_picker_modal.dart:120-122, 176, 210, 220, 225`. |
| `lib/presentation/screens/main_navigation_screen.dart` | `lib/presentation/screens/messages/widgets/drive_folder_picker_modal.dart` | Profile/Settings sheet `ListTile` opening `DriveFolderPickerModal.showDefaultFolderSettings` | ✓ WIRED | Verified at `lib/presentation/screens/main_navigation_screen.dart:504-522`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `functions/index.js` (`saveAttachmentToDrive`) | `fileBuffer`, `driveAttachmentInfo` | `LibrusClient.downloadAttachmentBuffer(downloadPath)` → `uploadBufferToDrive` (Google Drive REST API v3) → `students/{studentId}.messages[i].driveAttachments` in Firestore | Yes | ✓ FLOWING |
| `lib/data/repositories/firestore_school_repository.dart` | `driveAttachments` (`Map<String, DriveAttachmentInfo>`) | Firestore `students/{studentId}.messages` + `/api/messageDetails` + `/api/saveAttachmentToDrive` | Yes | ✓ FLOWING |
| `lib/presentation/screens/messages/message_thread_screen.dart` | `effectiveDriveAttachments`, `driveInfo` | `_currentThread.driveAttachments` & `message.driveAttachments` populated from `SchoolRepository` | Yes | ✓ FLOWING |
| `lib/presentation/screens/messages/widgets/drive_folder_picker_modal.dart` | `_folders`, `_selectedFolder` | `SchoolRepository.getDefaultDriveFolder()` & `SchoolRepository.listDriveFolders()` (`/api/driveFolder?action=list`) | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Cloud Functions Drive service unit tests (MIME detection, binary-safe `multipart/related`, 404 fallback to `root`, folder list/create/move, Firestore persistence) | `node --test functions/test/drive_service.test.js` | 6/6 tests passed (123ms) | ✓ PASS |
| Cloud Functions sync preservation of `driveAttachments` and `attachmentFiles` across background sync cycles | `node --test functions/test/message_body_indexing.test.js` | 4/4 tests passed (179ms) | ✓ PASS |
| Flutter static analysis across entire codebase | `flutter analyze` | `No issues found! (ran in 1.9s)` | ✓ PASS |
| Flutter widget & unit tests for Gmail-style attachment chips, bulk save, spinner, `'Otwórz w Google Drive'` transition, and `DriveFolderPickerModal` | `flutter test test/message_attachments_test.dart` | 7/7 tests passed (`All tests passed!`) | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| N/A (no shell probes declared for Phase 22) | — | — | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| `REQ-DRIVE-01` | `22-01-PLAN.md`, `22-02-PLAN.md` | Gmail-style saving of single or all Librus message attachments to the user's Google Drive account using OAuth 2.0 `drive.file` scope and server-side binary stream relay (`/api/saveAttachmentToDrive`) with loading states and confirmation `SnackBar`. | ✓ SATISFIED | Implemented in `functions/src/drive_service.js`, `functions/index.js`, `lib/core/auth/firebase_auth_service.dart`, and `lib/presentation/screens/messages/message_thread_screen.dart`. Verified by `drive_service.test.js` and `message_attachments_test.dart`. |
| `REQ-DRIVE-02` | `22-01-PLAN.md`, `22-02-PLAN.md` | Target folder organization on Google Drive (`Mój dysk` default, post-save `Zmień folder / Przenieś` modal, folder creation including `EduSync - Załączniki szkolne`, Settings default folder config) and persistent shared Firestore `driveAttachments` state (`Otwórz w Google Drive`) preserved across Librus syncs. | ✓ SATISFIED | Implemented in `functions/src/drive_service.js`, `functions/src/sync_service.js`, `lib/presentation/screens/messages/widgets/drive_folder_picker_modal.dart`, and `lib/presentation/screens/main_navigation_screen.dart`. Verified by `message_body_indexing.test.js` and `message_attachments_test.dart`. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | 0 `TODO`/`FIXME`/`XXX`/`HACK`/placeholder markers across all modified files | — | None |

### Human Verification Required

None — all backend, repository, and UI behaviors (including loading spinners, state transitions to „Otwórz w Google Drive”, bulk „Zapisz wszystkie na Dysku”, `SnackBar` actions, and `DriveFolderPickerModal` folder selection/move) are deterministically verified by automated unit and widget tests.

---

_Verified: 2026-09-29T05:41:00Z_
_Verifier: the agent (gsd-verifier)_
