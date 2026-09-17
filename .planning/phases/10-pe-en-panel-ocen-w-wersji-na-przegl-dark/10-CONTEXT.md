# Phase 10: Pełen panel ocen w wersji na przeglądarkę - Context

**Gathered:** 2026-09-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Faza 10 dostarcza kompleksowe wdrożenie nowoczesnego, pełnego panelu ocen w wersji na przeglądarkę (desktop/tablet/mobile) na podstawie makiet graficznych `docs/panel ocen` (`docs/panel_ocen.zip`) oraz `docs/szczegóły oceny` (`docs/szczegoly_oceny.zip`).
Panel integruje się z globalną powłoką aplikacji (wspólny `AppSidebar` i `AppDesktopHeader`) i dostarcza:
1. Dwukolumnowy układ Master-Detail na desktopie (tabela przedmiotów po lewej, panel inspekcji z wykazem ocen po prawej).
2. Pasek KPI i metryk akademickich: Karta średniej ważonej z trendem i lokatą w klasie, karta rozkładu ocen 1-6 (histogram słupkowy ze statystykami).
3. Wykres trajektorii średniej ocen w semestrze (linia ucznia vs średnia klasy).
4. Wysuwaną z prawej krawędzi szufladę (Side Sheet / Drawer) ze szczegółami wybranej oceny (duża ocena, kategoria, waga, data, nauczyciel, pełny komentarz oraz kalkulator wpływu na średnią).
5. Pełną responsywność: Master-Detail na ekranach desktopowych (>=1024px), a na tabletach i smartfonach (<1024px) jednokomumnowy widok z zachowaniem pigułek ocen i akordeonów.

</domain>

<decisions>
## Implementation Decisions

### 1. Układ Master-Detail i responsywność (Layout & Breakpoints)
- **D-01:** **Desktop (>=1024px):** Pełny dwukolumnowy układ Master-Detail. Lewa kolumna (~68% szerokości, 8/12 kolumn) zawiera listę przedmiotów (Ledger Table), legendę wag, wyszukiwarkę oraz dolny wykres trajektorii średniej. Prawa kolumna (~32% szerokości, 4/12 kolumn) zawiera panel inspekcji wybranego przedmiotu.
- **D-02:** **Tablety i smartfony (<1024px):** Jednokolumnowy układ zoptymalizowany pod dotyk, zachowujący dotychczasowe kafelki przedmiotów z pigułkami ocen w wierszu oraz rozwijanymi akordeonami szczegółów.
- **D-03:** **Domyślny stan zaznaczenia:** Po wejściu na ekran na desktopie żaden przedmiot nie jest domyślnie zaznaczony. Prawy panel inspekcji wyświetla estetyczny stan pusty (Empty State) z ikoną i zachętą: „Wybierz przedmiot z tabeli po lewej stronie, aby wyświetlić szczegółowy rejestr ocen i statystyki”.

### 2. Interakcja z tabelą i ocenami (Click Behaviors)
- **D-04:** **Wybór przedmiotu w tabeli:** Kliknięcie wiersza przedmiotu w lewej tabeli zaznacza ten przedmiot (wiersz wyróżniony lewym 4px indygo paskiem i aktywnym tłem) oraz natychmiast ładuje jego szczegóły do prawego panelu inspekcji.
- **D-05:** **Kliknięcie pigułki oceny w tabeli:** Kliknięcie w pojedynczą pigułkę oceny (np. `5 w:3`) bezpośrednio w tabeli otwiera szufladę boczną (Side Sheet / Drawer) ze szczegółami tej konkretnej oceny, NIE zmieniając zaznaczenia przedmiotu w prawym panelu inspekcji.

### 3. Szuflada szczegółów oceny (Grade Details Side Sheet / Drawer)
- **D-06:** **Format prezentacji:** Na ekranach desktopowych szczegóły oceny otwierają się jako wysuwana z prawej krawędzi ekranu szuflada boczna (Side Sheet / Drawer o szerokości ~480–520px) z animacją slide-in, przyciemnieniem tła (scrim), nagłówkiem z przyciskiem zamknięcia (X) i możliwością zamknięcia klawiszem Esc lub kliknięciem w tło. Na smartfonach i tabletach pozostaje sprawdzony arkusz dolny (Bottom Sheet).
- **D-07:** **Zawartość szuflady:** Pełne odwzorowanie makiety `docs/szczegóły oceny`:
  - Duży wyróżniony badge oceny (np. `5 B. Dobra`), pigułka kategorii (`Odpowiedź ustna`) i wagi (`Waga klasyfikacyjna: 3`).
  - Tytuł/temat oceny (np. `Kolory w chemii nieorganicznej`).
  - Metadane: data wystawienia, nauczyciel, procent punktów, kategoria, liczona do średniej.
  - Komentarz nauczyciela w czytelnej ramce ze stylizacją cytatu.
  - Wizualizator dynamicznego wpływu oceny na średnią przedmiotu i średnią ogólną (`Średnia przed: 4.88 → po: 4.92 (+0.04)`).

