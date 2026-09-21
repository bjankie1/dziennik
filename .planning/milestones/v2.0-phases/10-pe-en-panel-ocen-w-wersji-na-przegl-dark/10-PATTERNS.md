# Phase 10: Pełen panel ocen w wersji na przeglądarkę — Pattern Mapping

**Phase:** 10  
**Domain:** Grades Academic Portal (Desktop Master-Detail & Mobile Responsive)  
**Status:** Complete  
**Date:** 2026-09-17  

---

## 1. File Classification & Architecture Overview

Phase 10 upgrades the Grades module (`GradesScreen`) into an academic desktop portal (>=1024px) following the *Academic Precision* design language (`docs/panel ocen/` and `docs/szczegóły oceny/`), while preserving a touch-optimized mobile experience (<1024px).

```
lib/
├── core/theme/
│   └── app_colors.dart                              [MODIFY] Theme color tokens
├── presentation/
│   ├── providers/
│   │   └── school_providers.dart                    [MODIFY] Riverpod 3.x notifiers for grades
│   └── screens/grades/
│       ├── grades_screen.dart                       [MODIFY] Responsive coordinator & layout shell
│       ├── grade_details_modal.dart                 [MODIFY] Compatibility wrapper / redirect
│       └── widgets/
│           ├── academic_kpi_row.dart                [CREATE] Top KPI container
│           ├── weighted_average_kpi_card.dart       [CREATE] KPI Card: Score, trend, rank
│           ├── grade_distribution_card.dart         [CREATE] KPI Card: MEN 1-6 bar histogram
│           ├── subject_ledger_table.dart            [CREATE] 8-col Master Ledger Table
│           ├── subject_inspector_card.dart          [CREATE] 4-col Right Detail Inspector
│           ├── average_trajectory_card.dart         [CREATE] Trajectory chart card wrapper
│           ├── trajectory_chart_painter.dart        [CREATE] CustomPainter for Bézier spline
│           └── grade_details_side_sheet.dart        [CREATE] Slide-in Drawer / Sheet details
```

---

## 2. File-by-File Pattern Analysis

