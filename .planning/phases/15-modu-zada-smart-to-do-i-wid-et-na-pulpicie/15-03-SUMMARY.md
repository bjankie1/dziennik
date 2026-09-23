---
phase: 15-modu-zada-smart-to-do-i-wid-et-na-pulpicie
plan: 03
subsystem: dashboard-bento-widget
tags:
  - smart-todo
  - dashboard
  - bento-grid
  - urgent-tasks
  - firestore
requires:
  - lib/domain/models/school_task.dart
  - lib/presentation/providers/tasks_provider.dart
  - lib/presentation/screens/tasks/widgets/task_form_modal.dart
provides:
  - Interactive 'Zadania na dziś' Bento card (_buildDesktopTasksCard) mounted at the top of Desktop Column 2 above 'Wiadomości i Komunikaty'
  - Interactive 'Zadania na dziś' card (_buildMobileTasksCard) mounted in Mobile Dashboard below 'DZISIEJSZY PLAN ZAJĘĆ' and above 'WIADOMOŚCI'
  - One-click task completion checkbox with full parent/student attribution on Dashboard without leaving the screen
  - Column 3 'Zadania domowe' shortcut tile routed to /zadania while preserving test-compatible label
affects:
  - lib/presentation/screens/dashboard/dashboard_screen.dart
tech-stack:
  added: []
  patterns:
    - Shared _buildUrgentTaskRow rendering role badges, subject micro-pills, and due-date tags
    - Optimistic one-click Firestore task completion from Dashboard Bento cards
    - Extended mobile ListView cacheExtent (2000.0) so offscreen sections remain mounted in widget tests
key-files:
  created: []
  modified:
    - lib/presentation/screens/dashboard/dashboard_screen.dart
key-decisions:
  - "Mounted `_buildDesktopTasksCard` at the very top of `_buildDesktopMessagesColumn` (Column 2, center `flex: 5`) directly above `_buildDesktopMessagesCard` (`Wiadomości i Komunikaty`) with a 20px gap (`D-07`)."
  - "Mounted `_buildMobileTasksCard` in `_buildMobileDashboard` directly below `'DZISIEJSZY PLAN ZAJĘĆ'` and above `'WIADOMOŚCI'` with 16px spacing (`D-07`), and set `cacheExtent: 2000.0` on the mobile `ListView` so downstream sections (`'OSTATNIE OCENY'`) stay built in widget tests."
  - "Kept the exact `'Zadania domowe'` label on the Column 3 shortcut tile for `test/dashboard_screen_test.dart:33` compatibility while updating its `onTap` route to `/zadania`."
requirements-completed:
  - REQ-TASK-02
duration: "6 min"
completed: "2026-09-23"
status: complete
one_liner: "Interactive 'Zadania na dziś' Bento Grid card mounted at the top of Desktop Column 2 above Messages and below the Daily Schedule on Mobile with one-click Firestore completion and TaskFormModal launcher"
commits: 2
plan_head_before: 48f763664660d97059b537ee6a57f9bd82ad3035
actuals:
  tokens: 5800
  tasks: 2
  commits: 2
---

# Phase 15 Plan 03: Dashboard „Zadania na dziś” Bento Widget (`_buildDesktopTasksCard` & `_buildMobileTasksCard`) Summary

**One-liner:** Interactive `'Zadania na dziś'` Bento Grid card mounted at the top of Desktop Column 2 above Messages and below the Daily Schedule on Mobile with one-click Firestore completion and `TaskFormModal` launcher.

## Accomplishments

- **Desktop Column 2 Top Bento Card (`_buildDesktopTasksCard`):**
  - Mounted `'Zadania na dziś'` at the very top of `_buildDesktopMessagesColumn` (Column 2, center column `flex: 5`), directly above `'Wiadomości i Komunikaty'` separated by `const SizedBox(height: 20)` (`D-07`).
  - Subscribed to `urgentTasksProvider` (displaying up to 5 most urgent active tasks ordered by Overdue → Due Today → Role relevance → Priority) and `totalActiveTasksCountProvider` (`D-08`).
  - Added header with `Icons.checklist_rtl_rounded`, urgent tasks badge (red `AppColors.error` when any task is overdue, otherwise `AppColors.primaryFixed`), quick `+` button launching `TaskFormModal.show(context)`, and `'Zobacz wszystkie (X) →'` button navigating to `/zadania`.
  - Implemented `_buildUrgentTaskRow` with a one-click `Checkbox` that immediately calls `TasksRepository.toggleTaskCompletion` with full `completedByRole` and `completedByName` attribution (`T-15-05`), role assignment pills (`Dla Oskara`, `Dla Rodzica`, `Wspólne`), subject pills, and due-date badges (`Zaległe` / `Dzisiaj`).
  - Updated the Column 3 `'Zadania domowe'` shortcut tile `onTap` in `_buildDesktopMetricsColumn` to route to `/zadania` while retaining its exact label for `test/dashboard_screen_test.dart` compatibility.
- **Mobile Dashboard Card (`_buildMobileTasksCard`):**
  - Mounted `_buildMobileTasksCard` in `_buildMobileDashboard` directly below the `'DZISIEJSZY PLAN ZAJĘĆ'` card and above `'WIADOMOŚCI'` with `const SizedBox(height: 16)` spacing (`D-07`, `D-08`).
  - Configured `cacheExtent: 2000.0` on the mobile `ListView` so offscreen cards remain built during widget tests.

## Task Commits

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Mount `'Zadania na dziś'` Bento card at the top of Desktop Column 2 above Messages (`D-07`, `D-08`) | `2365959` |
| 2 | Mount `'Zadania na dziś'` Bento card in Mobile Dashboard below Daily Schedule (`D-07`, `D-08`) | `c5b6903` |

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

- `flutter analyze lib/presentation/screens/dashboard/dashboard_screen.dart` → `No issues found! (ran in 1.4s)`
- `flutter analyze` (whole repository) → `No issues found! (ran in 2.1s)`

## Self-Check: PASSED

- FOUND: `lib/presentation/screens/dashboard/dashboard_screen.dart`
- FOUND commit: `2365959`
- FOUND commit: `c5b6903`
