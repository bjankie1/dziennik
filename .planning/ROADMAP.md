# Roadmap: EduSync

## Overview

Milestone v2.0 skupia się na trzech kluczowych filarach: trwałym powiązaniu konta Librus (autologin), nowoczesnym układzie ocen wg makiety (pigułki ocen z wagami w wierszu przedmiotu, szczegóły po rozwinięciu) oraz interaktywnym module usprawiedliwiania nieobecności (filtrowanie, checkboxy, wysuwany panel szybkiego usprawiedliwienia).

## Phases

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

### Phase 13: Dedykowane URL i routing dla podstron i zasobów (deep linking)

**Goal:** [To be planned]
**Requirements**: TBD
**Depends on:** Phase 12
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 13 to break down)

---

## Phase Details

### Phase 4: Bezpieczny autologin i trwałe powiązanie profilu Librus

**Goal**: Użytkownik logujący się przez konto Google nie musi ponownie podawać loginu i hasła Librus, jeśli konto zostało już wcześniej skonfigurowane i powiązane w Firestore; przeładowanie strony nie wylogowuje.
**Requirements**: REQ-AUTH-01
**Success Criteria**:

  1. Po zalogowaniu Google Auth aplikacja sprawdza w Firestore (`/api/getConnection?userId=...`) czy istnieje powiązane konto Librus.
  2. Jeśli konto Librus jest sparowane, aplikacja automatycznie przechodzi do głównego widoku pulpitu bez konieczności wyświetlania formularza logowania Librus.
  3. Przeładowanie strony (odświeżenie w przeglądarce) nie powoduje wylogowania.
  4. Wylogowanie i ponowne zalogowanie Google zachowuje powiązanie.

### Phase 5: Nowy interfejs Ocen wg makiety

**Goal**: Implementacja dedykowanego widoku ocen odpowiadającego makiecie graficznej (`media_1789491587201.png`).
**Requirements**: REQ-GRADES-01, REQ-GRADES-02, REQ-GRADES-03, REQ-GRADES-04
**Success Criteria**:

  1. Zakładki semestrów (Semestr 1, Semestr 2, Roczna) na górze ekranu.
  2. Karta podsumowania: średnia ważona, odchylenie (+0.14), wskaźnik stypendium naukowego (próg 4.75) oraz pozycja w klasie.
  3. Lista przedmiotów: wiersz każdego przedmiotu od razu prezentuje pigułki ocen z wagami (np. `5 (w:3)`, `4+ (w:2)`).
  4. Rozwinięcie wiersza przedmiotu prezentuje szczegółowy wykaz ocen z datami, wagami i komentarzami.

### Phase 6: Moduł usprawiedliwiania nieobecności wg makiety

**Goal**: Implementacja nowego widoku frekwencji i formularza usprawiedliwiania odpowiadającego makiecie (`media_1789491681801.png`).
**Requirements**: REQ-ATTN-03, REQ-ATTN-04, REQ-ATTN-05, REQ-ATTN-06
**Success Criteria**:

  1. Okrągły wskaźnik frekwencji (np. 94.2%) oraz stan semestru z celami i licznikami.
  2. Filtry: Wszystkie, Do usprawiedliwienia (X), Usprawiedliwione.
  3. Kafelki dni z etykietami stanu (np. 2 DO DECYZJI) i możliwością zaznaczania checkboxów lekcji.
  4. Pływający dolny panel z licznikiem zaznaczonych lekcji, pigułkami szybkiego powodu (Choroba, Wizyta lekarska, Sprawy rodzinne) oraz akcją wysłania usprawiedliwienia.

### Phase 7: Funkcjonalny moduł wiadomości (czytanie, odpowiadanie, wysyłanie)

