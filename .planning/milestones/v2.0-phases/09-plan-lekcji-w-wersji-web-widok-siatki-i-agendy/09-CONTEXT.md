# Phase 9: Plan lekcji w wersji web (Widok siatki i agendy) - Context

**Gathered:** 2026-09-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Faza 9 dostarcza wdrożenie nowoczesnego, desktopowego i responsywnego planu lekcji w wersji web z dwoma widokami: pełną siatką tygodniową (Poniedziałek – Piątek) oraz szczegółową agendą dzienną, w oparciu o makiety `docs/plan_lekcji_v1/` oraz `docs/plan lekcji agenda/`.
Widok integruje się z globalną powłoką aplikacji (wspólny `AppSidebar` i `AppDesktopHeader`), uwzględnia dynamiczny status trwającej lekcji na żywo, odwołania, zastępstwa, podsumowanie tygodnia oraz interakcję ze szczegółami zajęć.

</domain>

<decisions>
## Implementation Decisions

### 1. Domyślny widok i zachowanie responsywne (Layout & Breakpoints)
- **D-01:** Domyślny widok po otwarciu ekranu Planu Lekcji na desktopie (szerokość >= 1024px) to pełna tygodniowa **Siatka (Grid)**, natomiast na urządzeniach mobilnych (< 768px) to **Agenda (Plan dnia)**. Na górnym pasku znajduje się segmentowany przełącznik `Siatka / Agenda` pozwalający użytkownikowi na swobodne przełączanie trybu w dowolnym momencie.
- **D-02:** **Synchronizacja wybranego dnia:** Przełączenie z Siatki do Agendy (lub kliknięcie nagłówka dnia w Siatce) zachowuje kontekst wskazanego dnia (np. kliknięcie Czwartku w Siatce otwiera Czwartek w Agendzie).
- **D-03:** **Siatka na tabletach (768px – 1023px):** Kompaktowa siatka bez konieczności przewijania poziomego (zoptymalizowane szerokości kolumn, skrócone nazwy przedmiotów i sal z zachowaniem pełnej czytelności 5 dni).
- **D-04:** **Interakcja z lekcjami w Siatce:** Kliknięcie kafelka lekcji w widoku Siatki otwiera elegancki modal / dialog ze szczegółami zajęć (pełna nazwa przedmiotu, sala, nauczyciel, temat lekcji, powód zastępstwa/odwołania, powiązane sprawdziany/zadania) bez opuszczania widoku tygodnia.

### 2. Pasek statystyk i alertów tygodnia (Weekly Summary Banner)
- **D-05:** Na górze widoku Siatki wyświetlany jest pasek 4 kafelków podsumowujących tydzień (Łączna liczba godzin lekcyjnych, Liczba zastępstw, Nadchodzące sprawdziany w danym tygodniu, Lekcje odwołane).
- **D-06:** **Interaktywność kafelków:** Kliknięcie kafelka (np. Zastępstwa lub Sprawdziany) podświetla lub filtruje powiązane lekcje w siatce tygodniowej, ułatwiając szybkie odnalezienie nietypowych zdarzeń.

### 3. Prezentacja lekcji w widoku Agendy (Agenda View Details)
- **D-07:** **Bieżąca lekcja w czasie rzeczywistym:** Lekcja trwająca w danej chwili otrzymuje wyróżnienie zgodnie z makietą (szmaragdowy pasek boczny, pulsujący wskaźnik na żywo `animate-ping`, licznik minut do końca zajęć `Trwa teraz • Zostało X min` oraz powiększony boks z tematem lekcji).
- **D-08:** **Lekcje odwołane i zastępstwa:** Odwołane lekcje są wyraźnie przekreślone z czerwonym paskiem bocznym, plakietką `Lekcja odwołana` oraz ramką z powodem (np. zwolnienie lekarskie). Zastępstwa posiadają pomarańczowy pasek boczny, przekreślenie pierwotnej sali/nauczyciela i wyróżnienie nowej sali/nauczyciela.
- **D-09:** **Model danych (LessonSlot):** Model `LessonSlot` zostaje rozszerzony o opcjonalne pola `topic`, `homework`, `materials`. Sekcje te wyświetlane są dynamicznie w Agendzie i modalu szczegółów tylko wtedy, gdy dane są dostępne (z terminarza lub bazy).

### the agent's Discretion
- Dobór tokenów kolorystycznych i zaokrągleń zgodnych z Material 3 i makietami (`Academic Precision`).
- Spójne zintegrowanie paska nawigacyjnego tygodnia (przyciski `chevron_left`, `chevron_right`, wskaźnik `Aktualny tydzień` oraz przycisk `Dzisiaj`).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Visual & Prototype Specifications
- `docs/plan_lekcji_v1/screen.png` — Główny zrzut ekranu docelowego widoku Siatki tygodniowej (Grid).
- `docs/plan_lekcji_v1/code.html` — Kompletny prototyp HTML/Tailwind siatki tygodniowej z kafelkami podsumowania, nagłówkiem nawigacji i kolumnami dni.
- `docs/plan_lekcji_v1/DESIGN.md` — Tokeny kolorystyczne, typografia Plus Jakarta Sans, specyfikacja siatki i zaokrągleń.
- `docs/plan lekcji agenda/screen.png` — Główny zrzut ekranu docelowego widoku Agendy dziennej (Agenda).
- `docs/plan lekcji agenda/code.html` — Kompletny prototyp HTML/Tailwind widoku agendy z dynamicznymi stanami lekcji (aktywna, odwołana, zastępstwo).
- `docs/plan lekcji agenda/DESIGN.md` — Specyfikacja stylów agendy.

### Existing Architecture & Navigation
- `lib/presentation/widgets/layout/app_shell.dart` — Wspólna powłoka nawigacyjna z paskiem bocznym `AppSidebar` i nagłówkiem `AppDesktopHeader`.
- `lib/presentation/screens/schedule/schedule_screen.dart` — Istniejący ekran planu lekcji.
- `lib/domain/models/lesson_slot.dart` — Model lekcji `LessonSlot` oraz `UpcomingEvent`.
- `lib/presentation/providers/school_providers.dart` — Providerzy `todayScheduleProvider`, `dayScheduleProvider`, `upcomingEventsProvider`.

</canonical_refs>
