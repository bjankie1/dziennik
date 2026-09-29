---
phase: "22"
slug: "zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-29"
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js `node --test` (Cloud Functions) + `flutter_test` (Flutter Web/App) |
| **Config file** | `functions/package.json` & `pubspec.yaml` |
| **Quick run command** | `node --test functions/test/drive_service.test.js && flutter test test/message_attachments_test.dart` |
| **Full suite command** | `npm --prefix functions test && flutter analyze && flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `node --test functions/test/drive_service.test.js && flutter analyze`
- **After every plan wave:** Run `npm --prefix functions test && flutter test test/message_attachments_test.dart`
- **Before `/gsd-verify-work`:** Full suite must be green (`npm --prefix functions test && flutter analyze && flutter test && flutter build web --release`)
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | REQ-DRIVE-01, REQ-DRIVE-02 | T-22-01, T-22-02, T-22-03 | Validate `downloadPath` regex, never log/persist OAuth `accessToken`, escape folder query quotes, preserve `driveAttachments` across Librus sync | unit | `node --test functions/test/drive_service.test.js && node --test functions/test/message_body_indexing.test.js` | ❌ W1 | ⬜ pending |
| 22-01-02 | 01 | 1 | REQ-DRIVE-01, REQ-DRIVE-02 | T-22-02 | Keep Google OAuth `accessToken` (`drive.file` scope) in memory only; map `driveAttachments` in domain models and repositories | unit / widget | `flutter analyze && flutter test test/message_attachments_test.dart` | ✅ | ⬜ pending |
| 22-02-01 | 02 | 2 | REQ-DRIVE-01, REQ-DRIVE-02 | — | Render Gmail-style attachment actions (`Pobierz` + `Zapisz na Dysku Google` / `Otwórz w Google Drive`), bulk `Zapisz wszystkie na Dysku`, `Zmień folder / Przenieś` modal, and Settings default Drive folder | widget | `flutter analyze && flutter test test/message_attachments_test.dart` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `functions/test/drive_service.test.js` — unit tests for `buildMultipartRelatedBody`, `guessMimeType`, `uploadBufferToDrive` (including 404 folder fallback to `root`), `moveDriveFileToFolder`, and Firestore `driveAttachments` persistence (created in Plan 22-01 Task 1).
- [ ] `test/message_attachments_test.dart` — expanded widget tests for Gmail-style Drive save, bulk save, „Otwórz w Google Drive” state, and folder picker modal (expanded in Plan 22-02).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Google OAuth popup (`drive.file` scope) and live upload to personal Google Drive on `https://lepsza-szkola.web.app` | REQ-DRIVE-01 | Browser Google OAuth popup requires interactive Google account consent | Open message `2027508`, click „Zapisz na Dysku Google” on an attachment, approve Google Drive `drive.file` popup, verify file appears in Google Drive and SnackBar shows „Zmień folder / Przenieś”. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-09-29