### 2.1 `lib/core/theme/app_colors.dart`
- **Role:** Design System Tokens.
- **Data Flow:** Static constants accessed directly by presentation widgets.
- **Closest Analog:** Existing `AppColors` definitions in [`lib/core/theme/app_colors.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/core/theme/app_colors.dart#L1-L53).
- **Concrete Code Excerpt (Existing):**
```dart
// lib/core/theme/app_colors.dart
class AppColors {
  static const Color surface = Color(0xFFF8F9FF);
  static const Color primary = Color(0xFF3525CD);
  static const Color primaryContainer = Color(0xFF4F46E5);
  static const Color primaryFixed = Color(0xFFE2DFFF);
  static const Color secondary = Color(0xFF006C4A);
  static const Color secondaryContainer = Color(0xFF82F5C1);
  static const Color tertiaryFixed = Color(0xFFFFDCC3);
  ...
}
```
- **Pattern Application for Phase 10:**
Add missing tokens specified in `docs/panel ocen/DESIGN.md`:
```dart
static const Color primaryFixedDim = Color(0xFFC3C0FF);
static const Color tertiaryFixedDim = Color(0xFFFFB77D);
```

---

### 2.2 `lib/presentation/providers/school_providers.dart`
- **Role:** State Management (Riverpod 3.x Notifiers).
- **Data Flow:** User actions (selecting a subject in the table, typing in the search box, switching terms) invoke notifier methods. Dependent widgets watch these providers and rebuild reactively.
- **Closest Analog:** `WeekScheduleFilterNotifier`, `SelectedScheduleDayNotifier`, and `CurrentNavIndexNotifier` in [`lib/presentation/providers/school_providers.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/providers/school_providers.dart#L16-L25).
- **Concrete Code Excerpt (Existing):**
```dart
// lib/presentation/providers/school_providers.dart:16-25
class CurrentNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final currentNavIndexProvider =
    NotifierProvider<CurrentNavIndexNotifier, int>(CurrentNavIndexNotifier.new);
```
- **Pattern Application for Phase 10:**
Adhere to Riverpod 3.x class-based `Notifier` without deprecated `StateProvider`:
```dart
// Selected subject in the Master-Detail view (null by default per D-03)
class SelectedGradesSubjectNotifier extends Notifier<Subject?> {
  @override
  Subject? build() => null;

  void select(Subject? subject) {
    if (state?.id == subject?.id) {
      state = null; // toggle off
    } else {
      state = subject;
    }
  }

  void clear() => state = null;
}

final selectedGradesSubjectProvider =
    NotifierProvider<SelectedGradesSubjectNotifier, Subject?>(SelectedGradesSubjectNotifier.new);

// Search query for filtering subjects & teachers
class GradesSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final gradesSearchQueryProvider =
    NotifierProvider<GradesSearchQueryNotifier, String>(GradesSearchQueryNotifier.new);

// Academic term (1 = Semestr 1, 2 = Semestr 2, 3 = Roczna)
class GradesTermNotifier extends Notifier<int> {
  @override
  int build() => 1;

  void setTerm(int term) => state = term;
}

final gradesTermProvider =
    NotifierProvider<GradesTermNotifier, int>(GradesTermNotifier.new);
```

---

### 2.3 `lib/presentation/screens/grades/grades_screen.dart`
- **Role:** Screen Coordinator / Root View.
- **Data Flow:** Watches `studentProfileProvider`, `subjectsProvider`, `selectedGradesSubjectProvider`, `gradesSearchQueryProvider`, and `gradesTermProvider`.
- **Closest Analog:** [`lib/presentation/screens/schedule/schedule_screen.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/schedule/schedule_screen.dart#L55-L95).
- **Concrete Code Excerpt (Existing Analog):**
```dart
// lib/presentation/screens/schedule/schedule_screen.dart:55-76
return LayoutBuilder(
  builder: (context, constraints) {
    final isDesktop = constraints.maxWidth >= 1024;
    return Scaffold(
      backgroundColor: isDesktop ? AppColors.surface : Colors.white,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(weekScheduleProvider),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 16,
          ),
          children: [
            // Top Nav & Toolbar
            // Summary Banner
            // Main Content Area
          ],
        ),
      ),
    );
  },
);
```
- **Pattern Application for Phase 10:**
  1. Breakpoint `constraints.maxWidth >= 1024`:
     - **Desktop:** Render Top Academic Breadcrumb & Action Toolbar ("Filtruj wg wag", "Eksportuj PDF/XLS", "Drukuj", "Przelicz GPA"), Term Switcher Tabs (Semestr 1, Semestr 2, Roczna), `AcademicKpiRow`, and a 12-column Grid:
       - Left 8 cols: `SubjectLedgerTable` + `AverageTrajectoryCard`.
       - Right 4 cols: `SubjectInspectorCard`.
     - **Mobile (<1024px):** Render single-column view with touch-optimized cards, expandable accordions, and grade pills.
  2. Integration with `AverageSimulatorModal`:
     - "Przelicz GPA" buttons in toolbar and inspector directly invoke `AverageSimulatorModal.show(context, cleanSubjects, overallAvg)`.

---

### 2.4 `lib/presentation/screens/grades/widgets/academic_kpi_row.dart` (and subcomponents)
- **Role:** Performance Metric Banners (Top KPI Row).
- **Data Flow:** Reads calculated metrics from `subjectsProvider` and `studentProfileProvider`. Computes distribution counts (MEN 1..6) and safety indicators.
- **Closest Analog:** [`lib/presentation/screens/schedule/widgets/weekly_summary_banner.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/schedule/widgets/weekly_summary_banner.dart#L14-L60) and `_buildSummaryStatsCard` in [`lib/presentation/screens/grades/grades_screen.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/grades/grades_screen.dart#L350-L405).
- **Concrete Code Excerpt (Existing Analog):**
```dart
// lib/presentation/screens/grades/grades_screen.dart:370-392
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: const Color(0xFFDCFCE7),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFBBF7D0)),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.star_rounded, size: 14, color: Color(0xFF15803D)),
      const SizedBox(width: 4),
      Text('Top 5% w $className', ...),
    ],
  ),
)
```
- **Pattern Application for Phase 10:**
  1. `WeightedAverageKpiCard` (4 cols):
     - Accent top line: `AppColors.primary` (4px height).
     - Score typography: `46px` bold leading-none (`4.82`).
     - Trend pill: `trending_up +0.14` in `secondaryContainer` with `onSecondaryContainer`.
     - Footer: `Top 5% w klasie 3B (2. lokata na 28 uczniów)` with `stars` icon in `AppColors.secondary`.
  2. `GradeDistributionCard` (8 cols):
     - Accent top line: `AppColors.primaryContainer` (4px height).
     - Title + Safety badge: `0 zagrożeń • 100% pozytywnych` with `verified` icon.
     - Total count: e.g. `38 ocen wpisanych w semestrze`.
     - 6-bar histogram: columns 1 through 6 with relative height based on max bucket count:
       - 1 & 2: `AppColors.surfaceContainerHigh` (or `AppColors.error` if count > 0).
       - 3: `AppColors.tertiaryFixedDim` (`#FFB77D`).
       - 4: `AppColors.primaryFixedDim` (`#C3C0FF`).
       - 5: `AppColors.primaryContainer` (`#4F46E5`).
       - 6: `AppColors.secondary` (`#006C4A`).
     - Legend footer: MEN scale note + percentage breakdown (e.g. `B. dobre (47.4%)`, `Celujące (21.1%)`).

