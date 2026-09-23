---
phase: 15-modu-zada-smart-to-do-i-wid-et-na-pulpicie
verified: "2026-09-23T14:44:00+02:00"
status: passed
score: 13/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
covered_files:
  - .planning/phases/15-modu-zada-smart-to-do-i-wid-et-na-pulpicie/15-01-PLAN.md
  - .planning/phases/15-modu-zada-smart-to-do-i-wid-et-na-pulpicie/15-01-SUMMARY.md
  - .planning/phases/15-modu-zada-smart-to-do-i-wid-et-na-pulpicie/15-02-PLAN.md
  - .planning/phases/15-modu-zada-smart-to-do-i-wid-et-na-pulpicie/15-02-SUMMARY.md
  - .planning/phases/15-modu-zada-smart-to-do-i-wid-et-na-pulpicie/15-03-PLAN.md
  - .planning/phases/15-modu-zada-smart-to-do-i-wid-et-na-pulpicie/15-03-SUMMARY.md
  - lib/domain/models/school_task.dart
  - lib/presentation/providers/tasks_provider.dart
  - firestore.rules
  - test/domain/models/school_task_test.dart
  - lib/presentation/screens/tasks/widgets/task_form_modal.dart
  - lib/presentation/screens/tasks/tasks_screen.dart
  - lib/presentation/routes/app_router.dart
  - lib/presentation/screens/main_navigation_screen.dart
  - lib/presentation/widgets/app_sidebar.dart
  - lib/presentation/widgets/app_header.dart
  - lib/presentation/screens/dashboard/dashboard_screen.dart
---

# Phase 15: Moduł zadań (Smart To-Do) i widżet na Pulpicie — Verification Report