**Goal**: Pełna obsługa wiadomości Librus: widok wątku w stylu Gmail, odpowiadanie na wiadomości i pisanie nowych wiadomości z inteligentnym autocomplete nauczyciela (nazwisko oraz przedmiot), prezentacja pełnej treści wiadomości oraz dynamiczne oznaczanie stanu przeczytania z licznikiem nieprzeczytanych.
**Requirements**: REQ-MSG-04, REQ-MSG-05, REQ-MSG-06, REQ-MSG-07, REQ-MSG-08
**Success Criteria**:

  1. Widok wątku wiadomości na jednym ekranie (w stylu Gmail) z chronologiczną historią konwersacji i możliwością zwijania/rozwijania wiadomości.
  2. Bezpośrednie pole szybkiej odpowiedzi w wątku wiadomości wysyłające odpowiedź do Librus Synergia.
  3. Formularz nowej wiadomości z wyszukiwarką/autocomplete odbiorcy działającym zarówno po nazwisku nauczyciela, jak i po nauczanym przedmiocie (np. "Chemia", "Pietrzak").
  4. Skuteczne wysyłanie wiadomości przez backend scraper Cloud Functions do Librus Synergia oraz natychmiastowe odświeżenie wątku.
  5. Pobieranie i prezentacja pełnej treści wiadomości z podstron Librusa (`div.container-message-content`) zamiast powtórzonego tematu, z automatycznym dociąganiem on-demand i trwałym zapisem w pamięci podręcznej Firestore.
  6. Dynamiczne oznaczanie wiadomości jako nowe i przeczytane (automatycznie przy otwarciu wątku oraz ręcznie) oraz wyświetlanie liczby nieprzeczytanych wiadomości w postaci badge na ikonie wiadomości paska nawigacji i nagłówka (ukrywany gdy brak nieprzeczytanych).

### Phase 8: Pełny design ekranu głównego w wersji web

**Goal**: Kompleksowe przeprojektowanie pulpitu głównego (Home / Dashboard) dla przeglądarek webowych na desktopie i tabletach (z zachowaniem pełnej responsywności mobilnej), z wykorzystaniem nowoczesnego układu Bento Grid, karty profilu ucznia ze szczęśliwym numerkiem, osi czasu dzisiejszych zajęć, skrótów do najnowszych ocen, frekwencji oraz szybkich akcji.
**Requirements**: REQ-DASH-02
**Success Criteria**:

  1. Responsywny układ Bento Grid optymalnie zagospodarowujący szerokość ekranu powyżej 900px i 1200px.
  2. Karta nagłówkowa z powitaniem, profilem ucznia, klasą, datą i szczęśliwym numerkiem.
  3. Sekcja planu dnia (harmonogram dzisiejszych lekcji z salami, nauczycielami i wyróżnieniem trwającej/najbliższej lekcji).
  4. Widżet podsumowania ocen (średnia ważona, ostatnie oceny z wagami i szybki skrót do pełnego modułu ocen).
  5. Widżet frekwencji (procent obecności, licznik nieobecności do usprawiedliwienia z bezpośrednim przejściem).
  6. Szybkie skróty: nowa wiadomość, usprawiedliwienie, pełny plan lekcji.

### Phase 9: Plan lekcji w wersji web (Widok siatki i agendy)

**Goal**: Implementacja nowoczesnego, desktopowego i responsywnego planu lekcji w wersji web z dwoma widokami (Siatka tygodniowa oraz Agenda dzienna) zgodnie z makietami graficznymi (`docs/plan_lekcji_v1` oraz `docs/plan lekcji agenda`).
**Requirements**: REQ-TIMETABLE-01, REQ-TIMETABLE-02, REQ-TIMETABLE-03, REQ-TIMETABLE-04
**Depends on:** Phase 8
**Success Criteria**:

  1. Przełącznik trybów widoku: Segmented control na górnym pasku (Siatka / Agenda) umożliwiający płynne przełączanie sposobu prezentacji planu.
  2. Pasek nawigacji tygodniowej: Wybór tygodnia (poprzedni / następny), wskaźnik aktualnego tygodnia, przycisk „Dzisiaj” oraz nagłówek klasy/profilu/wychowawcy.
  3. Kafelki podsumowania tygodnia: Pasek statystyk z łączną liczbą godzin, zastępstwami, sprawdzianami oraz odwołanymi lekcjami.
  4. Widok Siatki (Grid View): Tygodniowa tabela poniedziałek–piątek z kolumną godzin lekcyjnych (1–8+), kafelkami zajęć z salami, nauczycielami, tematami i kolorystycznymi znacznikami statusów (planowa, zastępstwo, odwołana, sprawdzian), z wyróżnieniem bieżącego dnia ("Dziś").
  5. Widok Agendy (Agenda View): Szczegółowa, czytelna oś czasu wybranego dnia z wyróżnieniem trwającej lekcji („Trwa teraz • Zostało X min”), rozszerzonymi informacjami o temacie, zadaniach domowych, powodach zastępstw lub odwołania lekcji.
  6. Responsywność i wspólna nawigacja: Pełna integracja ze wspólnym paskiem bocznym webowej nawigacji, responsywność na ekranach desktopowych, tabletach oraz urządzeniach mobilnych.

