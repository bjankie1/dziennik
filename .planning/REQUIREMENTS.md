# Requirements: EduSync • Lepsza Szkoła

**Defined:** 2026-09-21  
**Core Value:** Błyskawiczny, czytelny i niezależny dostęp do rzeczywistych danych edukacyjnych ucznia (LO nr X we Wrocławiu) w czasie rzeczywistym, z automatyczną synchronizacją w tle.

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

## v2 Requirements (Complete)

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

### Messages Functional Module
- [x] **REQ-MSG-04**: Widok wątku wiadomości na jednym ekranie w stylu Gmail (zwijalne/rozwijalne wiadomości, chronologia, czytelny nagłówek nadawcy).
- [x] **REQ-MSG-05**: Odpowiadanie na wiadomość bezpośrednio w widoku wątku z wysyłaniem do Librus Synergia.
- [x] **REQ-MSG-06**: Tworzenie nowej wiadomości z autocomplete odbiorcy po nazwisku nauczyciela oraz po nauczanym przedmiocie.
- [x] **REQ-MSG-07**: Pobieranie i prezentacja pełnej treści wiadomości z podstron szczegółów wiadomości Librus Synergia on-demand z cache'em w Firestore.
- [x] **REQ-MSG-08**: Oznaczanie wiadomości jako nowe i przeczytane z dynamicznym licznikiem nieprzeczytanych na pasku i nagłówku.

### Desktop Dashboard Bento Grid
- [x] **REQ-DASH-02**: Nowoczesny dashboard webowy (desktop/tablet/mobile) z bento-grid, harmonogramem na żywo, kartą powitalną ze statusem, podsumowaniem ocen, frekwencji i wspólną nawigacją AppSidebar.

### Timetable Web Views (Siatka i Agenda)
- [x] **REQ-TIMETABLE-01**: Segmented control trybów (Siatka / Agenda) na górnym pasku z synchronizacją wybranego dnia.
- [x] **REQ-TIMETABLE-02**: Pasek nawigacji tygodniowej oraz interaktywne kafelki podsumowania tygodnia.
- [x] **REQ-TIMETABLE-03**: Tygodniowa siatka (Pn-Pt) z godzinami lekcyjnymi (1-8+), kafelkami statusów i modalem szczegółów lekcji.
- [x] **REQ-TIMETABLE-04**: Widok agendy dziennej z chronologiczną osią czasu, lekcją na żywo („Trwa teraz • Zostało X min”), tematami i zadaniami.

### Desktop Master-Detail Grades (Phase 10)
- [x] **REQ-GRADES-05**: Układ Master-Detail 8+4 na desktopie z tabelą przedmiotów i inspektorem.
- [x] **REQ-GRADES-06**: Karta rozkładu ocen w skali MEN 1–6 (histogram) oraz wskaźnikiem bezpieczeństwa.
- [x] **REQ-GRADES-07**: Wykres trajektorii średniej ważonej (krzywa Béziera) z linią średniej klasy.
- [x] **REQ-GRADES-08**: Prawostronna szuflada szczegółów oceny z kalkulatorem wpływu na GPA.

### Stealth Scraping & Rate Limiting (Phase 11)
- [x] **REQ-STEALTH-01**: Profil Chrome 133 z nagłówkami Client Hints i pl-PL.
- [x] **REQ-STEALTH-02**: Sekwencyjne odpytywanie z losowym jitterem (1.0–2.5 s).
- [x] **REQ-STEALTH-03**: Trwała sesja CookieJar w Firestore i probe isSessionAlive().
- [x] **REQ-STEALTH-04**: Dynamiczny backoff 429/503 z 20-minutową blokadą.
- [x] **REQ-SCHED-01**: Inteligentny harmonogram w strefie Europe/Warsaw z ciszą nocną (22:30–06:30).
- [x] **REQ-CLIENT-01**: Cooldown 120s na ręczne odświeżanie z odliczaniem.

