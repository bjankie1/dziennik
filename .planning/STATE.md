---
gsd_state_version: "1.0"
milestone: v3.0
current_phase: 19
current_phase_name: Raporty tygodniowe (Piątkowy briefing sprawdzianów i planu)
status: planning
stopped_at: Phase 22 complete, ready to plan Phase 19
last_updated: "2026-09-29T05:42:58.007Z"
last_activity: 2026-09-29
last_activity_desc: Phase 22 complete, transitioned to Phase 19
state_head: b40442da2b087da216e173e295191468ce5c6b60
progress:
  total_phases: 11
  completed_phases: 8
  total_plans: 15
  completed_plans: 20
  percent: 73
milestone_name: Dostęp Ucznia, Smart Zadania, Kalendarz & Powiadomienia
---

# Project State

**Current Milestone:** Milestone v3.0 (Dostęp Ucznia, Smart Zadania, Kalendarz & Powiadomienia)  
**Active Phase:** Phase 20: Asystent AI dziennika szkolnego (Konwersacyjny agent Q&A) — COMPLETED  
**Status:** Ready to plan
**Last Updated:** 2026-09-26  

## Milestone v3.0 Roadmap

- [x] **Phase 14**: Dostęp ucznia (rola student vs parent) i współdzielony cache danych (completed 2026-09-22)
- [x] **Phase 14.1**: Czat rodzinny i dwukierunkowy dialog usprawiedliwień (completed 2026-09-23)
- [x] **Phase 15**: Moduł zadań (Smart To-Do) i widżet na Pulpicie (completed 2026-09-23)
- [x] **Phase 16**: Inteligentne podpowiedzi zadań ze sprawdzianów i wiadomości oraz dwukierunkowe linkowanie źródeł (completed 2026-09-23)
- [x] **Phase 17**: Eksport sprawdzianów do Kalendarza Google i iCal (completed 2026-09-23)
- [x] **Phase 17.1**: Refactoring architektury widoków i biblioteka współdzielonych komponentów UI (completed 2026-09-24)
- [x] **Phase 18**: Powiadomienia w czasie rzeczywistym: Telegram Bot i Web Push (completed 2026-09-25)
- [ ] **Phase 19**: Raporty tygodniowe (Piątkowy briefing sprawdzianów i planu)
- [x] **Phase 20**: Asystent AI dziennika szkolnego (Konwersacyjny agent Q&A) (completed 2026-09-26)

## Completed in Previous Milestones

### Milestone v1.0

- [x] **Phase 1**: Naprawa nawigacji planu lekcji i kompaktowy pulpit ocen
- [x] **Phase 2**: Rzeczywista frekwencja (Librus Synergia)
- [x] **Phase 3**: Rzeczywiste wiadomości i powiadomienia

### Milestone v2.0

- [x] **Phase 4**: Bezpieczny autologin i trwałe powiązanie profilu Librus (odporność na F5/przeładowanie, sesja w SharedPreferences, automatyczne odzyskiwanie z Firestore).
- [x] **Phase 5**: Nowy interfejs Ocen wg makiety (zakładki semestrów, karta średniej ważonej z postępem stypendium, pigułki ocen w wierszu bez rozwijania, pełny akordeon szczegółów ocen).
- [x] **Phase 6**: Moduł usprawiedliwiania nieobecności wg makiety (kołowy wykres frekwencji, filtry, zgrupowane karty lekcji z salami i nauczycielami, pływający dock z szybkimi powodami i autoryzacja PIN rodzica).
- [x] **Phase 7**: Funkcjonalny moduł wiadomości (widok Gmail, odpowiedź, nowa wiadomość z autocomplete, pełna treść Librus, stan przeczytany/nowy i dynamiczne badge).
- [x] **Phase 8**: Pełny design ekranu głównego w wersji web (wspólny pasek boczny AppSidebar dla wszystkich widoków, AppDesktopHeader z wyszukiwarką, Bento Grid z 3 kolumnami, harmonogramem na żywo, wiadomościami i szybkimi akcjami).
- [x] **Phase 9**: Plan lekcji w wersji web (Widok siatki i agendy) (nawigacja tygodnia, kafelki podsumowania, siatka Pn-Pt z modalem szczegółów, agenda z lekcją na żywo, wspólny sidebar i responsywność).
- [x] **Phase 10**: Pełen panel ocen w wersji na przeglądarkę (Master-Detail 8+4, karty KPI ze średnią i rozkładem MEN 1-6, wykres trajektorii Béziera, szuflada boczna ze szczegółami i kalkulatorem GPA).
- [x] **Phase 11**: Dyskretne odpytywanie serwerów Librus (rate limiting, harmonogram nocny) (nowoczesne nagłówki Chrome 133, sekwencyjny fetch z jitterem, probe sesji, dynamiczny backoff 429/503, cisza nocna 22:30-06:30, cooldown klienta 120s).
- [x] **Phase 12**: Audyt mocków, nieobecności w planie lekcji i stała szerokość przełącznika tygodni (odcięcie mocków z MockData, ukrywanie sprawdzianu, neutralny numerek w weekend, dynamiczny profil i wychowawca, frekwencja na kafelkach planu, stała szerokość 430px WeekNavigatorBar).
- [x] **Phase 13**: Dedykowane URL i routing dla podstron i zasobów (deep linking) (go_router, Path URL Strategy, StatefulShellRoute, trasy po polsku, deep linki /wiadomosci/:id i /plan-lekcji?data=...).

