---
gsd_state_version: "1.0"
milestone: v2.0
status: Milestone complete
stopped_at: Phase 13 verified
last_updated: "2026-09-21T07:31:00.000Z"
last_activity: 2026-09-21
last_activity_desc: "Completed Phase 13: Dedykowane URL i routing dla podstron i zasobów (deep linking)"
state_head: HEAD
progress:
  total_phases: 10
  completed_phases: 10
  total_plans: 18
  completed_plans: 18
current_phase_name: dedykowane-url-i-routing-dla-podstron-i-zasob-w-deep-linking
---

# Project State

**Current Milestone:** Milestone v2.0
**Active Phase:** Phase 13: Dedykowane URL i routing dla podstron i zasobów (deep linking)
**Status:** Completed & Deployed
**Last Updated:** 2026-09-21

## Completed in v2.0

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

## Milestone v2.0 Roadmap

- [x] **Phase 4**: Bezpieczny autologin i trwałe powiązanie profilu Librus
- [x] **Phase 5**: Nowy interfejs Ocen wg makiety
- [x] **Phase 6**: Moduł usprawiedliwiania nieobecności wg makiety
- [x] **Phase 7**: Funkcjonalny moduł wiadomości (czytanie, odpowiadanie, wysyłanie)
- [x] **Phase 8**: Pełny design ekranu głównego w wersji web
- [x] **Phase 9**: Plan lekcji w wersji web (Widok siatki i agendy)
- [x] **Phase 10**: Pełen panel ocen w wersji na przeglądarkę
- [x] **Phase 11**: Dyskretne odpytywanie serwerów Librus (rate limiting, harmonogram nocny)
- [x] **Phase 12**: Audyt mocków, nieobecności w planie lekcji i stała szerokość przełącznika tygodni
- [x] **Phase 13**: Dedykowane URL i routing dla podstron i zasobów (deep linking)

## Accumulated Context

### Roadmap Evolution

- Phase 8 added: Pełny design ekranu głównego w wersji web (nowoczesny pulpit webowy z Bento Grid dla wersji desktop/tablet).
- Phase 9 added: Plan lekcji w wersji web (Widok siatki i agendy) na podstawie makiet docs/plan_lekcji_v1 i docs/plan lekcji agenda.
- Phase 10 added: Pełen panel ocen w wersji na przeglądarkę na podstawie makiet docs/panel_ocen i docs/szczegoly_oceny.
- Phase 11 added: Dyskretne odpytywanie serwerów Librus (rate limiting, harmonogram nocny) na wniosek użytkownika (ochrona przed podejrzeniami o łamanie regulaminu, wyłączenie nocy).
- Phase 12 added: Audyt mocków, nieobecności w planie lekcji i stała szerokość przełącznika tygodni (eliminacja sztucznych danych, naniesienie frekwencji na plan lekcji, fixed-width dla date pickera tygodni).
- Phase 13 added: Dedykowane URL i routing dla podstron i zasobów (deep linking).

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

**Last session:** 2026-09-21T19:30:00.000Z
**Stopped at:** Milestone v2.0 summary generated
**Resume file:** .planning/reports/MILESTONE_SUMMARY-v2.0.md
Last activity: 2026-09-21 - Wygenerowano kompleksowe podsumowanie kamienia milowego v2.0 (MILESTONE_SUMMARY-v2.0.md)
