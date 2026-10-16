---
phase: 261016-cvn-upewnij-si-e-oceny-s-dobrze-prezentowane
plan: 01
subsystem: grades
tags: [grades, librus, averages, histogram, ui]
status: complete
requires: []
provides:
  - "MEN 1–6 grade parsing (Grade.tryParseMenValue, isMenScaleGrade, menScaleBucket) separated from unclassified Librus entries (0, +, -, np, bz)"
  - "Accurate weighted subject and overall averages in FirestoreGradesDataSource, FirestoreScheduleDataSource, librus_client.js, and gradesDistributionStatsProvider"
  - "Dynamic grade presentation across SubjectLedgerTable, GradeDistributionCard, WeightedAverageKpiCard, SubjectInspectorCard, GradeDetailsSideSheet, AverageSimulatorModal, GradesScreen, and DashboardMetricsColumn without hardcoded mock numbers"
affects:
  - grades
  - dashboard
tech-stack:
  added: []
  patterns:
    - "Single MEN 1–6 scale parser and base-digit bucketing (menScaleBucket) shared across data sources, providers, and UI"
key-files:
  created:
    - test/presentation/screens/grades/grades_presentation_test.dart
  modified:
    - lib/domain/models/grade.dart
    - lib/domain/models/subject.dart
    - lib/data/repositories/firestore/firestore_grades_data_source.dart
    - lib/data/repositories/firestore/firestore_schedule_data_source.dart
    - lib/presentation/providers/school_providers.dart
    - lib/presentation/screens/grades/widgets/subject_ledger_table.dart
    - lib/presentation/screens/grades/widgets/grade_distribution_card.dart
    - lib/presentation/screens/grades/widgets/weighted_average_kpi_card.dart
    - lib/presentation/screens/grades/widgets/subject_inspector_card.dart
    - lib/presentation/screens/grades/widgets/grade_details_side_sheet.dart
    - lib/presentation/screens/grades/grades_screen.dart
    - lib/presentation/screens/grades/average_simulator_modal.dart
    - lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart
    - functions/src/librus_client.js
    - test/data/repositories/firestore_cache_and_attendance_test.dart
decisions:
  - "Treat any Librus entry outside MEN 1–6 (0, +, -, np, bz) or lacking Licz do średniej: tak in a full Librus tooltip as uncounted (isCountedToAverage=false, numericValue=0.0, weight=0)"
  - "Bucket MEN 1–6 grades in GradeDistributionCard by their base digit (3+ -> 3, 4- -> 4) rather than .round() or .clamp(1, 6), and surface unclassified entries via otherGradesCount"
  - "Display '—' instead of fabricated 4.80/5.00/3 values for subjects with no counted grades, and bind SubjectLedgerTable footer directly to gradesDistributionStatsProvider.overallAverage"
metrics:
  duration: 15m
  completed_date: "2026-10-16"
  tasks: 3
  files: 16
  commits: 3
plan_head_before: 888c9975bf131c6402699162e3c39f9f5ac90ca2
plan_head_after: b0a0ee2e758d9eb2e7935f4e7c73b1f8cdd24599
actuals:
  tokens: 22919
  tasks: 3
  commits: 3
---

# Quick Task 261016-cvn: Upewnij się że oceny są dobrze prezentowane Summary

**Normalized MEN 1–6 grades vs. informational Librus entries (`0`, `+`, `-`, `np`, `bz`), unified weighted average and 1–6 histogram calculations, and eliminated all hardcoded mock averages (`4.82`, `4.80`, `5.00`, `3`, `+0.06 pkt`) across the Grades module and Dashboard.**

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | End-to-end normalizacja ocen MEN 1–6 i wpisów nieklasyfikowanych (`0`, `+`, `-`, `np`, `bz`) | `54356a2` | `lib/domain/models/grade.dart`, `lib/domain/models/subject.dart`, `lib/data/repositories/firestore/firestore_grades_data_source.dart`, `lib/data/repositories/firestore/firestore_schedule_data_source.dart`, `lib/presentation/providers/school_providers.dart`, `functions/src/librus_client.js` |
| 2 | Poprawa prezentacji ocen w UI (tabela przedmiotów, rozkład 1–6, karty KPI, inspektor, szuflada szczegółów, symulator i pulpit) | `7377339` | `lib/presentation/screens/grades/widgets/subject_ledger_table.dart`, `lib/presentation/screens/grades/widgets/grade_distribution_card.dart`, `lib/presentation/screens/grades/widgets/weighted_average_kpi_card.dart`, `lib/presentation/screens/grades/widgets/subject_inspector_card.dart`, `lib/presentation/screens/grades/widgets/grade_details_side_sheet.dart`, `lib/presentation/screens/grades/grades_screen.dart`, `lib/presentation/screens/grades/average_simulator_modal.dart`, `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart` |
| 3 | Testy jednostkowe i widgetowe dla rzeczywistego zestawu ocen ucznia (`0`, `+`, `3+`, `4-`, puste przedmioty) | `b0a0ee2` | `test/data/repositories/firestore_cache_and_attendance_test.dart`, `test/presentation/screens/grades/grades_presentation_test.dart` |