**Phase Goal:** Wdrożenie pełnoprawnego modułu zarządzania zadaniami ucznia i rodzica z dedykowaną podstroną `/zadania` w menu nawigacyjnym oraz interaktywnym widżetem szybkiej listy zadań w Bento Grid na Pulpicie (desktop oraz mobile).  
**Verified:** 2026-09-23T14:44:00+02:00  
**Status:** passed  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Zadania są przechowywane i synchronizowane w czasie rzeczywistym w kolekcji rodzinnej `family_tasks/{familyId}/tasks` przez Riverpod `StreamProvider` z pełnym śladem atrybucji (`createdByRole`, `createdByName`, `createdAt`, `completedByRole`, `completedByName`, `completedAt`) oraz przypisaniem odbiorcy (`student`, `parent`, `shared`) (per D-01) | ✓ VERIFIED | `lib/domain/models/school_task.dart:71-157` (`SchoolTask`, `TaskAssignee`, `attributionLabel`) oraz `lib/presentation/providers/tasks_provider.dart:116-178, 329-333` (`TasksRepository.watchTasks`, `tasksStreamProvider`) |
| 2 | Każde zadanie obsługuje 3 poziomy priorytetu (`high`, `medium`, `low`), opcjonalny tag przedmiotu/kategorii oraz pola `source` (`manual \| exam \| message`), `sourceId` i `metadata` przygotowane pod Fazę 16 (per D-02) | ✓ VERIFIED | `lib/domain/models/school_task.dart:4-67, 77-89, 256-321` (`TaskPriority`, `TaskSource`, `sourceId`, `metadata` serialization) |
| 3 | Zadanie utworzone przez Rodzica (`createdByRole == 'parent'`) ma zablokowaną możliwość usunięcia na koncie ucznia (`canBeDeletedBy(isStudent: true)` zwraca `false` oraz `TasksRepository.deleteTask` odrzuca usunięcie), przy zachowaniu możliwości odhaczenia i edycji notatki (per D-03) | ✓ VERIFIED | `lib/domain/models/school_task.dart:161-166`, `lib/presentation/providers/tasks_provider.dart:293-300`, `firestore.rules:51-54` |
| 4 | Gdy kolekcja `family_tasks/{familyId}/tasks` w Firestore jest pusta lub niezainicjalizowana w testach widżetowych, `TasksRepository` zwraca zestaw zadań startowych (`_fallbackTasks`) prezentujących współpracę Rodzic ↔ Oskar bez rzucania wyjątku `[core/no-app]` | ✓ VERIFIED | `lib/presentation/providers/tasks_provider.dart:20-27, 29-102, 123-125` (lazy `try/catch` `_db` getter + 4 realistyczne zadania startowe) |
| 5 | Opcjonalne pola metadanych (`description`, `dueDate`, `subject`, `completedByName`) są bezpiecznie obsługiwane przy serializacji, a zadania bez `dueDate` trafiają do sekcji `Bez terminu` | ✓ VERIFIED | `lib/domain/models/school_task.dart:147, 245-299` oraz `test/domain/models/school_task_test.dart:73-88` |
| 6 | Widok `/zadania` (`TasksScreen`) odwzorowuje wzorzec wizualny `MessagesScreen`: górny Segmented Control Bar z 4 zakładkami (`Wszystkie`, `Dzisiaj`, `Nadchodzące`, `Ukończone`) i licznikami badge, 44px pasek Quick Add + przycisk `+ Nowe zadanie` oraz rząd chipów przypisania roli (`Wszystkie`, `Dla Oskara`, `Dla Rodzica`, `Wspólne`) (per D-04) | ✓ VERIFIED | `lib/presentation/screens/tasks/tasks_screen.dart:223-415` |
| 7 | Wewnątrz zakładek aktywnych zadania są pogrupowane w niepuste sekcje chronologiczne: `Zaległe` (kolor `AppColors.error`), `Dzisiaj`, `Jutro / Nadchodzące` oraz `Bez terminu`, a w zakładce `Ukończone` posortowane malejąco wg daty ukończenia (per D-05) | ✓ VERIFIED | `lib/presentation/screens/tasks/tasks_screen.dart:192-194, 420-520` |
| 8 | Karty zadań prezentują interaktywny checkbox z natychmiastowym przekreśleniem tekstu i zapisem atrybucji (`'Dodał: Tata • Ukończył: Oskar'`), pigułki priorytetu, przedmiotu, terminu i roli oraz otwierają `TaskFormModal` po kliknięciu; dla zadań zleconych przez Rodzica na koncie ucznia przycisk usuwania jest zastąpiony odznaką kłódki `Icons.lock_person_outlined` (per D-01..D-06) | ✓ VERIFIED | `lib/presentation/screens/tasks/tasks_screen.dart:680-950` oraz `lib/presentation/screens/tasks/widgets/task_form_modal.dart:255-344, 649-667` |
| 9 | Trasa `/zadania` działa jako Branch 5 w `StatefulShellRoute.indexedStack`, a `/czat` jako Branch 6; na desktopie `AppSidebar` wyświetla wszystkie 7 pozycji, natomiast na mobile dolny `NavigationBar` wyświetla 6 zakładek edukacyjnych (`0..5`: `Pulpit..Zadania`) z bezpiecznym klamrowaniem `selectedIndex`, a `Czat Rodzinny` jest dostępny z ikony z badge'em w górnym `AppHeader` (per D-09) | ✓ VERIFIED | `lib/presentation/routes/app_router.dart:213-231`, `lib/presentation/screens/main_navigation_screen.dart:191-256`, `lib/presentation/widgets/app_sidebar.dart:203-220`, `lib/presentation/widgets/app_header.dart:163-176` |
| 10 | W 3-kolumnowym układzie Bento Grid na desktopie (`_buildDesktopMessagesColumn` — Kolumna 2, środkowa `flex: 5`) karta `'Zadania na dziś'` wyświetla się na samej górze Kolumny 2, bezpośrednio nad kartą `'Wiadomości i Komunikaty'` z odstępem `SizedBox(height: 20)` (per D-07) | ✓ VERIFIED | `lib/presentation/screens/dashboard/dashboard_screen.dart:1457-1476` |
| 11 | Na widoku mobilnym (`_buildMobileDashboard`) widżet `'Zadania na dziś'` wyświetla się bezpośrednio pod Harmonogramem dnia (`'DZISIEJSZY PLAN ZAJĘĆ'`) i nad sekcją `'WIADOMOŚCI'` z odstępem `SizedBox(height: 16)` (per D-07) | ✓ VERIFIED | `lib/presentation/screens/dashboard/dashboard_screen.dart:3293-3296` |
| 12 | Widżet `'Zadania na dziś'` prezentuje do 5 najpilniejszych aktywnych zadań z `urgentTasksProvider` (Zaległe -> Dzisiaj -> Priorytet/Rola), umożliwia natychmiastowe odhaczenie zadania jednym kliknięciem bez opuszczania Pulpitu, posiada przycisk `+` otwierający `TaskFormModal` oraz link `'Zobacz wszystkie (X) →'` prowadzący do `/zadania` (per D-08) | ✓ VERIFIED | `lib/presentation/screens/dashboard/dashboard_screen.dart:984-1454` (`_buildMobileTasksCard`, `_buildDesktopTasksCard`, `_buildUrgentTaskRow`) |
| 13 | Istniejący kafelek skrótu `'Zadania domowe'` w Kolumnie 3 (`_buildDesktopMetricsColumn`) zachowuje swoją etykietę dla zgodności z `test/dashboard_screen_test.dart:33` i przekierowuje po kliknięciu do `/zadania` | ✓ VERIFIED | `lib/presentation/screens/dashboard/dashboard_screen.dart:2489-2498` |

