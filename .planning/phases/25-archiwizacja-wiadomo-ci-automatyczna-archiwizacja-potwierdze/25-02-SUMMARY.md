---
phase: 25-archiwizacja-wiadomo-ci-automatyczna-archiwizacja-potwierdze
plan: 02
subsystem: ui
tags: [flutter, messages, attendance, archiving, justification]

requires:
  - phase: 25-01
    provides: MessageThread archiving fields, archiveMessage repository API, auto-archive detection
provides:
  - Pokaż zarchiwizowane (X) filter chip and manual archive/restore buttons in MessagesScreen and MessageThreadScreen
  - Auto-archiwum / Zarchiwizowana badges on archived message cards and thread headers
  - Usprawiedliwione (X) count chip, AcceptedJustificationsSummaryCard, and teacher approval badges in AttendanceScreen
affects: [MessagesScreen, MessageThreadScreen, AttendanceScreen]

tech-stack:
  added: []
  patterns:
    - FilterChip toggle in MessagesScreen header row with undoable SnackBar actions for archiving
    - Expandable AcceptedJustificationsSummaryCard in AttendanceFilterBar.bannerSlot when Usprawiedliwione filter is active

key-files:
  created:
    - lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart
    - test/presentation/screens/messages_archive_and_attendance_accepted_test.dart
  modified:
    - lib/presentation/screens/messages/messages_screen.dart
    - lib/presentation/screens/messages/message_thread_screen.dart
    - lib/presentation/screens/messages/widgets/message_thread_header_card.dart
    - lib/presentation/screens/attendance/widgets/attendance_filter_bar.dart
    - lib/presentation/screens/attendance/attendance_screen.dart
    - lib/presentation/screens/attendance/widgets/attendance_day_group_card.dart
    - lib/data/mock/mock_data.dart

key-decisions:
  - "Archived messages are hidden by default in MessagesScreen and revealed via the Pokaż zarchiwizowane (X) FilterChip without adding a third main SegmentedButton tab"
  - "When Usprawiedliwione (X) is active in AttendanceScreen, AcceptedJustificationsSummaryCard occupies bannerSlot to provide a grouped day-by-day summary of teacher-approved justifications"

patterns-established:
  - "Undoable archive/restore via SnackBarAction calling schoolRepositoryProvider.archiveMessage"

requirements-completed: [MSG-ARCH-01, MSG-ARCH-02, ATT-JUST-01]

duration: 12min
completed: 2026-10-04
---

# Phase 25 Plan 02: UI Archiwizacji Wiadomości i Zaakceptowanych Usprawiedliwień Summary

**Dodano filtr „Pokaż zarchiwizowane (X)” oraz ręczne archiwizowanie/przywracanie wiadomości z opcją „Cofnij”, a także rozbudowano widok „Usprawiedliwione (X)” w module Frekwencji o kartę podsumowania zaakceptowanych wniosków i oznaczenia akceptacji przez wychowawcę.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-10-04T07:50:00+02:00
- **Completed:** 2026-10-04T08:01:00+02:00
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Dodano przełącznik `FilterChip` `Pokaż zarchiwizowane (X)` (`ValueKey('messages_archive_filter_chip')`) w zakładce `Wiadomości` w `MessagesScreen`, ukrywający domyślnie wiadomości zarchiwizowane i auto-zarchiwizowane potwierdzenia systemowe.
- Dodano przyciski szybkiej archiwizacji / przywracania (`Archiwizuj` / `Przywróć`) na kartach wiadomości w `MessagesScreen` oraz w `AppBar` widoku wątku `MessageThreadScreen` wraz z powiadomieniem `SnackBar` i akcją `Cofnij`.
- Dodano plakietki `Auto-archiwum` oraz `Zarchiwizowana` na kartach wiadomości oraz w `MessageThreadHeaderCard`.
- Rozbudowano pasek filtrów w `AttendanceFilterBar` o licznik `Usprawiedliwione (X)`.
- Utworzono rozwijaną kartę `AcceptedJustificationsSummaryCard` prezentującą zaakceptowane wnioski pogrupowane według dni z przedmiotami i powodem usprawiedliwienia.
- Zaktualizowano wiersze lekcji w `AttendanceDayGroupCard`, aby dla usprawiedliwionych lekcji wyświetlały status `Usprawiedliwiona • Zaakceptowano przez wychowawcę (Powód)`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add archive filter chip and manual archive/restore actions in MessagesScreen and MessageThreadScreen** - `1397a64` (feat)
2. **Task 2: Enhance AttendanceScreen excused filter with count, summary card, and teacher approval badges** - `a5291a9` (feat)

## Files Created/Modified
- `lib/presentation/screens/messages/messages_screen.dart` - Filtr `Pokaż zarchiwizowane (X)`, filtrowanie aktywnych/zarchiwizowanych wiadomości, przycisk `Archiwizuj`/`Przywróć` i plakietki `Auto-archiwum`/`Zarchiwizowana`.
- `lib/presentation/screens/messages/message_thread_screen.dart` - Przycisk archiwizacji/przywracania w `AppBar.actions` z obsługą `Cofnij`.
- `lib/presentation/screens/messages/widgets/message_thread_header_card.dart` - Plakietka `Auto-archiwum` / `Zarchiwizowana` w nagłówku wątku.
- `lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart` - Karta podsumowania zaakceptowanych usprawiedliwień z podziałem na dni.
- `lib/presentation/screens/attendance/widgets/attendance_filter_bar.dart` - Licznik `Usprawiedliwione (X)` na pasku filtrów.
- `lib/presentation/screens/attendance/attendance_screen.dart` - Przekazanie `excusedCount` oraz `AcceptedJustificationsSummaryCard` dla filtra `Usprawiedliwione`.
- `lib/presentation/screens/attendance/widgets/attendance_day_group_card.dart` - Wyraźny status `Usprawiedliwiona • Zaakceptowano przez wychowawcę` wraz z powodem.
- `test/presentation/screens/messages_archive_and_attendance_accepted_test.dart` - Testy widgetowe archiwizacji wiadomości i widoku zaakceptowanych usprawiedliwień.

## Decisions Made
- Zarchiwizowane wiadomości są domyślnie ukryte w widoku skrzynki odbiorczej i wliczane do licznika na chipie `Pokaż zarchiwizowane (X)`.
- Ręczne odarchiwizowanie wiadomości auto-zarchiwizowanej zapisuje trwały override (`isArchived: false`), dzięki czemu wiadomość pozostaje w głównej skrzynce również po kolejnej synchronizacji.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Wszystkie zadania z Fazy 25 (`25-01` i `25-02`) zostały zrealizowane i przetestowane. Gotowe do weryfikacji fazy i wdrożenia na Firebase.

---
*Phase: 25-archiwizacja-wiadomo-ci-automatyczna-archiwizacja-potwierdze*
*Completed: 2026-10-04*