## Key Changes Made

1. **MEN 1–6 Scale Parsing & Bucketing (`Grade`, `Subject`, `librus_client.js`):**
   - Added `Grade.tryParseMenValue(String raw)` supporting `1..6` with `+` (`+0.5`) and `-` (`-0.25`) modifiers while rejecting `0`, `+`, `-`, `np`, `bz`, `nb`.
   - Added `isMenScaleGrade` (`numericValue >= 1.0 && numericValue <= 6.0`) and `menScaleBucket` (extracting the base digit `1..6` so `3+` buckets into `3` and `4-` into `4`).
   - Updated `Subject.calculateWeightedAverage` and `Subject.predictedGradeForTerm` to filter strictly by `g.isCountedToAverage && g.isMenScaleGrade && g.weight > 0` and return `null` when no counted grades exist.

2. **Firestore Data Sources & Distribution Provider (`FirestoreGradesDataSource`, `FirestoreScheduleDataSource`, `gradesDistributionStatsProvider`):**
   - Removed the `5.0` fallback for non-numeric grades in `FirestoreGradesDataSource` and `functions/src/librus_client.js`.
   - Parsed `Licz do średniej: tak/nie` and `Waga:` from `rawTooltip`; entries outside `1..6` or lacking `Licz do średniej: tak` in full Librus tooltips receive `isCountedToAverage: false`, `numericValue: 0.0`, `weight: 0`.
   - Added `otherGradesCount` to `GradesDistributionStats` and ensured `counts[1..6]` only counts `g.menScaleBucket != null` (preventing `0` from clamping into bucket `1` and `+` from falling into bucket `5`).

3. **UI Presentation & Removal of Hardcoded Mocks:**
   - Bound `SubjectLedgerTable` footer to `gradesDistributionStatsProvider.overallAverage` (removing hardcoded `'4.82'`).
   - Replaced fallback `'4.80'`, `'5.00'`, and predicted `'3'` with `'—'` for subjects without counted grades.
   - Styled non-MEN entries (`0`, `+`, `-`, `np`, `bz`) distinctly without fake `w:1` badges, sorted grade pills chronologically, and fixed `OSTATNI WPIS` to display the newest entry date.
   - Replaced hardcoded `+0.06 pkt` (`4.86 -> 4.92`) in `GradeDetailsSideSheet` with real before/after subject average impact calculations.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed dry baseline layout assertion and uninitialized locale fallback in Grades widgets**
- **Found during:** Task 3 (`GradesScreen` widget test)
- **Issue:** `WeightedAverageKpiCard` used `CrossAxisAlignment.baseline` on a `Row` containing an `Icon` (`RenderPositionedBox`) inside `IntrinsicHeight` (`AcademicKpiRow`), triggering Flutter's `RenderPositionedBox does not implement computeDryBaseline` assertion. Additionally, `SubjectLedgerTable` called `DateFormat('d MMM yyyy', 'pl')` without a fallback when `intl` locale data was not initialized.
- **Fix:** Changed `CrossAxisAlignment.baseline` to `CrossAxisAlignment.center` in `WeightedAverageKpiCard`, added a `dd.MM.yyyy` fallback around `DateFormat` in `SubjectLedgerTable`, clamped histogram bar height to `34px` inside the `80px` container in `GradeDistributionCard`, and wrapped the empty-state hint in `Flexible` in `SubjectInspectorCard`.
- **Files modified:** `lib/presentation/screens/grades/widgets/weighted_average_kpi_card.dart`, `lib/presentation/screens/grades/widgets/subject_ledger_table.dart`, `lib/presentation/screens/grades/widgets/grade_distribution_card.dart`, `lib/presentation/screens/grades/widgets/subject_inspector_card.dart`
- **Commit:** `b0a0ee2`

## Self-Check: PASSED

- Verified created/modified files exist on disk (`test/presentation/screens/grades/grades_presentation_test.dart`, `lib/domain/models/grade.dart`, `lib/presentation/screens/grades/widgets/subject_ledger_table.dart`).
- Verified commits `54356a2`, `7377339`, and `b0a0ee2` exist in git history.
- Verified `flutter test test/data/repositories/firestore_cache_and_attendance_test.dart test/presentation/screens/grades/grades_presentation_test.dart` passed (12/12 tests) and `flutter analyze` reported 0 issues.
