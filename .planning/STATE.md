---
gsd_state_version: "1.0"
milestone: v3.0
current_phase: 15
current_phase_name: Moduł zadań (Smart To-Do) i widżet na Pulpicie
status: ready_to_plan
stopped_at: Phase 14 completed and verified
last_updated: "2026-09-22T07:28:00.000Z"
last_activity: 2026-09-22
state_head: HEAD
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
  percent: 17
milestone_name: Dostęp Ucznia, Smart Zadania, Kalendarz & Powiadomienia
---

# Project State

**Current Milestone:** Milestone v3.0 (Dostęp Ucznia, Smart Zadania, Kalendarz & Powiadomienia)  
**Active Phase:** Phase 15: Moduł zadań (Smart To-Do) i widżet na Pulpicie  
**Status:** Ready to plan Phase 15  
**Last Updated:** 2026-09-22  

## Milestone v3.0 Roadmap

- [x] **Phase 14**: Dostęp ucznia (rola student vs parent) i współdzielony cache danych (completed 2026-09-22)
- [ ] **Phase 15**: Moduł zadań (Smart To-Do) i widżet na Pulpicie
- [ ] **Phase 16**: Inteligentne podpowiedzi zadań ze sprawdzianów i wiadomości
- [ ] **Phase 17**: Eksport sprawdzianów do Kalendarza Google i iCal
- [ ] **Phase 18**: Powiadomienia w czasie rzeczywistym: Telegram Bot i Web Push
- [ ] **Phase 19**: Raporty tygodniowe (Piątkowy briefing sprawdzianów i planu)

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

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260918-ev7 | Librus query access log modal and tracking | 2026-09-18 | 478def3 | [260918-ev7-librus-query-access-log-modal-and-tracki](./quick/260918-ev7-librus-query-access-log-modal-and-tracki/) |
| 260919-ufy | Naprawa rozpoznawania usprawiedliwień i zwolnień w module frekwencji | 2026-09-19 | 6c76505 | [260919-ufy-naprawa-rozpoznawania-usprawiedliwie-i-z](./quick/260919-ufy-naprawa-rozpoznawania-usprawiedliwie-i-z/) |
| 260920-wkd | Harmonogram na weekend oraz dynamiczne przełączanie tygodni w planie lekcji | 2026-09-20 | 39391f3 | [260920-wkd-harmonogram-weekend-i-przelaczanie-tygodni](./quick/260920-wkd-harmonogram-weekend-i-przelaczanie-tygodni/) |
| 260920-trm | Integracja terminarza z planem lekcji, nawigacja do tygodnia sprawdzianu, naprawa zastępstwa z j. polskiego | 2026-09-20 | a0d9d9c | [260920-trm-terminarz-integracja-kartkowka-zastepstwa](./quick/260920-trm-terminarz-integracja-kartkowka-zastepstwa/) |
| 260921-9sd | Uporządkowanie kalkulacji frekwencji: dual ring gauge i spójne wskaźniki obecności | 2026-09-21 | HEAD | [260921-9sd-uporzadkowanie-kalkulacji-frekwencji-dua](./quick/260921-9sd-uporzadkowanie-kalkulacji-frekwencji-dua/) |
| 260921-msg | Naprawa licznika nieprzeczytanych wiadomości oraz dodanie kafelków wiadomości na pulpicie mobilnym | 2026-09-21 | HEAD | [260921-msg-licznik-nieprzeczytanych-i-kafelki-wiadomosci-mobile](./quick/260921-msg-licznik-nieprzeczytanych-i-kafelki-wiadomosci-mobile/) |

## Session

**Last session:** 2026-09-22T07:28:00.000Z  
**Stopped at:** Phase 14 completed and verified  
**Resume file:** .planning/ROADMAP.md  
Last activity: 2026-09-22

## Current Position

Phase: 15 (Moduł zadań (Smart To-Do) i widżet na Pulpicie) — READY TO PLAN
Status: Phase 14 completed. Ready to discuss / plan Phase 15.
Last activity: 2026-09-22 — Phase 14 verified and closed
