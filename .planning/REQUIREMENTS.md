# Requirements: EduSync • Lepsza Szkoła

**Defined:** 2026-09-15  
**Core Value:** Błyskawiczny, czytelny i niezależny dostęp do rzeczywistych danych edukacyjnych ucznia (LO nr X we Wrocławiu) w czasie rzeczywistym, z automatyczną synchronizacją w tle co 30 minut.

## v1 Requirements

### Schedule & Calendar
- [x] **SCHED-01**: Interaktywne przełączanie dni tygodnia (Poniedziałek – Piątek) w widoku planu lekcji z dynamicznymi datami i filtrowaniem lekcji.

### Dashboard & Grades
- [x] **DASH-01**: Kompaktowy układ siatki ocen na pulpicie (zamiast kafelków pełnej szerokości) z widoczną datą dodania przy każdej ocenie.

### Attendance
- [x] **ATTN-01**: Pobieranie rzeczywistej frekwencji z Librus Synergia i prezentacja statystyk semestralnych oraz wpisów zamiast danych demonstracyjnych.
- [x] **ATTN-02**: Wskaźnik nieusprawiedliwionych nieobecności (badge) na dolnym pasku nawigacji.

### Messages & Notifications
- [x] **MSG-01**: Pobieranie rzeczywistych wiadomości ze skrzynki odbiorczej Librus Synergia i ich prezentacja z podziałem na wątki.
- [x] **MSG-02**: Wskaźnik nowych / nieprzeczytanych wiadomości (badge) na dolnym pasku nawigacji.
- [x] **MSG-03**: Automatyczne powiadomienia w tle o nowych wiadomościach i ocenach w cyklu Cloud Scheduler (co 30 min).

## v2 Requirements

### Push Notifications & Mobile
- **PUSH-01**: Bezpośrednie powiadomienia Web Push (FCM) na urządzenia mobilne i przeglądarki.
- **OFFLINE-01**: Pełny tryb offline z buforowaniem wpisów w lokalnej bazie Hive/Isar.
- **JUST-01**: Zgłaszanie usprawiedliwień nieobecności bezpośrednio do Librusa z poziomu aplikacji.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Płatne moduły komercyjne Librusa | Celem jest wolny, niezależny dostęp bez subskrypcji |
| Modyfikacja danych po stronie serwera szkoły | Wyłącznie bezpieczny odczyt danych ucznia |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCHED-01 | Phase 1 | Complete |
| DASH-01 | Phase 1 | Complete |
| ATTN-01 | Phase 2 | Complete |
| ATTN-02 | Quick polish | Complete |
| MSG-01 | Phase 3 | Complete |
| MSG-02 | Quick polish | Complete |
| MSG-03 | Phase 3 | Complete |

**Coverage:**
- v1 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0
