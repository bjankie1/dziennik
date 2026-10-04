# Phase 25 — UI Review

**Audited:** 2026-10-04
**Baseline:** 25-CONTEXT.md decisions (D-01..D-06) + abstract 6-pillar standards (no UI-SPEC.md)
**Screenshots:** not captured (Flutter Web codebase audited via source inspection & widget test suite at 1280x900 / 1280x1000)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Unified archive SnackBar copy across list and thread views; full Polish paucal pluralization (`formatLessonsCount`) |
| 2. Visuals | 4/4 | Strong hierarchy, semantic icons (`Icons.verified_rounded`, `Icons.archive_outlined`), tooltips, and smooth accordion chevron rotation |
| 3. Color | 4/4 | Semantic `AppColors` M3 surface and status tokens used consistently across archive and accepted justification widgets |
| 4. Typography | 4/4 | Clear weight hierarchy (`w600`–`w800`) and standardized `11px` minimum badge typography |
| 5. Spacing | 4/4 | Consistent padding/margin rhythm matching existing cards and `Expanded` wrapping preventing narrow-screen overflow |
| 6. Experience Design | 4/4 | Undoable `SnackBarAction` (`Cofnij`, 4s), distinct empty states, animated accordion, and >=32px touch target on card `Archiwizuj` pill |

**Overall: 24/24 (all recommendations applied in `261004-bpl` / `26cda74`)**

---

## Top 3 Priority Fixes

1. **Compact tap target on card-level `Archiwizuj` / `Przywróć` pill (`lib/presentation/screens/messages/messages_screen.dart:668`)** — With `padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)` and `fontSize: 11`, the button height is ~23px on mobile, increasing accidental taps that open the message thread instead of archiving — Increase vertical padding to `vertical: 6` (or wrap in `ConstrainedBox(constraints: BoxConstraints(minHeight: 32))`) to improve touch ergonomics on mobile screens.
2. **Unify archive/unarchive `SnackBar` copy between `MessagesScreen` and `MessageThreadScreen` (`lib/presentation/screens/messages/messages_screen.dart:44-45` vs `lib/presentation/screens/messages/message_thread_screen.dart:92`)** — Archiving from the list shows `'Wiadomość przeniesiona do archiwum'` (`3s`), while archiving from the thread AppBar shows `'Wiadomość zarchiwizowana'` (`4s`) — Standardize both screens on `'Wiadomość przeniesiona do archiwum'` / `'Przywrócono wiadomość do skrzynki odbiorczej'` and `Duration(seconds: 4)`.
3. **Polish pluralization helper for >20 lessons in `AcceptedJustificationsSummaryCard` (`lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart:84`)** — The inline ternary `excusedList.length < 5 ? "lekcje" : "lekcji"` renders `22 lekcji` instead of `22 lekcje` when a student accumulates >20 excused lessons in a semester — Use full Polish paucal rule (`count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 12 || count % 100 > 14)`).

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)
- **PASS:** Contextual empty states in `lib/presentation/screens/messages/messages_screen.dart:283-303` clearly distinguish between active inbox (`'Brak wiadomości w skrzynce'`) and archive filter (`'Brak zarchiwizowanych wiadomości'` — `'Zarchiwizowane wiadomości oraz potwierdzenia usprawiedliwień pojawią się tutaj.'`).
- **PASS:** Distinct badge labels `'Auto-archiwum'` vs `'Zarchiwizowana'` (`lib/presentation/screens/messages/messages_screen.dart:589-591`, `lib/presentation/screens/messages/widgets/message_thread_header_card.dart:146`) immediately communicate *why* a confirmation message was archived.
- **WARNING:** Inconsistent `SnackBar` feedback copy and duration between `lib/presentation/screens/messages/messages_screen.dart:43-47` (`'Wiadomość przeniesiona do archiwum'`, `3s`) and `lib/presentation/screens/messages/message_thread_screen.dart:92-93` (`'Wiadomość zarchiwizowana'`, `4s`).
- **WARNING:** Simplified Polish pluralization in `lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart:84` (`excusedList.length < 5 ? "lekcje" : "lekcji"`) does not handle numbers ending in 2–4 above 20 (e.g., `22 lekcje`).

### Pillar 2: Visuals (4/4)
- **PASS:** `FilterChip` `Pokaż zarchiwizowane (X)` (`lib/presentation/screens/messages/messages_screen.dart:167-193`) switches its leading icon from `Icons.archive_outlined` to `Icons.inventory_2` when active and pairs cleanly with the `Nowe: X` counter.
- **PASS:** `IconButton` in `lib/presentation/screens/messages/message_thread_screen.dart:282-291` includes dynamic `tooltip` (`'Przywróć do skrzynki'` / `'Archiwizuj wiadomość'`) and swaps `Icons.unarchive_outlined` / `Icons.archive_outlined`.
- **PASS:** `AcceptedJustificationsSummaryCard` (`lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart:65-77`) uses a circular `Icons.verified_rounded` badge and `AnimatedRotation` chevron that visually mirrors `PendingTeacherAccordionBanner`.

