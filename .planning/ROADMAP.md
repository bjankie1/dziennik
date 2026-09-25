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
- [ ] **Phase 18: Powiadomienia w czasie rzeczywistym: Telegram Bot i Web Push** — Integracja bota Telegram w Cloud Functions z kodem parowania, natychmiastowe alerty o ocenach/wiadomościach/sprawdzianach oraz powiadomienia Web Push w przeglądarce.
- [ ] **Phase 19: Raporty tygodniowe (Piątkowy briefing sprawdzianów i planu)** — Automatyczny harmonogram Cloud Scheduler w piątki wieczorem generujący i wysyłający raport podsumowujący nadchodzący tydzień przez bota Telegram do rodzica i ucznia.

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
