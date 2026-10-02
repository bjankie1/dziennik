# Phase 23 — UI Review

**Audited:** 2026-10-02
**Baseline:** `23-CONTEXT.md` (locked decisions D-01..D-09) + abstract 6-pillar standards (no `UI-SPEC.md` present)
**Screenshots:** not captured (no dev server at localhost:3000, 5173, or 8080 — code-only audit)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Duplicate & misleading `'Oczekuje na akceptację rodzica'` badge on teacher-pending rows, hardcoded `'Oskarowi'` in rejection modal, and Polish pluralization gaps |
| 2. Visuals | 3/4 | Missing `AnimatedSize`/`AnimatedCrossFade` on pending teacher accordion despite summary claim, redundant status badges on `isRequested` rows, and mobile banner button crowding |
| 3. Color | 2/4 | 283 hardcoded `Color(0x...)` hex literals vs 89 `AppColors` tokens across the 5 audited files; `attendance_screen.dart` and `parent_rejection_modal.dart` bypass `AppColors` entirely |
| 4. Typography | 2/4 | 10 distinct font sizes (including fractional `11.5px` and `9px`–`10px` micro-copy on interactive mobile buttons) and 6 font weights across audited widgets |
| 5. Spacing | 3/4 | Compact `28px` touch targets on mobile banner/accordion buttons (`minimumSize: Size.zero` / `Size(0, 28)`) and off-grid spacing values (`1`, `3`, `9`, `11`, `13`, `14`) |
| 6. Experience Design | 2/4 | Tapping a filtered `Oczekujące (Y)` row opens `_showRequestedDetailsModal` with an ungated, PIN-free `'Wyślij do Librusa'` button; bulk `'Cofnij wszystkie'` lacks confirmation and loading state |

**Overall: 15/24**

---

## Top 3 Priority Fixes

1. **Remove or role/PIN-gate `'Wyślij do Librusa'` in `_showRequestedDetailsModal` and fix duplicate `'Oczekuje na akceptację rodzica'` status copy (`lib/presentation/screens/attendance/attendance_screen.dart:846-885, 1711-1854`)** — When a user selects the new `'Oczekujące (Y)'` filter pill (`_activeFilter == 3`), every `JustificationStatus.requested` row displays `'Oczekuje na akceptację rodzica'` twice (even after the parent already approved it and it awaits the homeroom teacher), and tapping the row opens `_showRequestedDetailsModal` containing a `'Wyślij do Librusa'` button (`line 1821`) that is visible to students and bypasses PIN verification. — Change the status label on `JustificationStatus.requested` rows to `'Oczekuje na wychowawcę'` (with `record.justificationReason` subtitle), remove the duplicate amber badge at lines 859–885, and in `_showRequestedDetailsModal` remove the redundant `'Wyślij do Librusa'` action (or gate it behind `isParent` + `ParentApprovalModal`).
2. **Add `AnimatedSize` micro-animation and in-flight/confirmation protection to `_buildPendingTeacherAccordionBanner` (`lib/presentation/screens/attendance/attendance_screen.dart:913-1183`)** — Tapping the `'X wnioski czekają na wychowawcę'` banner causes an abrupt un-animated layout jump (`if (_isPendingBannerExpanded) ...`), and tapping `'Cofnij wszystkie'` immediately revokes all pending applications without confirmation or button disabling during the async call. — Wrap the expandable accordion body in `AnimatedSize(duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic, ...)` (per `23-CONTEXT.md` discretion), add a `_isCancellingPending` loading flag to disable `'Cofnij'` / `'Cofnij wszystkie'` while `cancelJustification` awaits, and show a confirmation dialog or `SnackBarAction(label: 'Cofnij')` on bulk cancellation.
3. **Consolidate hardcoded hex colors into `AppColors` tokens and raise mobile button font/tap sizes (`lib/presentation/screens/attendance/attendance_screen.dart`, `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart`, `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart`)** — Across the 5 files, 283 hardcoded `Color(0x...)` literals outnumber `AppColors` references (89) by more than 3:1, and mobile banner buttons (`dashboard_mobile_view.dart:438, 449, 495, 507`) use `fontSize: 10` with `minimumSize: const Size(0, 28)`. — Replace hardcoded primary/surface/error/amber hexes (`0xFF3525CD`, `0xFFF8FAFC`, `0xFFDC2626`, `0xFF006C4A`) with `AppColors` semantic constants, standardize typography to 4–5 sizes (`11`, `12`, `14`, `16`, `18`), and increase mobile action button height to at least `36px` with `fontSize: 12`.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

