---
phase: 23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni
plan: 02
subsystem: ui
tags: [flutter, riverpod, attendance, justifications, dashboard, modals, widgets]

requires:
  - phase: 23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni
    provides: JustificationRequest day-grouping helpers, effectiveStudentName, teacher/classroom enrichment, and partial selectedRecordIds approval support (Plan 23-01)
provides:
  - Day-grouped lesson breakdown with teacher/classroom metadata, Q&A dialogHistory, and per-lesson checkboxes for partial PIN approval in ParentApprovalModal
  - Day-grouped lesson breakdown and effectiveStudentName display in ParentRejectionModal
  - Interactive student justification request banners with effectiveStudentName, date range summary, and 'Zobacz szczegóły →' across DashboardMobileView, DashboardMetricsColumn, and AttendanceScreen
  - 4th filter pill 'Oczekujące (Y)' (_activeFilter == 3) in AttendanceScreen
  - Expandable 'X wnioski czekają na wychowawcę' accordion in AttendanceScreen with day-grouped requested lessons, per-lesson 'Cofnij' buttons, and bulk 'Cofnij wszystkie' action
affects:
  - AttendanceScreen, DashboardMobileView, DashboardMetricsColumn, ParentApprovalModal, ParentRejectionModal

actuals:
  tokens: 28500
  tasks: 2
  commits: 2
  plan_head_before: 85e7fc30a5bc99a5aed1ee8fa21f9986fd83de1a

tech-stack:
  added: []
  patterns:
    - "Interactive justification banners wrapped in Material + InkWell delegating to ParentApprovalModal.show with availableRecords, studentDisplayName, and onApproveSelected"
    - "Day-grouped lesson cards with CheckboxListTile / InkWell rows and dynamic partial approval button label ('Zatwierdź z PIN-em (X z Y lekcji)')"
    - "Expandable AnimatedCrossFade accordion for pending teacher applications with per-lesson 'Cofnij' and bulk 'Cofnij wszystkie'"

key-files:
  created:
    - test/attendance_pending_requests_test.dart
  modified:
    - lib/presentation/screens/attendance/widgets/parent_approval_modal.dart
    - lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart
    - lib/presentation/screens/attendance/attendance_screen.dart
    - lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart
    - lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart
    - lib/presentation/providers/school_providers.dart
    - test/attendance_justification_modal_test.dart
    - test/dashboard_screen_test.dart

key-decisions:
  - "Upgraded ParentApprovalModal with per-lesson checkboxes (all selected by default) and onApproveSelected callback so parents can uncheck individual hours and approve a subset of lessons with their 4-digit PIN."
  - "Wrapped justification request banners in DashboardMobileView, DashboardMetricsColumn, and AttendanceScreen in InkWell with 'Zobacz szczegóły →', effectiveStudentName ('Oskar Jankiewicz'), and date range summary."
  - "Transformed the 'X wnioski czekają na wychowawcę' banner in AttendanceScreen into an expandable accordion showing day-grouped JustificationStatus.requested lessons with per-lesson 'Cofnij' buttons alongside 'Cofnij wszystkie', and added the 4th 'Oczekujące (Y)' filter chip."

patterns-established:
  - "Consistent day-grouped lesson cards across approval modal, rejection modal, and pending teacher accordion using JustificationRequest.groupRecordsByDay and formatPolishDayHeader"

requirements-completed:
  - REQ-ATT-01
  - REQ-ATT-02

