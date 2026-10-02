---
phase: 23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni
verified: 2026-10-02T11:11:00+02:00
status: passed
score: 11/11 must-haves verified
covered_files:
  - ".planning/REQUIREMENTS.md"
  - ".planning/phases/23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni/23-01-PLAN.md"
  - ".planning/phases/23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni/23-01-SUMMARY.md"
  - ".planning/phases/23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni/23-02-PLAN.md"
  - ".planning/phases/23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni/23-02-SUMMARY.md"
  - "functions/index.js"
  - "functions/src/justification_service.js"
  - "functions/test/justification_requests.test.js"
  - "lib/data/repositories/firestore_school_repository.dart"
  - "lib/data/repositories/mock_school_repository.dart"
  - "lib/data/repositories/school_repository.dart"
  - "lib/domain/models/justification_request.dart"
  - "lib/presentation/providers/school_providers.dart"
  - "lib/presentation/screens/attendance/attendance_screen.dart"
  - "lib/presentation/screens/attendance/widgets/parent_approval_modal.dart"
  - "lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart"
  - "lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart"
  - "lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart"
  - "test/attendance_justification_modal_test.dart"
  - "test/attendance_pending_requests_test.dart"
  - "test/dashboard_screen_test.dart"
covered_digest: "v1:sha256:29b38ef3e7a0d884bff7b728b304254bf720a1fc2a59eb89e36f6a062a3c66ec"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 23: Podgląd szczegółów próśb o usprawiedliwienie i oczekujących wniosków Verification Report

