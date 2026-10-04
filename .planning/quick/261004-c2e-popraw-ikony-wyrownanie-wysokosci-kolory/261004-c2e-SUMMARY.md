---
phase: quick-261004-c2e
plan: 01
subsystem: ui
tags: [flutter, messages, archive, icons, responsive, material3]
provides:
  - Custom vector ArchiveBoxIcon independent of cached MaterialIcons-Regular.otf
  - Inline responsive archive filter toggle inside the Search & Write bar row (zero extra vertical space)
  - Equal 30px height and distinct semantic color themes (Indigo vs Warm Amber / Emerald Green) for task and archive buttons
affects: [MessagesScreen, MessageThreadScreen, MessageThreadHeaderCard]
tech-stack:
  added: []
  patterns: [CustomPaint vector icons for cache-immune web rendering, LayoutBuilder breakpoint toggle]
key-files:
  created:
    - lib/presentation/screens/messages/widgets/archive_box_icon.dart
  modified:
    - lib/presentation/screens/messages/messages_screen.dart
    - lib/presentation/screens/messages/message_thread_screen.dart
    - lib/presentation/screens/messages/widgets/message_thread_header_card.dart
    - web/index.html
    - test/presentation/screens/messages_archive_and_attendance_accepted_test.dart
key-decisions:
  - "Replaced font-glyph archive icons with vector ArchiveBoxIcon (CustomPaint) and added flutter-* CacheStorage cleanup in web/index.html so archive icons always render cleanly regardless of browser font cache state."
  - "Placed Pokaż zarchiwizowane (X) inline inside the Search & Write row with a <600px compact icon+badge mode so it consumes zero vertical space."
  - "Unified task creation and archive action buttons at height: 30px with distinct color palettes (Indigo for task actions vs Warm Amber for Archiwizuj and Emerald Green for Przywróć)."
duration: 8min
completed: 2026-10-04
---

# Quick Task 261004-c2e Summary

**Wektorowe ikony archiwum (`ArchiveBoxIcon`), przełącznik „Pokaż zarchiwizowane” w linii wyszukiwarki (z trybem ikony na wąskich ekranach), wyrównana wysokość `30px` oraz wyraźne rozróżnienie kolorystyczne przycisków akcji na kartach wiadomości**

## Performance

- **Duration:** 8 min
- **Completed:** 2026-10-04
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- **Niezawodne wektorowe ikony archiwum (`ArchiveBoxIcon`):** Utworzono widget `ArchiveBoxIcon` oparty na `CustomPaint` w `lib/presentation/screens/messages/widgets/archive_box_icon.dart` (obsługujący warianty: archiwizuj зі strzałką w dół, przywróć ze strzałką w górę oraz wskaźnik aktywnego filtra z haczykiem) i zastąpiono nim wywołania glifów `Icons.archive_outlined` / `Icons.unarchive_outlined` / `Icons.inventory_2_outlined` w `MessagesScreen`, `MessageThreadScreen` i `MessageThreadHeaderCard`. Dodatkowo w `web/index.html` dodano czyszczenie przestarzałych pamięci podręcznych `flutter-*` (`CacheStorage`), które w przeglądarce serwowały dawną czcionkę `MaterialIcons-Regular.otf`.
- **Przełącznik „Pokaż zarchiwizowane” bez zajmowania miejsca w pionie:** Przeniesiono przełącznik `messages_archive_filter_chip` do głównego wiersza paska wyszukiwania i przycisku „Napisz” (`height: 44px`). Na szerokich ekranach (`>= 600px`) wyświetla ikonę + tekst `Pokaż zarchiwizowane (X)`, a na wąskich urządzeniach (`< 600px`) przełącza się automatycznie w kompaktowy przycisk ikony z licznikiem w plakietce i podpowiedzią `Tooltip`.
- **Wyrównana wysokość (`30px`) i rozróżnienie kolorystyczne przycisków:** Ujednolicono wysokość przycisku `+ Utwórz zadanie z wiadomości` (`ValueKey('task_action_${thread.id}')`) oraz `Archiwizuj` / `Przywróć` (`ValueKey('archive_message_${thread.id}')`) do dokładnie `30px` i nadano im wyraźnie odmienne palety barw:
  - **Utwórz zadanie:** Indygo (`AppColors.primary` `#00288E`, tło `AppColors.primaryContainer` / `AppColors.primaryFixed`).
  - **Archiwizuj:** Ciepły bursztyn (`#B45309`, tło `#FFFBEB`, obramowanie `#F59E0B`).
  - **Przywróć:** Szmaragdowa zieleń (`AppColors.success` `#16A34A`, tło `AppColors.successSurface` `#DCFCE7`).

## Task Commits

1. **Tasks 1-2: Vector archive icons, inline responsive filter toggle, equal 30px height and distinct button colors** - `3b47a8d` (fix)

## Verification

- `flutter test test/presentation/screens/messages_archive_and_attendance_accepted_test.dart` — 2/2 testów przeszło pomyślnie (w tym weryfikacja `ArchiveBoxIcon`, identycznej wysokości `30.0` obu przycisków oraz responsywnego trybu ikony dla szerokości `390px`).
- `flutter analyze lib/presentation/screens/messages/ test/presentation/screens/messages_archive_and_attendance_accepted_test.dart` — `No issues found!`.
