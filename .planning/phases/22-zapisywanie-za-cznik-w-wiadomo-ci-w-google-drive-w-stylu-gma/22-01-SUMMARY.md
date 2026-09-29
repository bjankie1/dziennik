---
phase: 22-zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma
plan: 01
subsystem: api
tags: [google-drive, oauth, cloud-functions, firestore, flutter, attachments]

# Dependency graph
requires:
  - phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea
    provides: MessageThread and MessageItem attachment structures and Librus attachment download path resolution
provides:
  - Cloud Functions Google Drive REST API v3 service (functions/src/drive_service.js) with binary multipart/related upload, MIME detection, folder list/create/move, and 404 root fallback
  - Cloud Functions HTTP endpoints /api/saveAttachmentToDrive and /api/driveFolder with Firebase Hosting rewrites
  - Preservation of driveAttachments and attachmentFiles across background Librus sync cycles in mergeAndIndexMessages
  - FirebaseAuthService.requestGoogleDriveAccessToken with https://www.googleapis.com/auth/drive.file scope and 50-minute in-memory token cache
  - DriveAttachmentInfo and DriveFolderOption domain models and SchoolRepository / FirestoreSchoolRepository / MockSchoolRepository Google Drive methods
affects: [22-02-PLAN]

# Actuals (#2632)
actuals:
  tokens: 18964
  tasks: 2
  commits: 2
plan_head_before: ecad8c6ffda118b54b8156999f6467f25677d624

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Server-side binary stream relay from Librus (arraybuffer) to Google Drive REST API v3 (multipart/related via Buffer.concat) to bypass browser CORS and prevent UTF-8 binary corruption"
    - "Least-privilege Google OAuth 2.0 scope (https://www.googleapis.com/auth/drive.file) with 50-minute in-memory token cache in FirebaseAuthService"
    - "Shared family Drive state persisted on students/{studentId}.messages[i].driveAttachments and preserved across 15-minute Librus syncs in mergeAndIndexMessages"

key-files:
  created:
    - functions/src/drive_service.js
    - functions/test/drive_service.test.js
  modified:
    - functions/src/librus_client.js
    - functions/src/sync_service.js
    - functions/index.js
    - firebase.json
    - functions/test/message_body_indexing.test.js
    - lib/core/auth/firebase_auth_service.dart
    - lib/domain/models/message_thread.dart
    - lib/data/repositories/school_repository.dart
    - lib/data/repositories/firestore_school_repository.dart
    - lib/data/repositories/mock_school_repository.dart
    - test/message_attachments_test.dart

key-decisions:
  - "Use direct Google Drive REST API v3 calls via axios in functions/src/drive_service.js with Buffer.concat multipart/related payloads rather than adding the heavy googleapis npm package"
  - "Automatically retry upload to 'root' (Mój dysk) when a configured custom default folderId returns HTTP 404 on Google Drive"
  - "Cache OAuth accessToken strictly in browser memory for 50 minutes and never log or persist it in Firestore"

patterns-established:
  - "Pattern: Binary-safe RFC 2387 multipart/related construction using Buffer.concat([preambleBuf, fileBuffer, epilogueBuf])"
  - "Pattern: Preserving per-message user enrichment fields (driveAttachments, attachmentFiles) at the top of mergeAndIndexMessages before bodyLoaded short-circuiting"

requirements-completed:
  - REQ-DRIVE-01
  - REQ-DRIVE-02

coverage:
  - id: D1
    description: "Cloud Functions Google Drive service (drive_service.js) builds binary-safe multipart/related payloads, detects MIME types, uploads with 404 fallback to root, lists/creates folders, moves files, and updates Firestore"
    requirement: REQ-DRIVE-01
    verification:
      - kind: unit
        ref: "functions/test/drive_service.test.js"
        status: pass
    human_judgment: false
  - id: D2
    description: "mergeAndIndexMessages in sync_service.js preserves driveAttachments and attachmentFiles across background Librus sync cycles"
    requirement: REQ-DRIVE-02
    verification:
      - kind: unit
        ref: "functions/test/message_body_indexing.test.js#mergeAndIndexMessages preserves driveAttachments and attachmentFiles"
        status: pass
    human_judgment: false
  - id: D3
    description: "Flutter domain models (DriveAttachmentInfo, DriveFolderOption), OAuth drive.file token helper, and SchoolRepository / FirestoreSchoolRepository / MockSchoolRepository Google Drive methods"
    requirement: REQ-DRIVE-01
    verification:
      - kind: unit
        ref: "test/message_attachments_test.dart"
        status: pass
    human_judgment: false

# Metrics
duration: 11min
completed: 2026-09-29
status: complete
---

# Phase 22 Plan 01: Google Drive Backend Service, OAuth Scope & Repository Pipeline Summary

**Server-side Librus-to-Google-Drive binary multipart relay (`/api/saveAttachmentToDrive`, `/api/driveFolder`), sync preservation of `driveAttachments`, `drive.file` OAuth token caching in `FirebaseAuthService`, and full `SchoolRepository` Drive operations**

## Performance

