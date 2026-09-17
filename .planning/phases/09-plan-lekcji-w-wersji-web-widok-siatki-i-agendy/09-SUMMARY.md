# Phase 9: Plan lekcji w wersji web (Widok siatki i agendy) - Summary

**Execution Date:** 2026-09-17
**Status:** Success
**Requirements:** REQ-TIMETABLE-01, REQ-TIMETABLE-02, REQ-TIMETABLE-03, REQ-TIMETABLE-04

---

## 1. Executive Summary

Zrealizowano pełny, nowoczesny moduł planu lekcji w wersji web zoptymalizowany dla ekranów desktopowych, tabletów oraz smartfonów, oparty na makietach graficznych (`docs/plan_lekcji_v1` oraz `docs/plan lekcji agenda`).

Wdrożono:
1. **Dwuwarstwową prezentację planu**:
   - **Widok siatki tygodniowej (Grid View)**: Pełny tydzień poniedziałek–piątek z kolumną godzin (1–8+), kafelkami lekcji z salami, nauczycielami, tematami i kolorystycznymi statusami (normalna, zastępstwo, odwołana, sprawdzian), wyróżnieniem dzisiejszego dnia oraz modalem ze szczegółami po kliknięciu.
   - **Widok agendy dziennej (Agenda View)**: Chronologiczna oś czasu dla wybranego dnia z wyróżnieniem trwającej lekcji („Trwa teraz • Zostało X min”), rozszerzonymi informacjami o temacie, zadaniach domowych, materiałach oraz powodach odwołań/zastępstw.
2. **Pasek nawigacji tygodnia (`WeekNavigatorBar`)**:
   - Nawigacja poprzedni/następny tydzień z datami w formacie `16 – 20 września 2024`, wskaźnik „Aktualny tydzień”, przycisk „Dzisiaj”, przyciski eksportu/synchronizacji oraz przełącznik trybów widoku (Siatka / Agenda).
3. **Pasek podsumowania tygodnia (`WeeklySummaryBanner`)**:
   - 4 interaktywne kafelki metryk: Łączna liczba godzin lekcyjnych, Zastępstwa, Sprawdziany, Odwołane lekcje – z możliwością kliknięcia w celu filtrowania/podświetlenia odpowiednich lekcji w siatce i agendzie.
4. **Wspólna nawigacja i responsywność**:
   - Pełna integracja z globalnym paskiem bocznym nawigacji (`AppSidebar`) oraz nagłówkiem desktopowym (`AppDesktopHeader`).
   - Automatyczny wybór domyślnego widoku zależnie od szerokości ekranu (Siatka na desktopie >= 1024px, Agenda na telefonach < 768px, kompaktowa 5-kolumnowa siatka na tabletach 768–1023px).
   - Pełna synchronizacja wybranego dnia tygodnia pomiędzy widokiem siatki i agendy.

---

## 2. Detailed Deliverables by Plan

### Plan 09-01: Data & State Layer (`commit 1ee5f87`)
- **`lib/domain/models/lesson_slot.dart`**:
  - Rozszerzono model o pola: `topic`, `homework`, `materials`, `eventType`, `eventTitle`.
  - Zaktualizowano `toMap()` i `fromMap()` zachowując kompatybilność wsteczną z Firestore i cache.
- **`lib/data/mock/mock_data.dart`**:
  - Utworzono bogaty zestaw danych testowych dla pełnego tygodnia poniedziałek–piątek (`weekSchedule`), odwzorowujący stany z makiet (zastępstwa, odwołania, sprawdziany z matematyki, trwające lekcje).
- **`lib/data/repositories/school_repository.dart` & implementacje**:
  - Dodano sygnaturę i implementacje `getWeekSchedule({DateTime? weekStart})` w `SchoolRepository`, `MockSchoolRepository` oraz `FirestoreSchoolRepository`.