**Plans:** 3 plans

Plans:

- [x] 09-01-PLAN.md — Rozszerzenie modelu i providerów planu lekcji (Data & State Layer)
- [x] 09-02-PLAN.md — Widok siatki tygodniowej na desktopie i tabletach (Grid View Component & Modal)
- [x] 09-03-PLAN.md — Widok agendy dziennej i integracja przełącznika (Agenda View & Screen Integration)

### Phase 10: Pełen panel ocen w wersji na przeglądarkę

**Goal**: Kompleksowe wdrożenie nowoczesnego, pełnego panelu ocen w wersji na przeglądarkę (desktop/tablet/mobile) w oparciu o makiety `docs/panel_ocen` oraz `docs/szczegoly_oceny`. Zawiera dwukolumnowy układ Master-Detail na desktopie (lista przedmiotów z pigułkami ocen po lewej, panel inspekcji wybranego przedmiotu z wykazem ocen po prawej), wykres rozkładu ocen i trajektorii średniej, oraz wysuwaną szufladę/modal szczegółów pojedynczej oceny ze statystykami i wpływem na średnią.
**Requirements**: REQ-GRADES-05, REQ-GRADES-06, REQ-GRADES-07, REQ-GRADES-08
**Depends on:** Phase 9
**Success Criteria**:

  1. Górny nagłówek akademicki: kontekst semestru, klasy i szkoły, pasek akcji (filtrowanie wag, eksport, przelicz GPA) oraz zakładki okresu (Semestr 1, Semestr 2, Klasyfikacja Roczna).
  2. Kafelki metryk KPI: duża karta średniej ważonej z trendem i lokatą w klasie oraz karta rozkładu ocen cząstkowych ze słupkowym wykresem skali 1-6 i wskaźnikiem zagrożeń.
  3. Master-Detail Ledger: po lewej tabela przedmiotów z wagami ocen, średnią ważoną, oceną przewidywaną i ostatnim wpisem; zaznaczenie przedmiotu aktywuje go i aktualizuje prawy panel inspekcji.
  4. Prawy panel inspekcji przedmiotu: nagłówek wybranego przedmiotu z nauczycielem i średnią, wykaz ocen cząstkowych z wagami, procentami i komentarzami nauczyciela.
  5. Szuflada / modal szczegółów oceny (docs/szczegoly_oceny): po kliknięciu na ocenę otwiera się szczegółowy widok z dużą oceną, kategorią, wagą, terminem, komentarzem nauczyciela oraz wizualizacją wpływu oceny na średnią.
  6. Wykres trajektorii średniej: wizualizacja liniowa/krzywa postępu średniej ucznia na tle średniej klasy w trakcie semestru.
  7. Responsywność i wspólna nawigacja: bezproblemowe działanie wewnątrz wspólnego `AppSidebar` na desktopie i płynne dostosowanie do tabletów i urządzeń mobilnych.

**Plans:** 2 plans

Plans:

- [x] 10-01-PLAN.md — Layout Master-Detail, tokeny, Riverpod providery, KPI (histogram) i tabela ocen
- [x] 10-02-PLAN.md — Wykres trajektorii średniej, szuflada (drawer) szczegółów oceny i pełna integracja

### Phase 11: Dyskretne odpytywanie serwerów Librus (rate limiting, harmonogram nocny)

