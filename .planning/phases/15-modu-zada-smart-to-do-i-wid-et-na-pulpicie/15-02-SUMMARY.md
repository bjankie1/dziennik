---
phase: 15-modu-zada-smart-to-do-i-wid-et-na-pulpicie
plan: 02
subsystem: ui-and-navigation
tags:
  - smart-todo
  - tasks-screen
  - task-form-modal
  - go-router
  - navigation-shell
requires:
  - lib/domain/models/school_task.dart
  - lib/presentation/providers/tasks_provider.dart
provides:
  - TaskFormModal for creating, viewing, and editing shared family tasks with D-03 parent-task lock protection
  - TasksScreen (/zadania) matching MessagesScreen visual pattern with Segmented Control Bar, 44px Quick Add bar, role filter chips, and chronological sections
  - 7-branch StatefulShellRoute.indexedStack with Branch 5 (/zadania) and Branch 6 (/czat)
  - Desktop AppSidebar with Zadania (index 5, tasksBadgeCount) and Czat Rodzinny (index 6, chatUnreadCount)
  - Mobile 6-destination NavigationBar (Pulpit..Zadania) with clamped selectedIndex and AppHeader Czat Rodzinny badge button
affects:
  - lib/presentation/screens/tasks/widgets/task_form_modal.dart
  - lib/presentation/screens/tasks/tasks_screen.dart
  - lib/presentation/routes/app_router.dart
  - lib/presentation/screens/main_navigation_screen.dart
  - lib/presentation/widgets/app_sidebar.dart
  - lib/presentation/widgets/app_header.dart
tech-stack:
  added: []
  patterns:
    - MessagesScreen visual layout parity (Segmented Control Bar + 44px Quick Add bar + 16px rounded cards)
    - Clamped NavigationBar selectedIndex (activeIndex < 6 ? activeIndex : 0) for 7-branch shell with 6 mobile bottom tabs
    - Locale-safe DateFormat fallback for widget tests
key-files:
  created:
    - lib/presentation/screens/tasks/widgets/task_form_modal.dart
    - lib/presentation/screens/tasks/tasks_screen.dart
  modified:
    - lib/presentation/routes/app_router.dart
    - lib/presentation/screens/main_navigation_screen.dart
    - lib/presentation/widgets/app_sidebar.dart
    - lib/presentation/widgets/app_header.dart
key-decisions:
  - "Clamped mobile NavigationBar `selectedIndex: activeIndex < 6 ? activeIndex : 0` so navigating to Branch 6 (`/czat`) via the top `AppHeader` icon never triggers Flutter's `0 <= selectedIndex < destinations.length` assertion."
  - "Exposed `Czat Rodzinny` with unread badge in mobile `AppHeader` while dedicating all 6 bottom `NavigationBar` slots to educational modules (`Pulpit`, `Plan`, `Oceny`, `Frekwencja`, `Wiadomości`, `Zadania`) per D-09."
  - "Protected Parent-created tasks on Student accounts (`D-03`) in both `TasksScreen` cards and `TaskFormModal` by replacing delete controls with an `Icons.lock_person_outlined` badge and notice while preserving completion toggles and note editing."
requirements-completed:
  - REQ-TASK-01
duration: "9 min"
completed: "2026-09-23"
status: complete
one_liner: "Dedicated /zadania screen (TasksScreen + TaskFormModal) matching MessagesScreen visual pattern and 7-branch navigation shell with desktop AppSidebar, 6-tab mobile NavigationBar, and AppHeader Family Chat badge"
commits: 2
plan_head_before: 2227bdd9ae78123ed412934083ac8e1bbf6b1069
actuals:
  tokens: 14500
  tasks: 2
  commits: 2
---

# Phase 15 Plan 02: `/zadania` Screen (`TasksScreen` + `TaskFormModal`) & 7-Branch Navigation Shell Summary

**One-liner:** Dedicated `/zadania` screen (`TasksScreen` + `TaskFormModal`) matching `MessagesScreen` visual pattern and 7-branch navigation shell with desktop `AppSidebar`, 6-tab mobile `NavigationBar`, and `AppHeader` Family Chat badge.

