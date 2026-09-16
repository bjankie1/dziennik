# Phase 6: Moduł usprawiedliwiania nieobecności wg makiety - Context

**Gathered:** 2026-09-16 (po dyskusji z użytkownikiem `/gsd-discuss-phase 6`)
**Status:** Decisions Locked
**Reference Mockup:** `media_1789491681801.png`

<domain>
## Phase Boundary

Przebudowa modułu frekwencji i e-usprawiedliwień (`AttendanceScreen`), aby był w 100% zgodny z makietą wizualną `media_1789491681801.png`:
1. **Karta Stanu Semestru (Bento Header)**:
   - Okrągły wskaźnik frekwencji (np. `94.2% FREKWENCJA`) z grubym obrysem w kolorze szmaragdowym `#006C4A` / `#059669`.
   - Etykieta `Stan semestru` oraz pigułka `✔ Cel osiągnięty` (jasnozielone tło `#DCFCE7`, zielony tekst `#15803D`).
   - Tekst progowy: `Min. ustawowe: 50% • Cel szkoły: 90%`.
   - Poziomy pasek postępu pod tekstem progowym.
   - Trzy kropki legendy: zielona `142 obecne`, czerwona `6 opuszczonych`, bursztynowa `2 spóźn.`.
   - Trzy kolumny podsumowujące: `142` (Obecności), `3 / 3` (Nieusp. / Usp. - czerwone 3, szare / 3), `2` (Spóźnienia).
2. **Filtry kafelkowe**:
   - Pigułki: `Wszystkie`, `• Do usprawiedliwienia (3)` (z czerwoną kropką i czerwonawym tłem), `Usprawiedliwione`.
   - **Domyślnie aktywna zakładka:** `• Do usprawiedliwienia`, aby użytkownik od razu widział godziny wymagające interwencji.
3. **Nagłówek sekcji zgłoszeń**:
   - Ikona filtrów/suwaków + `Zgłoszenia nieobecności`.
   - Przycisk akcji po prawej stronie: `Odznacz wszystkie` / `Zaznacz wszystkie`.
4. **Zgrupowane dni i wiersze lekcji**:
   - Nagłówek dnia w zaokrąglonym kafelku z ikoną kalendarza i pełną polską datą (np. `Wtorek, 22 Października 2024`).
   - Pigułka stanu dnia po prawej: `2 DO DECYZJI` (czerwona) lub `ROZLICZONE` (zielona).
   - Każda lekcja jako osobny kafelek z pionowym paskiem po lewej stronie (czerwony dla nieobecności, zielony dla obecnej/usprawiedliwionej).
   - Checkbox wyboru (lub kłódka dla rozliczonych).
   - Nazwa lekcji i numer (np. `Lekcja 1: Fizyka`), godziny lekcji (np. `08:00 — 08:45`).
   - Sala i nauczyciel (np. `Sala 14 • mgr J. Wiśniewski`).
   - Stan tekstowy: czerwona kropka `• Nieobecność nieusprawiedliwiona` lub zielona kropka `• Usprawiedliwiona`.
5. **Dolny panel wyboru szybkiego powodu (Floating Justification Dock)**:
   - Pojawia się płynnie u dołu ekranu nad paskiem nawigacji po zaznaczeniu lekcji (`_selectedIds.isNotEmpty`).
   - Zaokrąglony panel z cieniem, niebieska okrągła pigułka z liczbą wybranych lekcji oraz tytuł `Wybrano lekcje do usprawiedliwienia`.
   - Podtytuł `WYBIERZ SZYBKI POWÓD:`.
   - Pigułki szybkich powodów: `Choroba`, `Wizyta lekarska` (aktywny: fioletowy obrys i fioletowy tekst), `Sprawy rodzinne`, `Zawody sportowe`, opcja wpisania własnego powodu.
   - Główny przycisk: `Wyślij usprawiedliwienie (X lekcje) →`.
   - Informacja o autoryzacji: `Wymagane zatwierdzenie kodem PIN rodzica w następnym kroku`.
   - Dialog wprowadzania 4-cyfrowego PIN-u rodzica (domyślny kod PIN "1234") z natychmiastowym zapisem i wysłaniem wniosku.
</domain>

<decisions>
## Implementation Decisions (Uzgodnione z użytkownikiem)

### 1. Rozszerzenie modelu AttendanceRecord
- **D-01:** Dodać opcjonalne pola `final String? classroom;` (np. "Sala 14") oraz `final String? teacherName;` (np. "mgr J. Wiśniewski") do `AttendanceRecord`, aby karta lekcji mogła wyświetlać pełne dane z makiety.

### 2. Pływający dolny panel (Docked Floating Sheet)
- **D-02 (User Choice):** Panel usprawiedliwiania jest renderowany jako zadokowany pływający pasek u dołu ekranu dokładnie wg makiety. Pojawia się natychmiast po zaznaczeniu co najmniej jednej lekcji.
- **D-03 (User Choice):** Użytkownik wybiera powód jednym kliknięciem z pigułek (`Choroba`, `Wizyta lekarska`, `Sprawy rodzinne`, `Zawody sportowe`) lub wpisuje własny tekst.

### 3. Autoryzacja kodem PIN rodzica
- **D-04 (User Choice):** Kliknięcie `Wyślij usprawiedliwienie` otwiera elegancki modal żądający 4-cyfrowego PIN-u rodzica (z domyślnym kodem "1234" i możliwością szybkiego zatwierdzenia).
- **D-05:** Po wprowadzeniu PIN-u lekcje przechodzą w stan `JustificationStatus.requested` ("W TRAKCIE DECYZJI") lub `approved`, stan jest trwale zapisywany w `SharedPreferences` i pamięci repozytorium, a zaznaczenia są czyszczone.

### 4. Domyślny filtr widoku
- **D-06 (User Choice):** Domyślnie aktywna zakładka to `• Do usprawiedliwienia`, aby po wejściu w ekran użytkownik od razu widział nieobecności wymagające uwagi. Użytkownik może w każdej chwili przełączyć na `Wszystkie` lub `Usprawiedliwione`.

### 5. Dane demonstracyjne zgodne z makietą
- **D-07:** Uzupełnić `MockData.attendanceRecords` o wpisy dokładnie odpowiadające makiecie:
  - Wtorek, 22 Października 2024: Lekcja 1 Fizyka (Sala 14, mgr J. Wiśniewski) i Lekcja 2 Matematyka (Sala 204, dr A. Nowak).
  - Piątek, 18 Października 2024: Lekcja 6 Chemia (Pracownia Chemiczna, mgr K. Lewandowska).
  - Środa, 16 Października 2024: Lekcja 4 Język angielski (10:45 - 11:30, Usprawiedliwiona).
  - Statystyki: 142 obecności, 6 opuszczonych (3 nieusp. / 3 usp.), 2 spóźnienia, 94.2% frekwencji.
</decisions>
