# Quick Task 260923-l4t Summary: Dodanie zadania nauki dla Oskara bezpośrednio z kafelka Nadchodzący sprawdzian na Pulpicie

**Status:** Completed & Deployed
**Date:** 2026-09-23

## Overview
Dodano bezpośrednio na kafelku **„Nadchodzący sprawdzian”** na Pulpicie (`DashboardScreen`, zarówno w widoku Desktop, jak i Mobile) interaktywny przycisk akcji **`+ Zadanie dla Oskara: Naucz się`** (`Icons.add_task_rounded`), umieszczony obok linku `Zobacz w terminarzu`.

## Key Changes
1. **Tworzenie zadania nauki 1-klikiem (`DashboardScreen._buildExamStudyTaskButton`)**:
   - Kliknięcie **`+ Zadanie dla Oskara: Naucz się`** natychmiast tworzy w Firestore zadanie (`SchoolTask`) przypisane do Oskara (`TaskAssignee.student`) z wysokim priorytetem (`TaskPriority.high`), powiązane z przedmiotem (`exam.subject`), zakresem i nauczycielem w opisie (`Zakres: ...`, nauczyciel, data sprawdzianu), z terminem wykonania (`dueDate`) ustawionym na dzień przed sprawdzianem (lub na dzisiaj, jeśli sprawdzian jest dzisiaj/jutro), oraz źródłem `TaskSource.exam` i deterministycznym identyfikatorem `sourceId = 'exam_${exam.subject}_${yyyy-MM-dd}'`.
   - Po utworzeniu zadania wyświetlany jest pływający `SnackBar` z potwierdzeniem oraz przyciskiem **`[ Edytuj ]`**, który otwiera `TaskFormModal` z właśnie utworzonym zadaniem na wypadek chęci zmiany terminu lub dopisania notatki.
2. **Reaktywny status zadania na kafelku sprawdzianu**:
   - Kafelek nasłuchuje `tasksStreamProvider` pod kątem zadania o `sourceId` odpowiadającym danemu sprawdzianowi.
   - Gdy zadanie zostało już dodane, przycisk dynamicznie zmienia się w plakietkę **`✓ Zadanie dla Oskara dodane`** (lub **`✓ Oskar wykonał zadanie!`** po odhaczeniu przez Oskara), a kliknięcie w nią otwiera podgląd/edycję tego zadania w `TaskFormModal`.
3. **Wsparcie pre-fill w `TaskFormModal`**:
   - Rozszerzono `TaskFormModal.show(...)` o opcjonalne parametry inicjalizujące (`initialTitle`, `initialDescription`, `initialSubject`, `initialAssignedTo`, `initialPriority`, `initialDueDate`, `initialSource`, `initialSourceId`, `initialMetadata`) i przekazano je do `TasksRepository.addTask`.
4. **Widok mobilny (`_buildMobileDashboard`)**:
   - Wyodrębniono `_buildUpcomingExamCard(context, exam)` i dodano go również do mobilnego widoku Pulpitu (`_buildMobileDashboard`), dzięki czemu rodzic może dodać zadanie nauki także z telefonu.

## Files Modified
- `lib/presentation/screens/dashboard/dashboard_screen.dart`
- `lib/presentation/screens/tasks/widgets/task_form_modal.dart`
