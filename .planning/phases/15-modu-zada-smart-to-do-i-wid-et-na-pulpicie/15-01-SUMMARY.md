---
phase: 15-modu-zada-smart-to-do-i-wid-et-na-pulpicie
plan: 01
subsystem: domain-and-data
tags:
  - smart-todo
  - firestore
  - riverpod
  - domain-model
  - security-rules
requires:
  - lib/presentation/providers/auth_providers.dart
  - lib/domain/models/user_role.dart
provides:
  - SchoolTask domain model with TaskPriority, TaskAssignee, and TaskSource enums
  - Chronological task helpers (isOverdue, isDueToday, isUpcoming, hasNoDueDate) and sortUrgentForDashboard
  - Role-based deletion guard (canBeDeletedBy & TasksRepository.deleteTask) protecting Parent-created tasks (D-03)
  - Real-time TasksRepository and Riverpod providers (tasksStreamProvider, urgentTasksProvider, activeTasksBadgeCountProvider, totalActiveTasksCountProvider)
  - Firestore security rules for /family_tasks/{familyId}/tasks/{taskId}
affects:
  - lib/domain/models/school_task.dart
  - lib/presentation/providers/tasks_provider.dart
  - firestore.rules
  - test/domain/models/school_task_test.dart
tech-stack:
  added: []
  patterns:
    - Lazy widget-test-safe FirebaseFirestore getter in TasksRepository
    - Optimistic local StreamController broadcast combined with Firestore snapshots
    - Normalized calendar date comparison against todayStart (00:00:00)
key-files:
  created:
    - lib/domain/models/school_task.dart
    - lib/presentation/providers/tasks_provider.dart
    - test/domain/models/school_task_test.dart
  modified:
    - firestore.rules
key-decisions:
  - "Normalized calendar dates (`DateTime(year, month, day)`) against `todayStart` (`00:00:00` local time) so tasks due today are never falsely classified as overdue (`isOverdue`)."
  - "Enforced D-03 parent-assigned task deletion protection at three layers: `SchoolTask.canBeDeletedBy(isStudent: true)`, `TasksRepository.deleteTask`, and `firestore.rules`."
  - "Used a lazy `try/catch` `_db` getter and broadcast `_localController` in `TasksRepository` so widget tests (`dashboard_screen_test.dart`, `navigation_shell_test.dart`) work without `Firebase.initializeApp()` while supporting reactive optimistic mutations."
requirements-completed:
  - REQ-TASK-01
  - REQ-TASK-02
duration: "6 min"
completed: "2026-09-23"
status: complete
one_liner: "SchoolTask domain model with chronological classification, D-03 parent-task deletion lock, Firestore rules for family_tasks, and real-time Riverpod TasksRepository with test-safe starter seed tasks"
commits: 2
plan_head_before: 3a26543f22ea86428a872aded37e203926267d83
actuals:
  tokens: 9485
  tasks: 2
  commits: 2
---

# Phase 15 Plan 01: Domain Model (`SchoolTask`), Firestore Security Rules & Real-Time `TasksRepository` Summary

**One-liner:** `SchoolTask` domain model with chronological classification, `D-03` parent-task deletion lock, Firestore rules for `family_tasks`, and real-time Riverpod `TasksRepository` with test-safe starter seed tasks.

## Accomplishments

- **Domain Model (`lib/domain/models/school_task.dart`):**
  - Implemented `SchoolTask` along with `TaskPriority` (`high`, `medium`, `low`), `TaskAssignee` (`student`, `parent`, `shared`), and `TaskSource` (`manual`, `exam`, `message` ready for Phase 16 per `D-02`).
  - Added calendar-normalized chronological getters (`isOverdue`, `isDueToday`, `isUpcoming`, `hasNoDueDate`), attribution formatting (`attributionLabel` returning `'Dodał: X • Ukończył: Y'` or `'Dodał: X'` per `D-01`), and `SchoolTask.sortUrgentForDashboard` selecting up to 5 urgent tasks ordered by Overdue → Due Today → Role relevance → Priority (`D-08`).
  - Implemented `canBeDeletedBy({required bool isStudent})` blocking student deletion of parent-created tasks (`D-03`).
- **Firestore Security Rules (`firestore.rules`):**
  - Added Section 7 for `/family_tasks/{familyId}` and `/tasks/{taskId}` requiring authentication (`request.auth != null`) and preventing deletion of parent-created tasks when token role is `student`.
- **Real-Time Repository & Riverpod Providers (`lib/presentation/providers/tasks_provider.dart`):**
  - Implemented `TasksRepository` with a lazy `try/catch` `_db` getter and 4 starter seed tasks demonstrating Parent ↔ Oskar collaboration (`Biologia`, `Matematyka`, `Opłata/Formalności`, and a completed shared `Szkoła` task).
  - Provided `tasksRepositoryProvider`, `tasksStreamProvider`, `urgentTasksProvider`, `activeTasksBadgeCountProvider`, and `totalActiveTasksCountProvider`.
- **Unit Test Suite (`test/domain/models/school_task_test.dart`):**
  - Added unit tests covering JSON/`Timestamp` serialization, chronological classification, `D-03` deletion permissions, `sortUrgentForDashboard` ordering, and `TasksRepository` fallback mutations.

## Task Commits

| Task | Description | Commit |
|------|-------------|--------|
| 1 | End-to-end `SchoolTask` domain contract, `firestore.rules`, and unit test suite (`D-01`, `D-02`, `D-03`) | `8d97386` |
| 2 | Real-time `TasksRepository` and Riverpod providers with test-safe fallback (`D-01`, `D-03`, `D-08`) | `a54b723` |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected Dart package import name in `school_task_test.dart`**
- **Found during:** Task 1 verification
- **Issue:** Initial test import used `package:dziennik_szkolny/...` whereas `pubspec.yaml` declares `name: edusync`.
- **Fix:** Updated import in `test/domain/models/school_task_test.dart` to `package:edusync/domain/models/school_task.dart`.
- **Files modified:** `test/domain/models/school_task_test.dart`
- **Commit:** `8d97386`

## Verification Results

- `flutter analyze lib/domain/models/school_task.dart lib/presentation/providers/tasks_provider.dart test/domain/models/school_task_test.dart` → `No issues found! (ran in 1.1s)`

## Self-Check: PASSED

- FOUND: `lib/domain/models/school_task.dart`
- FOUND: `lib/presentation/providers/tasks_provider.dart`
- FOUND: `firestore.rules`
- FOUND: `test/domain/models/school_task_test.dart`
- FOUND commit: `8d97386`
- FOUND commit: `a54b723`
