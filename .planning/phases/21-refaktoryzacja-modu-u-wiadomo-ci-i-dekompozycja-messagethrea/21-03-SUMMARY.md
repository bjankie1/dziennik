---
phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea
plan: 03
subsystem: ui
tags: [flutter, riverpod, attendance, widget-decomposition, refactoring]

# Dependency graph
requires:
  - phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea
    provides: Shared PolishDateFormatter utility and JustificationRequestBanner widget (21-01)
provides:
  - AttendanceSemesterKpiCard const StatelessWidget (lib/presentation/screens/attendance/widgets/attendance_semester_kpi_card.dart)
  - PendingTeacherAccordionBanner ConsumerStatefulWidget (lib/presentation/screens/attendance/widgets/pending_teacher_accordion_banner.dart)
  - AttendanceFilterBar const StatelessWidget (lib/presentation/screens/attendance/widgets/attendance_filter_bar.dart)
  - AttendanceDayGroupCard & AttendanceLessonRow const StatelessWidgets (lib/presentation/screens/attendance/widgets/attendance_day_group_card.dart)
  - FloatingJustificationDock ConsumerStatefulWidget (lib/presentation/screens/attendance/widgets/floating_justification_dock.dart)
  - RequestedAttendanceDetailsSheet ConsumerStatefulWidget (lib/presentation/screens/attendance/widgets/requested_attendance_details_sheet.dart)
  - Streamlined AttendanceScreen coordinator reduced from 1 952 LOC to 273 LOC (lib/presentation/screens/attendance/attendance_screen.dart)
affects: [21-04]

# Actuals (#2632)
plan_head_before: 05c8d3c46430fe3d964c623e73be9a549d529cc3
actuals:
  tokens: 19631
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Local ephemeral state isolation inside ConsumerStatefulWidget leaves (PendingTeacherAccordionBanner, FloatingJustificationDock, RequestedAttendanceDetailsSheet)"
    - "Coordinator screen pattern (< 350 LOC) with selective Riverpod .select(...) subscriptions and slot composition (bannerSlot)"

key-files:
  created:
    - lib/presentation/screens/attendance/widgets/attendance_semester_kpi_card.dart
    - lib/presentation/screens/attendance/widgets/pending_teacher_accordion_banner.dart
    - lib/presentation/screens/attendance/widgets/attendance_filter_bar.dart
    - lib/presentation/screens/attendance/widgets/attendance_day_group_card.dart
    - lib/presentation/screens/attendance/widgets/floating_justification_dock.dart
    - lib/presentation/screens/attendance/widgets/requested_attendance_details_sheet.dart
  modified:
    - lib/presentation/screens/attendance/attendance_screen.dart

key-decisions:
  - "Decomposed AttendanceScreen (1 952 -> 273 LOC) into 6 focused sub-widgets in lib/presentation/screens/attendance/widgets/ and wired JustificationRequestBanner(useIndigoStyle: true, bottomSpacing: 14) and PolishDateFormatter"
  - "Isolated accordion expansion, pending cancellation loading, and quick-reason selection states into PendingTeacherAccordionBanner, RequestedAttendanceDetailsSheet, and FloatingJustificationDock so local UI interactions do not rebuild the full attendance list"

patterns-established:
  - "Slot injection (bannerSlot on AttendanceFilterBar) to preserve exact vertical layout order between filter chips, conditional banners, and section headers"
  - "Static show(BuildContext, AttendanceRecord) helper on modal bottom sheet widgets (RequestedAttendanceDetailsSheet)"

requirements-completed:
  - REQ-ARCH-01
  - REQ-ARCH-02

coverage:
  - id: D1
    description: "Extracted AttendanceSemesterKpiCard, PendingTeacherAccordionBanner, and AttendanceFilterBar into lib/presentation/screens/attendance/widgets/ with isolated accordion/cancellation state and all ValueKeys preserved"
    requirement: REQ-ARCH-02
    verification:
      - kind: automated_ui
        ref: "test/attendance_pending_requests_test.dart"
        status: pass
    human_judgment: false
  - id: D2
    description: "Extracted AttendanceDayGroupCard, FloatingJustificationDock, and RequestedAttendanceDetailsSheet and reduced attendance_screen.dart from 1 952 LOC to 273 LOC (< 350 LOC), wiring JustificationRequestBanner and PolishDateFormatter"
    requirement: REQ-ARCH-01
    verification:
      - kind: automated_ui
        ref: "test/attendance_pending_requests_test.dart"
        status: pass
      - kind: automated_ui
        ref: "test/attendance_justification_modal_test.dart"
        status: pass
    human_judgment: false

# Metrics
duration: 6min
completed: 2026-10-03
status: complete
---

# Phase 21 Plan 03: AttendanceScreen Decomposition & Sub-Widget Extraction Summary