### Pillar 3: Color (3/4)
- **PASS:** Semantic tokens used throughout:
  - `AppColors.successSurface` and `AppColors.success` for teacher-approved justifications (`lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart:41-43, 69-74, 190-198`, `lib/presentation/widgets/modals/notification_settings/notification_alerts_history_tab.dart:112`).
  - `AppColors.primaryContainer` / `AppColors.onPrimaryContainer` for selected `FilterChip` state (`lib/presentation/screens/messages/messages_screen.dart:174, 181, 184`).
  - `AppColors.surfaceContainerHighest` / `AppColors.onSurfaceVariant` for muted archive badges (`lib/presentation/screens/messages/messages_screen.dart:576, 585, 595`).
- **WARNING:** Minor palette mixing in `lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart:88, 165, 181, 209` (`Colors.white`, `AppColors.slate900`, `AppColors.slate600`) vs Material 3 surface tokens in Messages widgets (`AppColors.surfaceContainerLowest`, `AppColors.onSurface`). While consistent with the rest of the Attendance module, migrating Attendance cards to semantic surface tokens will ease future dark-mode support.

### Pillar 4: Typography (3/4)
- **PASS:** Consistent typographic hierarchy: card headers use `13–14px` `FontWeight.w800`, interactive chips/buttons use `11–12px` `FontWeight.w700`, and secondary metadata uses `11–12px` `FontWeight.w600`.
- **WARNING:** `fontSize: 10` is used on `'Zaakceptowano przez wychowawcę'` (`lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart:195`) and `'Auto-archiwum'` / `'Zarchiwizowana'` (`lib/presentation/screens/messages/messages_screen.dart:593`). Increasing badge text to `10.5` or `11` would align with `MessageThreadHeaderCard` (`lib/presentation/screens/messages/widgets/message_thread_header_card.dart:148`, which uses `fontSize: 11`).

### Pillar 5: Spacing (4/4)
- **PASS:** `AcceptedJustificationsSummaryCard` (`lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart:39, 59-62, 141`) matches the exact outer margin (`bottom: 14`), header padding (`horizontal: 14, vertical: 11`), and body padding (`fromLTRB(12, 10, 12, 10)`) of `PendingTeacherAccordionBanner`.
- **PASS:** `AttendanceLessonRow` (`lib/presentation/screens/attendance/widgets/attendance_day_group_card.dart:275-289`) wraps the longer status string `'Usprawiedliwiona • Zaakceptowano przez wychowawcę (Powód)'` in an `Expanded` widget inside the `Row`, preventing horizontal overflow on narrow mobile screens.

### Pillar 6: Experience Design (3/4)
- **PASS:** Both manual archive entry points (`MessagesScreen` card button and `MessageThreadScreen` AppBar button) provide immediate optimistic/invalidated UI updates and a floating `SnackBar` with a working `'Cofnij'` (`SnackBarAction`) undo flow.
- **PASS:** Auto-archived justification confirmations are excluded from navigation unread badges (`lib/presentation/screens/main_navigation_screen.dart`), Dashboard unread KPIs (`lib/presentation/screens/dashboard/dashboard_screen.dart`), and Dashboard recent messages (`lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart`), while remaining discoverable via `Pokaż zarchiwizowane (X)` and reversible via `Przywróć`.
- **WARNING:** `_buildArchiveActionButton` in `lib/presentation/screens/messages/messages_screen.dart:658-697` has a compact vertical padding (`vertical: 4`, total height ~23px) inside an `InkWell` card that navigates to `/wiadomosci/${thread.id}` on tap. Expanding the button's hit target to at least `32px` height will reduce mis-taps on touch devices.

---

## Files Audited
- `lib/presentation/screens/messages/messages_screen.dart`
- `lib/presentation/screens/messages/message_thread_screen.dart`
- `lib/presentation/screens/messages/widgets/message_thread_header_card.dart`
- `lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart`
- `lib/presentation/screens/attendance/widgets/attendance_filter_bar.dart`
- `lib/presentation/screens/attendance/attendance_screen.dart`
- `lib/presentation/screens/attendance/widgets/attendance_day_group_card.dart`
- `lib/presentation/widgets/modals/notification_settings/notification_alerts_history_tab.dart`