coverage:
  - id: D1
    description: "ParentApprovalModal and ParentRejectionModal display day-grouped lessons (Polish date header, lesson number + hours, subject, teacher, classroom, reason, Q&A history) and support partial lesson approval via per-lesson checkboxes (D-03, D-04, D-05, D-06)"
    requirement: REQ-ATT-01
    verification:
      - kind: unit
        ref: "test/attendance_justification_modal_test.dart#ParentApprovalModal renders day-grouped lessons with timeSlot, subject, teacher, classroom, and Q&A history (D-04, D-05)"
        status: pass
      - kind: unit
        ref: "test/attendance_justification_modal_test.dart#ParentApprovalModal supports per-lesson checkboxes and partial approval via onApproveSelected (D-06)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Interactive justification banners with effectiveStudentName and 'Zobacz szczegóły →', 4th filter pill 'Oczekujące (Y)', and expandable 'X wnioski czekają na wychowawcę' accordion with per-lesson and bulk 'Cofnij' (D-01, D-02, D-03, D-07, D-08, D-09)"
    requirement: REQ-ATT-02
    verification:
      - kind: unit
        ref: "test/attendance_pending_requests_test.dart#Interactive parent justification banner displays effectiveStudentName, date summary, and supports partial approval"
        status: pass
      - kind: unit
        ref: "test/attendance_pending_requests_test.dart#Expandable pending teacher banner shows day-grouped requested lessons and supports per-lesson and bulk Cofnij"
        status: pass
      - kind: unit
        ref: "test/attendance_pending_requests_test.dart#4th filter pill Oczekujące (Y) filters main attendance list to JustificationStatus.requested lessons"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-10-02
status: complete
---

# Phase 23 Plan 02: Justification Request Detail UI & Pending Requests Accordion Summary

**Interactive student justification banners with `'Zobacz szczegóły →'`, day-grouped `ParentApprovalModal` with per-lesson checkboxes for partial PIN approval, expandable `"X wnioski czekają na wychowawcę"` accordion with per-lesson `Cofnij`, and 4th `Oczekujące (Y)` filter pill**

## Performance

- **Duration:** 18 min
- **Started:** 2026-10-02T08:46:00Z
- **Completed:** 2026-10-02T09:04:15Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Upgraded `ParentApprovalModal` (`lib/presentation/screens/attendance/widgets/parent_approval_modal.dart`) with `availableRecords`, `studentDisplayName`, and `onApproveSelected`, rendering day-grouped lessons (`JustificationRequest.groupRecordsByDay` & `formatPolishDayHeader`), lesson number + hours (`Lekcja X • HH:mm - HH:mm`), subject name, teacher & classroom metadata, Q&A `dialogHistory`, and per-lesson checkboxes (`ValueKey('approval_checkbox_${rec.id}')`) with dynamic button label `'Zatwierdź z PIN-em (X z Y lekcji)'`.
- Upgraded `ParentRejectionModal` (`lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart`) with `availableRecords`, `studentDisplayName`, `effectiveStudentName`, and day-grouped lesson cards.
- Made student justification request banners interactive (`InkWell` opening `ParentApprovalModal`) across `DashboardMobileView`, `DashboardMetricsColumn`, and `AttendanceScreen`, displaying `'Oskar Jankiewicz prosi o usprawiedliwienie'`, date range summary (`formatDateRangeSummary`), and `'Zobacz szczegóły →'`.
- Added the 4th filter pill `'Oczekujące (Y)'` (`_activeFilter == 3`) and transformed the `'X wnioski czekają na wychowawcę'` banner on `AttendanceScreen` into an expandable accordion showing day-grouped `JustificationStatus.requested` lessons with per-lesson `'Cofnij'` buttons (`ValueKey('cancel_pending_${rec.id}')`) and bulk `'Cofnij wszystkie'`.
- Added comprehensive widget tests in `test/attendance_justification_modal_test.dart` and `test/attendance_pending_requests_test.dart`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Upgrade ParentApprovalModal and ParentRejectionModal with Day-Grouped Lesson Breakdown, Teacher/Classroom Metadata, Q&A History, and Per-Lesson Checkboxes for Partial Approval (D-03, D-04, D-05, D-06)** - `b080260` (feat)
2. **Task 2: Make Justification Banners Interactive on Dashboard & AttendanceScreen, Add 'Oczekujące (Y)' Filter Pill, and Build Expandable 'X wnioski czekają na wychowawcę' Accordion with Per-Lesson 'Cofnij' (D-01, D-02, D-03, D-07, D-08, D-09)** - `c5fe676` (feat)