### 4. Wizualizacja danych i metryki akademickie (Data Viz & KPIs)
- **D-08:** **Karta rozkładu ocen cząstkowych:** Słupkowy histogram ocen w skali MEN (1–6) pokazujący liczbę ocen cząstkowych ucznia w semestrze z kolorystycznymi wyróżnieniami (bursztyn dla 3, indygo dla 4-5, szmaragd dla 6) oraz wskaźnikiem bezpieczeństwa (np. „0 zagrożeń • 100% pozytywnych”).
- **D-09:** **Karta średniej ważonej:** Eksponuje dużą wartość średniej (np. 4.82), wskaźnik trendu (+0.14) oraz informację o lokacie ucznia w klasie (np. „Top 5% w klasie 3B (2. lokata na 28 uczniów)”).
- **D-10:** **Wykres trajektorii średniej:** Komponent wykresu liniowego/obszarowego z łagodną krzywą (Spline/Bézier), gradientowym wypełnieniem, punktami pomiarowymi w czasie oraz przerywaną linią referencyjną średniej klasy.

### the agent's Discretion
- Dobór tokenów kolorystycznych i zaokrągleń zgodnych z Material 3 i specyfikacją `Academic Precision` (`DESIGN.md`).
- Integracja paska zakładek semestrów (Semestr 1, Semestr 2, Klasyfikacja Roczna) oraz paska akcji (w tym podpięcie przycisku `Przelicz GPA` pod istniejący `AverageSimulatorModal`).
- Generowanie punktów trajektorii średniej na osi czasu na podstawie rzeczywistych/dostępnych dat ocen ucznia.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Visual & Prototype Specifications
- `docs/panel ocen/screen.png` — Główny zrzut ekranu docelowego widoku panelu ocen na desktopie (Master-Detail, KPI, Trajektoria).
- `docs/panel ocen/code.html` — Prototyp HTML/Tailwind panelu ocen z tabelą lewą, panelem inspekcji prawym i wykresem trajektorii.
- `docs/panel ocen/DESIGN.md` — Specyfikacja stylów, tokenów kolorystycznych i typografii Plus Jakarta Sans.
- `docs/szczegóły oceny/screen.png` — Zrzut ekranu szczegółów pojedynczej oceny.
- `docs/szczegóły oceny/code.html` — Prototyp HTML/Tailwind szczegółów oceny z metrykami i wpływem na średnią.
- `docs/szczegóły oceny/DESIGN.md` — Specyfikacja stylów okna/szuflady szczegółów oceny.

### Existing Architecture & Navigation
- `lib/presentation/screens/grades/grades_screen.dart` — Istniejący ekran ocen (moduł semestralny, kafelki przedmiotów).
- `lib/presentation/screens/grades/grade_details_modal.dart` — Dotychczasowy modal szczegółów oceny.
- `lib/presentation/screens/grades/average_simulator_modal.dart` — Symulator średniej GPA.
- `lib/presentation/providers/school_providers.dart` — Providery przedmiotów (`subjectsProvider`), ocen i profilu.
- `lib/domain/models/grade.dart` oraz `lib/domain/models/subject.dart` — Modele domenowe ocen i przedmiotów.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppSidebar` & `AppDesktopHeader` (`lib/presentation/widgets/`): Globalna powłoka desktopowa zapewniająca spójny nagłówek, wyszukiwarkę i pasek boczny.
- `GradeDetailsModal` (`lib/presentation/screens/grades/grade_details_modal.dart`): Istniejący arkusz szczegółów oceny, który można rozszerzyć o wariant desktopowego Side Sheet / Drawer.
- `AverageSimulatorModal` (`lib/presentation/screens/grades/average_simulator_modal.dart`): Istniejący modal symulacji ocen, gotowy do podpięcia pod przycisk „Przelicz GPA”.
- `AppColors` (`lib/core/theme/app_colors.dart`): Tokeny barw Material Design 3.

### Established Patterns
- Riverpod 3.x z `NotifierProvider` i `Provider`.
- Responsywny podział `LayoutBuilder` (desktop >= 1024px vs mobile/tablet < 1024px).
- Formatowanie dat w języku polskim (`intl` i lokalne helpery).

### Integration Points
- `MainNavigationScreen`: Zakładka Oceny i Średnie (index 2).
- `school_providers.dart`: Stan ocen, przedmiotów, średnich ważonych.

</code_context>

<specifics>
## Specific Ideas

- Użytkownik w zapytaniu początkowym wyraźnie zaznaczył:
  - „Zwróć uwagę że można wybrać przedmiot aby w prawej części zobaczyć szczegóły ocen.”
  - „Po kliknięciu na ocenę pojawią się szczegóły w szufladzie - @[docs/szczegoly_oceny.zip]”.
- Prawy panel inspekcji przedmiotu powinien dynamicznie aktualizować się po kliknięciu wiersza przedmiotu w lewej tabeli.
- Kliknięcie w konkretną ocenę (zarówno w tabeli, jak i w panelu inspekcji) powinno wysuwać szufladę boczną (Drawer) ze szczegółami tej oceny.

</specifics>

<deferred>
## Deferred Ideas

- None — dyskusja dotyczyła wyłącznie zakresu Fazy 10.

</deferred>

---

*Phase: 10-pe-en-panel-ocen-w-wersji-na-przegl-dark*
*Context gathered: 2026-09-17*