### Audyt i Routing (Phase 12 & 13)
- [x] **REQ-AUDIT-01**: Całkowite odcięcie sztucznych danych mockowych i dynamiczny profil ucznia.
- [x] **REQ-TIMETABLE-05**: Naniesienie statusów frekwencji na kafelki planu lekcji.
- [x] **REQ-TIMETABLE-06**: Stała szerokość 430px kontenera tygodni w planie lekcji.
- [x] **REQ-ROUTING-01**: Czyste ścieżki HTML5 History API bez hasha w go_router z obsługą historii i przekierowań.
- [x] **REQ-ROUTING-02**: Deep linking do konkretnych zasobów (/wiadomosci/:threadId, /plan-lekcji?data=...).

## v3 Requirements (Active Milestone)

### Role & Multi-User Access
- [ ] **REQ-ROLE-01**: Logowanie kontem Google Oskara (ucznia) powiązane z tym samym profilem ucznia w Firestore.
- [ ] **REQ-ROLE-02**: Separacja uprawnień `student` vs `parent`: tryb ucznia posiada pełny wgląd w dane szkolne, lecz brak uprawnień rodzica (wysyłanie e-usprawiedliwień, podgląd/edycja PIN rodzica).
- [ ] **REQ-ROLE-03**: Współdzielenie pamięci podręcznej i stanu synchronizacji w Firestore (brak dublowania zapytań do Librusa).

### Smart To-Do & Task Management
- [ ] **REQ-TASK-01**: Dedykowana podstrona `/zadania` w menu bocznym i nawigacji z wykazem zadań, terminami i filtrami.
- [ ] **REQ-TASK-02**: Karta Bento Grid na Pulpicie (desktop oraz mobile) prezentująca najpilniejsze zadania z natychmiastowym odhaczaniem.
- [ ] **REQ-TASK-03**: Automatyczne i półautomatyczne generowanie zadań przygotowania do sprawdzianu/kartkówki z planu lekcji i terminarza.
- [ ] **REQ-TASK-04**: Heurystyczne wykrywanie zadań podczas czytania wiadomości Librusa (kwoty, wpłaty, terminy, zgody) z przyciskiem szybkiego utworzenia zadania.

### Calendar Export
- [ ] **REQ-CAL-01**: Przycisk „Dodaj do Kalendarza Google” w kafelkach sprawdzianów i modalu lekcji (bezpośredni link webowy z wypełnioną datą, godziną i zakresem).
- [ ] **REQ-CAL-02**: Pobieranie uniwersalnego pliku kalendarzowego `.ics` dla sprawdzianu lub zestawu terminów.

### Notifications & Weekly Briefing
- [ ] **REQ-NOTIF-01**: Integracja Telegram Bot w Cloud Functions z łączeniem konta poprzez jednorazowy kod.
- [ ] **REQ-NOTIF-02**: Natychmiastowe powiadomienia Telegram o nowych ocenach, wiadomościach i sprawdzianach.
- [ ] **REQ-NOTIF-03**: Obsługa powiadomień Web Push w przeglądarce (Service Worker / FCM).
- [ ] **REQ-REPORT-01**: Automatyczny harmonogram Cloud Scheduler w piątki wieczorem generujący zestawienie sprawdzianów i planu na nadchodzący tydzień.
- [ ] **REQ-REPORT-02**: Wysyłka piątkowego raportu tygodniowego przez bota Telegram do rodzica i ucznia.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REQ-ROLE-01 | TBD | Pending |
| REQ-ROLE-02 | TBD | Pending |
| REQ-ROLE-03 | TBD | Pending |
| REQ-TASK-01 | TBD | Pending |
| REQ-TASK-02 | TBD | Pending |
| REQ-TASK-03 | TBD | Pending |
| REQ-TASK-04 | TBD | Pending |
| REQ-CAL-01 | TBD | Pending |
| REQ-CAL-02 | TBD | Pending |
| REQ-NOTIF-01 | TBD | Pending |
| REQ-NOTIF-02 | TBD | Pending |
| REQ-NOTIF-03 | TBD | Pending |
| REQ-REPORT-01 | TBD | Pending |
| REQ-REPORT-02 | TBD | Pending |
