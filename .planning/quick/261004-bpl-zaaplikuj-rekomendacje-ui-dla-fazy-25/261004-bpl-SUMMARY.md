---
phase: quick-261004-bpl
plan: 01
status: complete
subsystem: ui
tags: [flutter, ui-review, messages, attendance, accessibility]
completed: 2026-10-04
---

# Quick Task 261004-bpl: Zaaplikuj rekomendacje UI dla Fazy 25 Summary

**Wdrożono wszystkie 3 priorytetowe poprawki oraz drobne usprawnienia typografii i palety kolorów z audytu `25-UI-REVIEW.md`.**

## Accomplishments
- **Ergonomia przycisku `Archiwizuj` / `Przywróć` na karcie wiadomości** (`lib/presentation/screens/messages/messages_screen.dart`): Dodano `constraints: const BoxConstraints(minHeight: 32)` oraz `padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)` z ikoną `14px`, zwiększając wysokość obszaru dotyku z ~23px do 32px.
- **Ujednolicenie komunikatów i czasu trwania `SnackBar`** (`lib/presentation/screens/messages/messages_screen.dart`, `lib/presentation/screens/messages/message_thread_screen.dart`): Zarówno lista wiadomości, jak i widok wątku wyświetlają teraz identyczny komunikat (`Wiadomość przeniesiona do archiwum` / `Przywrócono wiadomość do skrzynki odbiorczej`) przez `4 sekundy` z akcją `Cofnij`.
- **Pełna polska odmiana liczebników w `AcceptedJustificationsSummaryCard`** (`lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart`): Dodano statyczną metodę `formatLessonsCount(int count)` obsługującą pełną regułę fleksyjną (`1 lekcja`, `2–4 / 22–24 lekcje`, `5–21 / 25+ lekcji`).
- **Czytelność plakietek i semantyczne tokeny M3**: Podniesiono rozmiar tekstu plakietek `Auto-archiwum` / `Zarchiwizowana` oraz `Zaakceptowano przez wychowawcę` z `10px` do `11px` i zastąpiono tokeny `Colors.white` / `AppColors.slate900` / `AppColors.slate600` w `AcceptedJustificationsSummaryCard` semantycznymi tokenami `AppColors.surfaceContainerLowest` / `AppColors.onSurface` / `AppColors.onSurfaceVariant`.

## Task Commits
- `26cda74` — `fix(quick-261004-bpl): apply Phase 25 UI review recommendations`
