---
phase: 261016-e8f-s-upki-w-histogramie-ocen-s-rozjechane-c
plan: 01
subsystem: grades
tags: [grades, histogram, flutter-ui, layout, baseline-alignment, widget-tests]
requires: []
provides:
  - "Fixed-baseline MEN 1-6 histogram layout in GradeDistributionCard with ValueKey('grade_bar_$gradeNum') and ValueKey('grade_label_$gradeNum')"
  - "Widget regression test asserting identical bottom dy coordinates across all 6 bars and labels without vertical overflow"
affects: [grades]
tech-stack:
  added: []
  patterns:
    - "Fixed-height count and grade-scale slots inside MainAxisAlignment.end columns with integer-rounded bar heights to prevent RenderFlex overflow and subpixel baseline drift"
key-files:
  created: []
  modified:
    - lib/presentation/screens/grades/widgets/grade_distribution_card.dart
    - test/presentation/screens/grades/grades_presentation_test.dart
decisions:
  - "Increase histogram container height from 80px to 96px (bottom padding 6px) and bound count slot (16px), bar height (4..36px), gaps (4px + 6px), and grade label slot (18px) to at most 80px inside 89px inner height so MainAxisAlignment.end never triggers RenderFlex overflow"
  - "Round barHeight to integer logical pixels via .roundToDouble().clamp(4.0, 36.0) so all 6 bars share an exact integer bottom dy coordinate without IEEE-754 subpixel drift"
metrics:
  duration: "6m"
  completed: "2026-10-16"
status: complete
commits: 1
plan_head_before: 4126fb46e209d7c34e5d205d66af574d42804182
plan_head_after: 2a3a91f79a43b32f67937519f85021192a26e32b
actuals:
  tokens: 7754
  tasks: 2
  commits: 1
---

# Quick Task 261016-e8f Plan 01: Wyrównanie słupków w histogramie ocen Summary

Fixed-baseline MEN 1–6 grade distribution histogram in `GradeDistributionCard` with bounded slot heights, integer pixel bar heights, coordinate-level widget tests, and Firebase Hosting release deployment.

## What Was Built

### Task 1: Align GradeDistributionCard Histogram Bars & Coordinate Widget Tests (`2a3a91f`)
- **Root Cause**: In `GradeDistributionCard`, the histogram container was `80px` tall (`75px` available after `4px` bottom padding and `1px` border), while the tallest column (`count = 7`, `barHeight = 34px`) had unconstrained `Text('$count')` (~16px) + `4px` + `34px` + `4px` + `Text('$gradeNum')` (~20px) = `78px > 75px`. When a Flutter `RenderFlex` (`Column`) with `MainAxisAlignment.end` overflows `maxMainSize`, Flutter resets `leadingSpace = 0.0` and overflows out the bottom—pushing both the tallest bar and its `1` label ~8–10px below bars `2..6` in release web builds.
- **`lib/presentation/screens/grades/widgets/grade_distribution_card.dart`**:
  - Increased the histogram `Container` height from `80` to `96` (`padding: const EdgeInsets.only(bottom: 6)`), giving `89px` of inner vertical height.
  - Wrapped the top count label in a fixed `SizedBox(height: 16)` and the bottom grade scale label in a fixed `SizedBox(key: ValueKey('grade_label_$gradeNum'), height: 18)` with `height: 1.0` text styles.
  - Added `key: ValueKey('grade_bar_$gradeNum')` to each bar and computed `barHeight = (ratio * 36).roundToDouble().clamp(4.0, 36.0)` so total column height never exceeds `80px` (`9px` safety margin) and every bar's bottom edge lands on an exact integer `dy` coordinate.
- **`test/presentation/screens/grades/grades_presentation_test.dart`**:
  - Added `GradeDistributionCard aligns all 6 histogram bars and grade labels on the exact same horizontal baseline without overflow` testing both Oskar's dataset and a skewed `count = 7` grade `1` distribution, verifying `tester.getBottomLeft` and `tester.getCenter` `dy` coordinates are identical across all 6 bars and labels.

### Task 2: Release Web Build & Firebase Hosting Deployment
- Verified zero issues with `flutter analyze lib/presentation/screens/grades/widgets/grade_distribution_card.dart test/presentation/screens/grades/grades_presentation_test.dart`.
- Built production web bundle with `flutter build web --release`.
- Deployed to Firebase Hosting (`https://lepsza-szkola.web.app`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rounded `barHeight` to integer logical pixels to eliminate IEEE-754 subpixel bottom-edge drift**
- **Found during:** Task 1 widget coordinate verification
- **Issue:** Fractional ratios (e.g., `2 / 3 * 36` or `1 / 7 * 36`) produced floating-point heights where `topLeft.dy + height` differed by `0.00000000000006` (`337.00000000000006` vs `337.0`) and could cause subpixel anti-aliasing on the bottom edge in web renderers.
- **Fix:** Applied `.roundToDouble().clamp(4.0, 36.0)` to `barHeight`.
- **Files modified:** `lib/presentation/screens/grades/widgets/grade_distribution_card.dart`
- **Commit:** `2a3a91f`

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: `lib/presentation/screens/grades/widgets/grade_distribution_card.dart`
- FOUND: `test/presentation/screens/grades/grades_presentation_test.dart`
- FOUND commit: `2a3a91f`
- Live hosting deployed: `https://lepsza-szkola.web.app`
