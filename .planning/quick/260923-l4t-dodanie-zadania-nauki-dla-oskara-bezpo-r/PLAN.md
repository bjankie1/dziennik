---
phase: quick-260923-l4t
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/presentation/screens/tasks/widgets/task_form_modal.dart
  - lib/presentation/screens/dashboard/dashboard_screen.dart
autonomous: true
must_haves:
  truths:
    - "Na kafelku 'Nadchodzący sprawdzian' na Pulpicie (desktop oraz mobile) obok linku 'Zobacz w terminarzu' widoczny jest przycisk '+ Zadanie dla Oskara: Naucz się'"
    - "Kliknięcie przycisku natychmiast tworzy zadanie dla Oskara (TaskAssignee.student, TaskPriority.high, termin dzień przed sprawdzianem, source: TaskSource.exam, zakres i nauczyciel w opisie) w kolekcji family_tasks/{familyId}/tasks, wyświetla SnackBar z akcją 'Edytuj' i od razu pokazuje zadanie w widżecie 'Zadania na dziś'"
    - "Gdy zadanie dla danego sprawdzianu już istnieje, kafelek sprawdzianu wyświetla status 'Zadanie dla Oskara dodane' (lub 'Ukończone przez Oskara ✓'), a kliknięcie otwiera TaskFormModal do podglądu/edycji"
---

<objective>
Umożliwienie rodzicowi (i uczniowi) błyskawicznego dodania zadania przygotowania/nauki dla Oskara bezpośrednio z kafelka „Nadchodzący sprawdzian” na Pulpicie (`DashboardScreen` — desktop i mobile), z automatycznym wypełnieniem przedmiotu, zakresu, nauczyciela, wysokiego priorytetu i terminu na dzień przed sprawdzianem oraz podglądem statusu wykonania.
</objective>

<tasks>
<task type="auto">
  <name>Task 1: Extend TaskFormModal with pre-fill parameters & add 1-click Exam-to-Task action on DashboardScreen</name>
  <files>
    lib/presentation/screens/tasks/widgets/task_form_modal.dart
    lib/presentation/screens/dashboard/dashboard_screen.dart
  </files>
  <action>
    1. In `lib/presentation/screens/tasks/widgets/task_form_modal.dart`:
       - Add optional pre-fill fields (`initialTitle`, `initialDescription`, `initialSubject`, `initialAssignedTo`, `initialPriority`, `initialDueDate`, `initialSource`, `initialSourceId`, `initialMetadata`) to `TaskFormModal` and `TaskFormModal.show(...)`.
       - Pass `source`, `sourceId`, and `metadata` to `repo.addTask(...)` on creation.
    2. In `lib/presentation/screens/dashboard/dashboard_screen.dart`:
       - Create a helper `_buildExamStudyTaskAction(BuildContext context, UpcomingEvent exam)` that watches `tasksStreamProvider` to detect if a `SchoolTask` with `sourceId == 'exam_${exam.subject}_${DateFormat('yyyy-MM-dd').format(exam.date)}'` already exists.
       - If no task exists yet: render a prominent interactive pill button `+ Zadanie dla Oskara: Naucz się` (`Icons.add_task_rounded`) next to `Zobacz w terminarzu`. Clicking it creates the task in Firestore (`assignedTo: TaskAssignee.student`, `priority: TaskPriority.high`, `dueDate`: 1 day before exam or today if exam is today/tomorrow, `title: 'Nauczyć się: ${exam.subject} (${exam.type.toLowerCase()})'`, `description: 'Zakres: ${exam.title}${exam.room.isNotEmpty ? "\n${exam.room}" : ""}\nSprawdzian: ${DateFormat("d MMMM", "pl_PL").format(exam.date)}'`, `subject: exam.subject`, `source: TaskSource.exam`, `sourceId: examSourceId`) and shows a floating `SnackBar` with an `Edytuj` action that opens `TaskFormModal.show(context, existingTask: createdTask)`.
       - If the task already exists: render a status pill (`✓ Zadanie dla Oskara dodane` in primary/emerald tint, or `✓ Oskar już się nauczył!` if `isCompleted == true`) which opens `TaskFormModal.show(context, existingTask: existingTask)` on tap.
       - Also display the „Nadchodzący sprawdzian” card with this action button in `_buildMobileDashboard` when `exam != null`.
  </action>
  <verify>
    <automated>flutter analyze</automated>
    <fails_when>non-zero exit code or analyzer issues</fails_when>
  </verify>
  <done>Zero analyzer issues; clicking the button on „Nadchodzący sprawdzian” adds the task for Oskar and syncs immediately with the „Zadania na dziś” widget and `/zadania`.</done>
</task>
</tasks>
