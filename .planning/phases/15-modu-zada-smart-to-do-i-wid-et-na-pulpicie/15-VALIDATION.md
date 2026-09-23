---
phase: "15"
slug: "modu-zada-smart-to-do-i-wid-et-na-pulpicie"
status: draft
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-23"
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter SDK) |
| **Config file** | `pubspec.yaml` / `analysis_options.yaml` |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~5 seconds (`flutter analyze` ~2.1s) |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze`
- **After every plan wave:** Run `flutter analyze && flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | REQ-TASK-01 | T-15-01 / T-15-02 | `SchoolTask` model, `canBeDeletedBy(isStudent: true)` D-03 parent-task lock, and `firestore.rules` auth guard | unit + static | `flutter analyze && flutter test test/domain/models/school_task_test.dart` | ❌ W0 | ⬜ pending |
| 15-01-02 | 01 | 1 | REQ-TASK-01 | T-15-02 | `TasksRepository` (`family_tasks/{familyId}/tasks`) with lazy `_db` test safety, `tasksStreamProvider`, and `urgentTasksProvider` | unit + static | `flutter analyze && flutter test test/domain/models/school_task_test.dart` | ❌ W0 | ⬜ pending |
| 15-02-01 | 02 | 2 | REQ-TASK-01 | T-15-03 | `TasksScreen` (`/zadania`) with Segmented Control Bar, Quick Add bar, chronological sections, and `TaskFormModal` with D-03 lock | static | `flutter analyze` | ✅ | ⬜ pending |
| 15-02-02 | 02 | 2 | REQ-TASK-01 | — | Routing `/zadania` (Branch 5) & `/czat` (Branch 6) in `app_router.dart`, `AppSidebar` 7 items, Mobile 6-tab `NavigationBar` + `AppHeader` chat badge | widget + static | `flutter analyze && flutter test test/navigation_shell_test.dart` | ✅ | ⬜ pending |
| 15-03-01 | 03 | 3 | REQ-TASK-02 | — | Dashboard Bento Grid „Zadania na dziś” card in Desktop Column 2 (`_buildDesktopMessagesColumn`) and Mobile Dashboard (`_buildMobileDashboard`) with 1-click completion | widget + static | `flutter analyze && flutter test test/dashboard_screen_test.dart` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/domain/models/school_task_test.dart` — unit tests for `SchoolTask` serialization, chronological classification (`isOverdue`, `isDueToday`, `isUpcoming`), urgent dashboard sorting, and `D-03` parent-assigned deletion lock (`canBeDeletedBy`).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real-time cross-session sync between Parent and Oskar browser tabs | REQ-TASK-01, REQ-TASK-02 | Requires live Cloud Firestore WebSocket session across two authenticated profiles | 1. Add a task assigned to „Dla Oskara” as Parent. 2. Verify it appears immediately on `/zadania` and Dashboard Column 2. 3. Check the task off as Oskar and verify the `"Dodał: Tata • Ukończył: Oskar"` attribution updates live. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-09-23