**Goal**: Ulepszenie strategii odpytywania serwerów Librus (inteligentny throttling, losowy jitter, dynamiczny backoff oraz całkowite wyłączenie odpytywania w godzinach nocnych), aby nie budzić podejrzeń o automatyzację ani łamanie regulaminu serwisu.
**Requirements**: TBD
**Depends on:** Phase 10
**Success Criteria**:

  1. Harmonogram nocny: Całkowite zawieszenie automatycznego odpytywania serwerów Librus w godzinach nocnych (np. 23:00 – 06:00).
  2. Inteligentny throttling i jitter: Wprowadzenie losowych odstępów czasowych (jitter) pomiędzy żądaniami imitujących naturalne zachowanie człowieka zamiast stałych interwałów crona.
  3. Dynamiczny backoff: Automatyczne wydłużanie przerw w przypadku błędów HTTP (429, 503) lub wykrycia captcha/blokady.
  4. Cache-first & conditional requests: Wykorzystanie pamięci podręcznej Firestore/lokalnej, aby nie generować zbędnego ruchu.
  5. Manual on-demand sync: Możliwość wymuszenia odświeżenia na żądanie użytkownika z odpowiednim limitem (np. max 1 na 2 minuty).

**Plans:** 2/2 plans complete

Plans:

- [x] 11-01-PLAN.md — Bezpieczne odpytywanie serwerów Librus, humanizacja zapytań i odporność na rate limiting
- [x] 11-02-PLAN.md — Adaptacyjny harmonogram backendu (strefa Europe/Warsaw) i ograniczenia po stronie klienta

### Phase 12: Audyt mocków, nieobecności w planie lekcji i stała szerokość przełącznika tygodni

**Goal**: Kompleksowy audyt bazy kodu pod kątem ukrytych danych mockowanych / zastępczych, integracja statusów obecności/nieobecności bezpośrednio z kafelkami planu lekcji oraz zablokowanie stałej szerokości kontenera dat w przełączniku tygodni.
**Requirements**: REQ-AUDIT-01, REQ-TIMETABLE-05, REQ-TIMETABLE-06
**Depends on:** Phase 9, Phase 11
**Success Criteria**:

  1. Identyfikacja i usunięcie nieuzasadnionych wartości mockowych (np. sztywne sprawdziany, statyczne nazwy klas/profili, fallbacki do fikcyjnych ocen/ogłoszeń) i zastąpienie ich danymi rzeczywistymi z Firestore lub czystymi stanami pustymi (Empty State).
  2. Nanoszenie statusów frekwencji ucznia (nieobecność, usprawiedliwiona, spóźnienie, zwolnienie) bezpośrednio na kafelki lekcji w widoku tygodniowym (siatka) i dziennym (agenda) oraz w modalu szczegółów lekcji.
  3. Stała szerokość elementu wyboru tygodnia (WeekNavigatorBar), gwarantująca niezmienną pozycję przycisków `<` i `>` niezależnie od długości tekstu daty.

**Plans:** 2/2 plans complete

Plans:

- [x] 12-01-PLAN.md — Audyt mocków, ujednolicenie profilu ucznia i czyste stany puste
- [x] 12-02-PLAN.md — Frekwencja w planie lekcji i stała szerokość przełącznika tygodni

### Phase 13: Dedykowane URL i routing dla podstron i zasobów (deep linking)

**Goal**: Wdrożenie routingu URL (np. go_router lub wbudowany Navigator 2.0 / URL strategy), umożliwiającego bezpośrednie otwieranie i udostępnianie linków do poszczególnych modułów i zasobów (np. `/pulpit`, `/plan-lekcji`, `/oceny`, `/frekwencja`, `/wiadomosci`, a także podgląd konkretnego wątku wiadomości lub szczegółów lekcji).
**Requirements**: REQ-ROUTING-01, REQ-ROUTING-02
**Depends on:** Phase 8, Phase 9, Phase 10
**Success Criteria**:

  1. Każda główna zakładka posiada czytelny adres URL w przeglądarce (np. `/pulpit`, `/plan`, `/oceny`, `/frekwencja`, `/wiadomosci`).
  2. Zmiana adresu w przeglądarce, odświeżenie strony (F5) oraz przyciski Wstecz/Dalej w przeglądarce poprawnie przełączają widoki i zachowują stan.
  3. Możliwość bezpośredniego wejścia z linku do konkretnego zasobu (np. `/wiadomosci/:id` lub parametr daty/tygodnia w planie lekcji `/plan?data=YYYY-MM-DD`).

**Plans:** 2/2 plans complete

Plans:

- [x] 13-01-PLAN.md — Architektura routingu webowego (URL strategy, definicja tras i synchronizacja z MainNavigationScreen)
- [x] 13-02-PLAN.md — Deep linking dla zasobów (wątki wiadomości, widok tygodnia w planie lekcji, filtry frekwencji)
