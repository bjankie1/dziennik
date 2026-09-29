---
phase: 22-zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma
plan: 02
subsystem: ui
tags: [flutter, riverpod, google-drive, gmail-style, attachments, modal]

# Dependency graph
requires:
  - phase: 22-01
    provides: DriveAttachmentInfo & DriveFolderOption models, FirebaseAuthService.requestGoogleDriveAccessToken, and SchoolRepository Google Drive methods
provides:
  - Gmail-style attachment chips in MessageThreadScreen with dual Download (Icons.download_rounded) + Save to Google Drive (Icons.add_to_drive_rounded) actions, per-chip loading spinner, and shared "Otwórz w Google Drive" state
  - Bulk "Zapisz wszystkie na Dysku" button in the attachments header when a message has 2 or more attachments
  - Confirmation SnackBar with "Zmień folder / Przenieś" action opening DriveFolderPickerModal
  - DriveFolderPickerModal supporting selecting "Mój dysk" or custom folders, creating new Drive folders, moving saved attachments, and setting the default folder
  - Profile/Settings sheet entry in MainNavigationScreen ("Google Drive — załączniki wiadomości") for configuring the default Drive folder
affects: []

# Actuals (#2632)
actuals:
  tokens: 15029
  tasks: 1
  commits: 1
plan_head_before: 116ae79534a5ceeb10b49cb6591f7579a4ec496b

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Gmail-style immediate save to default Google Drive folder (or Mój dysk) followed by a confirmation SnackBar with 'Zmień folder / Przenieś' action"
    - "Immediate OAuth token acquisition on user gesture (_acquireDriveTokenOrDemo) prior to async network calls to preserve browser popup activation"
    - "URL prefix validation (https://drive.google.com/ or https://docs.google.com/) before opening saved webViewLink in browser"

key-files:
  created:
    - lib/presentation/screens/messages/widgets/drive_folder_picker_modal.dart
  modified:
    - lib/presentation/screens/messages/message_thread_screen.dart
    - lib/presentation/screens/main_navigation_screen.dart
    - test/message_attachments_test.dart

key-decisions:
  - "Acquire the Google OAuth accessToken immediately on user tap before any other await so browser popup blockers never block the consent dialog"
  - "Use a unified DriveFolderPickerModal with two modes (showMoveDialog for post-save folder change/move and showDefaultFolderSettings for Settings configuration)"
  - "Validate webViewLink against https://drive.google.com/ and https://docs.google.com/ before launching external browser tabs"

patterns-established:
  - "Pattern: Dual-action attachment chip with left download trigger and right stateful Google Drive control (Add to Drive -> Spinner -> Open in Google Drive)"

requirements-completed:
  - REQ-DRIVE-01
  - REQ-DRIVE-02

coverage:
  - id: D1
    description: "Every attachment chip in MessageThreadScreen displays dual Download (Icons.download_rounded) and Save to Google Drive (Icons.add_to_drive_rounded) actions, and messages with >=2 attachments display the bulk 'Zapisz wszystkie na Dysku' button"
    requirement: REQ-DRIVE-01
    verification:
      - kind: unit
        ref: "test/message_attachments_test.dart#MessageThreadScreen displays PDF and PPTX attachments for message 2027508"
        status: pass
      - kind: unit
        ref: "test/message_attachments_test.dart#MessageThreadScreen hides bulk Zapisz wszystkie na Dysku button when message has 1 attachment"
        status: pass
    human_judgment: false
  - id: D2
    description: "Clicking 'Zapisz na Dysku Google' or 'Zapisz wszystkie na Dysku' shows an inline loading spinner, saves to the default folder ('Mój dysk'), transitions the chip to 'Otwórz w Google Drive', and shows a confirmation SnackBar with 'Zmień folder / Przenieś'"
    requirement: REQ-DRIVE-01
    verification:
      - kind: unit
        ref: "test/message_attachments_test.dart#Clicking Zapisz na Dysku Google shows spinner, saves to Mój dysk, transitions to Otwórz w Google Drive, and opens DriveFolderPickerModal via Zmień folder / Przenieś"
        status: pass
      - kind: unit
        ref: "test/message_attachments_test.dart#Clicking Zapisz wszystkie na Dysku saves all attachments and transitions all chips to Otwórz w Google Drive"
        status: pass
    human_judgment: false
  - id: D3
    description: "DriveFolderPickerModal ('Zmień folder / Przenieś' and Settings 'Google Drive — załączniki wiadomości') lists 'Mój dysk' and custom folders, creates folders, moves saved attachments, and updates default folder preferences"
    requirement: REQ-DRIVE-02
    verification:
      - kind: unit
        ref: "test/message_attachments_test.dart#Clicking Zapisz na Dysku Google shows spinner, saves to Mój dysk, transitions to Otwórz w Google Drive, and opens DriveFolderPickerModal via Zmień folder / Przenieś"
        status: pass
    human_judgment: false