---

### 2.5 `lib/presentation/screens/grades/widgets/subject_ledger_table.dart`
- **Role:** 8-column Master Ledger Table.
- **Data Flow:** Receives filtered `List<Subject>`, `selectedSubject`, and callbacks:
  - `onSelectSubject(Subject subject)`: row click to toggle/update selection.
  - `onTapGrade(Grade grade, Subject subject)`: grade pill click to open side sheet.
- **Closest Analog:** [`lib/presentation/screens/schedule/widgets/weekly_grid_view.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/schedule/widgets/weekly_grid_view.dart#L104-L140) and grade pill rendering in [`lib/presentation/screens/grades/grades_screen.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/grades/grades_screen.dart#L614-L650).
- **Concrete Code Excerpt (Existing Grade Pill):**
```dart
// lib/presentation/screens/grades/grades_screen.dart:614-648
Material(
  color: Colors.transparent,
  child: InkWell(
    onTap: () => GradeDetailsModal.show(context, grade),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          text: grade.rawValue,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: palette.text),
          children: [
            TextSpan(
              text: ' (w:${grade.weight})',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: palette.weightColor),
            ),
          ],
        ),
      ),
    ),
  ),
)
```
- **Pattern Application for Phase 10:**
  1. Header strip: Search box (`gradesSearchQueryProvider`) + Weights legend badges:
     - `Waga 3 (Sprawdzian)`: `errorContainer` / `onErrorContainer`.
     - `Waga 2 (Kartkówka)`: `surfaceContainerHighest` / `primary`.
     - `Waga 1 (Bieżąca)`: `surfaceContainerHigh` / `onSurfaceVariant`.
  2. Table Grid Columns (12-column sub-grid):
     - `col-span-4`: Subject icon avatar (math symbol ∑, physics λ, chemistry ⚗, etc.), name, level pill (`Rozszerz.`), teacher.
     - `col-span-4`: Horizontal wrap of grade pills (`5 w:3`, `5 w:2`, etc.).
     - `col-span-1`: Weighted average (e.g. `4.90`).
     - `col-span-1`: Predicted grade badge (e.g. `5` in `secondaryContainer`).
     - `col-span-2`: Last entry date and teacher initials.
  3. Selection Styling (satisfying **D-04**):
     - Active row: 4px vertical bar on left edge (`AppColors.primary`), background tinted with `AppColors.surfaceContainerHigh.withOpacity(0.4)`.
  4. Non-interfering Pill Tap (satisfying **D-05**):
     - Pill `InkWell.onTap` triggers `onTapGrade(grade, subject)` without triggering the row's `onSelectSubject`.
  5. Summary Footer:
     - Total subjects count (`14 przedmiotów zrealizowanych...`) + overall average (`4.82`).

---

### 2.6 `lib/presentation/screens/grades/widgets/subject_inspector_card.dart`
- **Role:** 4-column Right Detail Inspector.
- **Data Flow:** Watches or receives `selectedSubject` (`Subject?`).
- **Closest Analog:** [`lib/presentation/screens/schedule/widgets/agenda_lesson_card.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/schedule/widgets/agenda_lesson_card.dart#L100-L150) and expanded grade view in [`lib/presentation/screens/grades/grades_screen.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/grades/grades_screen.dart#L720-L819).
- **Concrete Code Excerpt (Existing Grade Row):**
```dart
// lib/presentation/screens/grades/grades_screen.dart:741-760
Container(
  width: 38,
  height: 38,
  decoration: BoxDecoration(
    color: palette.circleBg,
    shape: BoxShape.circle,
  ),
  alignment: Alignment.center,
  child: Text(
    grade.rawValue,
    style: TextStyle(
      color: palette.text,
      fontWeight: FontWeight.w900,
      fontSize: 15,
    ),
  ),
)
```
- **Pattern Application for Phase 10:**
  1. **Empty State (satisfying D-03):**
     - When `selectedSubject == null`:
     - Centered illustration/icon (`school_outlined` or `touch_app_outlined`, 48px, `AppColors.outlineVariant`).
     - Heading: "Brak wybranego przedmiotu".
     - Body: "Wybierz przedmiot z tabeli po lewej stronie, aby wyświetlić szczegółowy rejestr ocen i statystyki."
  2. **Populated State:**
     - Header: Subject title, level, teacher name, weighted average display (`4.90`).
     - Grade cards list: Category title, weight, date, percentage badge (`100%`), and teacher's verbal quote.
     - Tapping any grade item in this inspector also opens `GradeDetailsSideSheet`.
     - EduSync AI Study Tip banner: `psychology` icon, suggestion for improving GPA.
     - Quick actions: "Symuluj ocenę dla tego przedmiotu" (opens `AverageSimulatorModal`), "Napisz do nauczyciela".

---

### 2.7 `lib/presentation/screens/grades/widgets/average_trajectory_card.dart` & `trajectory_chart_painter.dart`
- **Role:** Spline Canvas Data Visualization.
- **Data Flow:** Receives historical date/average pairs `List<TrajectoryPoint>` (e.g. 01 Wrz 4.60, 15 Wrz 4.68, 01 Paź 4.74, 15 Paź 4.78, Dzisiaj 4.82) and class average reference (4.18).
- **Closest Analog:** Flutter `CustomPainter` pattern.
- **Pattern Application for Phase 10 (CustomPainter Spline):**
```dart
class TrajectoryChartPainter extends CustomPainter {
  final List<double> values;
  final double classAverage;
  final Color primaryColor;
  final Color classAverageColor;

  TrajectoryChartPainter({
    required this.values,
    required this.classAverage,
    required this.primaryColor,
    required this.classAverageColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Horizontal dashed grid lines (4.0, 4.5, 5.0)
    // 2. Dashed class average reference line (4.18)
    // 3. Smooth Bézier spline path (cubicTo) through measurement points
    // 4. Gradient area fill: primaryContainer (18% -> 0% opacity)
    // 5. Solid primary line (width 3.0)
    // 6. Measurement dots: white circles with 2px primary border, last dot filled solid
  }

  @override
  bool shouldRepaint(covariant TrajectoryChartPainter oldDelegate) => true;
}
```
  - Beneath the chart: date axis labels aligned with checkpoints (`01 Wrz`, `15 Wrz`, `01 Paź`, `15 Paź`, `Dzisiaj (4.82)`).

---

### 2.8 `lib/presentation/screens/grades/widgets/grade_details_side_sheet.dart` & `grade_details_modal.dart`
- **Role:** Grade Inspection Overlay (Desktop Side Sheet / Mobile Bottom Sheet).
- **Data Flow:** Takes `Grade`, `Subject`, and current subject average. Calculates dynamic impact:
  $$\Delta = \text{AverageWithGrade} - \text{AverageWithoutGrade}$$
- **Closest Analog:** [`lib/presentation/screens/schedule/widgets/lesson_details_modal.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/schedule/widgets/lesson_details_modal.dart#L16-L28) and existing [`lib/presentation/screens/grades/grade_details_modal.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/grades/grade_details_modal.dart#L11-L19).
- **Concrete Code Excerpt (Existing Modal Invocation):**
```dart
// lib/presentation/screens/grades/grade_details_modal.dart:11-19
static void show(BuildContext context, Grade grade) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GradeDetailsModal(grade: grade),
  );
}
```
- **Pattern Application for Phase 10 (Unified `showGradeDetailsSheet`):**
```dart
static void show(BuildContext context, {required Grade grade, required Subject subject}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
  if (isDesktop) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Grade Details',
      barrierColor: const Color(0x66213145), // inverse-surface/40 scrim
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      pageBuilder: (context, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 500,
              height: double.infinity,
              child: GradeDetailsSideSheet(grade: grade, subject: subject),
            ),
          ),
        );
      },
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GradeDetailsSideSheet(grade: grade, subject: subject),
    );
  }
}
```
- **Drawer Contents (matching `docs/szczegóły oceny`):**
  1. Header: Subject tag (`Chemia Rozszerzona • Klasa 3B`), title `Szczegóły oceny cząstkowej`, close button (X).
  2. Hero banner:
     - Big grade badge (`5 B. Dobra` in `primaryContainer`).
     - Category pill (`Odpowiedź ustna`) and weight pill (`Waga klasyfikacyjna: 3`).
     - Assignment title (e.g. `Kolory w chemii nieorganicznej`).
     - Date & time (`Wtorek, 15 września 2024 r., 11:40`).
  3. Dynamic Impact Visualizer:
     - `WPŁYW NA ŚREDNIĄ: +0.06 pkt`.
     - `Przed: 4.86 → Teraz: 4.92`.
     - Mini progress bar towards 6.00 with `secondary` fill.
  4. Karta Ewidencyjna Oceny (MEN Register 2-col key-value grid):
     - Ocena cyfrowa (`5 (Bardzo dobra • 100%)`).
     - Kategoria.
     - Data lekcji.
     - Przedmiot.
     - Nauczyciel & Dodał do systemu.
     - Waga oceny (3 gwiazdki).
     - Licz do średniej badge (`TAK (Wliczana)`).
  5. Teacher quotation box:
     - Italic quote with 4px left primary border and `surfaceContainerLowest/70` background.
     - Competencies evaluated badges.
  6. Action buttons:
     - "Napisz do nauczyciela" (opens messages context).
     - "Zapisz się na konsultacje / Zgłoś zapytanie".
     - "Pobierz wyciąg ocen (PDF)" & "Zamknij".

---

## 3. Implementation Conventions & Guidelines

1. **State Management:** Riverpod 3.x only (`Notifier` + `NotifierProvider`). No deprecated `StateProvider`.
2. **Design Tokens:** Always use `AppColors` instead of hardcoded hex colors where token exists (`AppColors.surface`, `AppColors.primary`, `AppColors.secondaryContainer`, etc.).
3. **Click Decoupling:** Grade pills inside table rows must handle their own `onTap` events and NOT trigger parent row selection.
4. **Responsive Breakpoints:**
   - Desktop: `>=1024px` (Master-Detail, 8+4 grid, slide-in drawer).
   - Tablet / Mobile: `<1024px` (Single column, accordions, bottom sheet).
5. **No Regressions:** Maintain backward compatibility for `GradeDetailsModal.show(context, grade)` by redirecting to `GradeDetailsSideSheet.show`.

---

## PATTERN MAPPING COMPLETE
