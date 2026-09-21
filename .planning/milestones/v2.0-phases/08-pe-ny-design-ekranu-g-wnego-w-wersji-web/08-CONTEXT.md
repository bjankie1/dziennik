# Phase 8: Pełny design ekranu głównego w wersji web - Context

**Gathered:** 2026-09-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Faza 8 dostarcza kompletne wdrożenie nowego, nowoczesnego ekranu głównego (Pulpit / Dashboard) w wersji webowej i responsywnej, opartego na projekcie graficznym Stitch przygotowanym w `docs/start_page_web_v1/` (`screen.png`, `code.html`, `DESIGN.md`).
Ekran integruje rzeczywiste dane ucznia (Oskar Jankiewicz, LO nr X) pobierane z Librusa / Firestore, zachowując spójność architektury aplikacji Flutter.

</domain>

<decisions>
## Implementation Decisions

### 1. Układ responsywny i nawigacja (Responsive Layout & Navigation)
- **D-01:** Na ekranach desktopowych (szerokość >= 1024px) wdrażamy dedykowany lewy panel boczny (Sidebar, szerokość 256px / w-64) oraz górny nagłówek (Header, wysokość 64px / h-16) jako **wspólną powłokę nawigacyjną (Shell) dla wszystkich widoków aplikacji** (Pulpit, Plan Lekcji, Oceny i Średnie, Frekwencja, Wiadomości i Ogłoszenia), a nie tylko dla strony głównej.
- **D-02:** Główna przestrzeń pulpitu na desktopie wykorzystuje 3-kolumnowy Bento Grid (`lg:grid-cols-12`):
  - Kolumna lewa (`lg:col-span-4`): Harmonogram lekcji na dziś + nadchodzący sprawdzian.
  - Kolumna środkowa (`lg:col-span-5`): Wiadomości i komunikaty z pigułkami filtrów + szkolny komunikat specjalny.
  - Kolumna prawa (`lg:col-span-3`): Ostatnie oceny + frekwencja z miernikiem i celem rocznym + szybkie akcje.
- **D-03:** Na tabletach (768px – 1023px) układ adaptuje się płynnie do 2 kolumn, a na urządzeniach mobilnych (< 768px) zachowuje ergonomiczny układ jednokolumnowy z dolnym paskiem nawigacji (Bottom Navigation Bar) i nagłówkiem mobilnym. Na desktopie dolny pasek nawigacji jest ukryty, a nawigację w 100% przejmuje Sidebar.

### 2. Pasek wyszukiwania w nagłówku (Header Global Search)
- **D-04:** Pasek wyszukiwania w nagłówku ("Szukaj w ocenach, planie, wiadomościach...") odzwierciedla styl z makiety Stitch (`bg-surface-container-low`, zaokrąglenie `rounded-xl`, ikona lupy) i umożliwia dynamiczne filtrowanie oraz szybkie przejście (Command Palette / Search Modal) do pasujących lekcji, ocen i wiadomości.

### 3. Harmonogram dnia i dynamiczny wskaźnik lekcji "W trakcie" (Real-time Lesson Progress)
- **D-05:** Harmonogram dnia prezentuje lekcje z pionowym paskiem kategorii kolorystycznej (zielony dla planowych, pomarańczowy/tertiary dla zastępstw, czerwony dla odwołanych/sprawdzianów, indygo dla bieżącej).
- **D-06:** System w czasie rzeczywistym porównuje aktualną godzinę systemową z przedziałami lekcji:
  - Dla aktualnie trwającej lekcji wyświetla pulsujący badge `W trakcie` (`animate-ping`), oblicza i animuje pasek postępu (np. 65%) oraz czas do zakończenia (`Zostało X min`).
  - Pokazuje temat lekcji oraz nauczyciela i numer sali (z uwzględnieniem ewentualnej zmiany sali / zastępstwa).

### 4. Wiadomości i Komunikaty (Center Column Stream)
- **D-07:** Sekcja wiadomości zawiera przełącznik filtrów (pigułki `Nieprzeczytane`, `Wszystkie`, `Ogłoszenia`), dynamicznie filtrujący listę.
- **D-08:** Karty wiadomości posiadają wskaźnik nieprzeczytania (kropka primary), etykiety pilności (`PILNE`, `DYREKCJA`), nadawcę, datę/godzinę, podgląd treści oraz przycisk szybkiej akcji `Odpowiedz` (otwierający formularz odpowiedzi w wątku) oraz ikonę `Oznacz jako przeczytane`.
- **D-09:** Pod listą wiadomości wyświetlany jest szkolny baner informacyjny (np. konferencja/dzień wolny) z przyciskiem akcji.

