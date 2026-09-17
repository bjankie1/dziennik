# Phase 10: Pełen panel ocen w wersji na przeglądarkę — Research

**Status:** Complete  
**Date:** 2026-09-17  
**Goal:** Prepare a comprehensive technical foundation and implementation blueprint for Phase 10 to satisfy requirements **REQ-GRADES-05**, **REQ-GRADES-06**, **REQ-GRADES-07**, and **REQ-GRADES-08**.

---

## 1. Executive Summary

Phase 10 upgrades the Grades module (`GradesScreen`) to a modern, high-density academic portal optimized for web/desktop (>=1024px) while preserving and enhancing the touch experience on mobile/tablet (<1024px).

The visual specification stems directly from:
- `docs/panel ocen/` (`DESIGN.md`, `code.html`, `screen.png`) — Academic Precision design system, Master-Detail 8+4 grid, KPI banners, ledger table, and trajectory spline.
- `docs/szczegóły oceny/` (`DESIGN.md`, `code.html`, `screen.png`) — Grade Details Side Sheet / Drawer with grade badge, metadata register, quotation commentary, and dynamic GPA impact calculation.

---

## 2. Requirement Mapping & Acceptance Criteria

| Requirement ID | Description | Acceptance Criteria |
|---|---|---|
| **REQ-GRADES-05** | **Master-Detail Desktop Layout (>=1024px)** | 1. Two-column grid: 8 cols left (subject ledger + trajectory) + 4 cols right (subject inspector).<br>2. Default state: No subject selected; right panel shows empty state ("Wybierz przedmiot z tabeli po lewej stronie...").<br>3. Row click in table highlights row (4px left primary bar, active surface) and populates inspector.<br>4. Responsive fallback: On <1024px displays single-column view with expandable subject cards. |
| **REQ-GRADES-06** | **Academic KPI & Grade Distribution Cards** | 1. Weighted Average KPI card: big score (e.g. 4.82), trend pill (`trending_up +0.14`), class rank footer (`Top 5% w klasie 3B (2. lokata na 28 uczniów)`).<br>2. Grade Distribution card: MEN 1-6 scale bar histogram, count headers, color-coded bars (1-2 danger, 3 amber, 4-5 indigo, 6 emerald), safety badge (`0 zagrożeń • 100% pozytywnych`). |
| **REQ-GRADES-07** | **Average Trajectory Spline Chart** | 1. Rendered via `CustomPainter` for smooth 60fps performance on Flutter Web canvas.<br>2. Bézier / Catmull-Rom spline curve with gradient area fill under the line (primary color fading to 0% opacity).<br>3. Dashed reference line for class average (e.g. 4.18) with dashed grid markers.<br>4. Data points on key dates with interactive or aligned date labels along the bottom axis. |
| **REQ-GRADES-08** | **Grade Details Side Sheet / Drawer** | 1. On desktop (>=1024px): Opens as slide-in drawer from right edge (~480–520px wide), dimmed background scrim, dismissible via ESC key, X button, or scrim tap.<br>2. On mobile (<1024px): Opens as bottom sheet.<br>3. Tapping a grade pill in the table opens this drawer without changing the selected subject in the right inspector (per user decision D-05).<br>4. Content: Hero grade badge (`5 B. Dobra`), topic, metadata register, quote comment, and dynamic average impact visualizer (`Przed: 4.88 → Po: 4.92 (+0.04)`). |

---

## 3. Architecture & Responsive Layout

```
MainNavigationScreen (Responsive Shell)
 ├── AppSidebar (Desktop, persistent left)
 └── AppDesktopHeader (Desktop, top bar)
      └── GradesScreen (Index 2)
           ├── [LayoutBuilder: >=1024px Desktop vs <1024px Mobile]
           │
           ├── DESKTOP MASTER-DETAIL VIEW (>=1024px)
           │    ├── Top Academic Breadcrumb & Action Toolbar (Export, Print, Przelicz GPA)
           │    ├── Term Switcher Tabs (Semestr 1, Semestr 2, Klasyfikacja Roczna)
           │    ├── Top KPI Row (Col 1-4: WeightedAverageKpiCard, Col 5-12: GradeDistributionCard)
           │    └── Main 12-Col Grid:
           │         ├── Left Column (8 cols):
           │         │    ├── Search & Weights Legend Bar
           │         │    ├── SubjectLedgerTable (Rows with pills, averages, predicted grades)
           │         │    └── AverageTrajectoryCard (CustomPainter spline chart)
           │         └── Right Column (4 cols):
           │              └── SubjectInspectorCard
           │                   ├── Empty State (when selectedSubject == null)
           │                   └── Detailed Inspector (when selectedSubject != null):
           │                        ├── Subject Header & Weighted Avg
           │                        ├── Grade cards with preview & comments
           │                        ├── AI Study Tip Banner
           │                        └── Quick Actions (Simulator, Contact Teacher)
           │
           └── OVERLAY: GradeDetailsSideSheet / Drawer (showGeneralDialog, ~500px, right-aligned)
```

