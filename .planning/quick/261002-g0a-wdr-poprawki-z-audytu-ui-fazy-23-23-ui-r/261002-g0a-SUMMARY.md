---
phase: quick-261002-g0a
plan: 01
subsystem: attendance-ui
tags: [flutter, ui-audit, accessibility, typography, design-tokens, phase-23]
status: complete
plan_head_before: 809faa1def5822e0df75fee445ff4f1b6988799d
commits: [18bbec0, f0cd7ff]
requires:
  - phase-23
provides:
  - Single-row pending teacher status copy in AttendanceScreen
  - Read-only requested details modal with cancel guard
  - Animated pending teacher accordion with bulk-cancel confirmation dialog
  - Dynamic studentName & multi-day date range summary in ParentRejectionModal
  - Semantic AppColors tokens, >=11px typography, and >=36px touch targets across Phase 23 widgets
affects:
  - lib/core/theme/app_colors.dart
  - lib/presentation/screens/attendance/attendance_screen.dart
  - lib/presentation/screens/attendance/widgets/parent_approval_modal.dart
  - lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart
  - lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart
  - lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart
  - test/attendance_pending_requests_test.dart
  - test/attendance_justification_modal_test.dart
key-files:
  created: []
  modified:
    - lib/core/theme/app_colors.dart
    - lib/presentation/screens/attendance/attendance_screen.dart
    - lib/presentation/screens/attendance/widgets/parent_approval_modal.dart
    - lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart
    - lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart
    - lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart
    - test/attendance_pending_requests_test.dart
    - test/attendance_justification_modal_test.dart
decisions:
  - Differentiated the parent pending request banner using AppColors.indigoSurface / AppColors.indigoBorder and a responsive 2-row layout so action buttons never crowd the student title on compact viewports while keeping >=36px touch targets.
  - Replaced the ungated 'Wyślij do Librusa' action in _showRequestedDetailsModal with a read-only 'Oczekuje na wychowawcę w Librusie' status badge and 'Zamknij' CTA, since requested lessons are already submitted to the teacher.
metrics:
  duration: 12m
  completed_at: "2026-10-02T12:05:00+02:00"
  tasks_completed: 2
  files_modified: 8
---

# Quick Task 261002-g0a: Wdróż poprawki z audytu UI fazy 23 (23-UI-REVIEW.md) Summary

**One-liner:** Resolved all Priority 1, 2, and 3 UI audit findings from Phase 23 across attendance and dashboard surfaces, including single-line pending status copy, read-only requested details modal, animated pending teacher accordion with bulk-cancel confirmation, dynamic student name in `ParentRejectionModal`, `AppColors` token standardization, `>=11px` typography, and `>=36px` touch targets.

## Completed Tasks

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Fix AttendanceScreen status copy, secure requested details modal, and polish pending teacher accordion | `18bbec0` | [attendance_screen.dart](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/attendance/attendance_screen.dart) |
| 2 | Fix ParentRejectionModal hardcoded name, standardize AppColors tokens, typography (>=11px), touch targets (>=36px), and update tests | `f0cd7ff` | [app_colors.dart](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/core/theme/app_colors.dart), [attendance_screen.dart](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/attendance/attendance_screen.dart), [parent_approval_modal.dart](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/attendance/widgets/parent_approval_modal.dart), [parent_rejection_modal.dart](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart), [dashboard_mobile_view.dart](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart), [dashboard_metrics_column.dart](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart), [attendance_pending_requests_test.dart](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/test/attendance_pending_requests_test.dart), [attendance_justification_modal_test.dart](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/test/attendance_justification_modal_test.dart) |

## What Changed

### Priority 1 Fixes
- **Single-Row Pending Status Copy (`AttendanceScreen`):** Replaced the contradictory two-row status (`Wniosek wysłany (oczekuje)` + duplicate amber pill `Oczekuje na wychowawcę w Librusie`) on `JustificationStatus.requested` rows with a single clean status line: `'Oczekuje na wychowawcę (${record.justificationReason})'`.
- **Dynamic Student Name & Multi-Day Summary (`ParentRejectionModal`):** Replaced hardcoded `'Oskarowi'` / `'Oskara'` strings in subtitle, text field label, and submit button with dynamic `$studentName` (`effectiveStudentName`), added `tooltip: 'Zamknij'` on the close button, and displayed `request.formatDateRangeSummary(availableRecords)` when a request spans multiple calendar days.
- **Secured Requested Details Modal (`_showRequestedDetailsModal`):** Removed the ungated `'Wyślij do Librusa'` button that bypassed PIN verification on already-requested lessons, added an `'Oczekuje na wychowawcę w Librusie'` status badge, guarded `'Cofnij wniosek'` with `_isCancellingPending`, and added a `'Zamknij'` (`ValueKey('close_requested_details_modal_button')`) action.

### Priority 2 Fixes
- **Animated Pending Teacher Accordion & Bulk-Cancel Confirmation:** Added `AnimatedSize` (220ms, `Curves.easeOutCubic`) and `AnimatedRotation` on the chevron icon in `_buildPendingTeacherAccordionBanner`, added `_isCancellingPending` double-tap guards on per-lesson and bulk cancel buttons, and added a confirmation `AlertDialog` (`ValueKey('confirm_cancel_all_pending_button')`) before executing `'Cofnij wszystkie'`.
- **Semantic `AppColors` Tokens:** Extended `AppColors` with warning/amber, danger/red, success/emerald, neutral slate (`slate50`–`slate900`), and indigo tint tokens, and replaced inline `Color(0x...)` hex literals across `attendance_screen.dart`, `parent_approval_modal.dart`, `parent_rejection_modal.dart`, `dashboard_mobile_view.dart`, and `dashboard_metrics_column.dart`.
- **Responsive Parent Pending Banner & Visual Hierarchy:** Switched `_buildParentPendingBanner` to `ref.watch`, styled it with `AppColors.indigoSurface` / `AppColors.indigoBorder` to distinguish it from the amber teacher banner, and arranged the `'Zatwierdź (PIN)'` and `'Odrzuć'` buttons in a dedicated full-width bottom row.

### Priority 3 Fixes
- **Touch Targets (`>=36px`) & CTA Labels:** Increased minimum heights to `36px` on `'Cofnij wszystkie'`, per-lesson `'Cofnij'`, `'Zatwierdź (PIN)'`, and `'Odrzuć'` across `AttendanceScreen`, `DashboardMobileView`, and `DashboardMetricsColumn`, and unified the approval button label to `'Zatwierdź (PIN)'` (`fontSize: 12`).
- **Typography Floor (`>=11px`) & Spacing Grid:** Raised all sub-`11px` (`8`, `9`, `10`, `10.5`) and fractional (`11.5`) font sizes to the `11, 12, 13, 14, 16, 18` scale and aligned off-grid spacing values (`1`, `3`, `9`).

## Deviations from Plan

None — plan executed exactly as written.

## Verification

- `flutter analyze`: **0 issues found**
- `flutter test test/attendance_pending_requests_test.dart test/attendance_justification_modal_test.dart test/dashboard_screen_test.dart`: **11/11 tests passed**

## Self-Check: PASSED
- Verified `.planning/quick/261002-g0a-wdr-poprawki-z-audytu-ui-fazy-23-23-ui-r/261002-g0a-SUMMARY.md` exists on disk.
- Verified commits `18bbec0` and `f0cd7ff` exist in `git log`.
