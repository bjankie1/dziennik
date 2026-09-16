# Phase 5: Nowy interfejs Ocen wg makiety - Context

**Gathered:** 2026-09-16
**Status:** Ready for planning
**Reference Mockup:** `media_1789491587201.png`

<domain>
## Phase Boundary

Przebudowa ekranu ocen (`GradesScreen`), aby był w 100% zgodny z makietą wizualną:
1. **Górny przełącznik semestrów**: Pigułki `[Semestr 1]`, `[Semestr 2]`, `[Roczna]` z prawostronnym przyciskiem filtrów/narzędzi.
2. **Karta Średniej Ważonej Ocen**:
   - Tytuł nagłówka: `ŚREDNIA WAŻONA OCEN`.
   - Główna wartość: np. `4.82` z odchyleniem `↑ +0.14`.
   - Pigułka `Top 5% w 3B` / klasie oraz `Pozycja: 2 / 28`.
   - Pasek stypendium naukowego: `Stypendium naukowe (próg 4.75)` ze stanem `Spełniony (+0.07)`, wielokolorowym paskiem postępu i etykietami `Bazowa: 4.00`, `Cel: 4.75`, `Maks: 6.00`.
3. **Lista przedmiotów**:
   - Nagłówek `Przedmioty [12]` i podtytuł `Kliknij, aby rozwinąć historię`.
   - Karty przedmiotów w stanie zwiniętym:
     - Kolorowa kropka przedmiotu (indywidualna dla każdego przedmiotu).
     - Nazwa przedmiotu i nazwisko nauczyciela (`mgr K. Wiśniewski`).
     - Pigułka średniej ważonej przedmiotu (`4.90`) z podpisem `Ważona` oraz wskaźnikiem rozwijania.
     - **Pigułki ocen w wierszu bez konieczności rozwijania**: kolorystycznie kodowane pigułki np. `5 (w:3)`, `5 (w:3)`, `4+ (w:2)`, `5 (w:1)` (zielone dla 5/6, niebieskie dla 4, pomarańczowe dla 3, czerwone dla 1/2).
   - Karty przedmiotów w stanie rozwiniętym:
     - Nagłówek `SZCZEGÓŁOWY WYKAZ OCEN` i liczba `X oceny cząstkowe`.
     - Kafle poszczególnych ocen:
       - Okrągły znaczek oceny z kolorowym tłem (`5`, `4+`).
       - Tytuł/kategoria (np. `Sprawdzian: Ciągi liczbowe`).
       - Data i waga (`24 Października • Waga: 3`).
       - Komentarz nauczyciela w cudzysłowie w kursywie lub informacja `Brak uwag`.
       - Procent po prawej stronie w subtelnej ramce (np. `100%`, `94%`, `88%`).
</domain>

<decisions>
## Implementation Decisions

### 1. Kolorystyka i komponenty ocen (Pills)
- **D-01:** Pigułki ocen cząstkowych w nagłówku przedmiotu mają jasne tło i ciemny kontrastujący tekst:
  - 5, 5+, 6: zielone tło `#DCFCE7`, tekst `#15803D`.
  - 4, 4+: niebieskie tło `#DBEAFE`, tekst `#1D4ED8`.
  - 3, 3+: bursztynowe/żółte tło `#FEF3C7`, tekst `#B45309`.
  - 1, 2: czerwone tło `#FEE2E2`, tekst `#B91C1C`.
- **D-02:** Format tekstu w pigułce: `[Ocena] (w:[Waga])`, np. `5 (w:3)`.

### 2. Rozwinięcie akordeonu przedmiotu
- **D-03:** Kliknięcie w dowolne miejsce nagłówka przedmiotu płynnie rozwija/zwija szczegółowy wykaz ocen tego przedmiotu.
- **D-04:** Kliknięcie w pojedynczą ocenę (zarówno pigułkę w nagłówku, jak i kafelek w wykazie) otwiera szczegółowy modal oceny (`GradeDetailsModal`).

### 3. Pasek postępu stypendium
- **D-05:** Zakres paska to 4.00 do 6.00. Pozycja progu 4.75 jest wyraźnie zaznaczona, a odcinek powyżej 4.75 zmienia kolor na zielony (`AppColors.secondary` / green).

</decisions>