---

## 4. Component Deep Dive

### 4.1 Subject Ledger Table & Click Interactions
- **Click on Row** (`onTap`): Calls `ref.read(selectedGradesSubjectProvider.notifier).select(subject)`.
  - Toggles selection: if tapped again or if clicked on another subject, updates the right inspector card.
  - Active visual styling: 4px vertical bar on the left edge (`AppColors.primary`), background tinted with `AppColors.surfaceContainerHigh.withOpacity(0.4)`.
- **Click on Grade Pill** (`onTap` on pill):
  - Uses `GestureDetector` / `InkWell` on the pill widget with `e.stopPropagation()` / separate handler.
  - Calls `showGradeDetailsSheet(context, grade: grade, subject: subject, ...)`
  - **Does NOT** call `selectedGradesSubjectProvider.select(subject)` (satisfies **D-05**).
- **Search & Filter**:
  - Live filtering across subject name and teacher name (`gradesSearchQueryProvider`).

### 4.2 Grade Distribution Card (Bar Histogram 1–6)
- **Data calculation**:
  - Aggregate all grades from current term (Term 1).
  - Bucket into 1..6 using `grade.numericValue.round().clamp(1, 6)`.
  - Max bucket count sets the 100% relative height of the bars.
- **Color tokens**:
  - 1–2: Danger/Warning (`AppColors.error` or `surfaceContainerHigh` when 0).
  - 3: Amber/Tertiary (`AppColors.tertiaryFixedDim`, `#FFB77D`).
  - 4: Soft Indigo (`AppColors.primaryFixedDim`, `#C3C0FF`).
  - 5: Primary Indigo (`AppColors.primaryContainer`, `#4F46E5`).
  - 6: Emerald/Secondary (`AppColors.secondary`, `#006C4A`).
- **Safety Indicator**:
  - If count of 1s and 2s is 0: `0 zagrożeń • 100% pozytywnych` badge in `secondaryContainer` with verified icon.

### 4.3 Average Trajectory Spline Chart (CustomPainter)
- **Implementation**: `TrajectoryChartPainter extends CustomPainter`.
- **Path Generation**:
  - Accepts a list of chronological average points `(DateTime date, double average)`.
  - Maps `(x, y)` to canvas dimensions.
  - Generates smooth cubic Bézier segments (`cubicTo`) between points to produce a smooth natural curve.
- **Gradient Area Fill**:
  - Closes the path along `(width, height) -> (0, height)`.
  - Fills with `LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primaryContainer.withOpacity(0.18), AppColors.primaryContainer.withOpacity(0.0)])`.
- **Reference Lines**:
  - Horizontal grid guidelines at intervals (e.g. 4.0, 4.5, 5.0).
  - Dashed line for class average (`_drawDashedLine` with `dashWidth: 4, dashSpace: 4`).
- **Data Points**:
  - Draws white circles with 2px primary border on measurement dates; the latest date dot is filled solid with primary color.
- **Axis Labels**:
  - Placed in a structured row beneath the chart matching the makieta checkpoints.

### 4.4 Grade Details Side Sheet / Drawer
- **Desktop (>=1024px)**:
  - Invoked via `showGeneralDialog(...)`.
  - `barrierDismissible: true`, `barrierColor: Color(0x66213145)`.
  - `transitionDuration: Duration(milliseconds: 250)`.
  - `transitionBuilder`: `SlideTransition` from `Offset(1.0, 0.0)` to `Offset.zero` with `Curves.easeOutCubic`.
  - `pageBuilder`: Renders right-aligned card (`Align(alignment: Alignment.centerRight, child: GradeDetailsSideSheet(...))`) with fixed width `min(500, MediaQuery.sizeOf(context).width * 0.9)`.
  - Built-in ESC key dismissal via Flutter `ModalRoute` / `Actions`.
- **Mobile (<1024px)**:
  - Invoked via `showModalBottomSheet(...)`.