- **Duration:** 11 min
- **Started:** 2026-09-29T05:14:29Z
- **Completed:** 2026-09-29T05:25:00Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments
- Built `functions/src/drive_service.js` with binary-safe `Buffer.concat` `multipart/related` upload, MIME type mapping for school documents, automatic fallback to `'root'` (`Mój dysk`) on HTTP 404 when a custom folder was deleted on Drive, folder listing/creation/moving (`addParents`/`removeParents`), and Firestore `driveAttachments` updater.
- Exposed `/api/saveAttachmentToDrive` and `/api/driveFolder` (`saveAttachmentToDrive` and `manageDriveFolders`) in `functions/index.js` and `firebase.json`, and updated `LibrusClient` with `downloadAttachmentBuffer(downloadPath)`.
- Updated `mergeAndIndexMessages` in `functions/src/sync_service.js` to preserve `driveAttachments` and `attachmentFiles` across all scheduled and manual Librus sync cycles.
- Extended `FirebaseAuthService` with `requestGoogleDriveAccessToken` requesting least-privilege `https://www.googleapis.com/auth/drive.file` scope and caching the token in memory for 50 minutes.
- Added `DriveAttachmentInfo` and `DriveFolderOption` models to `lib/domain/models/message_thread.dart`, added `driveAttachments` to `MessageItem`, `MessageThread`, and `MessageDetailsResult`, and implemented `saveAttachmentToDrive`, `listDriveFolders`, `createDriveFolder`, `moveDriveAttachment`, `getDefaultDriveFolder`, and `setDefaultDriveFolder` across `SchoolRepository`, `FirestoreSchoolRepository`, and `MockSchoolRepository`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build Cloud Functions Google Drive Service, HTTP Endpoints (/api/saveAttachmentToDrive & /api/driveFolder), and Sync Preservation** - `228e425` (`feat`)
2. **Task 2: Extend FirebaseAuthService with Google Drive OAuth Scope, Add DriveAttachmentInfo Domain Models & Implement Repository Methods** - `40edde8` (`feat`)

## Files Created/Modified
- `functions/src/drive_service.js` - Google Drive REST API v3 multipart uploader, MIME resolver, folder list/create/move helpers, and Firestore `driveAttachments` updater
- `functions/src/librus_client.js` - Added `downloadAttachmentBuffer(downloadPath)` for binary arraybuffer fetching from `sandbox.librus.pl`
- `functions/src/sync_service.js` - Preserved `driveAttachments` and `attachmentFiles` in `mergeAndIndexMessages`
- `functions/index.js` - Added `exports.saveAttachmentToDrive` and `exports.manageDriveFolders`; included `driveAttachments` in `getMessageDetails`
- `firebase.json` - Added `/api/saveAttachmentToDrive` and `/api/driveFolder` hosting rewrites
- `functions/test/drive_service.test.js` - Unit tests for `drive_service.js`
- `functions/test/message_body_indexing.test.js` - Unit test for `driveAttachments` and `attachmentFiles` preservation across syncs
- `lib/core/auth/firebase_auth_service.dart` - Added `googleDriveFileScope`, 50-minute in-memory token cache, and `requestGoogleDriveAccessToken`
- `lib/domain/models/message_thread.dart` - Added `DriveAttachmentInfo`, `DriveFolderOption`, and `driveAttachments` on `MessageDetailsResult`, `MessageItem`, and `MessageThread`
- `lib/data/repositories/school_repository.dart` - Added Google Drive attachment and folder methods to `SchoolRepository`
- `lib/data/repositories/firestore_school_repository.dart` - Implemented Google Drive upload, folder list/create/move, and default folder persistence in Firestore and `SharedPreferences`
- `lib/data/repositories/mock_school_repository.dart` - Implemented deterministic demo/test mode Google Drive operations
- `test/message_attachments_test.dart` - Added unit tests for `DriveAttachmentInfo`, `DriveFolderOption`, `MessageThread.copyWith`, and `MockSchoolRepository` Drive operations

## Decisions Made
- Used direct Google Drive REST API v3 calls via `axios` and `Buffer.concat` rather than adding the `googleapis` npm package, keeping Cloud Functions cold-start fast and zero new dependencies.
- Added automatic 404 folder fallback in `uploadBufferToDrive` so if a user deletes their configured default folder in Google Drive web UI, saving an attachment transparently falls back to `'root'` (`Mój dysk`) and returns `fallbackToRoot: true`.
- Kept Google OAuth `accessToken` strictly in browser memory (`_cachedDriveAccessToken` with 50-minute expiry) and never logged or persisted it to Firestore.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All backend endpoints (`/api/saveAttachmentToDrive`, `/api/driveFolder`), OAuth token acquisition (`requestGoogleDriveAccessToken`), domain models (`DriveAttachmentInfo`, `DriveFolderOption`), and repository methods are tested and ready for Plan 22-02 (Gmail-style attachment tile UI, bulk "Zapisz wszystkie na Dysku" button, `DriveFolderPickerModal`, and Settings default folder selector).

## Self-Check: PASSED
- Verified all created and modified files exist on disk.
- Verified task commits `228e425` and `40edde8` exist in git history.
- Verified `node --test functions/test/drive_service.test.js`, `node --test functions/test/message_body_indexing.test.js`, `flutter analyze`, and `flutter test test/message_attachments_test.dart` pass with 0 errors.

---
*Phase: 22-zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma*
*Completed: 2026-09-29*