**Score:** 13/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/domain/models/school_task.dart` | Model `SchoolTask`, enumy `TaskPriority`, `TaskAssignee`, `TaskSource`, metody chronologiczne, `attributionLabel`, `canBeDeletedBy`, `sortUrgentForDashboard` | ✓ VERIFIED | 384 lines; full domain model and sorting logic implemented |
| `lib/presentation/providers/tasks_provider.dart` | `TasksRepository` (`watchTasks`, `addTask`, `updateTask`, `toggleTaskCompletion`, `deleteTask`) + Riverpod providers | ✓ VERIFIED | 353 lines; test-safe Firestore wrapper and 5 Riverpod providers |
| `firestore.rules` | Reguły bezpieczeństwa dla `/family_tasks/{familyId}/tasks/{taskId}` | ✓ VERIFIED | Lines 46–55; enforces auth and blocks student deletion of parent tasks |
| `test/domain/models/school_task_test.dart` | Testy jednostkowe modelu `SchoolTask`, klasyfikacji chronologicznej, sortowania i reguły D-03 | ✓ VERIFIED | 313 lines; covers JSON/Timestamp round-trip, chronological buckets, D-03 permissions, and repository fallback |
| `lib/presentation/screens/tasks/widgets/task_form_modal.dart` | Modal tworzenia, podglądu i edycji zadania z blokadą usuwania D-03 | ✓ VERIFIED | 781 lines; supports create/edit, role/priority/date/subject selection, and D-03 lock banner |
| `lib/presentation/screens/tasks/tasks_screen.dart` | Ekran `/zadania` w stylu `MessagesScreen` z Segmented Control Bar, Quick Add, chipami ról i sekcjami chronologicznymi | ✓ VERIFIED | 1061 lines; full implementation of `/zadania` screen |
| `lib/presentation/routes/app_router.dart` | Rejestracja Branch 5 (`/zadania`) oraz Branch 6 (`/czat`) w `StatefulShellRoute.indexedStack` | ✓ VERIFIED | Lines 213–231; 7-branch shell routing |
| `lib/presentation/screens/main_navigation_screen.dart` | Obsługa 7 branchy, 6-zakładkowy mobilny `NavigationBar` z klamrowaniem `selectedIndex < 6 ? activeIndex : 0` | ✓ VERIFIED | Lines 29–47, 68, 190–256 |
| `lib/presentation/widgets/app_sidebar.dart` | Pozycja `'Zadania'` (index 5, `tasksBadgeCount`) oraz `'Czat Rodzinny'` (index 6, `chatUnreadCount`) | ✓ VERIFIED | Lines 12, 203–220 |
| `lib/presentation/widgets/app_header.dart` | Ikona `'Czat Rodzinny'` z `Badge` (`chatUnreadCount`) w mobilnym `AppHeader` nawigująca do `/czat` | ✓ VERIFIED | Lines 32, 163–176 |
| `lib/presentation/screens/dashboard/dashboard_screen.dart` | Karta Bento Grid `'Zadania na dziś'` (`_buildDesktopTasksCard` i `_buildMobileTasksCard`) na górze Kolumny 2 oraz pod Harmonogramem dnia na mobile | ✓ VERIFIED | Lines 984–1476, 2489–2498, 3293–3296 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/presentation/providers/tasks_provider.dart` | `lib/domain/models/school_task.dart` | `SchoolTask.fromJson` & `SchoolTask.sortUrgentForDashboard` | ✓ WIRED | Lines 151, 339 |
| `lib/presentation/providers/tasks_provider.dart` | `lib/presentation/providers/auth_providers.dart` | `ref.watch(appUserProvider)` | ✓ WIRED | Lines 330, 338 |
| `lib/presentation/routes/app_router.dart` | `lib/presentation/screens/tasks/tasks_screen.dart` | `GoRoute(path: '/zadania')` in Branch 5 | ✓ WIRED | Lines 16, 216–219 |
| `lib/presentation/screens/main_navigation_screen.dart` | `lib/presentation/widgets/app_sidebar.dart` | `activeTasksBadgeCountProvider` -> `tasksBadgeCount` | ✓ WIRED | Lines 68, 140, 240–254 |
| `lib/presentation/widgets/app_header.dart` | `lib/presentation/providers/family_chat_provider.dart` | `familyChatUnreadCountProvider` & `context.go('/czat')` | ✓ WIRED | Lines 32, 165–168 |
| `lib/presentation/screens/dashboard/dashboard_screen.dart` | `lib/presentation/providers/tasks_provider.dart` | `urgentTasksProvider`, `totalActiveTasksCountProvider`, `toggleTaskCompletion` | ✓ WIRED | Lines 985–986, 1142–1143, 1351 |
| `lib/presentation/screens/dashboard/dashboard_screen.dart` | `lib/presentation/screens/tasks/widgets/task_form_modal.dart` | `TaskFormModal.show(context)` | ✓ WIRED | Lines 1078, 1236, 1327 |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Static analysis across entire workspace | `flutter analyze` | `No issues found! (ran in 1.9s)` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| `REQ-TASK-01` | `15-01`, `15-02` | Dedykowana podstrona `/zadania` w menu bocznym i nawigacji z wykazem zadań, terminami i filtrami | ✓ SATISFIED | `TasksScreen`, `TaskFormModal`, `AppSidebar`, `MainNavigationScreen`, `app_router.dart` |
| `REQ-TASK-02` | `15-01`, `15-03` | Karta Bento Grid na Pulpicie (desktop oraz mobile) prezentująca najpilniejsze zadania z natychmiastowym odhaczaniem | ✓ SATISFIED | `_buildDesktopTasksCard`, `_buildMobileTasksCard`, `urgentTasksProvider` w `DashboardScreen` |

### Anti-Patterns Found

None (`0` errors, `0` warnings, `0` TODO/FIXME/placeholder stubs in Phase 15 files).