All core Phase 23 copywriting contracts (`D-01`..`D-09`) are implemented: `'Oskar Jankiewicz prosi o usprawiedliwienie'`, `'Zobacz szczegóły →'`, `'Zatwierdź z PIN-em (X z Y lekcji)'`, `'Pokaż szczegóły'` / `'Ukryj szczegóły'`, `'Cofnij'` / `'Cofnij wszystkie'`, `'Oczekujące (Y)'`, and Polish day headers (`'Poniedziałek, 28 Września 2026'`).

- **WARNING — Duplicate & contradictory status copy on `JustificationStatus.requested` rows (`lib/presentation/screens/attendance/attendance_screen.dart:846-885`):**
  - Line 847 renders `'Oczekuje na akceptację rodzica'` next to the amber dot, and lines 861–884 render a second boxed badge directly below with the identical string `'Oczekuje na akceptację rodzica'`.
  - Furthermore, `JustificationStatus.requested` represents lessons in `pendingList` (`'X wnioski czekają na wychowawcę'` and filter `'Oczekujące (Y)'`), including lessons that the parent has *already* approved with their PIN. Showing `'Oczekuje na akceptację rodzica'` after parental PIN approval contradicts the banner above it.
- **WARNING — Hardcoded `'Oskarowi'` / `'dla Oskara'` in `ParentRejectionModal` (`lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart:174, 368, 435`):**
  - While `studentName` is dynamically resolved via `effectiveStudentName()` at lines 113 and 214, the modal header subtitle (`'Wyjaśnij Oskarowi powód odmowy lub zadaj pytanie'`, line 174), input label (`'Komentarz rodzica (widoczny dla Oskara)'`, line 368), and submit CTA (`'Przekaż odmowę Oskarowi'`, line 435) hardcode `'Oskar'`.
- **WARNING — Polish pluralization inconsistencies across banners:**
  - `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart:409` and `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart:662` hardcode `'$count lekcji'` (producing `'1 lekcji'` or `'2 lekcji'`).
  - `lib/presentation/screens/attendance/attendance_screen.dart:1310` uses `_getLessonLabel(count)` (`lines 65-69`), which returns the accusative `'lekcję'` for `1` (`'22.09 • 1 lekcję • Choroba'`) instead of nominative `'1 lekcja'`.
  - `lib/presentation/screens/attendance/attendance_screen.dart:941` uses a binary check `pendingList.length == 1 ? "wniosek czeka" : "wnioski czekają"`, which renders `'5 wnioski czekają na wychowawcę'` for counts `>= 5` (where Polish grammar requires `'wniosków czeka'`, though note `test/attendance_pending_requests_test.dart:320` tests `2 wnioski czekają na wychowawcę`).
- **WARNING — Minor CTA & SnackBar copy drift across the 3 parent request banners:**
  - Banner approve button reads `'Zatwierdź'` in `dashboard_mobile_view.dart:436` vs `'Zatwierdź (PIN)'` in `dashboard_metrics_column.dart:688` and `attendance_screen.dart:1337` (`D-01` specifies `Zatwierdź (PIN)`).
  - Post-approval `SnackBar` copy differs across all 3 screens: `'Usprawiedliwienie dla $studentName zostało wysłane.'` (`dashboard_mobile_view.dart:323`), `'...zostało zatwierdzone.'` (`dashboard_metrics_column.dart:580`), and `'...zostało wysłane do szkoły.'` (`attendance_screen.dart:1220`).

### Pillar 2: Visuals (3/4)