## Accomplishments

- **`TaskFormModal` (`lib/presentation/screens/tasks/widgets/task_form_modal.dart`):**
  - Built full create/edit dialog supporting title validation, multiline notes, role assignment pills (`Dla Oskara`, `Dla Rodzica`, `Wspólne` per `D-01`), priority levels (`Wysoki`, `Normalny`, `Niski` per `D-02`), quick due-date pills + `showDatePicker`, and preset/custom subject tags.
  - Enforced `D-03` parent-task protection: when `isStudent && createdByRole == 'parent'`, hides the delete button and displays an `Icons.lock_person_outlined` info banner while allowing note edits.
- **`TasksScreen` (`lib/presentation/screens/tasks/tasks_screen.dart`):**
  - Implemented visual parity with `MessagesScreen` (`D-04`): top Segmented Control Bar with 4 tabs (`Wszystkie`, `Dzisiaj`, `Nadchodzące`, `Ukończone`) and live badges, 44px Quick Add bar with inline due-date/priority/role toggles + `+ Nowe zadanie` `FilledButton.icon`, and horizontal role filter chips.
  - Grouped active tasks into non-empty chronological sections (`Zaległe` in `AppColors.error`, `Dzisiaj`, `Jutro / Nadchodzące`, `Bez terminu` per `D-05`) and sorted completed tasks descending by completion timestamp.
  - Rendered interactive task cards (`D-06`) with one-click completion checkbox, strike-through animation, attribution footer (`Dodał: X • Ukończył: Y`), and `D-03` lock badge (`Icons.lock_person_outlined`).
- **7-Branch Navigation Shell (`app_router.dart`, `main_navigation_screen.dart`, `app_sidebar.dart`, `app_header.dart`):**
  - Registered Branch 5 (`/zadania` -> `TasksScreen`) and shifted Branch 6 (`/czat` -> `FamilyChatScreen`) in `StatefulShellRoute.indexedStack`.
  - Updated desktop `AppSidebar` with 7 items including `Zadania` (`tasksBadgeCount`) and `Czat Rodzinny` (`chatUnreadCount`).
  - Configured mobile `NavigationBar` with 6 educational destinations (`Pulpit`, `Plan`, `Oceny`, `Frekwencja`, `Wiadomości`, `Zadania`), clamped `selectedIndex: activeIndex < 6 ? activeIndex : 0`, and added the `Czat Rodzinny` icon button with `Badge` to `AppHeader` (`D-09`).

## Task Commits

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Build `TaskFormModal` and `TasksScreen` (`/zadania`) matching `MessagesScreen` visual pattern (`D-01..D-06`) | `4de6e47` |
| 2 | Wire `/zadania` (Branch 5) and `/czat` (Branch 6) in `go_router`, `AppSidebar`, Mobile `NavigationBar`, and `AppHeader` (`D-09`) | `6474957` |

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

- `flutter analyze lib/presentation/screens/tasks/widgets/task_form_modal.dart lib/presentation/screens/tasks/tasks_screen.dart` → `No issues found! (ran in 1.2s)`
- `flutter analyze lib/presentation/routes/app_router.dart lib/presentation/screens/main_navigation_screen.dart lib/presentation/widgets/app_sidebar.dart lib/presentation/widgets/app_header.dart` → `No issues found! (ran in 1.3s)`
- `flutter analyze` (whole repository) → `No issues found! (ran in 1.1s)`

## Self-Check: PASSED

- FOUND: `lib/presentation/screens/tasks/widgets/task_form_modal.dart`
- FOUND: `lib/presentation/screens/tasks/tasks_screen.dart`
- FOUND: `lib/presentation/routes/app_router.dart`
- FOUND: `lib/presentation/screens/main_navigation_screen.dart`
- FOUND: `lib/presentation/widgets/app_sidebar.dart`
- FOUND: `lib/presentation/widgets/app_header.dart`
- FOUND commit: `4de6e47`
- FOUND commit: `6474957`
