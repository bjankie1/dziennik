---
gsd_state_version: "1.0"
milestone: v3.0
current_phase: 19
current_phase_name: Raporty tygodniowe (Piątkowy briefing sprawdzianów i planu)
current_plan: Not started
status: planning
stopped_at: Phase 25 complete, ready to plan Phase 19
last_updated: "2026-10-04T06:04:08.611Z"
last_activity: 2026-10-04
last_activity_desc: Phase 25 complete, transitioned to Phase 19
state_head: a5291a9f6f3fa16efb905a17c41715dae920e04d
progress:
  total_phases: 14
  completed_phases: 8
  total_plans: 25
  completed_plans: 23
  percent: 57
milestone_name: Dostęp Ucznia, Smart Zadania, Kalendarz & Powiadomienia
---

# Project State

**Current Milestone:** Milestone v3.0 (Dostęp Ucznia, Smart Zadania, Kalendarz & Powiadomienia)  
**Active Phase:** Phase 23: Podgląd szczegółów próśb o usprawiedliwienie i oczekujących wniosków — COMPLETED  
**Status:** Ready to plan
**Last Updated:** 2026-10-02  

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
- [x] **Phase 21**: Refaktoryzacja monolitycznych widoków UI (>1 600 LOC), wspólne komponenty i optymalizacja granic przebudowy Riverpod (completed 2026-10-03)
- [x] **Phase 22**: Zapisywanie załączników wiadomości w Google Drive w stylu Gmail (completed 2026-10-01)
- [x] **Phase 23**: Podgląd szczegółów próśb o usprawiedliwienie i oczekujących wniosków (completed 2026-10-02)
- [x] **Phase 24**: Dekompozycja monolitycznego FirestoreSchoolRepository (2 691 LOC) na serwisy domenowe i izolacja warstwy cache (completed 2026-10-03)
- [ ] **Phase 25**: Archiwizacja wiadomości, automatyczna archiwizacja potwierdzeń usprawiedliwień i powiadomienia o akceptacji

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
- Phase 21 expanded: Refaktoryzacja monolitycznych widoków UI (`message_thread_screen.dart` 2 059 LOC, `attendance_screen.dart` 1 942 LOC, `notification_settings_modal.dart` 1 642 LOC), wspólne komponenty (`JustificationRequestBanner`, `PolishDateFormatter`) i optymalizacja granic przebudowy Riverpod (`.select`)
- Phase 22 added: Zapisywanie załączników wiadomości w Google Drive w stylu Gmail (na życzenie użytkownika jednym kliknięciem z linkiem „Otwórz w Google Drive”)
- Phase 23 added: Podgląd szczegółów próśb o usprawiedliwienie i oczekujących wniosków (podgląd konkretnych dni, lekcji, przedmiotów i powodów dla prośby o usprawiedliwienie „6 lekcji • Choroba” na Pulpicie i we Frekwencji oraz dla banera „7 wnioski czekają na wychowawcę”)
- Phase 24 added: Dekompozycja monolitycznego `FirestoreSchoolRepository` (2 691 LOC) na serwisy domenowe i izolacja warstwy cache (`SchoolDataCacheManager`, `*DataSource`)
- Phase 25 added: Archiwizacja wiadomości, automatyczna archiwizacja potwierdzeń usprawiedliwień (z podglądem zaakceptowanych usprawiedliwień we Frekwencji) i powiadomienia o akceptacji usprawiedliwienia

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
| 260930-dhq | Naprawa wyświetlania rzeczywistych dat i godzin wiadomości na kartach zamiast stałego 'Dzisiaj, 09:15' | 2026-09-30 | 80f6fea | [260930-dhq-wszystkie-wiadomo-ci-pokazuj-si-jakby-by](./quick/260930-dhq-wszystkie-wiadomo-ci-pokazuj-si-jakby-by/) |
| 261002-94s | Dodanie szczegółowej instrukcji krok po kroku konfiguracji Telegram Bot w oknie powiadomień oraz automatycznego pobierania nazwy bota przez getMe | 2026-10-02 | e0b604c | [261002-94s-dodaj-szczeg-ow-instrukcj-krok-po-kroku-](./quick/261002-94s-dodaj-szczeg-ow-instrukcj-krok-po-kroku-/) |
| 261002-g0a | Wdróż poprawki z audytu UI Fazy 23 (23-UI-REVIEW.md): zabezpieczenie Wyślij do Librusa i poprawa statusu Oczekuje na wychowawcę, animacja AnimatedSize i potwierdzenie/stan ładowania przy Cofnij wszystkie, ujednolicenie czcionek i tap targetów | 2026-10-02 | f0cd7ff | [261002-g0a-wdr-poprawki-z-audytu-ui-fazy-23-23-ui-r](./quick/261002-g0a-wdr-poprawki-z-audytu-ui-fazy-23-23-ui-r/) |
| 261004-bpl | Zaaplikuj rekomendacje UI dla Fazy 25 (25-UI-REVIEW.md): minHeight 32px dla przycisku Archiwizuj/Przywróć, ujednolicenie SnackBar (4s), pełna polska odmiana liczebników w AcceptedJustificationsSummaryCard, plakietki 11px i tokeny M3 | 2026-10-04 | 26cda74 | [261004-bpl-zaaplikuj-rekomendacje-ui-dla-fazy-25](./quick/261004-bpl-zaaplikuj-rekomendacje-ui-dla-fazy-25/) |
| 261004-c2e | Wektorowe ikony archiwum (ArchiveBoxIcon), przełącznik Pokaż zarchiwizowane w linii wyszukiwarki (kompaktowa ikona <600px), wyrównana wysokość 30px i rozróżnienie kolorystyczne przycisków Utwórz zadanie vs Archiwizuj | 2026-10-04 | 3b47a8d | [261004-c2e-popraw-ikony-wyrownanie-wysokosci-kolory](./quick/261004-c2e-popraw-ikony-wyrownanie-wysokosci-kolory/) |
| 261004-d04 | Zachowanie znaków końca linii (<br>, \n) w ogłoszeniach szkolnych z Librusa oraz automatyczne formatowanie wypunktowań (•) i sekcji numerowanych (1., 2., ...) | 2026-10-04 | 9f21a74 | [261004-d04-og-oszenia-s-wy-wietlane-jako-jeden-zbit](./quick/261004-d04-og-oszenia-s-wy-wietlane-jako-jeden-zbit/) |