`ParentApprovalModal` (`lib/presentation/screens/attendance/widgets/parent_approval_modal.dart:204-558`) establishes clear visual hierarchy: a pinned header with verification icon and `'Oczekuje'` badge, a distinct quote card with Q&A chat bubbles (`lines 254-335`), day-grouped cards with calendar headers (`lines 373-498`), strike-through + muted styling on unchecked lessons (`lines 467-476`), and a pinned bottom action bar (`lines 561-618`).

- **WARNING — Missing accordion micro-animation on `_buildPendingTeacherAccordionBanner` (`lib/presentation/screens/attendance/attendance_screen.dart:1017`):**
  - `23-CONTEXT.md` (line 38) calls for an expand/collapse micro-animation (`AnimatedCrossFade` / `AnimatedSize`), and `23-02-SUMMARY.md` (line 30) states `"Expandable AnimatedCrossFade accordion"`. In actual code (`attendance_screen.dart:1017`), the expanded section is conditionally rendered via `if (_isPendingBannerExpanded) ...[...]` with no `AnimatedSize` or `AnimatedCrossFade`.
- **WARNING — Horizontal action button crowding in `AttendanceScreen` parent banner (`lib/presentation/screens/attendance/attendance_screen.dart:1285-1384`):**
  - Unlike `DashboardMetricsColumn` (which places `Zatwierdź (PIN)` and `Odrzuć` in a bottom full-width row at `lines 679-756`) or `DashboardMobileView` (which stacks them vertically in a `Column` at `lines 429-514`), `AttendanceScreen._buildParentPendingBanner` places the icon box, the expanded text column, and a horizontal `Row` of both buttons (`Zatwierdź (PIN)` + `Odrzuć`, `lines 1330-1383`) on a single horizontal line. On a `360px`–`390px` phone screen, the two buttons consume ~195px, leaving <90px for `$studentName prosi o usprawiedliwienie` and causing severe multi-line wrapping.
- **WARNING — Single-date header on multi-day requests in `ParentRejectionModal` (`lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart:221-228`):**
  - The top-right of the summary card displays `_formatDate(widget.request.date)` (a single date), even when `groupedByDay` directly below it renders lessons across multiple calendar days. Use `widget.request.formatDateRangeSummary(widget.availableRecords)` when `groupedByDay.length > 1`.
- **WARNING — Icon-only close button missing `tooltip` (`lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart:183-186`):**
  - The modal close `IconButton` has no `tooltip` or semantic label for screen readers.

### Pillar 3: Color (2/4)

- **WARNING — Extensive hardcoded hex colors bypassing `AppColors` (`283` `Color(0x...)` instances vs `89` `AppColors.*` references across the 5 audited files):**
  - `lib/presentation/screens/attendance/attendance_screen.dart`: `0` uses of `AppColors`, `140+` hardcoded `Color(0x...)` literals.
  - `lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart`: `0` uses of `AppColors`, `31` hardcoded `Color(0x...)` literals.
  - `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart`: imports `AppColors` (`line 2`) and uses `AppColors.primary` at `lines 430, 583`, yet hardcodes `const Color(0xFF3525CD)` at `lines 213, 267, 363, 395, 457, 549`.
  - Top hardcoded colors across the 5 files:
    - `Color(0xFFDC2626)` — 31 occurrences (vs `AppColors.error` = `0xFFBA1A1A`)
    - `Color(0xFF64748B)` — 25 occurrences (vs `AppColors.outline` / `onSurfaceVariant`)
    - `Color(0xFFE2E8F0)` — 18 occurrences (vs `AppColors.outlineVariant`)
    - `Color(0xFF3525CD)` — 18 occurrences (exact duplicate of `AppColors.primary`)
    - `Color(0xFFB45309)` — 15 occurrences (amber 700)
    - `Color(0xFF0F172A)` — 15 occurrences (vs `AppColors.onSurface`)
    - `Color(0xFF006C4A)` — 10 occurrences (exact duplicate of `AppColors.secondary`)