# Metrics
duration: 10min
completed: 2026-09-29
status: complete
---

# Phase 22 Plan 02: Gmail-Style Google Drive Attachment UI, Folder Picker Modal & Settings Summary

**Gmail-style dual Download/Drive attachment chips, bulk "Zapisz wszystkie na Dysku" action, shared "Otwórz w Google Drive" state, post-save "Zmień folder / Przenieś" modal (`DriveFolderPickerModal`), and Profile/Settings default folder configuration**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-29T05:27:20Z
- **Completed:** 2026-09-29T05:37:00Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments
- Created `DriveFolderPickerModal` (`lib/presentation/screens/messages/widgets/drive_folder_picker_modal.dart`) with `showMoveDialog` (post-save Gmail-style "Zmień folder / Przenieś" with optional default folder checkbox) and `showDefaultFolderSettings` (Settings default folder selector), including `Mój dysk (katalog główny)`, custom Drive folders, and inline folder creation with a quick `EduSync - Załączniki szkolne` suggestion chip.
- Updated `MessageThreadScreen` (`lib/presentation/screens/messages/message_thread_screen.dart`) to render dual actions on every attachment chip (`Pobierz na urządzenie` + `Zapisz na Dysku Google`), an inline per-chip loading spinner (`CircularProgressIndicator`) during upload, automatic state transition to `Otwórz w Google Drive` (`Icons.open_in_new_rounded`), a bulk `Zapisz wszystkie na Dysku` button when a message has 2 or more attachments, and a floating confirmation `SnackBar` with `Zmień folder / Przenieś`.
- Added the `Google Drive — załączniki wiadomości` configuration entry in `MainNavigationScreen` (`_showProfileSheet`) displaying the current default Drive folder and opening `DriveFolderPickerModal.showDefaultFolderSettings`.
- Expanded `test/message_attachments_test.dart` with widget tests covering dual attachment icons, bulk button visibility for 2+ vs 1 attachment, single-attachment save with loading spinner and `Otwórz w Google Drive` transition, `DriveFolderPickerModal` folder move & default update, and bulk `Zapisz wszystkie na Dysku`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement Gmail-Style Attachment Actions in MessageThreadScreen, DriveFolderPickerModal, Settings Integration & Widget Tests** - `43b7b3f` (`feat`)

## Files Created/Modified
- `lib/presentation/screens/messages/widgets/drive_folder_picker_modal.dart` - Modal dialog for moving saved attachments to a selected or newly created Google Drive folder and configuring the default Drive folder
- `lib/presentation/screens/messages/message_thread_screen.dart` - Gmail-style attachment chips, bulk save button, per-chip loading spinner, "Otwórz w Google Drive" state, OAuth token acquisition, and confirmation SnackBar
- `lib/presentation/screens/main_navigation_screen.dart` - Added "Google Drive — załączniki wiadomości" tile in the Profile/Settings bottom sheet
- `test/message_attachments_test.dart` - Widget tests verifying dual attachment icons, bulk save button visibility, single & bulk Drive save flows, and `DriveFolderPickerModal`

## Decisions Made
- Acquired the Google Drive OAuth token immediately at the start of `_saveAttachmentToDrive` and `_saveAllAttachmentsToDrive` before any other `await` calls so the browser never blocks the OAuth popup window.
- Mitigated open-redirect risks (`T-22-05`) in `_openSavedDriveAttachment` by verifying `webViewLink` starts with `https://drive.google.com/` or `https://docs.google.com/` before invoking `openUrlInBrowser`.
- Validated and trimmed folder names (1–120 chars) in `DriveFolderPickerModal` (`T-22-06`) before calling `createDriveFolder`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 22 is complete. Both plans (`22-01` and `22-02`) are implemented, verified with unit and widget tests, and committed.

## Self-Check: PASSED
- Verified `lib/presentation/screens/messages/widgets/drive_folder_picker_modal.dart`, `lib/presentation/screens/messages/message_thread_screen.dart`, `lib/presentation/screens/main_navigation_screen.dart`, and `test/message_attachments_test.dart` exist on disk.
- Verified commit `43b7b3f` exists in git history.
- Verified `flutter analyze`, `flutter test test/message_attachments_test.dart`, `node --test functions/test/drive_service.test.js`, and `node --test functions/test/message_body_indexing.test.js` pass with 0 issues.

---
*Phase: 22-zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma*
*Completed: 2026-09-29*
