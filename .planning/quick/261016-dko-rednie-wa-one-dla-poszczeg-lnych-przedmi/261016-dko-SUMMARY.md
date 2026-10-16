---
phase: 261016-dko
plan: 01
subsystem: grades
tags: [grades, weighted-average, librus, firestore, flutter-ui, simulator, ai-context]
requires: []
provides:
  - "Deterministic MEN weighted average normalization and Firestore self-healing (normalizeStudentGradesData)"
  - "Accurate weighted averages per subject and term across desktop ledger, inspector card, mobile cards, and GPA simulator"
  - "Explicit non-counted grade metadata presentation in grade pills, details modals/sheets, dashboard, and AI assistant context"
affects: [grades, dashboard, ai-assistant, cloud-functions]
tech-stack:
  added: []
  patterns:
    - "Shared backend normalization (normalizeStudentGradesData) applied on scrape, sync, and cached Firestore reads with merge write-back"
    - "Strict MEN grade scale (1..6) andLiczenie do średniej (isCountedToAverage && weight > 0 && numericalValue >= 1.0) enforcement in both backend and Flutter data source"
key-files:
  created:
    - functions/test/grades_normalization.test.js
    - test/presentation/screens/grades/grades_presentation_test.dart
  modified:
    - functions/src/librus_client.js
    - functions/src/sync_service.js
    - functions/index.js
    - lib/data/repositories/firestore/firestore_grades_data_source.dart
    - lib/presentation/screens/grades/grades_screen.dart
    - lib/presentation/screens/grades/average_simulator_modal.dart
    - lib/presentation/screens/grades/grade_details_modal.dart
    - lib/presentation/screens/grades/widgets/subject_ledger_table.dart
    - lib/presentation/screens/grades/widgets/subject_inspector_card.dart
    - lib/presentation/screens/grades/widgets/grade_details_side_sheet.dart
    - lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart
    - lib/presentation/widgets/common/grade_badge_pill.dart
    - lib/core/services/school_ai_context_builder.dart
    - test/data/repositories/firestore_cache_and_attendance_test.dart
decisions:
  - "Auto-heal existing Firestore student documents in getStudentData and syncStudentData using normalizeStudentGradesData so stale weights on '0'/'+'/'-'/'np'/'bz' are corrected without waiting for a manual Librus re-scrape"
  - "Never fall back to stale server currentAverage in FirestoreGradesDataSource when a subject has zero counted numeric grades"
  - "Expand AverageSimulatorModal weight selector to full Librus scale 1..6 and accept initialSubjectId + term from caller"
metrics:
  duration: "14m"
  completed: "2026-10-16"
status: complete
commits: 2
plan_head_before: a7bbd27acc53b081990d345c61e6a680ccff06ba
plan_head_after: 9e2b22ce77a7885b42d58b1be4680c4c256fd696
actuals:
  tokens: 20991
  tasks: 3
  commits: 2
---

# Quick Task 261016-dko Plan 01: Średnie ważone dla poszczególnych przedmiotów Summary

End-to-end MEN weighted average normalization, Firestore cache self-healing, and full UI/simulator/AI presentation of per-subject grades and non-counted markers (`0`, `+`, `-`, `np`, `bz`, `nb`, `zw`, `nk`).

## What Was Built

### Task 1: Backend Normalization & Firestore Self-Healing (`6e97700`)
- **`functions/src/librus_client.js`**: Extracted and exported `parseMenGradeValue(valText)` and `normalizeStudentGradesData(studentData)`. Re-parses `rawTooltip` (`Kategoria`, `Data`, `Nauczyciel`, `Licz do średniej`, `Waga`, `Dodał`, `Komentarz`), enforces `isCountedToAverage = false`, `numericalValue = 0`, `weight = 0` for non-MEN markers (`0`, `+`, `-`, `np`, `bz`, `nb`, `zw`, `nk`), and computes rounded 2-decimal `currentAverage` per subject and `overallAverage` across subjects with `currentAverage > 0`.
- **`functions/index.js` & `functions/src/sync_service.js`**: Wired `normalizeStudentGradesData` into `exports.getStudentData` (with automatic `{ merge: true }` write-back when `changed === true`) and `syncStudentData` so cached Firestore documents are healed immediately on read and during background sync.
- **`lib/data/repositories/firestore/firestore_grades_data_source.dart`**: Removed the fallback to stale `sMap['currentAverage']` when a subject has no counted numeric grades (`average` is strictly `0.0` when `totalWeight == 0`).