## Session

**Last session:** 2026-10-03T17:40:41.458Z
**Stopped at:** Phase 25 complete, ready to plan Phase 19
**Resume file:** None
Last activity: 2026-10-04 — Phase 25 complete, transitioned to Phase 19

## Current Position

Phase: 19 — Raporty tygodniowe (Piątkowy briefing sprawdzianów i planu)
Current Plan: Not started
Total Plans in Phase: 2
Next Phase: 19 (Raporty tygodniowe)
Status: Phase complete — ready for verification
Last activity: 2026-10-03 — Completed 24-01-PLAN.md

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 23 P01 | 9 min | 2 tasks | 8 files |
| Phase 23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni P02 | 18min | 2 tasks | 8 files |
| Phase 21 P01 | 11 min | 2 tasks | 7 files |
| Phase 21 P02 | 12 min | 2 tasks | 7 files |
| Phase 21 P03 | 6 min | 2 tasks | 7 files |
| Phase 21 P04 | 7 min | 2 tasks | 7 files |
| Phase 24 P01 | 6 min | 2 tasks | 5 files |
| Phase 24 P02 | 9 min | 2 tasks | 4 files |

## Decisions

- [Phase 23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni]: Upgraded ParentApprovalModal with day-grouped lesson breakdowns, teacher/classroom metadata, Q&A history, and per-lesson checkboxes for partial PIN approval; made justification banners interactive with 'Zobacz szczegóły →' and effectiveStudentName across Dashboard and AttendanceScreen; and added the expandable 'X wnioski czekają na wychowawcę' accordion with per-lesson 'Cofnij' plus the 4th 'Oczekujące (Y)' filter pill
- [Phase 21-01]: Consolidated three variants of the parent pending / student rejected justification banner into a single parameterized JustificationRequestBanner with selective Riverpod .select(...) subscriptions, and created PolishDateFormatter utility
- [Phase 21]: [Phase 21-02]: Decomposed MessageThreadScreen (2 060 -> 340 LOC) into MessageThreadHeaderCard, MessageTaskBanner, MessageAccordionTile, and MessageReplyComposer with .select(...) subscriptions and moved sender/CC/attachment regex parsing to MessageThread
- [Phase 21]: [Phase 21-03]: Decomposed AttendanceScreen (1 952 -> 273 LOC) into 6 focused sub-widgets in lib/presentation/screens/attendance/widgets/ with isolated Riverpod/UI state and wired JustificationRequestBanner and PolishDateFormatter
- [Phase 21]: [Phase 21-04]: Decomposed NotificationSettingsModal (1 643 -> 333 LOC) into 6 focused sub-widgets in lib/presentation/widgets/modals/notification_settings/ with Dart 3 record .select(...) subscriptions and GlobalKey pending-config flush
- [Phase 24-01]: Extracted instance-scoped SchoolDataCacheManager (eliminating all static override maps and counters) and domain data sources FirestoreGradesDataSource, FirestoreAttendanceDataSource, and FirestoreJustificationsDataSource with lazy FirebaseFirestore resolution and injectable http.Client
- [Phase 24]: [Phase 24-02]: Extracted FirestoreMessagesDataSource and FirestoreScheduleDataSource and reduced FirestoreSchoolRepository (2 691 -> 242 LOC) to a clean SchoolRepository facade with shared instance-scoped SchoolDataCacheManager and zero static mutable maps
