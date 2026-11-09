# Phase 29: Usprawiedliwianie nieobecności w przyszłości - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-09
**Phase:** 29-chcia-bym-mie-mo-liwo-usprawiedliwiania-nieobecno-ci-w-przys
**Areas discussed:** Wybór zakresu dat i szybkie skróty, Punkt wejścia na ekranie Frekwencji i Planu Lekcji, Obieg prośby ucznia i zatwierdzania przez rodzica dla przyszłych dat, Prezentacja wysłanych przyszłych usprawiedliwień we Frekwencji

---

## Wybór zakresu dat i szybkie skróty

| Option | Description | Selected |
|--------|-------------|----------|
| Szybkie pigułki + przycisk Zakres dat (showDateRangePicker) | Pigułki okresów + pojedynczy kalendarz zakresu | |
| Dwa osobne pola „Data od” i „Data do” + szybkie pigułki | Klasyczny formularz z dwoma polami daty otwierającymi kalendarz dla początku i końca okresu | ✓ |
| Tylko kalendarz zakresu (showDateRangePicker) | Tylko „Dzisiaj”, „Jutro” i przycisk wyboru zakresu | |

**User's choice:** Dwa osobne pola „Data od” i „Data do” + szybkie pigułki („Dzisiaj”, „Jutro”, „Obecny tydzień”)
**Notes:** Zestaw szybkich pigułek nad polami `Data od` i `Data do` (`Dzisiaj`, `Jutro`, `Obecny tydzień (Pn–Pt)`, `Obecny tydzień + poniedziałek`, `Przyszły tydzień`) oraz pomijanie weekendów w podglądzie aplikacji przy wysyłce pełnego zakresu `dataOd–dataDo` do Librusa przekazano do decyzji agenta. Użytkownik zatwierdził dodanie szybkiego powodu „Wyjazd rodzinny”.

---

## Punkt wejścia na ekranie Frekwencji i Planu Lekcji

| Option | Description | Selected |
|--------|-------------|----------|
| Przycisk w pasku nagłówka sekcji na ekranie Frekwencji (`AttendanceFilterBar`) + Szybka Akcja na Pulpicie | Przycisk jest zawsze widoczny nad listą frekwencji niezależnie od zaznaczenia zaległych lekcji | ✓ |
| Stały pływający przycisk (FAB / pasek na dole) | Dolny dock widoczny zawsze | |
| Osobna zakładka „Zaplanuj nieobecność” | Osobna karta formularza na górze ekranu Frekwencji | |

**User's choice:** Przycisk „Zgłoś nieobecność / zakres dat” w pasku nagłówka sekcji na ekranie Frekwencji (`AttendanceFilterBar`) + zachowanie Szybkiej Akcji na Pulpicie
**Notes:** Po kliknięciu przycisku modal otwiera się w trybie wyboru zakresu dat (`Data od = dzisiaj`, `Data do = dzisiaj`) bez automatycznego podpinania starych zaległych nieobecności. Na ekranie Planu lekcji nie dokładamy dodatkowego przycisku w nagłówku (wystarczają ekran Frekwencji, Pulpit oraz modal szczegółów lekcji).

---

## Obieg prośby ucznia i zatwierdzania przez rodzica dla przyszłych dat

| Option | Description | Selected |
|--------|-------------|----------|
| Na banerze zakres dat i liczba dni szkolnych, a w modalu lista dni szkolnych z lekcjami z planu | Rodzic widzi konkretne dni oraz planowane lekcje i może odznaczyć wybrany dzień przed zatwierdzeniem PIN-em | ✓ |
| W modalu pokaż tylko listę samych dni kalendarzowych | Prostszy widok samych dat od–do | |
| Ty zdecyduj (Agent's Discretion) | Dobór prezentacji przez agenta | |

**User's choice:** Na banerze pokaż zakres dat i liczbę dni szkolnych (np. „09.11–16.11 (6 dni) • Wyjazd rodzinny”), a w modalu listę dni szkolnych wraz z planowanymi lekcjami z planu lekcji
**Notes:** Zarówno Rodzic, jak i Uczeń mogą wybierać przyszły zakres dat. Wysyłka do Librus Synergia odbywa się w trybie całodniowym `wgDat` (`dataOd`–`dataDo`), a prośby dotyczące przyszłych dat czekają na decyzję rodzica i nie są automatycznie zamykane przez brak wpisów nieobecności.

---

## Prezentacja wysłanych przyszłych usprawiedliwień we Frekwencji

| Option | Description | Selected |
|--------|-------------|----------|
| Przyszłe wyprzedzające dni nie obniżają bieżącej frekwencji procentowej + plakietki w Planie lekcji + obsługa „Cofnij” | Integracja z sekcją „Oczekujące” i banerem wychowawcy, ochrona wykresu KPI i oznaczenie w Planie lekcji | ✓ |
| Osobny kafelek „Zaplanowane usprawiedliwienia” / wliczanie do statystyk z góry | Alternatywne podejścia | |

**User's choice:** Integracja z sekcją „Oczekujące” i banerem wychowawcy, ochrona bieżącego procentu frekwencji przed sztucznym spadkiem, oznaczenie kafelków w Planie lekcji plakietką „Zgłoszona nieobecność / Usprawiedliwione” oraz zachowanie przycisku „Cofnij”.

---

## the agent's Discretion

- Zestaw pigułek szybkiego wyboru nad polami „Data od” i „Data do” (`Dzisiaj`, `Jutro`, `Obecny tydzień (Pn–Pt)`, `Obecny tydzień + poniedziałek`, `Przyszły tydzień`).
- Pomijanie weekendów w podglądzie dni/lekcji wewnątrz aplikacji przy wysyłce pełnego przedziału `dataOd–dataDo` (`wgDat`) do Librusa.
- Etykiety i ikony przycisku na ekranie Frekwencji zależnie od roli (`Zgłoś nieobecność` dla Rodzica, `Poproś o usprawiedliwienie` dla Ucznia).
- Techniczny sposób persystencji przyszłych zakresów usprawiedliwień w `SchoolDataCacheManager` i Firestore.

## Deferred Ideas

Brak — wszystkie ustalenia mieszczą się w zakresie Fazy 29.