### Task 2: Flutter UI, GPA Simulator & AI Context Polish (`9e2b22c`)
- **`SubjectLedgerTable`, `SubjectInspectorCard`, `GradesScreen`**: Filtered grades by selected term (`term == 0 || g.term == term`), sorted chronologically (`a.date.compareTo(b.date)`), displayed `'Brak ocen'` when a subject has no grades in the selected term, and wired `initialSubjectId` and `term` into `AverageSimulatorModal`.
- **`AverageSimulatorModal`**: Added `initialSubjectId` and `term` parameters, filtered base grades to `g.isCountedToAverage && g.value >= 1.0 && g.weight > 0` for the active term, and expanded weight chips to full Librus scale `[1, 2, 3, 4, 5, 6]` inside a responsive `Wrap`.
- **`GradeBadgePill`, `GradeDetailsModal`, `GradeDetailsSideSheet`, `DashboardMobileView`, `SchoolAiContextBuilder`**: Replaced misleading `(waga 0)`/`Waga: 1` labels on non-counted markers with explicit `'nieliczona do średniej'` / `'Brak (nie wlicza się)'`, muted border styling, and accurate AI context formatting.

### Task 3: Production Build, Firebase Deployment & Live Verification
- Built production web bundle (`flutter build web --release`).
- Deployed `functions:getStudentData`, `functions:syncNow`, `functions:scheduledLibrusSync`, and `hosting` to Firebase project `lepsza-szkola`.
- Verified live `https://europe-west3-lepsza-szkola.cloudfunctions.net/getStudentData?login=11010033` response:
  - `overallAverage`: `3.02`
  - `Chemia`: `5`
  - `Język angielski`: `3.36`
  - `Język polski`: `1.8`
  - `Matematyka`: `1`
  - `Wychowanie fizyczne`: `3.83`
  - `Historia`: `0` (only `+`)
  - `Język niemiecki`: `0` (only `0`)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed horizontal RenderFlex overflows on narrow mobile viewports and wide fonts**
- **Found during:** Task 2 widget testing (`GradesScreen (desktop)` and `GradesScreen (mobile)`)
- **Issue:** In `GradesScreen` (mobile summary stats header row, subjects section header row, and expanded accordion header `'SZCZEGÓŁOWY WYKAZ OCEN'`) and `AverageSimulatorModal` (modal title header `Column` inside `Row`), unflexed `Column`/`Text` children overflowed horizontally under narrow constraints (`364px`–`600px`).
- **Fix:** Wrapped flexible text/column children in `Expanded`/`Flexible` with `TextOverflow.ellipsis`.
- **Files modified:** `lib/presentation/screens/grades/grades_screen.dart`, `lib/presentation/screens/grades/average_simulator_modal.dart`
- **Commit:** `9e2b22c`

**2. [Rule 1 - Bug] Added locale-safe fallback for `DateFormat(..., 'pl')` in grade widgets**
- **Found during:** Task 2 widget testing
- **Issue:** `SubjectInspectorCard`, `GradeDetailsModal`, and `GradeDetailsSideSheet` called `DateFormat(..., 'pl')` directly, which throws `LocaleDataException` when `initializeDateFormatting('pl')` has not been run prior to widget rendering.
- **Fix:** Wrapped `DateFormat(..., 'pl')` in `try/catch` with deterministic ISO date fallback (`yyyy-MM-dd`).
- **Files modified:** `lib/presentation/screens/grades/widgets/subject_inspector_card.dart`, `lib/presentation/screens/grades/grade_details_modal.dart`, `lib/presentation/screens/grades/widgets/grade_details_side_sheet.dart`
- **Commit:** `9e2b22c`

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: `functions/test/grades_normalization.test.js`
- FOUND: `test/presentation/screens/grades/grades_presentation_test.dart`
- FOUND commit: `6e97700`
- FOUND commit: `9e2b22c`
- Live endpoint verified: `https://europe-west3-lepsza-szkola.cloudfunctions.net/getStudentData?login=11010033`
