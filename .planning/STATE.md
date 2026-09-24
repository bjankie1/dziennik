---
gsd_state_version: "1.0"
milestone: v3.0
current_phase: 19
current_phase_name: "Raporty tygodniowe (Piątkowy briefing sprawdzianów i planu)"
status: ready_to_plan
stopped_at: Completed Phase 18 (Powiadomienia w czasie rzeczywistym: Telegram Bot + 6-digit pairing + Web Push Service Worker + NotificationSettingsModal)
last_updated: "2026-09-24T12:15:00Z"
last_activity: 2026-09-24
state_head: 0ee4634
progress:
  total_phases: 8
  completed_phases: 7
  total_plans: 18
  completed_plans: 18
  percent: 88
milestone_name: Dostęp Ucznia, Smart Zadania, Kalendarz & Powiadomienia
---

# Project State

**Current Milestone:** Milestone v3.0 (Dostęp Ucznia, Smart Zadania, Kalendarz & Powiadomienia)  
**Active Phase:** Phase 19: Raporty tygodniowe (Piątkowy briefing sprawdzianów i planu)  
**Status:** Phase 18 verified & completed (7/8 phases completed in v3.0 — 88%)  
**Last Updated:** 2026-09-24  

## Milestone v3.0 Roadmap

- [x] **Phase 14**: Dostęp ucznia (rola student vs parent) i współdzielony cache danych (completed 2026-09-22)
- [x] **Phase 14.1**: Czat rodzinny i dwukierunkowy dialog usprawiedliwień (completed 2026-09-23)
- [x] **Phase 15**: Moduł zadań (Smart To-Do) i widżet na Pulpicie (completed 2026-09-23)
- [x] **Phase 16**: Inteligentne podpowiedzi zadań ze sprawdzianów i wiadomości oraz dwukierunkowe linkowanie źródeł (completed 2026-09-23)
- [x] **Phase 17**: Eksport sprawdzianów do Kalendarza Google i iCal (completed 2026-09-23)
- [x] **Phase 17.1**: Refactoring architektury widoków i biblioteka współdzielonych komponentów UI (completed 2026-09-24)
- [x] **Phase 18**: Powiadomienia w czasie rzeczywistym: Telegram Bot i Web Push (completed 2026-09-24)
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

### Roadmap Evolution

- Phase 14.1 inserted: Czat rodzinny i dwukierunkowy dialog usprawiedliwień (URGENT)

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

## Session

**Last session:** 2026-09-23T15:55:00Z
**Stopped at:** Completed Quick Task 260923-spr (Oznaczenie sprawdzianu w planie lekcji: chip na lekcji + szczegóły i zakres w modalu)
**Resume file:** None
Last activity: 2026-09-23

## Current Position

Phase: 15 (Moduł zadań (Smart To-Do) i widżet na Pulpicie) — COMPLETE (3/3 plans completed)
Next Phase: 16 (Inteligentne podpowiedzi zadań ze sprawdzianów i wiadomości)
Status: Phase 15 completed + Quick Tasks 260923-l4t, 260923-osk & 260923-spr deployed. Ready for Phase 16.
Last activity: 2026-09-23 — Completed Quick Task 260923-spr
