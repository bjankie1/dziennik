# Roadmap: EduSync

## Overview

Milestone v3.0 („Dostęp Ucznia, Smart Zadania, Kalendarz & Powiadomienia”) rozbudowuje EduSync o bezpieczny dostęp dla Oskara (ucznia) ze współdzielonym cache'em i separacją uprawnień rodzic/uczeń, inteligentny moduł zadań (Smart To-Do) zintegrowany z terminarzem i wiadomościami, bezpośredni eksport sprawdzianów do Kalendarza Google oraz wielokanałowe powiadomienia (Telegram Bot + Web Push) wraz z automatycznym piątkowym raportem tygodniowym.

## Phases

### Completed Phases (v1.0 & v2.0)

- [x] **Phase 1: Naprawa nawigacji planu lekcji i kompaktowy pulpit ocen** — Interaktywny przełącznik dni tygodnia w zakładce Plan oraz siatka kompaktowych kafelków ocen z datami na Pulpicie.
- [x] **Phase 2: Rzeczywista frekwencja (Librus Synergia)** — Scraper modułu nieobecności, statystyki semestralne i podgląd wpisów w zakładce Frekwencja.
- [x] **Phase 3: Rzeczywiste wiadomości i powiadomienia** — Scraper skrzynki odbiorczej Librus, wątki konwersacji i powiadomienia w czasie rzeczywistym.
- [x] **Phase 4: Bezpieczny autologin i trwałe powiązanie profilu Librus** — Zapisanie i automatyczne wczytywanie powiązania Librus z Firestore po zalogowaniu kontem Google, eliminacja wymogu ponownego podawania loginu, odporność na odświeżenie strony (F5).
- [x] **Phase 5: Nowy interfejs Ocen wg makiety** — Karta średniej ważonej z postępem stypendium i pozycją w klasie, pigułki ocen z wagami w wierszu przedmiotu bez konieczności rozwijania, szczegółowy akordeon ocen.
- [x] **Phase 6: Moduł usprawiedliwiania nieobecności wg makiety** — Kołowy wykres frekwencji, filtry, checkboxy lekcji pogrupowane dniami, dolny panel wyboru szybkiego powodu i wysyłanie usprawiedliwienia do Librus.
- [x] **Phase 7: Funkcjonalny moduł wiadomości (czytanie, odpowiadanie, wysyłanie)** — Widok wątku wiadomości w stylu Gmail, odpowiadanie na wiadomości oraz nowa wiadomość z autocomplete nauczyciela (nazwisko + przedmiot).
- [x] **Phase 8: Pełny design ekranu głównego w wersji web** — Nowoczesny dashboard webowy (desktop/tablet/mobile) z bento-grid, podsumowaniem dnia, nadchodzącymi sprawdzianami, planem dnia, statystykami ocen i frekwencji.
- [x] **Phase 9: Plan lekcji w wersji web (Widok siatki i agendy)** — Nowoczesny desktopowy i responsywny plan lekcji z widokiem pełnej siatki tygodniowej oraz agendy wg makiet (docs/plan_lekcji_v1 i docs/plan lekcji agenda).
- [x] **Phase 10: Pełen panel ocen w wersji na przeglądarkę** — Nowoczesny dwukolumnowy panel ocen na desktopie z wyborem przedmiotu, szczegółami ocen, wykresem/statystykami i szufladą (drawer) szczegółów oceny wg makiet docs/panel_ocen i docs/szczegoly_oceny.
- [x] **Phase 11: Dyskretne odpytywanie serwerów Librus (rate limiting, harmonogram nocny)** — Optymalizacja strategii synchronizacji z Librus (inteligentny throttling, losowy jitter, dynamiczny backoff, całkowite wyłączenie odpytywania w nocy oraz cache'owanie), aby nie budzić podejrzeń o łamanie regulaminu serwisu. (completed 2026-09-18)
- [x] **Phase 12: Audyt mocków, nieobecności w planie lekcji i stała szerokość przełącznika tygodni** — Kompleksowy audyt i usunięcie sztucznych mocków/wartości fallbackowych w kodzie, prezentacja nieobecności/frekwencji w planie lekcji oraz stała szerokość nawigatora tygodni. (completed 2026-09-20)
- [x] **Phase 13: Dedykowane URL i routing dla podstron i zasobów (deep linking)** — Wdrożenie routingu URL go_router z HTML5 History API bez hasha, dedykowane ścieżki po polsku oraz deep linking do wiadomości i planu lekcji. (completed 2026-09-21)

### Active Milestone Phases (v3.0)

- [x] **Phase 14: Dostęp ucznia (rola student vs parent) i współdzielony cache danych** — Logowanie kontem Google Oskara, separacja ról (`student` vs `parent`) z blokadą e-usprawiedliwień i PIN dla ucznia oraz Single Source of Truth w Firestore bez duplikowania scrapingu. (completed 2026-09-22)
- [x] **Phase 14.1: Czat rodzinny i dwukierunkowy dialog usprawiedliwień** (INSERTED) — Komunikator rodzinny (Rodzic ↔ Uczeń) w czasie rzeczywistym, bezpośredni przycisk „Odrzuć” z komentarzem rodzica na Pulpicie i we Frekwencji oraz wątek dialogu Q&A i ponownej prośby ucznia. (completed 2026-09-23)
- [x] **Phase 15: Moduł zadań (Smart To-Do) i widżet na Pulpicie** — Dedykowana podstrona `/zadania` w menu bocznym i nawigacji oraz interaktywny widżet zadań w Bento Grid na Pulpicie z szybkim odhaczaniem. (completed 2026-09-23)
- [x] **Phase 16: Inteligentne podpowiedzi zadań ze sprawdzianów i wiadomości oraz dwukierunkowe linkowanie źródeł** — Trwałe powiązanie zadań ze źródłem (`sourceId` dla sprawdzianów i wiadomości), blokada duplikacji po odświeżeniu strony (F5), bezpośrednie linki do już utworzonych zadań oraz tworzenie zadań z widoku wiadomości (np. opłacenie składki). (completed 2026-09-23)
- [x] **Phase 17: Eksport sprawdzianów do Kalendarza Google i iCal** — Przycisk „Dodaj do Kalendarza Google” w kafelkach sprawdzianów i modalu lekcji oraz pobieranie plików kalendarzowych `.ics` (w tym zbiorczy eksport wszystkich sprawdzianów). (completed 2026-09-23)
- [x] **Phase 17.1: Refactoring architektury widoków i biblioteka współdzielonych komponentów UI (INSERTED)** — Dekompozycja monolitycznych ekranów (`dashboard_screen.dart` 3833 LOC → 381 LOC) na modułowe sub-widgety `ConsumerWidget` oraz ekstrakcja powtarzających się wzorców UI (`BentoCard`, `GradeBadgePill`, `LinkedTaskActionBar`, `ExamCalendarActionsRow`, `FilterChipPill`, `JustificationApprovalBanner`) do `lib/presentation/widgets/common/`. (completed 2026-09-24)
- [x] **Phase 18: Powiadomienia w czasie rzeczywistym: Telegram Bot i Web Push** — Integracja bota Telegram w Cloud Functions z kodem parowania, natychmiastowe alerty o ocenach/wiadomościach/sprawdzianach oraz powiadomienia Web Push w przeglądarce. (completed 2026-09-25)
- [ ] **Phase 19: Raporty tygodniowe (Piątkowy briefing sprawdzianów i planu)** — Automatyczny harmonogram Cloud Scheduler w piątki wieczorem generujący i wysyłający raport podsumowujący nadchodzący tydzień przez bota Telegram do rodzica i ucznia.
- [x] **Phase 20: Asystent AI dziennika szkolnego (Konwersacyjny agent Q&A)** — Konwersacja z agentem AI na temat danych w dzienniku (oceny, plan lekcji, sprawdziany, wiadomości, ogłoszenia, nieobecności, zadania) z przeszukiwaniem pełnej treści wiadomości (np. „Kiedy jest następny sprawdzian?”, „Kiedy jest wycieczka Oskara do Warszawy?”, „Kiedy jest zebranie z rodzicami?”). (completed 2026-09-26)
- [ ] **Phase 21: Refaktoryzacja monolitycznych widoków UI (>1 600 LOC), wspólne komponenty i optymalizacja granic przebudowy Riverpod** — Dekompozycja `message_thread_screen.dart` (2 059 LOC), `attendance_screen.dart` (1 942 LOC) oraz `notification_settings_modal.dart` (1 642 LOC) na modularne klasy `ConsumerWidget` / `StatelessWidget` (< 350 LOC), wydzielenie wspólnego `JustificationRequestBanner` i `PolishDateFormatter` oraz zawężenie przebudów przez `.select(...)`.
- [x] **Phase 22: Zapisywanie załączników wiadomości w Google Drive w stylu Gmail** — Zapisywanie pojedynczych lub wszystkich załączników wiadomości Librus na żądanie użytkownika bezpośrednio na jego koncie Google Drive (do dedykowanego folderu np. `EduSync / Załączniki szkolne`) z wizualnym statusem zapisania i bezpośrednim linkiem „Otwórz w Google Drive” na wzór Gmaila. (completed 2026-09-29)
- [x] **Phase 23: Podgląd szczegółów próśb o usprawiedliwienie i oczekujących wniosków** — Możliwość podglądu konkretnych dni, numerów lekcji, przedmiotów, godzin i powodów zarówno na banerze prośby o usprawiedliwienie („6 lekcji • Choroba” na Pulpicie i we Frekwencji), jak i na banerze oczekujących wniosków („7 wnioski czekają na wychowawcę”). (completed 2026-10-02)
- [ ] **Phase 24: Dekompozycja monolitycznego FirestoreSchoolRepository (2 691 LOC) na serwisy domenowe i izolacja warstwy cache** — Podział `FirestoreSchoolRepository` na wyspecjalizowane klasy domenowe (`SchoolDataCacheManager`, `FirestoreGradesDataSource`, `FirestoreAttendanceDataSource`, `FirestoreJustificationsDataSource`, `FirestoreMessagesDataSource`, `FirestoreScheduleDataSource`) z eliminacją statycznych map globalnych i zachowaniem fasady `SchoolRepository`.

---

## Phase Details

### Phase 14: Dostęp ucznia (rola student vs parent) i współdzielony cache danych

**Goal**: Umożliwienie Oskarowi (uczniowi) logowania kontem Google z powiązaniem do wspólnego profilu edukacyjnego w Firestore, z automatyczną separacją ról (`student` vs `parent` – brak możliwości edycji PIN oraz wysyłania usprawiedliwień dla roli ucznia) oraz pojedynczym źródłem prawdy (Single Source of Truth) dla pobranych danych bez duplikowania zapytań do serwerów Librus.  
**Requirements**: REQ-ROLE-01, REQ-ROLE-02, REQ-ROLE-03  
**Depends on**: Phase 13  
**Success Criteria**:

1. Użytkownik logujący się adresem e-mail Oskara (Google OAuth) zostaje przypisany do profilu ucznia z rolą `student`, podczas gdy konto rodzica zachowuje rolę `parent`.
2. Użytkownik z rolą `student` nie ma dostępu do modułu wysyłania e-usprawiedliwień (formularz i przyciski wysyłania są zablokowane/ukryte) ani do wglądu i konfiguracji kodu PIN rodzica.
3. Dane szkolne (oceny, frekwencja, plan lekcji, terminarz) są współdzielone w centralnej kolekcji Firestore — logowanie i odświeżenie danych przez ucznia korzysta z tego samego cache'a co rodzic, nie wywołując zdublowanego scrapingu serwerów Librus.
4. Interfejs aplikacji prezentuje odpowiedni kontekst użytkownika (np. etykietę profilu "Oskar - Uczeń" lub "Rodzic") i poprawnie izoluje preferencje użytkownika przy współdzieleniu danych akademickich.

**Plans:** 3 plans

Plans:

- [x] 14-01-PLAN.md: Data Layer & Backend Roles & Shared Cache (Wave 1)
- [x] 14-02-PLAN.md: Student Justification Request Flow & Parent PIN Approval (Wave 2)
- [x] 14-03-PLAN.md: Role Badge, Connect Screen Selection & Student Message Session (Wave 3)

### Phase 14.1: Czat rodzinny i dwukierunkowy dialog usprawiedliwień (INSERTED)

**Goal**: Wdrożenie bezpośredniego czatu rodzinnego w czasie rzeczywistym między kontem rodzica a ucznia w aplikacji oraz rozszerzenie obiegu e-usprawiedliwień o akcję odmowy z komentarzem rodzica na Pulpicie i we Frekwencji, a także wątek pytań i odpowiedzi (Q&A) z możliwością ponownej prośby Oskara.  
**Requirements**: REQ-ROLE-04, REQ-CHAT-01  
**Depends on**: Phase 14  
**Success Criteria**:

1. Na kafelku prośby na Pulpicie (`DashboardScreen`) oraz we Frekwencji (`AttendanceScreen`) obok przycisku „Zatwierdź (PIN)” widnieje przycisk „Odrzuć”, otwierający formularz wpisania komentarza/pytania do Oskara.
2. Oskar na swoim koncie widzi powód odmowy i ma możliwość natychmiastowej odpowiedzi / ponownej prośby z dodatkowym wyjaśnieniem (wątek konwersacji w dokumencie wniosku w Firestore).
3. Powstaje dedykowany moduł Czatu Rodzinnego (Rodzic ↔ Uczeń) w czasie rzeczywistym w Firestore z obsługą konwersacji tekstowych.
4. Wnioski o usprawiedliwienie mogą być automatycznie podlinkowane lub osadzone w konwersacji czatu jako interaktywne karty.

**Plans:** 3 plans

Plans:

- [x] 14.1-01-PLAN.md: Backend & Domain Layer for Rejection Dialogue & Family Chat (Wave 1)
- [x] 14.1-02-PLAN.md: Two-Way Excuse Rejection Dialogue UI (Wave 2)
- [x] 14.1-03-PLAN.md: Real-Time Family Chat & Navigation Integration (Wave 3)

### Phase 15: Moduł zadań (Smart To-Do) i widżet na Pulpicie

**Goal**: Wdrożenie pełnoprawnego modułu zarządzania zadaniami ucznia i rodzica z dedykowaną podstroną `/zadania` w menu nawigacyjnym oraz interaktywnym widżetem szybkiej listy zadań w Bento Grid na Pulpicie (desktop oraz mobile).  
**Requirements**: REQ-TASK-01, REQ-TASK-02  
**Depends on**: Phase 14  
**Success Criteria**:

1. W menu bocznym (`AppSidebar`) oraz dolnym pasku nawigacji pojawia się nowa pozycja `/zadania` prowadząca do podstrony To-Do z obsługą deep linkingu go_router.
2. Widok `/zadania` umożliwia tworzenie, edycję, oznaczanie ukończenia i usuwanie zadań wraz z terminami (Due Date), priorytetami i filtrowaniem (Wszystkie, Dzisiaj, Nadchodzące, Ukończone).
3. Karta Bento Grid na Pulpicie (`DashboardScreen`) wyświetla listę najpilniejszych zadań na dany dzień z możliwością natychmiastowego odhaczenia jednym kliknięciem bez opuszczania pulpitu.
4. Zadania są trwale synchronizowane w kolekcji Firestore powiązanej z profilem ucznia z natychmiastową reaktywnością (Riverpod / StreamProvider).

**Plans:** 3 plans

Plans:

- [x] 15-01-PLAN.md: Domain Model (`SchoolTask`), Firestore Security Rules & Real-Time `TasksRepository` (Wave 1)
- [x] 15-02-PLAN.md: `/zadania` Screen (`TasksScreen` + `TaskFormModal`) & 7-Branch Navigation Shell (Wave 2)
- [x] 15-03-PLAN.md: Dashboard Bento Grid Widget „Zadania na dziś” in Desktop Column 2 & Mobile (Wave 3)

### Phase 16: Inteligentne podpowiedzi zadań ze sprawdzianów i wiadomości oraz dwukierunkowe linkowanie źródeł

**Goal**: Automatyzacja tworzenia zadań edukacyjnych i organizacyjnych ze sprawdzianów i wiadomości z deterministycznym powiązaniem ze źródłem (`sourceId`), trwałą pamięcią między odświeżeniami (Firestore + `SharedPreferences`), ochroną przed duplikacją oraz dwukierunkowymi linkami między zadaniem a źródłem (sprawdzianem w planie / wiadomością w skrzynce).  
**Requirements**: REQ-TASK-03, REQ-TASK-04  
**Depends on**: Phase 15  
**Success Criteria**:

1. Zadania tworzone ze sprawdzianów (na Pulpicie i w modalu lekcji) oraz z wiadomości otrzymują kanoniczny identyfikator źródła (`sourceId`) i są trwale zapisywane w Firestore oraz `SharedPreferences` — po odświeżeniu strony (`F5`) nie można utworzyć duplikatu, a w miejscu przycisku wyświetla się link do już utworzonego zadania (`✓ Powiązane zadanie` + `Pokaż zadanie`).
2. W widoku wątku wiadomości (`/wiadomosci/:id`) oraz na liście wiadomości (`/wiadomosci`) mechanizm heurystyczny analizuje treść pod kątem składek/opłat (np. „opłacenie składki”, kwoty w zł), zgód i terminów, prezentując baner „Wykryto składkę / opłatę” z akcją `+ Dodaj zadanie (1-klik)` lub `Dostosuj przed dodaniem...`.
3. Na kartach zadań w `/zadania` oraz w modalu zadania wyświetlana jest klikalna pigułka źródła (`Źródło: Sprawdzian: ...` / `Źródło: Wiadomość: ...`), która przenosi użytkownika bezpośrednio do powiązanej lekcji w planie lub wiadomości w skrzynce.

**Plans:** 2 plans

Plans:

- [x] 16-01-PLAN.md: Canonical Source Linking (`sourceId`), Deduplication & Persistent Storage Across Page Reloads (`Firestore` + `SharedPreferences`)
- [x] 16-02-PLAN.md: Smart Task Creation & Heuristic Fee/Consent Detection in Messages View (`MessageThreadScreen` & `MessagesScreen`) + Bidirectional Source Links

### Phase 17: Eksport sprawdzianów do Kalendarza Google i iCal

**Goal**: Bezproblemowa integracja sprawdzianów, kartkówek i wydarzeń szkolnych z zewnętrznymi kalendarzami użytkownika poprzez bezpośrednie generowanie linków do Kalendarza Google oraz uniwersalnych plików `.ics` (iCal / Apple Calendar / Outlook).  
**Requirements**: REQ-CAL-01, REQ-CAL-02  
**Depends on**: Phase 14  
**Success Criteria**:

1. Kafelki sprawdzianów w terminarzu, widżecie Bento Grid oraz w modalu szczegółów lekcji posiadają przycisk „Dodaj do Kalendarza Google”, otwierający w nowej karcie predefiniowane wydarzenie z poprawnym tytułem, zakresem, datą i godzinami zajęć.
2. Każde wydarzenie/sprawdzian udostępnia opcję pobrania pliku `.ics` ze sformatowanym standardem RFC 5545 (strefa Europe/Warsaw, opis, lokalizacja sali).
3. Użytkownik może pobrać zbiorczy plik `.ics` dla wszystkich nadchodzących sprawdzianów w danym miesiącu/semestrze jednym kliknięciem.
4. Generowanie linków i plików `.ics` działa bezbłędnie na urządzeniach stacjonarnych i mobilnych (obsługa pobierania w przeglądarce).

**Plans:** 2 plans

Plans:

- [x] 17-01-PLAN.md: CalendarExportService (Google Calendar URL template + RFC 5545 `.ics` generator with `Europe/Warsaw` & `VALARM`) & Web Interop Helper
- [x] 17-02-PLAN.md: UI Integration on Dashboard Exam Cards, Lesson Details Modal & Bulk `.ics` Export Dialog in Schedule Screen

### Phase 17.1: Refactoring architektury widoków i biblioteka współdzielonych komponentów UI (INSERTED)

**Goal**: Eliminacja długu technicznego i duplikacji kodu poprzez rozbicie monolitycznych widoków (`dashboard_screen.dart` – 3 832 linii, `attendance_screen.dart` – 1 548 linii, `grades_screen.dart` – 1 162 linie) na niezależne, reużywalne klasy `ConsumerWidget` / `StatelessWidget` oraz wydzielenie wspólnej biblioteki komponentów (`lib/presentation/widgets/common/`).  
**Requirements**: REQ-ARCH-01, REQ-ARCH-02  
**Depends on**: Phase 17  
**Success Criteria**:

1. Żaden plik ekranu w `lib/presentation/screens/` nie przekracza ~500–600 linii kodu; `dashboard_screen.dart` (obecnie 3 832 LOC) zostaje rozbity na autonomiczne widgety sekcji (`lib/presentation/screens/dashboard/widgets/`), z których każdy subskrybuje wyłącznie własny wycinek stanu Riverpod (`ref.watch`).
2. Powtarzające się wizualnie komponenty mają jedną, kanoniczną reprezentację w `lib/presentation/widgets/common/`:
   - `BentoCard` (wspólny kontener kart z cieniem, obramowaniem i nagłówkiem sekcji),
   - `LinkedTaskActionBar` (wspólny pasek „+ Zadanie dla Oskara” / „✓ Powiązane zadanie” używany na Pulpicie, w modalu lekcji i w wiadomościach),
   - `ExamCalendarActionsRow` (wspólny rząd przycisków `+ Kalendarz Google` oraz `.ics`),
   - `GradeBadgePill` (zunifikowana pigułka oceny z wagą i kolorystyką MEN 1–6),
   - `FilterChipPill` (wspólny przełącznik filtrów/zakładek),
   - `JustificationApprovalBanner` (wspólny komponent i dialogi PIN / odrzucenia prośby ucznia dla Pulpitu i Frekwencji).
3. Kompilacja `flutter analyze` przechodzi z 0 błędów/ostrzeżeń, a wszystkie funkcje na produkcji działają identycznie przy mniejszym narzucie przebudowy drzewa widgetów (Element Tree).

**Plans:** 3 plans

Plans:

- [x] 17.1-01-PLAN.md: Shared UI Component Library (`lib/presentation/widgets/common/`: `BentoCard`, `GradeBadgePill`, `FilterChipPill`, `LinkedTaskActionBar`, `ExamCalendarActionsRow`, `JustificationApprovalBanner`)
- [x] 17.1-02-PLAN.md: Decomposition of `DashboardScreen` (3832 LOC → modular `lib/presentation/screens/dashboard/widgets/` with isolated Riverpod rebuild boundaries)
- [x] 17.1-03-PLAN.md: Refactoring of `AttendanceScreen`, `LessonDetailsModal`, and `MessageThreadScreen` to consume shared widgets

### Phase 18: Powiadomienia w czasie rzeczywistym: Telegram Bot i Web Push

**Goal**: Stworzenie wielokanałowego systemu powiadomień natychmiastowych o kluczowych zdarzeniach szkolnych (nowa ocena, nowa wiadomość, nadchodzący sprawdzian) z wykorzystaniem bota Telegram oraz powiadomień Web Push w przeglądarce.  
**Requirements**: REQ-NOTIF-01, REQ-NOTIF-02, REQ-NOTIF-03  
**Depends on**: Phase 14  
**Success Criteria**:

1. Integracja Telegram Bot w Firebase Cloud Functions z generowaniem jednorazowego 6-cyfrowego kodu parowania w ustawieniach aplikacji, umożliwiającego powiązanie czatu Telegram rodzica lub ucznia z ich kontem.
2. Wykrycie w cyklu synchronizacji nowej oceny, nowej wiadomości lub dodanego sprawdzianu powoduje natychmiastowe wysłanie sformatowanego powiadomienia na powiązany czat Telegram z kluczowymi szczegółami (przedmiot, ocena, waga, nadawca).
3. Aplikacja webowa rejestruje Service Worker i obsługuje subskrypcję Web Push API (VAPID / FCM), wyświetlając natywne powiadomienia w przeglądarce po uzyskaniu zgody użytkownika.
4. W ustawieniach użytkownik może niezależnie włączać i wyłączać kanały powiadomień (Telegram / Web Push) oraz kategorie zdarzeń.

**Plans:** 2 plans

Plans:

- [x] 18-01-PLAN.md: Telegram Bot Cloud Functions (`telegram_service.js`, 6-digit pairing code verification, exam diff detection & HTML notification dispatch in `sync_service.js`)
- [x] 18-02-PLAN.md: Web Push Service Worker (`/sw-notifications.js`), JS Interop & `NotificationSettingsModal` UI with per-role channel & category toggles

### Phase 19: Raporty tygodniowe (Piątkowy briefing sprawdzianów i planu)

**Goal**: Automatyczne generowanie i dostarczanie zwięzłego, ustrukturyzowanego podsumowania nadchodzącego tygodnia szkolnego w każdy piątek wieczorem do rodzica i ucznia za pośrednictwem bota Telegram.  
**Requirements**: REQ-REPORT-01, REQ-REPORT-02  
**Depends on**: Phase 18  
**Success Criteria**:

1. Zadanie Cloud Scheduler uruchamiane w każdy piątek o godz. 18:00 (Europe/Warsaw) agreguje plan lekcji, zaplanowane sprawdziany, kartkówki oraz zadania domowe na nadchodzący tydzień (poniedziałek–piątek).
2. Cloud Function formatuje czytelny, estetyczny raport Markdown (z podziałem na dni, listą sprawdzianów, ważnymi ogłoszeniami i zadaniami).
3. Raport jest automatycznie wysyłany przez bota Telegram do wszystkich sparowanych kont (rodzic oraz uczeń).
4. W przypadku braku sprawdzianów w danym tygodniu raport zawiera pozytywny komunikat podsumowujący (spokojny tydzień) wraz z ramowym planem zajęć.

**Plans:** 2 plans

Plans:

- [ ] 19-01-PLAN.md: Backend Weekly Briefing Engine (`functions/src/weekly_briefing_service.js`) & Friday 18:00 Cloud Scheduler (`scheduledWeeklyBriefing` + `sendWeeklyBriefingNow`)
- [ ] 19-02-PLAN.md: Client Weekly Briefing Generator (`weekly_briefing_service.dart`), `WeeklyBriefingModal` preview & 1-click Telegram dispatch in `NotificationSettingsModal` and `WeekNavigatorBar`

### Phase 20: Asystent AI dziennika szkolnego (Konwersacyjny agent Q&A)

**Goal**: Konwersacja z agentem na temat tego co znajduje się w dzienniku czyli oceny, plan lekcji, sprawdziany, wiadomości, nieobecności. Przykładowy prompt: „Kiedy jest następny sprawdzian”, „Kiedy jest wycieczka Oskara do Warszawy” lub „Kiedy jest zebranie z rodzicami”.  
**Requirements**: REQ-AI-01, REQ-AI-02  
**Depends on**: Phase 19  
**Success Criteria**:

1. Użytkownik (rodzic lub uczeń) ma dostęp do konwersacyjnego czatu z Asystentem AI dziennika (w aplikacji webowej/mobilnej oraz opcjonalnie przez sparowanego bota Telegram), z gotowymi chipami szybkich pytań (np. „Kiedy jest następny sprawdzian?”, „Kiedy jest wycieczka Oskara do Warszawy?”, „Kiedy jest zebranie z rodzicami?”, „Jakie mam nieusprawiedliwione nieobecności?”).
2. Agent AI buduje ustrukturyzowany kontekst (RAG / Context Grounding) z aktualnych danych w Firestore: ocen cząstkowych i średnich, planu lekcji, terminarza sprawdzianów, nieobecności, zadań To-Do oraz **pełnych treści wiadomości i ogłoszeń Librus** (gdzie znajdują się informacje o wycieczkach, zebraniach z rodzicami i składkach).
3. Odpowiedzi agenta cytują konkretne źródła z dziennika (np. datę i nadawcę wiadomości o wycieczce lub zebraniu, dokładną datę i zakres sprawdzianu) oraz zawierają klikalne odnośniki (deep linki) do powiązanej wiadomości (`/wiadomosci/:id`), planu lekcji (`/plan-lekcji?data=...`) lub ocen (`/oceny`).
4. Jeśli w pobranych nagłówkach wiadomości brakuje pełnej treści (`body`) dla potencjalnie pasujących tematów, system automatycznie dociąga brakujące treści wiadomości przed udzieleniem odpowiedzi i nigdy nie zmyśla faktów spoza dziennika.

**Plans:** 2 plans

Plans:

- [x] 20-01-PLAN.md: Backend Full Message Body Indexing (`sync_service.js` + `librus_client.js`) + Flutter AI Domain Models, `SchoolAiContextBuilder` & `SchoolAiAssistantService` (`firebase_ai: ^4.0.0`, Gemini 3.8 Flash / 3.1 Pro)
- [x] 20-02-PLAN.md: Riverpod AI Providers (`ai_assistant_provider.dart`), Per-Role Firestore History, Floating Chat Widget (`FloatingChatFab` + `FloatingChatPanel`) & Dual-Mode `FamilyChatScreen` Integration

### Phase 21: Refaktoryzacja monolitycznych widoków UI (>1 600 LOC), wspólne komponenty i optymalizacja granic przebudowy Riverpod

**Goal**: Doprowadzenie największych widoków aplikacji (`message_thread_screen.dart` – 2 059 LOC, `attendance_screen.dart` – 1 942 LOC, `notification_settings_modal.dart` – 1 642 LOC) do pełnej zgodności z dobrymi praktykami Fluttera i Riverpod poprzez dekompozycję monolitycznych klas `State` i prywatnych metod `Widget _build*()` na autonomiczne widgety `ConsumerWidget` / `StatelessWidget` z konstruktorami `const`, wydzielenie wspólnego komponentu `JustificationRequestBanner` oraz helpera `PolishDateFormatter`, a także zawężenie przebudów drzewa widgetów przez `.select(...)`.  
**Requirements**: REQ-ARCH-01, REQ-ARCH-02  
**Depends on**: Phase 23  
**Success Criteria**:

1. Pliki `message_thread_screen.dart` (2 059 LOC), `attendance_screen.dart` (1 942 LOC) oraz `notification_settings_modal.dart` (1 642 LOC) zostają zredukowane do **< 350 LOC każdy**, pełniąc rolę koordynatorów układu delegujących sekcje do dedykowanych klas widgetów (`widgets/`).
2. Powtarzający się w 3 miejscach (`DashboardMobileView`, `DashboardMetricsColumn`, `AttendanceScreen`) żółty baner prośby ucznia o usprawiedliwienie zostaje zastąpiony jednym współdzielonym komponentem `JustificationRequestBanner` w `lib/presentation/widgets/common/`, a formatowanie polskich dat jednym helperem `PolishDateFormatter` w `lib/core/utils/`.
3. Prywatne metody pomocnicze `Widget _build*()` w refaktoryzowanych ekranach zostają zastąpione klasami `StatelessWidget` / `ConsumerWidget` z konstruktorami `const` i selektywnym `ref.watch(...select(...))`, dzięki czemu lokalne interakcje (np. zaznaczenie checkboxa lekcji, rozwinięcie akordeonu, pisanie odpowiedzi) przebudowują wyłącznie dany pod-widget, a nie cały ekran.
4. `flutter analyze` zwraca 0 błędów i ostrzeżeń, a wszystkie istniejące testy widgetów przechodzą bez regresji.

**Plans:** 4/4 plans executed

Plans:
**Wave 1**

- [x] 21-01-PLAN.md: Shared Foundation — `PolishDateFormatter` (`lib/core/utils/polish_date_formatter.dart` + unit tests) & `JustificationRequestBanner` (`lib/presentation/widgets/common/justification_request_banner.dart`, replacing duplicated ~300 LOC banners in `DashboardMobileView` & `DashboardMetricsColumn`)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 21-02-PLAN.md: `message_thread_screen.dart` Decomposition (`2 060 LOC` -> `< 350 LOC`) — `MessageThread` domain helpers (`resolveSenderName`, `extractCcTeacherFromBody`, `looksLikeMessageWithAttachment`) + 4 sub-widgets (`MessageThreadHeaderCard`, `MessageTaskBanner`, `MessageAccordionTile`, `MessageReplyComposer`) with `.select(...)`
- [x] 21-03-PLAN.md: `attendance_screen.dart` Decomposition (`1 952 LOC` -> `< 350 LOC`) — 6 sub-widgets (`AttendanceSemesterKpiCard`, `PendingTeacherAccordionBanner`, `AttendanceFilterBar`, `AttendanceDayGroupCard`, `FloatingJustificationDock`, `RequestedAttendanceDetailsSheet`) + `JustificationRequestBanner` & `PolishDateFormatter`
- [x] 21-04-PLAN.md: `notification_settings_modal.dart` Decomposition (`1 643 LOC` -> `< 350 LOC`) — 6 sub-widgets (`NotificationSectionCard`, `TelegramChannelCard`, `TelegramStepByStepGuide`, `WebPushChannelCard`, `NotificationCategoriesCard`, `NotificationAlertsHistoryTab`) with Dart 3 record `.select(...)` selectors

### Phase 22: Zapisywanie załączników wiadomości w Google Drive w stylu Gmail

**Goal**: Umożliwienie użytkownikowi zapisywania załączników wiadomości z Librus Synergia na własnym koncie Google Drive jednym kliknięciem („Dodaj do Dysku Google” / „Zapisz wszystkie na Dysku”), analogicznie do obsługi załączników w Gmailu — z automatycznym tworzeniem uporządkowanego folderu docelowego (np. `EduSync - Załączniki szkolne`), zapamiętywaniem stanu zapisania w Firestore oraz bezpośrednim przyciskiem „Otwórz w Google Drive”.  
**Requirements**: REQ-DRIVE-01, REQ-DRIVE-02  
**Depends on**: Phase 21  
**Success Criteria**:

1. Na kafelku każdego załącznika w widoku wątku wiadomości (`MessageThreadScreen`) obok akcji pobrania na urządzenie znajduje się przycisk/ikona **„Zapisz na Dysku Google”** (w stylu Gmaila), a przy wielu załącznikach również zbiorcza akcja **„Zapisz wszystkie na Dysku”**.
2. Kliknięcie „Zapisz na Dysku Google” wykorzystuje autoryzację OAuth 2.0 konta Google zalogowanego użytkownika (scope `https://www.googleapis.com/auth/drive.file` — dostęp wyłącznie do plików utworzonych przez aplikację), pobiera strumień załącznika z Librusa przez Cloud Function (`downloadAttachment`) i przesyła go bezpośrednio na Google Drive użytkownika do dedykowanego folderu (np. `EduSync - Załączniki szkolne`).
3. Po zapisaniu załącznika na Google Drive jego stan (`driveFileId`, `webViewLink`, `savedAt`) jest utrwalany w Firestore, a ikona na kafelku zmienia się na **„Zapisano na Dysku — Otwórz w Google Drive”**, pozwalając jednym kliknięciem otworzyć plik lub folder w Google Drive bez ponownego wgrywania duplikatu.
4. Proces zapisu prezentuje czytelny stan ładowania (spinner / pasek postępu na kafelku załącznika) oraz powiadomienie `SnackBar` z akcją „Otwórz na Dysku”.

**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 22-01-PLAN.md: Cloud Functions Google Drive Service (`drive_service.js`, `/api/saveAttachmentToDrive`, `/api/driveFolder`), Sync Preservation (`sync_service.js`), Google OAuth `drive.file` Token Acquisition (`FirebaseAuthService`) & Repository Layer (`DriveAttachmentInfo`, `FirestoreSchoolRepository`, `MockSchoolRepository`)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 22-02-PLAN.md: Gmail-Style Attachment Actions in `MessageThreadScreen` (`Pobierz` + `Zapisz na Dysku Google` / `Otwórz w Google Drive`, bulk `Zapisz wszystkie na Dysku`), `DriveFolderPickerModal` (`Zmień folder / Przenieś`), Settings Default Drive Folder & Widget Tests

### Phase 23: Podgląd szczegółów próśb o usprawiedliwienie i oczekujących wniosków

**Goal**: Umożliwienie rodzicowi i uczniowi przejrzystego podglądu, czego dokładnie dotyczą prośby o usprawiedliwienie (zarówno na Pulpicie, jak i na ekranie Frekwencji, gdzie obecnie widać jedynie „6 lekcji • Choroba”) oraz jakie konkretnie lekcje wchodzą w skład oczekujących wniosków („7 wnioski czekają na wychowawcę”).  
**Requirements**: REQ-ATT-01, REQ-ATT-02  
**Depends on**: Phase 22  
**Success Criteria**:

1. Na banerze prośby o usprawiedliwienie (`JustificationApprovalBanner` na Pulpicie oraz na ekranie Frekwencji) użytkownik widzi nie tylko liczbę lekcji i powód (np. „6 lekcji • Choroba”), ale może jednym kliknięciem rozwinąć lub otworzyć modal szczegółów pokazujący pełną listę objętych lekcji (data, dzień tygodnia, numer lekcji, przedmiot, godziny trwania oraz notatka ucznia).
2. W modalu zatwierdzania PIN-em lub odrzucania prośby rodzic również widzi listę konkretnych lekcji i dni, których dotyczy zatwierdzana/odrzucana prośba.
3. Na ekranie Frekwencji baner „X wnioski czekają na wychowawcę” udostępnia interaktywny podgląd (rozwijana lista lub modal) wszystkich lekcji ze statusem oczekującego wniosku (data, numer lekcji, przedmiot, godzina, powód/data wysłania) wraz z możliwością cofnięcia wybranych lub wszystkich wniosków.
4. Wszystkie widoki (Pulpit desktop/mobile oraz Frekwencja) działają spójnie na rzeczywistych danych z Firestore (`justification_requests` oraz `attendances`).

**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 23-01-PLAN.md: Backend Partial Approval & Multi-Day `hoursByDate` (`justification_service.js`, `index.js`), Student Profile Name Resolution (`Oskar Jankiewicz`), Timetable Teacher/Classroom Enrichment in `getAttendanceRecords`, `JustificationRequest` Day-Grouping Helpers & Repository/Notifier `selectedRecordIds` Support

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 23-02-PLAN.md: Day-Grouped Lesson Breakdown & Per-Lesson Checkboxes in `ParentApprovalModal` & `ParentRejectionModal`, Interactive Justification Banners with `'Zobacz szczegóły →'` on Dashboard & `AttendanceScreen`, Expandable `"X wnioski czekają na wychowawcę"` Accordion with Per-Lesson `Cofnij`, 4th Filter Pill `Oczekujące (Y)` & Widget Tests

### Phase 24: Dekompozycja monolitycznego FirestoreSchoolRepository (2 691 LOC) na serwisy domenowe i izolacja warstwy cache

**Goal**: Rozbicie monolitycznego pliku `lib/data/repositories/firestore_school_repository.dart` (2 691 LOC) na wyspecjalizowane, łatwe w utrzymaniu i testowaniu serwisy domenowe w `lib/data/repositories/firestore/` oraz zastąpienie globalnych pól `static final Map<...>` instancyjnym menedżerem pamięci podręcznej (`SchoolDataCacheManager`) przy pełnym zachowaniu kontraktu interfejsu `SchoolRepository`.  
**Requirements**: REQ-ARCH-03, REQ-ARCH-04  
**Depends on**: Phase 21  
**Success Criteria**:

1. Plik `lib/data/repositories/firestore_school_repository.dart` zostaje odchudzony z **2 691 LOC do < 250 LOC**, pełniąc rolę czystej fasady implementującej `SchoolRepository` i delegującej wywołania do wyspecjalizowanych klas domenowych.
2. W katalogu `lib/data/repositories/firestore/` powstają dedykowane, jednozadaniowe moduły domenowe:
   - `SchoolDataCacheManager` (współdzielony cache dokumentu `school_data/{primaryLogin}` oraz instancyjne zarządzanie lokalnymi nadpisaniami w `SharedPreferences` bez pól `static`),
   - `FirestoreGradesDataSource` (oceny, przedmioty, średnie ważone i delty),
   - `FirestoreAttendanceDataSource` (rekordy frekwencji, wzbogacanie o nauczyciela/salę z planu lekcji, wysyłanie i cofanie wniosków),
   - `FirestoreJustificationsDataSource` (prośby ucznia, zatwierdzanie PIN-em pełne i częściowe, odrzucenia i historia Q&A),
   - `FirestoreMessagesDataSource` (wiadomości, wątki, oznaczanie przeczytania, wysyłanie, załączniki i integracja z Google Drive),
   - `FirestoreScheduleDataSource` (plan lekcji, zastępstwa, sprawdziany, szczęśliwy numerek).
3. Żaden z istniejących providerów Riverpod (`school_providers.dart`) ani ekranów UI nie wymaga zmiany swojego publicznego API, a wszystkie testy jednostkowe i widgetowe przechodzą w 100%.
4. Dodane zostają dedykowane testy jednostkowe dla `SchoolDataCacheManager` oraz wyodrębnionych klas `*DataSource`.

**Plans:** 0 plans

Plans:

- [ ] TBD (run `/gsd-plan-phase 24` to break down)
