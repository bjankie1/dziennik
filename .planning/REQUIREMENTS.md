# Requirements: EduSync • Lepsza Szkoła

**Defined:** 2026-09-15  
**Core Value:** Błyskawiczny, czytelny i niezależny dostęp do rzeczywistych danych edukacyjnych ucznia (LO nr X we Wrocławiu) w czasie rzeczywistym, z automatyczną synchronizacją w tle co 30 minut.

## v1 Requirements (Complete)

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

## v2 Requirements (Active Milestone)

### Authentication & Persistence
- [x] **REQ-AUTH-01**: Trwałe powiązanie konta Librus pod profilem użytkownika Google w Firestore. Po wylogowaniu i ponownym zalogowaniu kontem Google aplikacja automatycznie rozpoznaje istniejące powiązanie i wchodzi do aplikacji bez ponownego wpisywania loginu Librus. Odświeżenie strony (F5) zachowuje sesję.

### Grades Interface (wg makiety)
- [x] **REQ-GRADES-01**: Zakładki semestrów (Semestr 1, Semestr 2, Roczna) z filtrami.
- [x] **REQ-GRADES-02**: Karta podsumowania średniej ważonej z pozycją w klasie i paskiem stypendium naukowego.
- [x] **REQ-GRADES-03**: Lista przedmiotów od razu prezentująca pigułki ocen cząstkowych z wagami w wierszu przedmiotu bez konieczności rozwijania.
- [x] **REQ-GRADES-04**: Rozwijany panel szczegółów ocen z dokładną datą, wagą, procentem i komentarzem nauczyciela.

### Attendance Justification (wg makiety)
- [x] **REQ-ATTN-03**: Nowoczesny widok frekwencji z kołowym wykresem, celem semestru i podsumowaniem obecności/spóźnień.
- [x] **REQ-ATTN-04**: Filtrowanie frekwencji (Wszystkie, Do usprawiedliwienia, Usprawiedliwione) z grupowaniem po dniach i etykietami stanu.
- [x] **REQ-ATTN-05**: Zaznaczanie wielu lekcji checkboxami i dolny wysuwany panel z szybkimi powodami usprawiedliwienia.
- [x] **REQ-ATTN-06**: Autoryzacja kodem PIN rodzica i wysyłanie e-usprawiedliwienia do wychowawcy.
### Messages Functional Module (czytanie, odpowiadanie, wysyłanie)
- [x] **REQ-MSG-04**: Widok wątku wiadomości na jednym ekranie w stylu Gmail (zwijalne/rozwijalne wiadomości, chronologia, czytelny nagłówek nadawcy).
- [x] **REQ-MSG-05**: Odpowiadanie na wiadomość bezpośrednio w widoku wątku z wysyłaniem do Librus Synergia.
- [x] **REQ-MSG-06**: Tworzenie nowej wiadomości z autocomplete odbiorcy po nazwisku nauczyciela oraz po nauczanym przedmiocie (np. "Chemia", "Pietrzak") oraz wysyłaniem do Librus Synergia.
- [x] **REQ-MSG-07**: Pobieranie i prezentacja pełnej treści wiadomości z podstron szczegółów wiadomości Librus Synergia (zamiast powtórzonego tematu/podglądu), z automatycznym dociąganiem on-demand i trwałym cache'owaniem w Firestore.
- [x] **REQ-MSG-08**: Oznaczanie wiadomości jako nowe i przeczytane (automatycznie przy otwarciu wątku oraz ręcznie) wraz z dynamicznym licznikiem nieprzeczytanych wiadomości na ikonie nawigacji dolnej i nagłówka (badge z liczbą, ukrywany gdy 0).

### Desktop Dashboard Bento Grid
- [x] **REQ-DASH-02**: Nowoczesny dashboard webowy (desktop/tablet/mobile) z bento-grid, harmonogramem na żywo, kartą powitalną ze statusem, podsumowaniem ocen, frekwencji i wspólną nawigacją AppSidebar.

### Timetable Web Views (Siatka i Agenda)
- [x] **REQ-TIMETABLE-01**: Segmented control trybów (Siatka / Agenda) na górnym pasku z synchronizacją wybranego dnia.
- [x] **REQ-TIMETABLE-02**: Pasek nawigacji tygodniowej (zakres dat, dzisiaj, klasa) oraz interaktywne kafelki podsumowania tygodnia (godziny, zastępstwa, sprawdziany, odwołane).
- [x] **REQ-TIMETABLE-03**: Tygodniowa siatka (Pn-Pt) z godzinami lekcyjnymi (1-8+), kafelkami statusów, podświetleniem "Dziś" i modalem szczegółów lekcji.
- [x] **REQ-TIMETABLE-04**: Widok agendy dziennej z chronologiczną osią czasu, lekcją na żywo ("Trwa teraz • Zostało X min"), tematami, zadaniami domowymi i materiałami.

### Stealth Scraping & Rate Limiting (Phase 11)
- [ ] **REQ-STEALTH-01**: Nowoczesny profil przeglądarki i nagłówki HTTP (Chrome 133, Client Hints, Sec-*, Accept-Language) zamiast Firefox 10.
- [ ] **REQ-STEALTH-02**: Humanizowane sekwencyjne odpytywanie modułów w `fetchAll()` z losowym opóźnieniem 1.0–2.5 s zamiast `Promise.all`.
- [ ] **REQ-STEALTH-03**: Trwałość sesji cookie (`tough-cookie` w Firestore) z probe `isSessionAlive()` eliminujące zbędne autoryzacje OAuth.
- [ ] **REQ-STEALTH-04**: Dynamiczny backoff na kody 429/503 z blokadą w Firestore i serwowaniem z cache.
- [ ] **REQ-SCHED-01**: Inteligentny harmonogram w strefie `Europe/Warsaw` z ciszą nocną (22:30–06:30), taktem w dni szkolne i oknami weekendowymi.
- [ ] **REQ-CLIENT-01**: Ochrona przycisku odświeżania w aplikacji (cooldown 120s) i informacja o trybie nocnym.

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
| REQ-AUTH-01 | Phase 4 | Complete |
| REQ-GRADES-01 | Phase 5 | Complete |
| REQ-GRADES-02 | Phase 5 | Complete |
| REQ-GRADES-03 | Phase 5 | Complete |
| REQ-GRADES-04 | Phase 5 | Complete |
| REQ-ATTN-03 | Phase 6 | Complete |
| REQ-ATTN-04 | Phase 6 | Complete |
| REQ-ATTN-05 | Phase 6 | Complete |
| REQ-ATTN-06 | Phase 6 | Complete |
| REQ-MSG-04 | Phase 7 | Complete |
| REQ-MSG-05 | Phase 7 | Complete |
| REQ-MSG-06 | Phase 7 | Complete |
| REQ-MSG-07 | Phase 7 | Complete |
| REQ-MSG-08 | Phase 7 | Complete |
| REQ-DASH-02 | Phase 8 | Complete |
| REQ-TIMETABLE-01 | Phase 9 | Complete |
| REQ-TIMETABLE-02 | Phase 9 | Complete |
| REQ-TIMETABLE-03 | Phase 9 | Complete |
| REQ-TIMETABLE-04 | Phase 9 | Complete |
| REQ-STEALTH-01 | Phase 11 | Pending |
| REQ-STEALTH-02 | Phase 11 | Pending |
| REQ-STEALTH-03 | Phase 11 | Pending |
| REQ-STEALTH-04 | Phase 11 | Pending |
| REQ-SCHED-01 | Phase 11 | Pending |
| REQ-CLIENT-01 | Phase 11 | Pending |