### 5. Oceny, Frekwencja i Szybkie Skróty (Right Column Actions)
- **D-10:** Karta ocen prezentuje wskaźnik trendu średniej ważonej (`+0.12 do średniej`), listę ostatnich ocen z kolorowymi kafelkami ocen (np. `5`, `4+`), wagami i przedmiotami oraz linkiem `Zobacz wszystkie oceny`.
- **D-11:** Karta frekwencji zawiera dwukolorowy poziomy pasek postępu z progiem minimalnym 50% i celem rocznym 90%, ostrzeżenie o nieusprawiedliwionych godzinach oraz przycisk `Szybkie usprawiedliwienie (PIN)`.
- **D-12:** Podpięcie kafelków szybkich akcji:
  - Przycisk `Szybkie usprawiedliwienie (PIN)` oraz kafelek `Zgłoś nieobecność` otwierają modal e-Usprawiedliwień z obsługą PIN rodzica i wysyłką do Librusa.
  - Kafelek `Czat / Kontakt z wychowawcą` otwiera formularz nowej wiadomości z automatycznie uzupełnionym wychowawcą.
  - Kafelek `Zadania domowe` oraz `Pełny plan lekcji na cały tydzień` kierują bezpośrednio do widoku terminarza / planu lekcji.

### the agent's Discretion
- Dobór szczegółowych tokenów kolorystycznych i stylów w Flutterze na podstawie `DESIGN.md` (paleta *Academic Precision* oparta na Material 3, barwy `#3525cd`, `#f8f9ff`, `#006c4a`, `#703a00`, `#ba1a1a`).
- Wykorzystanie istniejących providerów Riverpod (`studentProfileProvider`, `todayScheduleProvider`, `recentGradesProvider`, `attendanceProvider`, `messagesProvider`, `syncProvider`).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Visual & Prototype Specifications
- `docs/start_page_web_v1/screen.png` — Główny zrzut ekranu docelowego designu pulpitu.
- `docs/start_page_web_v1/code.html` — Kompletny prototyp HTML/Tailwind z 3-kolumnowym układem Bento Grid i komponentami.
- `docs/start_page_web_v1/DESIGN.md` — Tokeny projektowe (kolory, typografia Plus Jakarta Sans, zaokrąglenia, cienie, wymiary siatki).

### Codebase & Integrations
- `lib/presentation/screens/dashboard/dashboard_screen.dart` — Istniejąca implementacja pulpitu (dane, widgety, obsługa pull-to-refresh i status synchronizacji).
- `lib/presentation/screens/main_navigation_screen.dart` — Główny kontener nawigacyjny (obecnie z dolnym paskiem nawigacji).
- `lib/presentation/screens/messages/compose_message_modal.dart` — Modal tworzenia wiadomości z autocomplete nauczycieli.
- `lib/presentation/screens/attendance/quick_excuse_dialog.dart` — Dialog e-Usprawiedliwień z autoryzacją PIN rodzica.
- `lib/core/theme/app_colors.dart` — Aktualne definicje kolorów aplikacji.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `todayScheduleProvider`: Dostarcza rzeczywiste lekcje na dany dzień (`LessonSlot`), w tym statusy odwołania i zastępstwa.
- `studentProfileProvider`: Zapewnia dane ucznia (Oskar Jankiewicz, klasa, szkoła, frekwencja, średnia, szczęśliwy numerek).
- `recentGradesProvider`: Zwraca najnowsze oceny z wagami i przedmiotami.
- `messagesProvider`: Zwraca listę wątków wiadomości z flagą `isUnread` i datami.
- `attendanceProvider`: Zwraca wpisy frekwencji i nieobecności kwalifikujące się do usprawiedliwienia.
- `quick_excuse_dialog.dart`: Gotowy komponent dialogu do wysyłania e-Usprawiedliwień przez Cloud Function.

### Established Patterns
- Flutter Riverpod (`ConsumerWidget`, `ref.watch`) do reaktywnego bindowania stanu.
- `LayoutBuilder` / `MediaQuery` do responsywnego przełączania układu w zależności od szerokości ekranu (`kDesktopBreakpoint = 1024`).

### Integration Points
- `MainNavigationScreen`: Rozbudowa o boczny `NavigationRail` / `Sidebar` na ekranach desktopowych (>=1024px) oraz ukrywanie dolnego `NavigationBar`.
- `DashboardScreen`: Podział na komponenty desktopowe (Top Banner, ScheduleColumn, MessagesColumn, MetricsColumn) oraz responsywny kontener.

</code_context>

<specifics>
## Specific Ideas
- Wierne odwzorowanie layoutu, typografii i kolorystyki z `docs/start_page_web_v1/code.html`.
- Dynamiczne przeliczanie paska postępu lekcji na żywo za pomocą timera / czasu zegarowego.
- Płynne animacje i hover-states na kafelkach i przyciskach.

</specifics>

<deferred>
## Deferred Ideas
- Pełny czat grupowy z klasą (wymaga odrębnej infrastruktury czatu realtime; na razie skrót kieruje do kontaktu z wychowawcą).
- Pobieranie załączników PDF z lekcji (wymaga dedykowanego scrapera materiałów Librus).

</deferred>

---

*Phase: 08-pe-ny-design-ekranu-g-wnego-w-wersji-web*  
*Context gathered: 2026-09-16*
