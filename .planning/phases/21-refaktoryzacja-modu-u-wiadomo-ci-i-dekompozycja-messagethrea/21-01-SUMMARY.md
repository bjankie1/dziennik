---
phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea
plan: 01
subsystem: ui
tags: [flutter, riverpod, date-formatting, attendance, dashboard, refactoring]

# Dependency graph
requires:
  - phase: 23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni
    provides: Interactive justification banners, ParentApprovalModal partial approval, and effectiveStudentName
provides:
  - Shared PolishDateFormatter utility (lib/core/utils/polish_date_formatter.dart) with unit tests
  - Shared JustificationRequestBanner widget (lib/presentation/widgets/common/justification_request_banner.dart) with selective Riverpod .select(...) subscriptions
  - Deduplicated DashboardMobileView (-340 LOC) and DashboardMetricsColumn (-317 LOC) justification banners
affects: [21-02, 21-03, 21-04]

# Actuals (#2632)
plan_head_before: db6c23bc8164c03cf1d7d94e88338006a8727c5f
actuals:
  tokens: 21999
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure static PolishDateFormatter utility for weekday/month genitive formatting and Polish noun pluralization"
    - "Shared ConsumerWidget (JustificationRequestBanner) using Dart 3 record selectors with Riverpod .select(...)"

key-files:
  created:
    - lib/core/utils/polish_date_formatter.dart
    - test/core/utils/polish_date_formatter_test.dart
    - lib/presentation/widgets/common/justification_request_banner.dart
  modified:
    - lib/domain/models/justification_request.dart
    - lib/presentation/widgets/common/justification_approval_dialogs.dart
    - lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart
    - lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart

key-decisions:
  - "Consolidated three variants of the parent pending / student rejected justification banner (mobile default, desktop compact, and attendance indigo) into a single parameterized JustificationRequestBanner with selective Riverpod subscriptions"
  - "Converted unused 312-LOC justification_approval_dialogs.dart into a clean barrel re-exporting justification_request_banner.dart and polish_date_formatter.dart"

patterns-established:
  - "PolishDateFormatter: Single source of truth for Polish weekday names, genitive month names, zero-padded timestamps, and nominative/accusative lesson pluralization"
  - "Riverpod .select(...) with Dart 3 records for role-gated banner components"

requirements-completed:
  - REQ-ARCH-01
  - REQ-ARCH-02

coverage:
  - id: D1
    description: "PolishDateFormatter utility class providing formatDayHeader, formatShortDayHeader, formatFullDate, formatNumericDateTime, formatNumericDateShortTime, pluralizeLesson, and pluralizeLessonAccusative, wired into JustificationRequest.formatPolishDayHeader"
    requirement: REQ-ARCH-01
    verification:
      - kind: unit
        ref: "test/core/utils/polish_date_formatter_test.dart#PolishDateFormatter"
        status: pass
    human_judgment: false
  - id: D2
    description: "Shared JustificationRequestBanner ConsumerWidget with selective Riverpod .select(...) subscriptions replacing duplicated banners in DashboardMobileView and DashboardMetricsColumn"
    requirement: REQ-ARCH-02
    verification:
      - kind: automated_ui
        ref: "test/attendance_justification_modal_test.dart"
        status: pass
      - kind: automated_ui
        ref: "test/dashboard_screen_test.dart"
        status: pass
    human_judgment: false

# Metrics
duration: 11min
completed: 2026-10-02
status: complete
---

# Phase 21 Plan 01: Shared PolishDateFormatter & JustificationRequestBanner Foundations Summary