- **WARNING —Competing amber containers on `AttendanceScreen` (`lib/presentation/screens/attendance/attendance_screen.dart:140-143, 475, 909, 1274`):**
  - When a parent has both an incoming student request (`_buildParentPendingBanner`, fill `0xFFFEF3C7`, border `0xFFFDE68A`), unexcused absences in the semester header badge (`0xFFFEF3C7`), and pending teacher requests (`_buildPendingTeacherAccordionBanner`, fill `0xFFFFFBEB`, border `0xFFFDE68A`), three warm yellow/amber surfaces appear in the top viewport simultaneously. Differentiating the student-to-parent request banner with an indigo/primary-tinted accent border or icon container (`AppColors.primaryFixed`) would visually separate "Action required by Parent (PIN)" from "Waiting on Homeroom Teacher".

### Pillar 4: Typography (2/4)

- **WARNING — 10 distinct font sizes across the 5 audited files (exceeds 4–5 step typographic scale):**
  - `fontSize: 9` (2 occurrences: `attendance_screen.dart:629`, `dashboard_metrics_column.dart:140`)
  - `fontSize: 10` (12 occurrences: including mobile CTA button labels at `dashboard_mobile_view.dart:438, 495` and status badges at `attendance_screen.dart:351, 368, 500, 653, 876`)
  - `fontSize: 11` (51 occurrences)
  - `fontSize: 11.5` (1 fractional occurrence: `parent_rejection_modal.dart:260`)
  - `fontSize: 12` (38 occurrences)
  - `fontSize: 13` (15 occurrences)
  - `fontSize: 14` (7 occurrences)
  - `fontSize: 15` (2 occurrences: `attendance_screen.dart:286, 1533`)
  - `fontSize: 16` (8 occurrences)
  - `fontSize: 18` (3 occurrences)
- **WARNING — Sub-legible `10px` font size on interactive mobile buttons (`lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart:438, 495`):**
  - The `'Zatwierdź'` and `'Odrzuć'` buttons inside the mobile dashboard banner use `fontSize: 10`. Interactive button labels on mobile should be at least `12px`.
- **WARNING — 6 distinct font weights (`w500`, `w600`, `w700`, `bold`, `w800`, `w900`):**
  - `FontWeight.w700` (47x) and `FontWeight.bold` (13x) are used side-by-side despite being identical (`w700`), alongside `w500` (10x), `w600` (24x), `w800` (27x), and `w900` (1x at `attendance_screen.dart:616`).

### Pillar 5: Spacing (3/4)

`ParentApprovalModal` and `ParentRejectionModal` properly constrain modal height to `mediaQuery.size.height * 0.90`, wrap the lesson list in `Flexible` + `SingleChildScrollView`, and account for `mediaQuery.viewInsets.bottom` so the keyboard never obscures the PIN field or action buttons (`test/attendance_justification_modal_test.dart:111-167`).

- **WARNING — Undersized touch targets (`< 48dp`) on mobile banners and accordion actions:**
  - `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart:449, 507`: `minimumSize: const Size(0, 28)` with `padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)` yields a `28px`-tall button directly inside a tappable `InkWell` banner.
  - `lib/presentation/screens/attendance/attendance_screen.dart:996-1001`: `'Cofnij wszystkie'` `TextButton` uses `minimumSize: Size.zero`, `tapTargetSize: MaterialTapTargetSize.shrinkWrap`, and `padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)` inside the accordion header `InkWell`, creating a ~`24px` touch target where a slightly off-center tap toggles the accordion instead of cancelling, or vice versa.
  - `lib/presentation/screens/attendance/attendance_screen.dart:1151-1157`: per-lesson `'Cofnij'` `OutlinedButton` uses `minimumSize: Size.zero` and `tapTargetSize: MaterialTapTargetSize.shrinkWrap` with `vertical: 6` padding (~`28px` height).
- **WARNING — Off-grid spacing values (`1`, `2`, `3`, `6`, `9`, `11`, `13`, `14`):**
  - Non-4px-grid `EdgeInsets` and `SizedBox` values appear across the audited files: `EdgeInsets.all(9)` (`parent_approval_modal.dart:207`, `parent_rejection_modal.dart:148`), `EdgeInsets.symmetric(vertical: 13)` (`parent_rejection_modal.dart:409, 441`), `SizedBox(height: 3)` (`parent_approval_modal.dart:465`, `dashboard_mobile_view.dart:416`, `attendance_screen.dart:1317`), and `SizedBox(height: 1)` (`parent_approval_modal.dart:478`, `attendance_screen.dart:627, 1106`).