- **`lib/presentation/providers/school_providers.dart`**:
  - Wdrożono riverpod providery: `weekScheduleProvider`, `selectedScheduleDayProvider` (`SelectedScheduleDayNotifier`), `weekScheduleFilterProvider` (`WeekScheduleFilterNotifier`), oraz `weeklyScheduleStatsProvider`.

### Plan 09-02: Weekly Grid View Component & Modal (`commit 676ede4`)
- **`lib/presentation/screens/schedule/widgets/week_navigator_bar.dart`**:
  - Pasek nawigacji tygodniowej z tytułem klasy (`Klasa 3B • Profil matematyczno-fizyczny`), zakresem dat, badge'em aktualnego tygodnia, przyciskiem „Dzisiaj” oraz przełącznikiem segmentowym widoków.
- **`lib/presentation/screens/schedule/widgets/weekly_summary_banner.dart`**:
  - 4 interaktywne kafelki podsumowania tygodnia (Godziny, Zastępstwa, Sprawdziany, Odwołane) działające jako przełączniki filtrów.
- **`lib/presentation/screens/schedule/widgets/lesson_details_modal.dart`**:
  - Dialog modalny wyświetlający pełne dane o lekcji (przedmiot, sala, nauczyciel, godziny, status, powód zastępstwa/odwołania, temat lekcji, zadanie domowe oraz materiały).
- **`lib/presentation/screens/schedule/widgets/weekly_grid_view.dart`**:
  - Kolumna godzinowa (1–8) + 5 kolumn dni tygodnia.
  - Wyróżnienie dzisiejszego dnia kolorem akcentu w nagłówku kolumny.
  - Obsługa kliknięcia w nagłówek dnia (automatyczne przejście do agendy dla tego dnia).
  - Obsługa kliknięcia w kafelek lekcji (otwarcie modalu ze szczegółami).
  - Płynne skalowanie dla tabletów (kompaktowy układ 5 kolumn bez poziomego paska przewijania).

### Plan 09-03: Agenda View & Screen Integration (`commit 40093f7`)
- **`lib/presentation/screens/schedule/widgets/agenda_lesson_card.dart`**:
  - Wskaźnik statusu na żywo („Trwa teraz • Zostało X min”) z pulsującą zieloną kropką.
  - Wizualne przekreślenie i czerwone ostrzeżenie dla lekcji odwołanych.
  - Bursztynowa pigułka i informacja o nowym nauczycielu/sali dla zastępstw.
  - Karty szczegółów: temat lekcji, zadanie domowe (z terminem), materiały na zajęcia.
- **`lib/presentation/screens/schedule/widgets/agenda_view.dart`**:
  - Poziomy pasek dni tygodnia (Pn–Pt) ze wskaźnikami anomalii (kropki dla sprawdzianów, zastępstw, odwołań).
  - Nagłówek wybranego dnia z pełną datą i podsumowaniem godzin.
  - Chronologiczna lista kart lekcji.
- **`lib/presentation/screens/schedule/schedule_screen.dart`**:
  - Główny kontener ekranu planu lekcji zintegrowany ze wspólnym layoutem `AppSidebar` i `AppDesktopHeader`.
  - Responsywne automatyczne ustawianie domyślnego widoku zależnie od szerokości viewportu (`LayoutBuilder`).
  - Wsparcie dla odświeżania danych (`RefreshIndicator`).

---

## 3. Verification & Deployment

- **Analiza statyczna**: `flutter analyze` — zakończona wynikiem `No issues found!`.
- **Kompilacja**: `flutter build web --release` — zbudowano bezbłędnie (kod wyjścia 0).
- **Hosting**: Wdrożono na Firebase Hosting (`https://lepsza-szkola.web.app`).

---

## 4. Git Commits
- `1ee5f87` — feat(schedule): extend LessonSlot model and add weekSchedule providers
- `676ede4` — feat(schedule): implement weekly grid view, navigator bar, summary banner and lesson details modal
- `40093f7` — feat(schedule): implement agenda view and integrate full responsive schedule screen
