---
phase: "23"
slug: "podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-02"
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter test` (Dart/Flutter UI & Repository) + `node --test` (Cloud Functions) |
| **Config file** | `pubspec.yaml` / `functions/package.json` |
| **Quick run command** | `flutter test test/attendance_justification_modal_test.dart && node --test functions/test/justification_requests.test.js` |
| **Full suite command** | `flutter test && node --test functions/test/justification_requests.test.js` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/attendance_justification_modal_test.dart && node --test functions/test/justification_requests.test.js`
- **After every plan wave:** Run `flutter test && node --test functions/test/justification_requests.test.js`
- **Before `/gsd-verify-work`:** Full suite must be green + `flutter analyze` with 0 errors
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 23-01-01 | 01 | 1 | REQ-ATT-01 | T-23-01 | Partial approval validates `selectedRecordIds` and 4-digit PIN hash | unit | `node --test functions/test/justification_requests.test.js` | ✅ | ⬜ pending |
| 23-01-02 | 01 | 1 | REQ-ATT-01 | T-23-02 | Student name resolved from student profile (`Oskar Jankiewicz`), teacher/classroom enriched | unit/analyze | `flutter analyze` | ✅ | ⬜ pending |
| 23-02-01 | 02 | 2 | REQ-ATT-01 | T-23-01 | `ParentApprovalModal` requires >=1 checked lesson and 4-digit PIN | widget | `flutter test test/attendance_justification_modal_test.dart` | ✅ | ⬜ pending |
| 23-02-02 | 02 | 2 | REQ-ATT-01, REQ-ATT-02 | — | Role-gated parent actions on banners; expandable pending banner & 4th filter pill | widget | `flutter test test/attendance_pending_requests_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/attendance_pending_requests_test.dart` — widget tests for REQ-ATT-02 (D-07 expandable pending banner, D-08 single vs bulk `Cofnij`, D-09 `Oczekujące (Y)` filter pill) and REQ-ATT-01 banner click on `AttendanceScreen`
- [ ] Extend `test/attendance_justification_modal_test.dart` — widget tests for day-grouped lessons (D-04, D-05) and checkbox partial approval (`selectedRecordIds`, D-06)
- [ ] Extend `functions/test/justification_requests.test.js` — unit tests for partial `selectedRecordIds` in `processParentReview` and `formatLibrusJustificationPayload` (D-06)

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