**Phase Goal:** Umożliwienie rodzicowi i uczniowi przejrzystego podglądu, czego dokładnie dotyczą prośby o usprawiedliwienie (zarówno na Pulpicie, jak i na ekranie Frekwencji, gdzie obecnie widać jedynie „6 lekcji • Choroba”) oraz jakie konkretnie lekcje wchodzą w skład oczekujących wniosków („7 wnioski czekają na wychowawcę”).
**Verified:** 2026-10-02T11:11:00+02:00
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 |Cloud Function `processParentReview` and `formatLibrusJustificationPayload` in `functions/src/justification_service.js` accept optional `selectedRecordIds`, `selectedLessonNumbers`, `hoursByDate`, `dateFrom`, and `dateTo` so partial parental approval of a subset of lessons updates `recordIds`/`lessonNumbers` on the request document and dispatches only the selected lessons grouped by date to Librus (D-06, REQ-ATT-01) | ✓ VERIFIED | `functions/src/justification_service.js:103-175` validates `selectedRecordIds` (rejecting `[]` with HTTP 400), computes `effectiveRecordIds`, `effectiveLessonNumbers`, and multi-day `hoursByDate`; `functions/src/justification_service.js:274-292` preserves multi-day `hoursByDate`, `dateFrom`, and `dateTo`; `functions/index.js:958-1006` forwards the fields and passes `reviewResult.updatedRequest` to `formatLibrusJustificationPayload`. Exercised by unit tests in `functions/test/justification_requests.test.js` (14/14 passing). |
| 2 | `FirestoreSchoolRepository.requestJustification` and `respondJustificationRequest` resolve the student's actual name from the student profile (`'Oskar Jankiewicz'`) instead of `appUser.displayName` when a parent tests the student role, and `JustificationRequest.effectiveStudentName` guards UI banners/modals against legacy documents that stored the parent's `displayName` (D-03, REQ-ATT-01) | ✓ VERIFIED | `lib/data/repositories/firestore_school_repository.dart:1637-1648` defines `_resolveStudentFullName()` reading `getStudentProfile().name` and calls it in `requestJustification` (`L1654`) and `respondJustificationRequest` (`L1953`). `lib/domain/models/justification_request.dart:182-204` implements `effectiveStudentName()` replacing empty/`'Uczeń'`/parent (`'bartosz'`) names with `'Oskar Jankiewicz'`. Exercised by `test/attendance_justification_modal_test.dart` and `test/attendance_pending_requests_test.dart`. |
| 3 | `FirestoreSchoolRepository.getAttendanceRecords` enriches every `AttendanceRecord` with `teacherName` from `item['teacherName'] ?? item['teacher']` and cross-references `data['timetable']` by `(dayOfWeek, lessonNumber)` and subject name to populate missing `teacherName` and `classroom` fields (D-05, REQ-ATT-01) | ✓ VERIFIED | `lib/data/repositories/firestore_school_repository.dart:975-1064` defines `lookupTimetableSlot(weekday, lessonNum, subjectName)` with 3-tier matching (`dayOfWeek + lessonNumber` -> `dayOfWeek + subject` -> `any day + subject`) and lines `1154-1195` populate `resolvedTeacher`, `resolvedClassroom` (filtering out placeholder `'Sala szkolna'`), and `resolvedSubject`. |
| 4 | `JustificationRequest` provides shared helpers `resolveAttendanceRecords`, `groupRecordsByDay`, `formatPolishDayHeader`, and `formatDateRangeSummary` to resolve `recordIds` (with fallback to `date + lessonNumbers` and synthetic fallback for isolated tests) and group lessons chronologically by day (D-01, D-02, D-04, D-05, D-07) | ✓ VERIFIED | `lib/domain/models/justification_request.dart:208-373` implements `resolveAttendanceRecords`, `groupRecordsByDay`, `formatPolishDayHeader`, and `formatDateRangeSummary`. Exercised across `test/attendance_justification_modal_test.dart` and `test/attendance_pending_requests_test.dart`. |
| 5 | `SchoolRepository`, `FirestoreSchoolRepository`, `MockSchoolRepository`, and `AttendanceNotifier.approveJustification` accept optional `selectedRecordIds`, updating `_localJustificationOverrides` only for approved `recordIds` while leaving unchecked lessons in `JustificationStatus.none` (`'Do usprawiedliwienia'`) (D-06, D-08, REQ-ATT-01, REQ-ATT-02) | ✓ VERIFIED | `lib/data/repositories/school_repository.dart:26-30`, `lib/data/repositories/firestore_school_repository.dart:1798-1911`, `lib/data/repositories/mock_school_repository.dart:295-334`, and `lib/presentation/providers/school_providers.dart:253-266` thread `{List<String>? selectedRecordIds}`, cancelling/removing deselected IDs so unchecked lessons revert to `JustificationStatus.none`. Exercised by `test/attendance_pending_requests_test.dart:251-275`. |
| 6 | Clicking anywhere on the yellow student justification request banner in `DashboardMobileView`, `DashboardMetricsColumn`, or `AttendanceScreen` opens `ParentApprovalModal` showing the full day-grouped list of requested lessons alongside `Zatwierdź (PIN)` and `Odrzuć` actions (D-01, REQ-ATT-01, ROADMAP SC-1) | ✓ VERIFIED | `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart:368-373`, `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart:625-630`, and `lib/presentation/screens/attendance/attendance_screen.dart:1265-1271` wrap the yellow banner in `Material` + `InkWell(onTap: openApprovalModal)` invoking `ParentApprovalModal.show(...)`. Exercised by `test/attendance_pending_requests_test.dart:243-250`. |
| 7 | Each yellow justification request banner displays the student's profile name (`'Oskar Jankiewicz'` via `effectiveStudentName`), a concise date range + lesson count + reason summary, and a visible interactive cue `'Zobacz szczegóły →'` (D-02, D-03, REQ-ATT-01, ROADMAP SC-1) | ✓ VERIFIED | `dashboard_mobile_view.dart:399-424`, `dashboard_metrics_column.dart:649-677`, and `attendance_screen.dart:1300-1325` render `'$studentName prosi o usprawiedliwienie'`, `'${dateRange.isNotEmpty ? "$dateRange • " : ""}$count ... • ${req.reason}'`, and `'Zobacz szczegóły →'`. Exercised by `test/attendance_pending_requests_test.dart:228-242`. |
| 8 | `ParentApprovalModal` and `ParentRejectionModal` resolve the request's `AttendanceRecord` items, group them by calendar day under a Polish day header (e.g. `'Wtorek, 29 Września 2026'`), and display lesson number + hours (`'Lekcja 3 • 09:50 - 10:35'`), subject name, teacher name (and classroom if available), student reason, and any prior Q&A `dialogHistory` (D-04, D-05, REQ-ATT-01, ROADMAP SC-2) | ✓ VERIFIED | `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart:253-498` and `lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart:200-312` render day-grouped headers, lesson number + `timeSlot`, subject, teacher + classroom, student reason, and `dialogHistory`. Exercised by `test/attendance_justification_modal_test.dart:170-273`. |
| 9 | Every lesson row in `ParentApprovalModal` has a checkbox (all checked by default); parents can uncheck individual lessons for partial approval, dynamically updating the submit button label (e.g. `'Zatwierdź z PIN-em (5 z 6 lekcji)'`) and sending only `selectedRecordIds` to `AttendanceNotifier.approveJustification` (D-06, REQ-ATT-01) | ✓ VERIFIED | `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart:67-140, 427-434, 565-582` initializes `_selectedRecordIds` with all resolved IDs, toggles selection on row/checkbox tap (`ValueKey('approval_checkbox_${rec.id}')`), updates button label to `'Zatwierdź z PIN-em (${_selectedRecordIds.length} z ${_resolvedRecords.length} lekcji)'`, and invokes `onApproveSelected!(pin, selectedList)`. Exercised by `test/attendance_justification_modal_test.dart:276-381` and `test/attendance_pending_requests_test.dart:251-275`. |
| 10 | In `AttendanceScreen`, the amber `'X wnioski czekają na wychowawcę'` banner is an expandable accordion (toggled by tapping the banner or `'Pokaż szczegóły'` / `'Ukryj szczegóły'`) that reveals all lessons with `JustificationStatus.requested` grouped by day (Polish date header, lesson number + hours, subject, teacher, sent reason) with per-lesson `'Cofnij'` buttons and a bulk `'Cofnij wszystkie'` action (D-07, D-08, REQ-ATT-02, ROADMAP SC-3) | ✓ VERIFIED | `lib/presentation/screens/attendance/attendance_screen.dart:905-1185` implements `_buildPendingTeacherAccordionBanner` with `ValueKey('pending_teacher_banner_toggle')`, day-grouped `JustificationStatus.requested` cards, per-lesson `OutlinedButton` (`ValueKey('cancel_pending_${rec.id}')`) calling `cancelJustification([rec.id])`, and bulk `TextButton` (`ValueKey('cancel_all_pending_button')`) calling `cancelJustification(ids)`. Exercised by `test/attendance_pending_requests_test.dart:278-363`. |
| 11 | `AttendanceScreen`'s filter bar includes a 4th filter pill `'Oczekujące (Y)'` (`_activeFilter == 3`) next to `'Wszystkie'`, `'Do usprawiedliwienia (X)'`, and `'Usprawiedliwione'` that filters the main attendance list to lessons with `JustificationStatus.requested`, and all views work consistently on Firestore data (D-09, REQ-ATT-02, ROADMAP SC-4) | ✓ VERIFIED | `lib/presentation/screens/attendance/attendance_screen.dart:185-186, 214` adds `_activeFilter == 3` (`filtered = pendingList`) and `_buildFilterChip(3, 'Oczekujące (${pendingList.length})')`. Exercised by `test/attendance_pending_requests_test.dart:366-423`. |

