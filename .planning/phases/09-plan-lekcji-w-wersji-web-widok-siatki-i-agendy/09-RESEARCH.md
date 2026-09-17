# Phase 9: Plan lekcji w wersji web (Widok siatki i agendy) - Research

**Date:** 2026-09-17
**Status:** Complete
**Confidence:** HIGH

---

## User Constraints & Locked Decisions

### From CONTEXT.md
- **D-01 (Układ i domyślny widok):** Na desktopie (>= 1024px) domyślnym widokiem jest pełna **Siatka tygodniowa (Grid)**, a na telefonach (< 768px) **Agenda dzienna**. W nagłówku znajduje się przełącznik `Siatka / Agenda` pozwalający na zmianę trybu w dowolnej chwili.
- **D-02 (Synchronizacja dnia):** Przełączenie z Siatki do Agendy lub kliknięcie dnia w Siatce zachowuje kontekst wskazanego dnia (np. Czwartek w Siatce -> Czwartek w Agendzie).
- **D-03 (Tablety 768px - 1023px):** Kompaktowa siatka mieszcząca 5 dni bez poziomego paska przewijania (zoptymalizowane kolumny, skrócone nazwy sal i przedmiotów).
- **D-04 (Interakcja w Siatce):** Kliknięcie kafelka lekcji w Siatce otwiera modal / dialog ze szczegółami zajęć (pełna nazwa przedmiotu, sala, nauczyciel, temat lekcji, powód zastępstwa/odwołania, sprawdziany/zadania) bez opuszczania widoku tygodnia.
- **D-05 (Pasek statystyk):** 4 kafelki podsumowujące tydzień: łączny wymiar godzin, zastępstwa, sprawdziany, lekcje odwołane.
- **D-06 (Interaktywność kafelków):** Kliknięcie kafelka statystyk (np. Zastępstwa lub Sprawdziany) podświetla lub filtruje powiązane lekcje w siatce.
- **D-07 (Lekcja na żywo w Agendzie):** Trwająca lekcja otrzymuje szmaragdowy pasek boczny, pulsujący indykator `animate-ping`, licznik czasu do końca `Trwa teraz • Zostało X min` oraz rozszerzony boks tematu.
- **D-08 (Odwołania i zastępstwa w Agendzie):** Odwołane lekcje są przekreślone z czerwonym paskiem bocznym, plakietką i ramką wyjaśniającą. Zastępstwa mają pomarańczowy pasek, przekreślone pierwotne dane i wyróżnioną nową salę/nauczyciela.
- **D-09 (Model LessonSlot):** Rozszerzenie `LessonSlot` o opcjonalne pola `topic`, `homework`, `materials`, `eventType`, `eventTitle` z eleganckim ukrywaniem sekcji gdy brak danych.

---

## Technical Stack & Existing Codebase

### 1. Flutter Framework & Navigation Shell
- Widok jest ładowany wewnątrz istniejącej powłoki `MainNavigationScreen` pod indeksem `1` (`ScheduleScreen`).
- Na desktopie (>=1024px) aplikacja posiada stały `AppSidebar` (256px) oraz `AppDesktopHeader` (64px). `ScheduleScreen` wypełnia pozostałą przestrzeń `Expanded`.
- Stylistyka oparta na Material 3, fontach **Plus Jakarta Sans** i palecie `AppColors` (*Academic Precision* z `docs/plan_lekcji_v1/DESIGN.md`).

### 2. State Management & Providers
- Obecnie w `lib/presentation/providers/school_providers.dart`:
  - `todayScheduleProvider` -> `List<LessonSlot>`
  - `dayScheduleProvider(dayOfWeek)` -> `List<LessonSlot>`
  - `upcomingEventsProvider` -> `List<UpcomingEvent>` (sprawdziany i wydarzenia terminarza)
- Potrzebne nowe / rozszerzone providerzy:
  - `weekScheduleProvider` (FutureProvider zwracający `Map<int, List<LessonSlot>>` dla dni 1..5)
  - `weekScheduleFilterProvider` (StateProvider filtrujący podświetlenia: null, 'substitutions', 'exams', 'canceled')
  - `activeLessonSlotProvider` (Stream/Timer Provider wyliczający w czasie rzeczywistym aktualną lekcję i minuty do dzwonka)

### 3. Model `LessonSlot` (`lib/domain/models/lesson_slot.dart`)
- Aktualne pola:
  - `lessonNumber`, `subjectName`, `originalSubjectName`, `startTime`, `endTime`, `room`, `originalRoom`, `teacher`, `substituteTeacher`, `status`, `statusNote`, `progressFraction`.
- Nowe opcjonalne pola:
  - `topic` (temat lekcji)
  - `homework` (zadanie domowe)
  - `materials` (podręcznik / pomoce naukowe)
  - `eventType` (np. "Sprawdzian", "Kartkówka")
  - `eventTitle` (np. "Reakcje redox")