**Decomposed `AttendanceScreen` (`1 952 → 273 LOC`) into 6 dedicated sub-widgets in `lib/presentation/screens/attendance/widgets/` with isolated Riverpod/UI rebuild boundaries, wiring `JustificationRequestBanner` and `PolishDateFormatter`.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-10-03T16:37:44Z
- **Completed:** 2026-10-03T16:43:30Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Extracted `AttendanceSemesterKpiCard` (`const StatelessWidget`), `PendingTeacherAccordionBanner` (`ConsumerStatefulWidget`), and `AttendanceFilterBar` (`const StatelessWidget`) into `lib/presentation/screens/attendance/widgets/`.
- Isolated `_isExpanded` and `_isCancellingPending` inside `PendingTeacherAccordionBanner` while preserving `ValueKey('pending_teacher_banner_toggle')`, `ValueKey('cancel_all_pending_button')`, `ValueKey('confirm_cancel_all_pending_button')`, and `ValueKey('cancel_pending_${rec.id}')`.
- Extracted `AttendanceDayGroupCard` + `AttendanceLessonRow` (`const StatelessWidget`), `FloatingJustificationDock` (`ConsumerStatefulWidget` owning `_selectedQuickReason`), and `RequestedAttendanceDetailsSheet` (`ConsumerStatefulWidget` with `ValueKey('close_requested_details_modal_button')`).
- Reduced `lib/presentation/screens/attendance/attendance_screen.dart` from `1 952 LOC` to `273 LOC` (`< 350 LOC`), replacing duplicated parent/student banners and date formatting helpers with `const JustificationRequestBanner(useIndigoStyle: true, bottomSpacing: 14)` and `PolishDateFormatter`, and narrowing `appUserProvider` via `.select((u) => u?.isStudent ?? false)`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract AttendanceSemesterKpiCard, PendingTeacherAccordionBanner & AttendanceFilterBar into attendance/widgets/** - `cd2fed3` (feat)
2. **Task 2: Extract AttendanceDayGroupCard, FloatingJustificationDock & RequestedAttendanceDetailsSheet and Reduce attendance_screen.dart to < 350 LOC** - `c4a486d` (refactor)

## Files Created/Modified
- `lib/presentation/screens/attendance/widgets/attendance_semester_kpi_card.dart` - `const StatelessWidget` rendering `DualRingAttendanceGauge`, status pill, progress bar, ring legend, and 4 KPI stat columns
- `lib/presentation/screens/attendance/widgets/pending_teacher_accordion_banner.dart` - `ConsumerStatefulWidget` for teacher-pending items with per-lesson `Cofnij` and `Cofnij wszystkie` confirmation dialog
- `lib/presentation/screens/attendance/widgets/attendance_filter_bar.dart` - `const StatelessWidget` for the 4 filter chips, optional `bannerSlot`, and `Zaznacz wszystkie` / `Odznacz wszystkie` header row
- `lib/presentation/screens/attendance/widgets/attendance_day_group_card.dart` - `AttendanceDayGroupCard` and `AttendanceLessonRow` `const StatelessWidget`s for day-grouped attendance records
- `lib/presentation/screens/attendance/widgets/floating_justification_dock.dart` - `ConsumerStatefulWidget` owning `_selectedQuickReason` and dispatching role-gated `StudentJustificationModal` / `JustificationModal`
- `lib/presentation/screens/attendance/widgets/requested_attendance_details_sheet.dart` - `ConsumerStatefulWidget` bottom sheet with `static show(BuildContext, AttendanceRecord)` helper
- `lib/presentation/screens/attendance/attendance_screen.dart` - Streamlined 273-LOC coordinator widget

## Decisions Made
- Exposed an optional `Widget? bannerSlot` on `AttendanceFilterBar` so `PendingTeacherAccordionBanner` renders in its exact original position between the horizontal filter chip row and the `'Zgłoszenia nieobecności'` section header while keeping `AttendanceScreen` clean and concise.
- Captured `ScaffoldMessenger.maybeOf(context)` and `ref.read(attendanceProvider.notifier)` prior to `Navigator.pop(context)` inside `RequestedAttendanceDetailsSheet` to avoid using `BuildContext` or `WidgetRef` across an async gap after sheet dismissal.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `AttendanceScreen` decomposition is complete and verified (`273 LOC`, all widget tests passing). Ready for `21-04` (`NotificationSettingsModal` decomposition).

## Self-Check: PASSED
- Verified all 6 created widget files and `lib/presentation/screens/attendance/attendance_screen.dart` (273 LOC) exist on disk.
- Verified commits `cd2fed3` and `c4a486d` exist in git history.
- Verified `flutter analyze` (0 issues) and `flutter test test/attendance_pending_requests_test.dart test/attendance_justification_modal_test.dart` pass 100%.

---
*Phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea*
*Completed: 2026-10-03*