## Accumulated Context

### Roadmap Evolution

- Phase 14.1 inserted: Czat rodzinny i dwukierunkowy dialog usprawiedliwień (URGENT)
- Phase 17.1 inserted: Refactoring architektury widoków i biblioteka współdzielonych komponentów UI (URGENT)
- Phase 20 added: Asystent AI dziennika szkolnego — Konwersacja z agentem na temat tego co znajduje się w dzienniku czyli oceny, plan lekcji, sprawdziany, wiadomości, nieobecności (np. „Kiedy jest następny sprawdzian”, „Kiedy jest wycieczka Oskara do Warszawy”, „Kiedy jest zebranie z rodzicami”)
- Phase 21 added: Refaktoryzacja modułu wiadomości i dekompozycja MessageThreadScreen (1 340 LOC → modularne widgety zgodne z dobrymi praktykami Flutter)
- Phase 22 added: Zapisywanie załączników wiadomości w Google Drive w stylu Gmail (na życzenie użytkownika jednym kliknięciem z linkiem „Otwórz w Google Drive”)

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260918-ev7 | Librus query access log modal and tracking | 2026-09-18 | 478def3 | [260918-ev7-librus-query-access-log-modal-and-tracki](./quick/260918-ev7-librus-query-access-log-modal-and-tracki/) |
| 260919-ufy | Naprawa rozpoznawania usprawiedliwień i zwolnień w module frekwencji | 2026-09-19 | 6c76505 | [260919-ufy-naprawa-rozpoznawania-usprawiedliwie-i-z](./quick/260919-ufy-naprawa-rozpoznawania-usprawiedliwie-i-z/) |
| 260920-wkd | Harmonogram na weekend oraz dynamiczne przełączanie tygodni w planie lekcji | 2026-09-20 | 39391f3 | [260920-wkd-harmonogram-weekend-i-przelaczanie-tygodni](./quick/260920-wkd-harmonogram-weekend-i-przelaczanie-tygodni/) |
| 260920-trm | Integracja terminarza z planem lekcji, nawigacja do tygodnia sprawdzianu, naprawa zastępstwa z j. polskiego | 2026-09-20 | a0d9d9c | [260920-trm-terminarz-integracja-kartkowka-zastepstwa](./quick/260920-trm-terminarz-integracja-kartkowka-zastepstwa/) |
| 260921-9sd | Uporządkowanie kalkulacji frekwencji: dual ring gauge i spójne wskaźniki obecności | 2026-09-21 | HEAD | [260921-9sd-uporzadkowanie-kalkulacji-frekwencji-dua](./quick/260921-9sd-uporzadkowanie-kalkulacji-frekwencji-dua/) |
| 260921-msg | Naprawa licznika nieprzeczytanych wiadomości oraz dodanie kafelków wiadomości na pulpicie mobilnym | 2026-09-21 | HEAD | [260921-msg-licznik-nieprzeczytanych-i-kafelki-wiadomosci-mobile](./quick/260921-msg-licznik-nieprzeczytanych-i-kafelki-wiadomosci-mobile/) |
| 260923-l4t | Dodanie zadania nauki dla Oskara bezpośrednio z kafelka Nadchodzący sprawdzian na Pulpicie | 2026-09-23 | 3e5d25d | [260923-l4t-dodanie-zadania-nauki-dla-oskara-bezpo-r](./quick/260923-l4t-dodanie-zadania-nauki-dla-oskara-bezpo-r/) |
| 260923-osk | Naprawa braku planu lekcji na koncie Oskara (rozwiązywanie primaryLogin 11010033 dla roli ucznia) | 2026-09-23 | 15ce87d | [260923-osk-naprawa-braku-planu-lekcji-na-koncie-oskara](./quick/260923-osk-naprawa-braku-planu-lekcji-na-koncie-oskara/) |
| 260923-spr | Oznaczenie sprawdzianu w planie lekcji (chip na lekcji + szczegóły i zakres w modalu) | 2026-09-23 | HEAD | [260923-spr-sprawdzian-w-planie-lekcji-chip-i-szczegoly](./quick/260923-spr-sprawdzian-w-planie-lekcji-chip-i-szczegoly/) |
| 260924-cor | Automatyczna korelacja próśb o usprawiedliwienie od Oskara z niezależnie wysłanymi wnioskami rodzica + usunięcie wycieku mockowego req_init_01 | 2026-09-24 | HEAD | [260924-cor-korelacja-prosb-o-usprawiedliwienie](./quick/260924-cor-korelacja-prosb-o-usprawiedliwienie/) |
| 260926-avg | Prawdziwa zmiana średniej po ostatniej ocenie (lastGradeDelta) i usunięcie zmyślonej lokaty w klasie (Top 5% / 1. lokata na 28) | 2026-09-26 | 736e97d | [260926-avg-prawdziwa-zmiana-sredniej-i-usuniecie-f](./quick/260926-avg-prawdziwa-zmiana-sredniej-i-usuniecie-f/) |
| 260927-msg | Naprawa pustego adresata odpowiedzi na wiadomość "Ubezpieczenie szkolne" ([Administrator szkoły]) oraz chipy adresatów i DW | 2026-09-27 | 826baa0 | [260927-msg-naprawa-pustego-adresata-odpowiedzi-ubez](./quick/260927-msg-naprawa-pustego-adresata-odpowiedzi-ubez/) |
| 260928-ogq | Parsowanie, wyświetlanie i pobieranie załączników wiadomości z Librus Synergia (np. wiadomość 2027508) | 2026-09-28 | HEAD | [260928-ogq-parsowanie-wy-wietlanie-i-pobieranie-za-](./quick/260928-ogq-parsowanie-wy-wietlanie-i-pobieranie-za-/) |
| 260929-jas | Naprawa układu modala prośby o usprawiedliwienie - stały przycisk Wyślij i przewijana zawartość | 2026-09-29 | HEAD | [260929-jas-naprawa-uk-adu-modala-pro-by-o-usprawied](./quick/260929-jas-naprawa-uk-adu-modala-pro-by-o-usprawied/) |
| 260929-ooj | Rzeczywisty czas ostatniej synchronizacji z backendu (zamiast czasu otwarcia aplikacji) i poprawne etykiety dnia | 2026-09-29 | HEAD | [260929-ooj-naprawa-czasu-ostatniej-synchronizacji-w](./quick/260929-ooj-naprawa-czasu-ostatniej-synchronizacji-w/) |
| 260929-ox0 | Automatyczne linkowanie URL w treści wiadomości (otwieranie w nowej karcie) | 2026-09-29 | HEAD | [260929-ox0-automatyczne-linkowanie-url-w-tre-ci-wia](./quick/260929-ox0-automatyczne-linkowanie-url-w-tre-ci-wia/) |
| 260929-plh | Naprawa zapisu załączników na Google Drive – włączenie Drive API i rozróżnienie błędów 403 | 2026-09-29 | HEAD | [260929-plh-naprawa-zapisu-za-cznik-w-na-google-driv](./quick/260929-plh-naprawa-zapisu-za-cznik-w-na-google-driv/) |

## Session

**Last session:** 2026-09-29
**Stopped at:** Completed quick task 260929-jas, ready to plan Phase 19
**Resume file:** .planning/phases/22-zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma/22-CONTEXT.md
Last activity: 2026-09-29 — Completed quick task 260929-jas (Naprawa układu modala prośby o usprawiedliwienie)

## Current Position

Phase: 19 — Raporty tygodniowe (Piątkowy briefing sprawdzianów i planu)
Next Phase: 19 (Raporty tygodniowe) / 21 (Refaktoryzacja modułu wiadomości i dekompozycja MessageThreadScreen)
Status: Ready to plan Phase 19
Last activity: 2026-09-29 — Completed quick task 260929-jas
