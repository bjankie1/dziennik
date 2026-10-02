---
phase: "21"
slug: "refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-02"
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter SDK) |
| **Config file** | `pubspec.yaml` / `analysis_options.yaml` |
| **Quick run command** | `flutter test test/message_attachments_test.dart test/presentation/screens/messages_timestamp_test.dart test/attendance_pending_requests_test.dart test/attendance_justification_modal_test.dart test/dashboard_screen_test.dart test/presentation/widgets/notification_settings_modal_test.dart` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze` and the targeted widget/unit tests for the refactored module.
- **After every plan wave:** Run `flutter analyze && flutter test`.
- **Before `/gsd-verify-work`:** Full suite must be green + `flutter analyze` with 0 errors/warnings + LOC budget check (`< 350 LOC` for all 3 target screens/modals).
- **Max feedback latency:** 25 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 1 | REQ-ARCH-01 | — | Pure date/pluralization formatting in `PolishDateFormatter` | unit | `flutter test test/core/utils/polish_date_formatter_test.dart` | ❌ W1 | ⬜ pending |
| 21-01-02 | 01 | 1 | REQ-ARCH-01, REQ-ARCH-02 | T-21-01 | `JustificationRequestBanner` enforces `authRoleProvider == UserRole.parent` and `ParentApprovalModal` PIN flow | widget | `flutter test test/attendance_justification_modal_test.dart test/dashboard_screen_test.dart test/attendance_pending_requests_test.dart` | ✅ | ⬜ pending |
| 21-02-01 | 02 | 2 | REQ-ARCH-01 | — | Pure domain logic (`resolveSenderName`, `extractCcTeacherFromBody`, `looksLikeMessageWithAttachment`) on `MessageThread` | unit/widget | `flutter test test/message_attachments_test.dart test/presentation/screens/messages_timestamp_test.dart` | ✅ | ⬜ pending |
| 21-02-02 | 02 | 2 | REQ-ARCH-01, REQ-ARCH-02 | — | `message_thread_screen.dart` < 350 LOC; `MessageTaskBanner` uses `tasksStreamProvider.select(...)`; `MessageReplyComposer` owns controller state | widget/static | `flutter analyze && flutter test test/message_attachments_test.dart test/presentation/screens/messages_timestamp_test.dart` | ✅ | ⬜ pending |
| 21-03-01 | 03 | 2 | REQ-ARCH-01, REQ-ARCH-02 | — | `attendance_screen.dart` < 350 LOC; 6 sub-widgets extracted preserving all `ValueKey`s | widget/static | `flutter analyze && flutter test test/attendance_pending_requests_test.dart test/attendance_justification_modal_test.dart` | ✅ | ⬜ pending |
| 21-04-01 | 04 | 2 | REQ-ARCH-01, REQ-ARCH-02 | — | `notification_settings_modal.dart` < 350 LOC; 6 sub-widgets extracted with `.select(...)` and step-by-step keys preserved | widget/static | `flutter analyze && flutter test test/presentation/widgets/notification_settings_modal_test.dart` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 / Wave 1 Requirements

- [ ] `test/core/utils/polish_date_formatter_test.dart` — unit tests for `PolishDateFormatter.formatDayHeader`, `formatFullDate`, `formatNumericDateTime`, and `pluralizeLesson` (created in Plan 21-01).
- [ ] Unit tests for `MessageThread.resolveSenderName` and `MessageThread.extractCcTeacherFromBody` (added in Plan 21-02).

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0/1 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0/1 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 25s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