### Pillar 6: Experience Design (2/4)

Phase 23's partial approval state machine (`_selectedRecordIds`, `_toggleRecord`, `_toggleAll`, disabled button state when `_selectedRecordIds.isEmpty`, and 3-tier `resolveAttendanceRecords` fallback) is solid and thoroughly covered by widget tests.

- **WARNING — Ungated, PIN-free `'Wyślij do Librusa'` action in `_showRequestedDetailsModal` (`lib/presentation/screens/attendance/attendance_screen.dart:744, 1711-1854`):**
  - Phase 23 added the 4th filter pill `'Oczekujące (Y)'` (`_activeFilter == 3`, `line 214`) to surface `JustificationStatus.requested` lessons in the main list.
  - Each `isRequested` row in `_buildAbsenceRow` has `onTap: () => _showRequestedDetailsModal(context, record)` (`line 744`).
  - `_showRequestedDetailsModal` (`lines 1821-1845`) renders a primary `'Wyślij do Librusa'` button that calls `submitJustification` directly:
    1. It is not gated by `isParent` (a logged-in student can tap an `Oczekujące` lesson and press `'Wyślij do Librusa'`).
    2. It does not require the 4-digit parent PIN.
    3. The lesson is *already* in `JustificationStatus.requested` state ("wniosek czeka na wychowawcę"), making a second `'Wyślij do Librusa'` action redundant and confusing.
- **WARNING — Destructive `'Cofnij wszystkie'` and `'Cofnij'` lack loading state and confirmation (`lib/presentation/screens/attendance/attendance_screen.dart:977-1011, 1128-1170`):**
  - Tapping `'Cofnij wszystkie'` immediately cancels all pending homeroom teacher applications without a confirmation dialog or undo action.
  - Neither `'Cofnij wszystkie'` nor per-lesson `'Cofnij'` tracks an in-flight loading state, allowing rapid double-taps while `await ref.read(attendanceProvider.notifier).cancelJustification(...)` executes.
- **WARNING — Pre-filled PIN `'1234'` in `ParentApprovalModal` (`lib/presentation/screens/attendance/widgets/parent_approval_modal.dart:57`):**
  - `final _pinController = TextEditingController(text: '1234');` pre-populates the 4-digit PIN field on open. Because the modal already displays a visible hint badge (`'Domyślny PIN: 1234'` at `line 520`), pre-filling the controller reduces parental PIN authorization to a single tap without active PIN entry. (Note: existing widget tests in `test/attendance_justification_modal_test.dart:162, 375` rely on the pre-filled `'1234'` value, so any change here must update those tests.)
- **WARNING — Multiple pending student requests only surface `.first` (`lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart:295`, `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart:338`, `lib/presentation/screens/attendance/attendance_screen.dart:1188`):**
  - All three parent banners bind exclusively to `pendingRequests.first`. When a student submits multiple separate justification requests, no counter badge (e.g. `'1 z ${pendingRequests.length} wniosków'`) is shown on the banner.
- **WARNING — `ref.read` instead of `ref.watch` inside `_buildParentPendingBanner` (`lib/presentation/screens/attendance/attendance_screen.dart:1190-1191`):**
  - `_buildParentPendingBanner` calls `ref.read(studentProfileProvider).value` inside a build helper without `AttendanceScreen.build` watching `studentProfileProvider` (unlike `DashboardMobileView:25` and `DashboardMetricsColumn:554` which use `ref.watch`).

---

## Files Audited

- `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart`
- `lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart`
- `lib/presentation/screens/attendance/attendance_screen.dart`
- `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart`
- `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart`
- `lib/domain/models/justification_request.dart`
- `lib/core/theme/app_colors.dart`
- `test/attendance_justification_modal_test.dart`
- `test/attendance_pending_requests_test.dart`