**Score:** 11/11 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `functions/src/justification_service.js` | Partial approval support (`selectedRecordIds`, `selectedLessonNumbers`, `hoursByDate`, `dateFrom`, `dateTo`) in `processParentReview` and multi-day `hoursByDate` support in `formatLibrusJustificationPayload` | ✓ VERIFIED | Exists, substantive (319 lines), exported and wired into `functions/index.js` and `functions/test/justification_requests.test.js` |
| `functions/index.js` | `exports.reviewJustificationRequest` forwarding partial selection fields and passing `reviewResult.updatedRequest` to `formatLibrusJustificationPayload` | ✓ VERIFIED | Exists, substantive, wired to `justification_service.js` (`L955-1006`) |
| `functions/test/justification_requests.test.js` | Unit tests for partial `selectedRecordIds` approval, empty selection 400 rejection, and multi-day `hoursByDate` payload formatting | ✓ VERIFIED | Exists, substantive (282 lines), 14/14 unit tests passing |
| `lib/domain/models/justification_request.dart` | `effectiveStudentName`, `resolveAttendanceRecords`, `groupRecordsByDay`, `formatPolishDayHeader`, and `formatDateRangeSummary` helpers on `JustificationRequest` | ✓ VERIFIED | Exists, substantive (449 lines), imported and used across modals, banners, and repository |
| `lib/data/repositories/school_repository.dart` | `approveJustificationRequest(String requestId, String pin, {List<String>? selectedRecordIds})` | ✓ VERIFIED | Exists, substantive, implemented by both `FirestoreSchoolRepository` and `MockSchoolRepository` |
| `lib/data/repositories/firestore_school_repository.dart` | `_resolveStudentFullName()`, timetable teacher/classroom enrichment in `getAttendanceRecords()`, and `selectedRecordIds` + `_localJustificationOverrides` handling in `approveJustificationRequest` | ✓ VERIFIED | Exists, substantive, wired to Firestore `justification_requests`, `students` (`attendance` + `timetable`), and `/api/reviewJustificationRequest` |
| `lib/data/repositories/mock_school_repository.dart` | `approveJustificationRequest` handling `selectedRecordIds` and cancelling deselected record IDs | ✓ VERIFIED | Exists, substantive (`L295-334`) |
| `lib/presentation/providers/school_providers.dart` | `AttendanceNotifier.approveJustification` forwarding `selectedRecordIds` | ✓ VERIFIED | Exists, substantive (`L253-266`), wired to `SchoolRepository.approveJustificationRequest` |
| `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart` | Day-grouped lesson breakdown with per-lesson checkboxes, partial approval (`selectedRecordIds`), teacher/classroom metadata, Q&A dialog history, and PIN verification | ✓ VERIFIED | Exists, substantive (626 lines), wired into `AttendanceScreen`, `DashboardMobileView`, and `DashboardMetricsColumn` |
| `lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart` | Day-grouped lesson breakdown and `effectiveStudentName` in the parent rejection modal | ✓ VERIFIED | Exists, substantive (455 lines), wired into `ParentApprovalModal`, `AttendanceScreen`, `DashboardMobileView`, and `DashboardMetricsColumn` |
| `lib/presentation/screens/attendance/attendance_screen.dart` | Interactive parent request banner with `'Zobacz szczegóły →'`, 4th filter pill `'Oczekujące (Y)'`, and expandable `'X wnioski czekają na wychowawcę'` accordion with per-lesson `'Cofnij'` and bulk `'Cofnij wszystkie'` | ✓ VERIFIED | Exists, substantive (1856 lines), wired to `attendanceProvider`, `justificationRequestsProvider`, and `ParentApprovalModal` |
| `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart` | Interactive mobile dashboard justification request banner with `'Zobacz szczegóły →'`, `effectiveStudentName`, and partial approval forwarding | ✓ VERIFIED | Exists, substantive (`L292-520`), wired to `ParentApprovalModal.show` and `approveJustification` |
| `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart` | Interactive desktop dashboard justification request card with `'Zobacz szczegóły →'`, `effectiveStudentName`, and partial approval forwarding | ✓ VERIFIED | Exists, substantive (`L547-762`), wired to `ParentApprovalModal.show` and `approveJustification` |
| `test/attendance_justification_modal_test.dart` | Widget tests verifying day-grouped lesson details, teacher/classroom rendering, and checkbox partial selection (`selectedRecordIds`) in `ParentApprovalModal` | ✓ VERIFIED | Exists, substantive (383 lines), 5/5 widget tests passing |
| `test/attendance_pending_requests_test.dart` | Widget tests verifying the expandable `'X wnioski czekają na wychowawcę'` banner, single vs bulk `'Cofnij'`, `'Oczekujące (Y)'` filter pill, and interactive request banner on `AttendanceScreen` | ✓ VERIFIED | Exists, substantive (425 lines), 3/3 widget tests passing |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `functions/index.js` | `functions/src/justification_service.js` | `exports.reviewJustificationRequest` passing `selectedRecordIds`, `selectedLessonNumbers`, `hoursByDate`, `dateFrom`, `dateTo` to `processParentReview` and `reviewResult.updatedRequest` to `formatLibrusJustificationPayload` | WIRED | Verified at `functions/index.js:958-1006` |
| `lib/presentation/providers/school_providers.dart` | `lib/data/repositories/school_repository.dart` | `AttendanceNotifier.approveJustification` forwarding `selectedRecordIds` to `SchoolRepository.approveJustificationRequest` | WIRED | Verified at `lib/presentation/providers/school_providers.dart:253-266` |
| `lib/data/repositories/firestore_school_repository.dart` | `functions/index.js` | HTTP POST to `/api/reviewJustificationRequest` with `selectedRecordIds`, `selectedLessonNumbers`, `hoursByDate`, `dateFrom`, and `dateTo` | WIRED | Verified at `lib/data/repositories/firestore_school_repository.dart:1852-1879` |
| `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart` | `lib/domain/models/justification_request.dart` | `request.resolveAttendanceRecords`, `JustificationRequest.groupRecordsByDay`, and `JustificationRequest.formatPolishDayHeader` | WIRED | Verified at `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart:67, 168, 375` |
| `lib/presentation/screens/attendance/attendance_screen.dart` | `lib/presentation/providers/school_providers.dart` | `approveJustification(firstReq.id, pin, selectedRecordIds: selectedIds)` and `cancelJustification([rec.id])` | WIRED | Verified at `lib/presentation/screens/attendance/attendance_screen.dart:1131-1133, 1228-1235` |
| `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart` | `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart` | `InkWell` `onTap` and `Zatwierdź (PIN)` button opening `ParentApprovalModal.show` with `availableRecords` and `onApproveSelected` | WIRED | Verified at `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart:566-630` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `lib/data/repositories/firestore_school_repository.dart` | `AttendanceRecord.teacherName`, `AttendanceRecord.classroom` | Firestore `students/{studentId}` (`data['attendance']` cross-referenced with `data['timetable']` via `lookupTimetableSlot`) | Yes | ✓ FLOWING |
| `lib/data/repositories/firestore_school_repository.dart` | `studentFullName` in `requestJustification` / `respondJustificationRequest` | `getStudentProfile().name` (`_resolveStudentFullName()`) | Yes | ✓ FLOWING |
| `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart` | `_resolvedRecords`, `_selectedRecordIds`, `groupedByDay` | `attendanceProvider` (`FirestoreSchoolRepository.getAttendanceRecords`) + `justificationRequestsProvider` (`justification_requests` collection) | Yes | ✓ FLOWING |
| `lib/presentation/screens/attendance/attendance_screen.dart` | `pendingList` in `_buildPendingTeacherAccordionBanner` and `_activeFilter == 3` | `attendanceProvider` records where `r.justificationStatus == JustificationStatus.requested` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Cloud Functions partial approval (`selectedRecordIds`, `hoursByDate`) & 400 validation | `node --test functions/test/justification_requests.test.js` | 14/14 tests passed (0 failures) | ✓ PASS |
| `ParentApprovalModal` day-grouped lesson details, Q&A history, and checkbox partial approval | `flutter test test/attendance_justification_modal_test.dart` | 5/5 widget tests passed | ✓ PASS |
| Interactive banner, expandable pending teacher accordion (`Cofnij` / `Cofnij wszystkie`), and 4th filter pill `Oczekujące (Y)` | `flutter test test/attendance_pending_requests_test.dart test/dashboard_screen_test.dart` | 5/5 widget tests passed | ✓ PASS |
| Static analysis across entire Dart codebase | `flutter analyze` | `No issues found!` (exit code 0) | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| N/A | No shell probes declared in Phase 23 plans | N/A | N/A |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| `REQ-ATT-01` | `23-01-PLAN.md`, `23-02-PLAN.md` | Interaktywny podgląd szczegółów prośby o usprawiedliwienie (zgrupowana po dniach lista lekcji, przedmiotów, godzin, nauczycieli i historii Q&A) z możliwością częściowego zatwierdzania wybranych godzin (checkboxy) na Pulpicie i we Frekwencji. | ✓ SATISFIED | Implemented in `justification_service.js`, `justification_request.dart`, `firestore_school_repository.dart`, `parent_approval_modal.dart`, `parent_rejection_modal.dart`, `dashboard_mobile_view.dart`, `dashboard_metrics_column.dart`, and `attendance_screen.dart`. Verified by `functions/test/justification_requests.test.js`, `test/attendance_justification_modal_test.dart`, and `test/attendance_pending_requests_test.dart`. |
| `REQ-ATT-02` | `23-01-PLAN.md`, `23-02-PLAN.md` | Rozwijany akordeon „X wnioski czekają na wychowawcę” z możliwością wycofania pojedynczej lekcji (`Cofnij`) lub wszystkich wniosków (`Cofnij wszystkie`) oraz 4. pigułka filtra `Oczekujące (Y)`. | ✓ SATISFIED | Implemented in `attendance_screen.dart` (`_buildPendingTeacherAccordionBanner`, `_activeFilter == 3` `'Oczekujące (Y)'` filter chip, per-lesson `'Cofnij'` and bulk `'Cofnij wszystkie'`). Verified by `test/attendance_pending_requests_test.dart`. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | 0 `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` or stub patterns in modified files | — | — |

### Human Verification Required

None — all observable truths and behavioral invariants are covered by deterministic unit and widget tests (`functions/test/justification_requests.test.js`, `test/attendance_justification_modal_test.dart`, `test/attendance_pending_requests_test.dart`, `test/dashboard_screen_test.dart`).