**Shared `PolishDateFormatter` utility with unit tests and `JustificationRequestBanner` widget with selective Riverpod `.select(...)` subscriptions, eliminating ~650 LOC of duplicated justification banner code across `DashboardMobileView` and `DashboardMetricsColumn`.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-10-02T10:54:07Z
- **Completed:** 2026-10-02T11:05:24Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Created `PolishDateFormatter` (`lib/core/utils/polish_date_formatter.dart`) centralizing Polish weekday names, capitalized and lowercase genitive month names, zero-padded numeric timestamps, and nominative/accusative pluralization of "lekcja", and delegated `JustificationRequest.formatPolishDayHeader` to `PolishDateFormatter.formatDayHeader`.
- Added 6 unit test groups in `test/core/utils/polish_date_formatter_test.dart` verifying all date/time formats and Polish pluralization edge cases (`0`, `1`, `2-4`, `5+`, `12-14`, `22-24`).
- Created `JustificationRequestBanner` (`lib/presentation/widgets/common/justification_request_banner.dart`) supporting mobile default, desktop `compact`, and attendance `useIndigoStyle` layouts with `const ValueKey('parent_pending_request_banner')`, `ParentApprovalModal`, `ParentRejectionModal`, and `StudentResponseModal` integration, and narrow `.select(...)` subscriptions on `appUserProvider`, `justificationRequestsProvider`, `attendanceProvider`, and `studentProfileProvider`.
- Replaced inline justification banners in `DashboardMobileView` (`1050 → 710 LOC`) and `DashboardMetricsColumn` (`962 → 645 LOC`), and replaced the unused 312-LOC `justification_approval_dialogs.dart` with a clean 2-line barrel export.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create PolishDateFormatter Utility, Unit Tests & Wire JustificationRequest.formatPolishDayHeader** - `17bc285` (feat)
2. **Task 2: Create Shared JustificationRequestBanner & Replace Duplicated Banners in DashboardMobileView and DashboardMetricsColumn** - `dffa3f9` (refactor)

## Files Created/Modified
- `lib/core/utils/polish_date_formatter.dart` - Pure static helper class for Polish dates, headers, timestamps, and lesson pluralization
- `test/core/utils/polish_date_formatter_test.dart` - Unit tests for `PolishDateFormatter` and `JustificationRequest.formatPolishDayHeader`
- `lib/domain/models/justification_request.dart` - Delegated `formatPolishDayHeader` to `PolishDateFormatter.formatDayHeader`
- `lib/presentation/widgets/common/justification_request_banner.dart` - Shared `ConsumerWidget` for parent pending and student rejected justification requests
- `lib/presentation/widgets/common/justification_approval_dialogs.dart` - Converted legacy unused 312-LOC file into barrel export
- `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart` - Replaced ~340 LOC of inline justification banners and `DateFormat` logic with `JustificationRequestBanner` and `PolishDateFormatter.formatShortDayHeader`
- `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart` - Replaced `_buildParentPendingRequestCard` and `_buildStudentRejectedRequestCard` (~317 LOC) with `const JustificationRequestBanner(showDetailsLink: true, compact: true)`

## Decisions Made
- Consolidated all three visual variants of the justification banner (`default` mobile row, `compact` desktop column, and `useIndigoStyle` attendance card) into `JustificationRequestBanner` so Wave 2 (`21-03` `AttendanceScreen` decomposition) can drop in `const JustificationRequestBanner(showDetailsLink: true, useIndigoStyle: true, bottomSpacing: 14)` with zero extra changes.
- Removed redundant top-level `ref.watch(justificationRequestsProvider)` and `ref.watch(appUserProvider)` calls from `DashboardMobileView.build` since `JustificationRequestBanner` now watches them selectively via `.select(...)`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `PolishDateFormatter` and `JustificationRequestBanner` are ready for consumption in `21-03` (`AttendanceScreen` decomposition) and `21-02` (`MessageThreadScreen` decomposition).

## Self-Check: PASSED
- Verified all created/modified files exist on disk.
- Verified commits `17bc285` and `dffa3f9` exist in git history.
- Verified `flutter analyze` (0 issues) and all unit/widget tests pass.

---
*Phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea*
*Completed: 2026-10-02*