- **Key Features in Drawer**:
  1. Header with subject tag, class, title "Szczegóły oceny cząstkowej", and close (X) icon.
  2. Hero banner: Large grade value (e.g. `5`), verbal grade (`B. Dobra`), category badge, weight badge, assignment title, date and time.
  3. Dynamic Impact Visualizer:
     - Calculates subject average without this grade vs with this grade.
     - Displays: `WPŁYW NA ŚREDNIĄ: +0.06 pkt` (or negative/zero), `Przed: 4.86 → Teraz: 4.92`.
     - Progress bar indicating position towards 6.00.
  4. MEN Register Key-Value table (`Karta Ewidencyjna Oceny`): digital grade, category, date, subject, teacher, entered by, weight stars, counted to average badge.
  5. Teacher quotation box: italic commentary with left primary border.
  6. Action buttons: "Napisz do nauczyciela" (opens messages) and "Zapisz się na konsultacje / Zgłoś zapytanie".

---

## 5. Riverpod 3.x State Management

To adhere strictly to Riverpod 3.x conventions (no deprecated `StateProvider`):

```dart
// Selected subject in the Master-Detail view (null by default for D-03)
class SelectedSubjectNotifier extends Notifier<Subject?> {
  @override
  Subject? build() => null;

  void select(Subject? subject) {
    if (state?.id == subject?.id) {
      state = null; // toggle off if already selected
    } else {
      state = subject;
    }
  }

  void clear() => state = null;
}

final selectedGradesSubjectProvider =
    NotifierProvider<SelectedSubjectNotifier, Subject?>(SelectedSubjectNotifier.new);

// Search query for filtering subjects
class GradesSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final gradesSearchQueryProvider =
    NotifierProvider<GradesSearchQueryNotifier, String>(GradesSearchQueryNotifier.new);

// Selected academic term (1 = Semestr 1, 2 = Semestr 2, 3 = Roczna)
class GradesTermNotifier extends Notifier<int> {
  @override
  int build() => 1;

  void setTerm(int term) => state = term;
}

final gradesTermProvider =
    NotifierProvider<GradesTermNotifier, int>(GradesTermNotifier.new);
```

---

## 6. Color Tokens Additions to `AppColors`

To achieve 100% visual fidelity with `docs/panel ocen/DESIGN.md`, add the missing tokens to `lib/core/theme/app_colors.dart`:
```dart
static const Color primaryFixedDim = Color(0xFFC3C0FF);
static const Color tertiaryFixedDim = Color(0xFFFFB77D);
```

---

## 7. Plan Decomposition Recommendation

Phase 10 can be structured into 2 logical plans:

### Plan 10-01: Foundation, Master-Detail Layout, Table & KPI Cards
- Add color tokens to `AppColors`.
- Define Riverpod 3.x notifiers (`selectedGradesSubjectProvider`, `gradesSearchQueryProvider`, `gradesTermProvider`).
- Create `AcademicKpiRow` (`WeightedAverageKpiCard` + `GradeDistributionCard` with 1-6 bar histogram).
- Create `SubjectLedgerTable` with search filter, weight legend, subject rows, grade pills, and summary footer.
- Create `SubjectInspectorCard` with empty state and selected subject details.
- Integrate into `GradesScreen` with responsive `LayoutBuilder` (Desktop >=1024px vs Mobile fallback).

### Plan 10-02: Average Trajectory Spline Chart & Grade Details Side Sheet
- Implement `TrajectoryChartPainter` (CustomPainter with Bézier curves, area gradient, dashed lines, and measurement points).
- Create `AverageTrajectoryCard` and embed below the ledger table in the left column.
- Implement `GradeDetailsSideSheet` and unified `showGradeDetailsSheet` (Desktop `showGeneralDialog` slide-in drawer + mobile bottom sheet).
- Connect grade pill clicks in both the table and inspector card to `showGradeDetailsSheet`.
- Connect "Przelicz GPA" toolbar and card buttons to `AverageSimulatorModal`.
- Run verification (`flutter analyze`) and finalize manual testing walkthrough.

---

## 8. Verification Strategy

- **Static Analysis**: `flutter analyze` must pass with 0 errors / 0 warnings.
- **Visual Checks**:
  1. Desktop at >=1024px: Master-Detail 8+4 layout, no initial selection, empty state in right column.
  2. Clicking a subject row updates the inspector card and displays active styling.
  3. Clicking a grade pill directly in the table opens the slide-in side sheet without changing the selected subject.
  4. Histogram displays correct counts for 1..6 with safety badge.
  5. Trajectory spline chart displays smooth curve, gradient area fill, and dashed class average.
  6. Mobile/tablet at <1024px: Single-column view with touch-friendly pills, expandable subject cards, and bottom sheet for grade details.

---

## RESEARCH COMPLETE