### 4. Mock & Firestore Repositories
- `MockData` zawiera dane demonstracyjne dla `todaySchedule`. Należy dodać `weekSchedule` z bogatymi danymi dla wszystkich 5 dni tygodnia (w tym zastępstwa, odwołania, sprawdziany i tematy lekcji z makiet).
- `FirestoreSchoolRepository`: `_parseTimetableForDay` filtruje pobrany z Firestore `rawList` po `dayOfWeek`. Jeśli terminarz zawiera wydarzenia dla danego dnia i godziny, powiązujemy je z `LessonSlot`.

---

## UI Components Breakdown

1. **`ScheduleHeader` & Navigation Controls:**
   - Wybór tygodnia (poprzedni / następny tydzień, etykieta "21 – 25 Października 2024", badge "Aktualny tydzień", przycisk "Dzisiaj").
   - Informacja o klasie i wychowawcy ("Klasa 3B • Profil matematyczno-fizyczno-chemiczny • Wychowawca: mgr K. Wiśniewski").
   - Segmented view control: `Siatka` (ikona `grid_view`), `Agenda` (ikona `view_agenda`).
   - Przyciski narzędziowe: Drukuj/PDF, Synchronizuj z kalendarzem (iCal / Google / Apple).

2. **`WeeklySummaryBanner` (4 kafelki alertów):**
   - 1. Łączny czas zajęć (np. `32 godz.`)
   - 2. Zastępstwa (np. `2 Zastępstwa` - Wt: Geografia, Czw: Matematyka)
   - 3. Sprawdziany (np. `2 Sprawdziany` - Czw: Chemia, Pt: J. Polski)
   - 4. Lekcje odwołane (np. `1 Lekcja odwołana` - Czw: 08:00 Fizyka)
   - Kafelki posiadają stan zaznaczenia/aktywności (kliknięcie filtruje lub podświetla lekcje w siatce).

3. **`WeeklyGridView` (Siatka tygodniowa):**
   - Tabela Poniedziałek - Piątek z kolumną godzin lekcyjnych (1. Lekcja: 08:00-08:45, 2. Lekcja: 08:50-09:35, itd.).
   - Nagłówki dni z kropkami statusów (zielona = planowo, pomarańczowa = zastępstwo, czerwona = odwołana, indygo = sprawdzian) oraz wyróżnieniem dnia dzisiejszego ("Dziś").
   - Kafelki lekcji w komórkach: nazwa przedmiotu, numer sali (badge `s. 204`), nauczyciel, temat lekcji, wskaźnik zastępstwa/odwołania/sprawdzianu.
   - Wersja kompaktowa dla tabletów (768px-1023px) mieszcząca 5 kolumn.
   - Kliknięcie kafelka -> `LessonDetailsModal`.

4. **`AgendaView` (Widok dzienny):**
   - Poziomy pasek wyboru dnia tygodnia (Pn-Pt) z kropkami anomalii.
   - Karty lekcji:
     - Odwołana: czerwony pasek, przekreślone godziny i nazwa przedmiotu, ramka z powodem i informacją o starcie zajęć.
     - Trwa teraz: zielony pasek, pulsujący wskaźnik, licznik minut do końca, rozszerzony boks z tematem, materiałami i zadaniem domowym.
     - Zastępstwo: pomarańczowy pasek, przekreślona sala i nauczyciel, wyróżnione nowe dane.
     - Planowa: standardowy czysty kafelek z tematem i zadaniem.

5. **`LessonDetailsModal` (Modal szczegółów lekcji):**
   - Estetyczne okno dialogowe wywoływane z Siatki:
     - Nagłówek z numerem lekcji, godzinami, przedmiotem i statusem.
     - Sekcja sali i nauczyciela (z informacją o zastępstwie/zmianie sali).
     - Sekcja tematu lekcji, materiałów i zadań domowych.
     - Informacja o sprawdzianie / kartkówce (jeśli dotyczy).

---

## Verification Plan
1. `flutter analyze` — brak jakichkolwiek błędów i ostrzeżeń lintera.
2. Testy widoków w przeglądarce:
   - Sprawdzenie desktopu (>=1024px): domyślna siatka, podsumowanie 4 kafelków, interaktywne filtrowanie, kliknięcie kafelka otwiera modal detali.
   - Sprawdzenie tabletów (768px-1023px): kompaktowa siatka mieszcząca 5 dni bez paska przewijania.
   - Sprawdzenie telefonów (<768px): domyślna agenda dzienna, przełącznik dni, karta trwającej lekcji z pulsującym wskaźnikiem.
   - Przełącznik Siatka / Agenda w nagłówku z zachowaniem wybranego dnia.
3. `flutter build web --release` i wdrożenie na Firebase Hosting.
