---
phase: "24"
slug: "dekompozycja-monolitycznego-firestoreschoolrepository-2-691"
status: ready
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-03"
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter SDK, Dart `^3.10.4`) |
| **Config file** | `analysis_options.yaml` / `pubspec.yaml` |
| **Quick run command** | `flutter test test/data/repositories/ test/presentation/screens/messages_timestamp_test.dart` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze && flutter test test/data/repositories/`
- **After every plan wave:** Run `flutter analyze && flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green + `flutter analyze` with 0 errors/warnings + `wc -l lib/data/repositories/firestore_school_repository.dart` < 250 + 0 `static final Map` in `lib/data/repositories/`
- **Max feedback latency:** 25 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 24-01-01 | 01 | 1 | REQ-ARCH-03, REQ-ARCH-04 | T-24-01 | Instance-scoped `SchoolDataCacheManager` eliminates cross-user `static final Map` leakage; `FirestoreGradesDataSource` parses subjects/grades | unit/analyze | `flutter analyze` | ❌ W1 | ⬜ pending |
| 24-01-02 | 01 | 1 | REQ-ARCH-03, REQ-ARCH-04 | T-24-01 | `FirestoreAttendanceDataSource` and `FirestoreJustificationsDataSource` extracted with unit tests verifying instance cache isolation & partial PIN approval | unit | `flutter analyze && flutter test test/data/repositories/firestore_cache_and_attendance_test.dart` | ❌ W1 | ⬜ pending |
| 24-02-01 | 02 | 2 | REQ-ARCH-03 | T-24-02 | `FirestoreMessagesDataSource` and `FirestoreScheduleDataSource` extracted preserving URL encoding and Drive attachment state | unit/analyze | `flutter analyze` | ❌ W2 | ⬜ pending |
| 24-02-02 | 02 | 2 | REQ-ARCH-03, REQ-ARCH-04 | T-24-01 | `FirestoreSchoolRepository` reduced to `< 250 LOC` facade with zero `static final Map` and unit tests for messages, schedule, and facade delegation | unit/widget | `flutter analyze && flutter test test/data/repositories/ test/presentation/screens/messages_timestamp_test.dart test/attendance_pending_requests_test.dart test/message_attachments_test.dart` | ❌ W2 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 1 / Wave 2 Test Requirements

- [ ] `test/data/repositories/firestore_cache_and_attendance_test.dart` — unit tests for `SchoolDataCacheManager`, `FirestoreGradesDataSource`, `FirestoreAttendanceDataSource`, and `FirestoreJustificationsDataSource` (created in Plan `24-01`).
- [ ] `test/data/repositories/firestore_messages_and_schedule_test.dart` — unit tests for `FirestoreMessagesDataSource`, `FirestoreScheduleDataSource`, and `FirestoreSchoolRepository` facade delegation (created in Plan `24-02`).

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 1/2 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 1/2 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 25s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