## Files Created/Modified
- `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart` - Day-grouped lesson breakdown, teacher/classroom metadata, Q&A history, per-lesson checkboxes, and partial approval forwarding via `onApproveSelected`
- `lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart` - Day-grouped lesson summary and `effectiveStudentName` resolution
- `lib/presentation/screens/attendance/attendance_screen.dart` - Interactive parent request banner (`ValueKey('parent_pending_request_banner')`), 4th filter chip `'Oczekujące (Y)'`, and expandable `_buildPendingTeacherAccordionBanner` with per-lesson `'Cofnij'` and bulk `'Cofnij wszystkie'`
- `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart` - Interactive pending justification banner with `effectiveStudentName`, date range summary, `'Zobacz szczegóły →'`, and `onApproveSelected`
- `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart` - Interactive desktop pending justification card with `effectiveStudentName`, date range summary, `'Zobacz szczegóły →'`, and `onApproveSelected`
- `lib/presentation/providers/school_providers.dart` - Removed redundant circular `ref.invalidate(justificationRequestsProvider)` calls inside `AttendanceNotifier` (since `justificationRequestsProvider` already watches `attendanceProvider`)
- `test/attendance_justification_modal_test.dart` - Widget tests for day-grouped lesson details, Q&A history, and partial checkbox approval in `ParentApprovalModal`
- `test/attendance_pending_requests_test.dart` - Widget tests for interactive parent justification banner, expandable pending teacher accordion with single/bulk `'Cofnij'`, and 4th `'Oczekujące (Y)'` filter pill
- `test/dashboard_screen_test.dart` - Added `pl_PL` locale initialization and `SharedPreferences`/`MockSchoolRepository` provider overrides for headless widget tests

## Decisions Made
- Kept backward-compatible `onApprove: Future<bool> Function(String pin)` alongside `onApproveSelected: Future<bool> Function(String pin, List<String> selectedRecordIds)?` on `ParentApprovalModal` so existing callers and tests continue to work seamlessly while new callers pass `selectedRecordIds`.
- Wrapped flexible row children in `Expanded` in day headers and modal headers so headless `Ahem` font tests do not overflow on narrow viewports.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed circular `ref.invalidate(justificationRequestsProvider)` inside `AttendanceNotifier`**
- **Found during:** Task 2 (`test/attendance_pending_requests_test.dart` execution)
- **Issue:** `justificationRequestsProvider` watches `attendanceProvider` via `ref.watch(attendanceProvider)`. Calling `ref.invalidate(justificationRequestsProvider)` from inside `AttendanceNotifier` methods triggered Riverpod's `CircularDependencyError` in widget tests.
- **Fix:** Removed redundant `ref.invalidate(justificationRequestsProvider)` calls inside `AttendanceNotifier` since updating `state = AsyncValue.data(await repo.getAttendanceRecords())` automatically invalidates and recomputes `justificationRequestsProvider`.
- **Files modified:** `lib/presentation/providers/school_providers.dart`
- **Verification:** `flutter test test/attendance_pending_requests_test.dart` passed all 3 widget tests with 0 Riverpod errors.
- **Committed in:** `c5fe676` (part of Task 2 commit)

**2. [Rule 3 - Blocking] Added `pl_PL` date formatting init and `SharedPreferences`/`MockSchoolRepository` overrides to `test/dashboard_screen_test.dart`**
- **Found during:** Task 2 verification (`flutter test ... test/dashboard_screen_test.dart`)
- **Issue:** `test/dashboard_screen_test.dart` was created in Phase 08 before `DashboardScreen` / `DashboardMobileView` added `DateFormat(..., 'pl_PL')` and `syncProvider` (`sharedPreferencesProvider`), causing `LocaleDataException` and `UnimplementedError` when run in isolation.
- **Fix:** Added `initializeDateFormatting('pl_PL')`, `SharedPreferences.setMockInitialValues({})`, and `MockSchoolRepository` overrides in `test/dashboard_screen_test.dart`.
- **Files modified:** `test/dashboard_screen_test.dart`
- **Verification:** `flutter test test/dashboard_screen_test.dart` passed 2/2 tests.
- **Committed in:** `c5fe676` (part of Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 Rule 1 bug, 1 Rule 3 blocking test setup)
**Impact on plan:** Both auto-fixes were required for clean Riverpod state updates and passing verification suites. No scope creep.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 23 (`23-01` and `23-02`) is complete. All `REQ-ATT-01` and `REQ-ATT-02` requirements and decisions (`D-01` through `D-09`) are implemented and verified.

## Self-Check: PASSED

---
*Phase: 23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni*
*Completed: 2026-10-02*
