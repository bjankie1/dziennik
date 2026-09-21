# Milestone v2.0 — Project Summary: EduSync • Lepsza Szkoła

**Wygenerowano:** 2026-09-21  
**Cel:** Onboarding zespołu, podsumowanie architektury i przegląd ukończonego kamienia milowego v2.0  
**Wersja:** v2.0  
**Status:** Zakończony i wdrożony produkcyjnie (100% zrealizowanych planów)  
**Środowisko:** [https://lepsza-szkola.web.app](https://lepsza-szkola.web.app) • Google Cloud Functions v2 (`europe-west3`)

---

## 1. Project Overview

### Czym jest EduSync • Lepsza Szkoła
**EduSync** to niezależna, nowoczesna i responsywna aplikacja webowa oraz mobilna (PWA) dziennika szkolnego stworzona dla uczniów i rodziców korzystających z systemu **Librus Synergia** (referencyjnie: LO nr X we Wrocławiu). 

Projekt powstał w odpowiedzi na ograniczenia i koszty oficjalnej aplikacji komercyjnej (Librus Mobilny), oferując:
- **Błyskawiczny i czytelny dostęp** do ocen z wagami, planu lekcji na żywo, frekwencji, wiadomości oraz szczęśliwego numerka.
- **Odporność na przeciążenia serwerów szkolnych** dzięki synchronizacji w tle do dedykowanej bazy Cloud Firestore i serwowaniu danych z pamięci podręcznej (cache-first).
- **Elegancki interfejs desktopowy i mobilny** inspirowany Google Classroom, Gmail i Bento Grid, zaprojektowany z dbałością o typografię (*Plus Jakarta Sans*), mikromacierze statusów i spójność wizualną.

### Zakres kamienia milowego v2.0
Kamień milowy **Milestone v2.0** przekształcił prototyp v1.0 w dojrzałą, kompletną aplikację produkcyjną klasy enterprise. Zrealizowano 10 pełnych faz rozwojowych (Fazy 4–13) oraz 6 zadań szybkiego doszlifowania (Quick Tasks), obejmujących:
1. Trwałe uwierzytelnianie i autologin odporny na F5.
2. Zaawansowane moduły ocen (wagi, pigułki, układ Master-Detail 8+4, histogram MEN 1-6, krzywa Béziera, szuflada boczna z kalkulatorem wpływu GPA).
3. E-usprawiedliwianie nieobecności z autoryzacją kodem PIN rodzica.
4. Pełną obsługę wiadomości w stylu Gmail (wątki, wyszukiwarka nauczycieli, pobieranie treści on-demand, bezpośrednie odpowiedzi).
5. Nowoczesny Bento Grid Dashboard dla komputerów i tabletów ze wspólnym paskiem bocznym (`AppSidebar`).
6. Dwuwarstwowy plan lekcji (siatka tygodniowa Pn–Pt oraz chronologiczna agenda dzienna z lekcją na żywo) wzbogacony o statusy obecności i nieruchomy przełącznik tygodni o szerokości 430px.
7. Dyskretne, „niewidzialne” odpytywanie serwerów Librus (Chrome 133 headers, sekwencyjny fetch z jitterem, dynamiczny backoff 429/503, cisza nocna 22:30–06:30, cooldown 120s).
8. Kompletny audyt mocków i eliminację sztucznych danych.
9. Deklaratywny routing webowy z czystymi adresami URL (`go_router`, HTML5 History API) i głębokim linkowaniem (`/wiadomosci/:id`, `/plan-lekcji?data=...`, `/oceny?semestr=...`).

---

## 2. Architecture & Technical Decisions

EduSync opiera się na nowoczesnym, asynchronicznym stosie technologicznym z wyraźnym podziałem odpowiedzialności:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          FLUTTER WEB FRONTEND                            │
│  - go_router (StatefulShellRoute + Path URL Strategy bez '#')            │
│  - Flutter Riverpod 3.x (Notifier / NotifierProvider, brak StateProvider)│
│  - Material Design 3 + Plus Jakarta Sans + Responsive LayoutBuilder     │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │ HTTPS / Firestore SDK
                                     ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                   FIREBASE BACKEND (europe-west3)                        │
│  - Firebase Hosting (SPA Rewrites, CDN Cache)                            │
│  - Cloud Firestore (kolekcje users, grades, timetable, messages, status) │
│  - Cloud Functions v2 (Node.js 20, Axios, Tough-Cookie, Cheerio)         │
│  - Cloud Scheduler (takt co 15 min z adaptacyjnym ewaluatorem Warszawy)  │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │ Stealth Scraping (Chrome 133 + Jitter)
                                     ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                    PORTAL LIBRUS SYNERGIA (Synergia API)                 │
└──────────────────────────────────────────────────────────────────────────┘
```

### Kluczowe decyzje architektoniczne i techniczne:

- **Decyzja:** Zastosowanie `go_router` z `StatefulShellRoute.indexedStack` oraz `usePathUrlStrategy()` (Phase 13, D-01, D-05).
  - **Dlaczego:** Pozwala na czyste, czytelne adresy URL w przeglądarce (`/pulpit`, `/plan-lekcji`, `/oceny`, `/frekwencja`, `/wiadomosci`) bez hasha `/#/`. Stan ekranów (pozycja przewijania, otwarte akordeony, wybrane filtry) jest zachowywany w pamięci podręcznej przy przełączaniu zakładek, a przyciski Wstecz/Dalej w przeglądarce działają intuicyjnie.
- **Decyzja:** Deep linking z bezpiecznym fallbackiem powrotu (`/wiadomosci/:threadId` oraz `/plan-lekcji?data=YYYY-MM-DD`) (Phase 13, D-03).
  - **Dlaczego:** Umożliwia kopiowanie i wysyłanie bezpośrednich linków do konkretnych zasobów (np. powiadomienie o sprawdzianie z pulpitu otwiera plan dokładnie na dany tydzień; kliknięcie linku do wiadomości otwiera konkretny wątek, a kliknięcie „Wstecz” cofa do listy wiadomości zamiast wylogowywać z aplikacji).
- **Decyzja:** Desktop Master-Detail 8+4 w panelu ocen z prawostronną szufladą boczną (520px slide-in drawer) (Phase 10, D-01, D-06).
  - **Dlaczego:** Duże ekrany monitorów zyskują profesjonalny podział: lewe 8 kolumn na pełną tabelę przedmiotów i wykres trajektorii, prawe 4 kolumny na inspektor wybranego przedmiotu. Kliknięcie pojedynczej oceny cząstkowej wysuwa elegancką szufladę ze szczegółami MEN i kalkulatorem wpływu GPA, nie zaburzając widoku tabeli.
- **Decyzja:** Niezależne, dyskretne odpytywanie serwerów Librus z harmonogramem nocnym (Phase 11, D-01, D-05, D-06, D-07).
  - **Dlaczego:** Wyeliminowano ryzyko blokad konta przez portal Librus. Zamiast równoległych zapytań `Promise.all` zastosowano sekwencyjne odpytywanie z losowym jitterem (1.0–2.5 s), profil Chrome 133 z nagłówkami Client Hints, trwałe ciasteczka sesyjne w Firestore z szybkim testem `isSessionAlive()`, dynamiczny 20-minutowy lock przy kodach 429/503 oraz całkowite wstrzymanie synchronizacji w godzinach nocnych (22:30–06:30) w strefie `Europe/Warsaw`.
- **Decyzja:** Całkowite odcięcie mocków z `MockData` w trybie zalogowania (Phase 12, D-04, D-05, D-09, D-10).
  - **Dlaczego:** Aplikacja prezentuje wyłącznie autentyczne dane szkolne ucznia. Puste dni nie generują fikcyjnych lekcji, brak sprawdzianu ukrywa boks na pulpicie, weekendy wyświetlają neutralną informację o braku losowania numerka, a profil dynamicznie odczytuje prawdziwego wychowawcę (`Sobota Łukasz`).
- **Decyzja:** Zablokowanie stałej szerokości paska tygodni (430px) w planie lekcji (Phase 12, D-06, D-07).
  - **Dlaczego:** Zapobiega irytującemu przesuwaniu się przycisku następnego tygodnia `[>]` przy zmianie długości tekstu daty i obecności badge'a „Aktualny tydzień”.
- **Decyzja:** Migracja na Riverpod 3.x z klasami `Notifier<T>` (Phase 08, 09, 10).
  - **Dlaczego:** Zapewnia pełną zgodność z najnowszym standardem biblioteki, unika przestarzałych `StateProvider` i gwarantuje stabilny cykl życia stanu.

---

## 3. Phases Delivered

W ramach Milestone v2.0 dostarczono 10 pełnych faz (18 planów realizacyjnych), z których każda przeszła rygorystyczne testy i została wdrożona:

| Faza | Nazwa | Status | Podsumowanie (One-Liner) |
|:---:|---|:---:|---|
| **04** | Bezpieczny autologin i trwałe powiązanie profilu Librus | ✅ Zakończona | Odporność na F5/przeładowanie strony, pamięć sesji w SharedPreferences i autologin z bazy Firestore bez ponownego podawania hasła. |
| **05** | Nowy interfejs Ocen wg makiety | ✅ Zakończona | Zakładki semestrów, karta średniej ważonej ze stypendium (4.75), pigułki ocen cząstkowych z wagami w wierszu przedmiotu oraz szczegółowy akordeon. |
| **06** | Moduł usprawiedliwiania nieobecności wg makiety | ✅ Zakończona | Bento Header z kołowym wykresem obecności, filtry, zgrupowane kafelki lekcji z checkboxami, pływający dock szybkich powodów i autoryzacja PIN rodzica. |
| **07** | Funkcjonalny moduł wiadomości (czytanie, odpowiadanie, wysyłanie) | ✅ Zakończona | Widok wątku w stylu Gmail ze zwijanymi wiadomościami, szybka odpowiedź, nowa wiadomość z autocomplete po nazwisku i przedmiocie, pełna treść z podstron Librus i dynamiczne badge. |
| **08** | Pełny design ekranu głównego w wersji web | ✅ Zakończona | Bento Grid Dashboard na desktopie i tabletach z 3 kolumnami, harmonogramem na żywo, powiadomieniami, skrótami oraz wspólnym lewym paskiem bocznym `AppSidebar`. |
| **09** | Plan lekcji w wersji web (widok siatki i agendy) | ✅ Zakończona | Tygodniowa siatka Pn–Pt ze statusem zajęć i modalem szczegółów, chronologiczna agenda z trwającą lekcją na żywo, kafelki podsumowania i pasek wyboru tygodnia. |
| **10** | Pełen panel ocen w wersji na przeglądarkę | ✅ Zakończona | Układ Master-Detail 8+4, kafelki KPI ze średnią i histogramem MEN 1-6, wykres trajektorii Béziera z linią klasy oraz wysuwana szuflada szczegółów z kalkulatorem GPA (+0.06 pkt). |
| **11** | Dyskretne odpytywanie serwerów Librus (rate limiting, harmonogram nocny) | ✅ Zakończona | Humanizowane nagłówki Chrome 133, sekwencyjny fetch z jitterem, test sesji `isSessionAlive`, dynamiczny backoff 429/503, cisza nocna (22:30–06:30) i cooldown 120s w aplikacji. |
| **12** | Audyt mocków, nieobecności w planie lekcji i stała szerokość przełącznika tygodni | ✅ Zakończona | Całkowite odcięcie mocków z `MockData`, ukrywanie pustego sprawdzianu, dynamiczny wychowawca, pigułki frekwencji na kafelkach planu lekcji i stała szerokość 430px nawigatora tygodni. |
| **13** | Dedykowane URL i routing dla podstron i zasobów (deep linking) | ✅ Zakończona | Wdrożenie `go_router` z Path URL Strategy (HTML5), polskimi trasami (`/pulpit`, `/plan-lekcji`, etc.), zapamiętywaniem ścieżki powrotnej `?redirect=` oraz deep linkami `/wiadomosci/:id` i `/plan-lekcji?data=...`. |

### Zrealizowane zadania Quick Polish (v2.0):
- **`260918-ev7`**: Modal dziennika zapytań do serwerów Librus i śledzenie historii synchronizacji.
- **`260919-ufy`**: Naprawa detekcji statusów usprawiedliwień i zwolnień w module frekwencji.
- **`260920-wkd`**: Harmonogram weekendowy na pulpicie i dynamiczne przełączanie tygodni w planie lekcji.
- **`260920-trm`**: Integracja terminarza sprawdzianów z planem lekcji, przejście do tygodnia kartkówki i obsługa zastępstw z j. polskiego.
- **`260921-9sd`**: Uporządkowanie kalkulacji frekwencji (podwójny wykres pierścieniowy: frekwencja ogólna vs frekwencja bez nieusprawiedliwionych).
- **`260921-msg`**: Naprawa licznika nieprzeczytanych wiadomości w nagłówku i na pulpicie mobilnym oraz ujednolicenie kafelków wiadomości do 3 wpisów.

---

## 4. Requirements Coverage

Wszystkie wymagania zdefiniowane w specyfikacji Milestone v2.0 zostały w 100% zrealizowane:

### Uwierzytelnianie i sesja
- ✅ **REQ-AUTH-01**: Trwałe powiązanie konta Librus pod profilem Google w Firestore. Automatyczne przywracanie sesji na klatce 0, pełna odporność na F5 / odświeżenie przeglądarki, rozdzielenie wylogowania Google od usunięcia poświadczeń. *(Phase 4)*

### Oceny i statystyki akademickie
- ✅ **REQ-GRADES-01**: Przełącznik semestrów (Semestr 1, Semestr 2, Roczna) z modale symulatora średniej. *(Phase 5)*
- ✅ **REQ-GRADES-02**: Karta podsumowania średniej ważonej z odchyleniem, pozycją w rankingu klasy (Top 5%) i paskiem stypendium (4.75). *(Phase 5)*
- ✅ **REQ-GRADES-03**: Wiersze przedmiotów prezentujące od razu pigułki ocen cząstkowych z wagami bez konieczności rozwijania. *(Phase 5)*
- ✅ **REQ-GRADES-04**: Rozwijany akordeon ocen ze szczegółowymi datami, wagami, procentami i komentarzami nauczycieli. *(Phase 5)*
- ✅ **REQ-GRADES-05**: Responsywny układ Master-Detail na desktopie (>=1024px): 8 kolumn na tabelę przedmiotów + 4 kolumny na inspektor, z czystym stanem początkowym. *(Phase 10)*
- ✅ **REQ-GRADES-06**: Karta rozkładu ocen w skali MEN 1–6 (histogram z dynamicznymi słupkami) oraz wskaźnikiem zagrożeń. *(Phase 10)*
- ✅ **REQ-GRADES-07**: Wykres trajektorii średniej ważonej (krzywa Béziera `CustomPainter`) z gradientem i przerywaną linią średniej klasy. *(Phase 10)*
- ✅ **REQ-GRADES-08**: Prawostronna szuflada szczegółów oceny (slide-in drawer 520px na desktopie, bottom sheet na mobile) z rejestrem MEN i kalkulatorem wpływu GPA (+0.06 pkt). *(Phase 10)*

### Frekwencja i e-usprawiedliwienia
- ✅ **REQ-ATTN-03**: Bento Header z kołowym wykresem frekwencji (dual ring gauge), celem semestru (>90%) i licznikami obecności/spóźnień. *(Phase 6, Quick 260921-9sd)*
- ✅ **REQ-ATTN-04**: Filtrowanie nieobecności (Wszystkie, Do usprawiedliwienia, Usprawiedliwione) z grupowaniem po dniach i etykietami stanu. *(Phase 6)*
- ✅ **REQ-ATTN-05**: Zaznaczanie wielu lekcji checkboxami i pływający dock z szybkimi powodami usprawiedliwienia. *(Phase 6)*
- ✅ **REQ-ATTN-06**: Bezpieczna autoryzacja kodem PIN rodzica i natychmiastowe wysłanie e-usprawiedliwienia do Librusa. *(Phase 6)*

### Moduł wiadomości
- ✅ **REQ-MSG-04**: Widok wątku wiadomości w stylu Gmail z chronologią konwersacji i możliwością zwijania/rozwijania wiadomości. *(Phase 7)*
- ✅ **REQ-MSG-05**: Bezpośrednie pole szybkiej odpowiedzi w wątku z natychmiastową wysyłką do Librusa. *(Phase 7)*
- ✅ **REQ-MSG-06**: Formularz nowej wiadomości z autocomplete odbiorcy zarówno po nazwisku nauczyciela, jak i nauczanym przedmiocie. *(Phase 7)*
- ✅ **REQ-MSG-07**: Automatyczne dociąganie pełnej treści wiadomości z podstron Librusa (`div.container-message-content`) on-demand z cache'em w Firestore. *(Phase 7)*
- ✅ **REQ-MSG-08**: Dynamiczne stany przeczytania/nieprzeczytania i badge liczników na ikonie nawigacji i dzwonku powiadomień. *(Phase 7, Quick 260921-msg)*

### Ekran główny i nawigacja
- ✅ **REQ-DASH-02**: Nowoczesny Bento Grid Dashboard na desktopie/tabletach ze wspólnym lewym paskiem nawigacyjnym `AppSidebar`, nagłówkiem z wyszukiwarką `AppDesktopHeader`, harmonogramem na żywo, kafelkami ocen i frekwencji. *(Phase 8)*

### Plan lekcji
- ✅ **REQ-TIMETABLE-01**: Segmented control na górnym pasku (Siatka / Agenda) z synchronizacją wybranego dnia. *(Phase 9)*
- ✅ **REQ-TIMETABLE-02**: Pasek wyboru tygodnia oraz interaktywne kafelki podsumowania tygodnia (godziny, zastępstwa, sprawdziany, odwołane). *(Phase 9)*
- ✅ **REQ-TIMETABLE-03**: Tygodniowa siatka Pn–Pt z godzinami 1–8+, kafelkami statusów, wyróżnieniem „Dziś” i modalem szczegółów lekcji. *(Phase 9)*
- ✅ **REQ-TIMETABLE-04**: Oś czasu agendy z lekcją na żywo („Trwa teraz • Zostało X min”), tematami i zadaniami domowymi. *(Phase 9)*
- ✅ **REQ-TIMETABLE-05**: Naniesienie statusów obecności/nieobecności i wniosków rodzica na kafelki planu w siatce, agendzie i modalu. *(Phase 12)*
- ✅ **REQ-TIMETABLE-06**: Stała szerokość 430px kontenera wyboru tygodnia `WeekNavigatorBar` ze stabilną pozycją przycisków `<` i `>`. *(Phase 12)*

### Dyskretna synchronizacja z Librusem
- ✅ **REQ-STEALTH-01**: Nowoczesny profil przeglądarki Chrome 133 z kompletnymi nagłówkami Client Hints i językiem `pl-PL`. *(Phase 11)*
- ✅ **REQ-STEALTH-02**: Sekwencyjne odpytywanie modułów z losowym opóźnieniem jitter (1.0–2.5 s) imitujące człowieka. *(Phase 11)*
- ✅ **REQ-STEALTH-03**: Trwała sesja `CookieJar` w Firestore i test `isSessionAlive()` eliminujący zbędne logowania OAuth. *(Phase 11)*
- ✅ **REQ-STEALTH-04**: Dynamiczny 20-minutowy lock przy błędach 429/503 i bezpieczne serwowanie z cache'u. *(Phase 11)*
- ✅ **REQ-SCHED-01**: Inteligentny ewaluator harmonogramu w strefie `Europe/Warsaw` z ciszą nocną (22:30–06:30) i oknami weekendowymi. *(Phase 11)*
- ✅ **REQ-CLIENT-01**: Ochrona przycisku ręcznego odświeżania z 120-sekundowym cooldownem i komunikatem o trybie nocnym. *(Phase 11)*

### Jakość danych i routing
- ✅ **REQ-AUDIT-01**: Całkowita eliminacja sztucznych danych i mocków fallbackowych; czyste stany puste i dynamiczny profil. *(Phase 12)*
- ✅ **REQ-ROUTING-01**: Czyste ścieżki HTML5 bez hasha (`/pulpit`, `/plan-lekcji`, etc.) z obsługą historii Wstecz/Dalej i guardami logowania `?redirect=`. *(Phase 13)*
- ✅ **REQ-ROUTING-02**: Deep linking do konkretnych zasobów (`/wiadomosci/:threadId`, `/plan-lekcji?data=YYYY-MM-DD`, query parametry filtrów). *(Phase 13)*

---

## 5. Key Decisions Log

Poniższa tabela stanowi rejestr najważniejszych decyzji projektowych wypracowanych w trakcie realizacji kamienia milowego v2.0:

| ID Decyzji | Obszar | Wybór i Uzasadnienie | Faza |
|---|---|---|:---:|
| **D-04-01** | Sesja i F5 | Wstrzyknięcie `SharedPreferences` przed `runApp` i synchroniczne odtworzenie stanu użytkownika na klatce 0, aby odświeżenie strony nigdy nie migało ekranem logowania. | Faza 4 |
| **D-05-01** | Oceny | Prezentacja pigułek ocen cząstkowych od razu w wierszu przedmiotu, aby uczeń nie musiał klikać każdego przedmiotu, by zobaczyć oceny. | Faza 5 |
| **D-06-01** | Frekwencja | Zgrupowanie nieobecności dniami z wielokrotnym wyborem lekcji i pływającym panelem szybkich powodów usprawiedliwienia pod kod PIN rodzica. | Faza 6 |
| **D-07-01** | Wiadomości | Pobieranie pełnej treści wiadomości on-demand w tle z podstron Librusa i trwałe zapisywanie w Firestore, eliminując ograniczenie krótkich podglądów. | Faza 7 |
| **D-08-01** | Desktop Shell | Stały lewy pasek nawigacyjny `AppSidebar` (szerokość 256px) wspólny dla wszystkich podstron powyżej 1024px, ukrywający dolny pasek mobilny. | Faza 8 |
| **D-09-01** | Plan lekcji | Architektura dual-view (Siatka tygodniowa na desktopie / Agenda dzienna na telefonach) z zachowaniem synchronizacji wybranego dnia. | Faza 9 |
| **D-10-01** | Panel ocen | Układ Master-Detail 8+4 z prawostronną wysuwaną szufladą (520px drawer) po kliknięciu w ocenę, z kalkulatorem wpływu GPA na średnią. | Faza 10 |
| **D-11-01** | Stealth sync | Całkowite zawieszenie odpytywania serwerów Librus w godzinach 22:30–06:30 w strefie `Europe/Warsaw` oraz sekwencyjny fetch z jitterem 1.0–2.5 s. | Faza 11 |
| **D-12-01** | Rzetelność danych | Całkowite wycięcie mocków z `MockData` w trybie produkcyjnym; puste dni i brak sprawdzianów skutkują czystym stanem pustym zamiast sztucznych danych. | Faza 12 |
| **D-12-02** | UX nawigatora | Zablokowanie szerokości nawigatora tygodni na 430px z przyciskami `<` i `>` przypiętymi do skrajnych krawędzi, aby kursory myszy nie uciekały przy klikaniu. | Faza 12 |
| **D-13-01** | Routing web | Wdrożenie `go_router` ze `StatefulShellRoute` i `usePathUrlStrategy()`, zapewniające czyste URL bez hashów, zachowanie stanu zakładek oraz głębokie linkowanie. | Faza 13 |

---

## 6. Tech Debt & Deferred Items

Poniższe zagadnienia zostały zidentyfikowane podczas weryfikacji i rozwoju jako potencjalne usprawnienia w kolejnym kamieniu milowym (Milestone v3.0):

1. **Pobieranie i podgląd załączników wiadomości (Pliki PDF/DOCX)**:
   - *Stan obecny:* Załączniki są wykrywane i prezentowane w wątku wiadomości jako etykiety/metadane informacyjne.
   - *Rekomendacja na v3.0:* Dodać dedykowany endpoint w Cloud Functions pośredniczący w bezpiecznym pobieraniu binarnym załączników z Librusa z podglądem w aplikacji.
2. **Eksport planu lekcji do formatu iCal / Google Calendar**:
   - *Stan obecny:* W nagłówku planu lekcji przygotowano przycisk eksportu i synchronizacji.
   - *Rekomendacja na v3.0:* Wdrożyć generator plików `.ics` z dynamicznym uwzględnieniem przerw i sal lekcyjnych.
3. **Inteligentny symulator ocen końcoworocznych (Predyktor GPA)**:
   - *Stan obecny:* Użytkownik może dodawać hipotetyczne oceny w modalu symulatora średniej i obserwować zmianę średniej.
   - *Rekomendacja na v3.0:* Odwrócony kalkulator: „Jakie oceny cząstkowe muszę uzyskać, aby podnieść przewidywaną ocenę z Matematyki z 4 na 5?”.
4. **Wielodostęp dla rodzeństwa (Multi-student switcher)**:
   - *Stan obecny:* Profil obsługuje jednego aktywnego ucznia powiązanego z kontem.
   - *Rekomendacja na v3.0:* Dla rodziców posiadających więcej niż jedno dziecko w Librusie – szybki przełącznik profilu w nagłówku.

---

## 7. Getting Started for New Contributors

### Środowisko deweloperskie
- **Flutter SDK:** `>=3.22.0` (Dart `>=3.4.0`)
- **Node.js:** `>=20.0.0` (preferowany Node 22+)
- **Firebase CLI:** `npm install -g firebase-tools`
- **Przeglądarka:** Google Chrome (dla uruchamiania webowego)

### Struktura katalogów
```
dziennik szkolny/
├── lib/
│   ├── core/                  # Motyw (AppColors, AppTypography, AppTheme), stałe
│   ├── data/
│   │   ├── mock/              # MockData (dla trybu demo i testów widżetowych)
│   │   └── repositories/      # SchoolRepository, FirestoreSchoolRepository
│   ├── domain/
│   │   └── models/            # Modele danych: Grade, Subject, LessonSlot, MessageThread...
│   └── presentation/
│       ├── providers/         # Riverpod providery (school_providers, authProvider...)
│       ├── routes/            # Konfiguracja routingu (app_router.dart z go_router)
│       ├── screens/           # Ekramy: dashboard, schedule, grades, attendance, messages
│       └── widgets/           # Globalne komponenty UI (AppSidebar, AppDesktopHeader...)
├── functions/
│   ├── src/
│   │   ├── librus_client.js   # Scraper Librus Synergia (Axios, Cheerio, Tough-Cookie)
│   │   ├── schedule_evaluator.js # Ewaluator okien czasowych (strefa Europe/Warsaw)
│   │   └── sync_service.js    # Logika synchronizacji z bazą Cloud Firestore
│   └── index.js               # Definicje Cloud Functions v2 i Cloud Scheduler
├── .planning/                 # Dokumentacja architektoniczna, plany i rejestr stanu GSD
└── web/                       # Pliki bazowe aplikacji webowej (index.html)
```

### Uruchomienie projektu lokalnie
1. **Frontend (Flutter Web):**
   ```bash
   flutter pub get
   flutter run -d chrome
   ```
2. **Backend (Cloud Functions - testy i linter):**
   ```bash
   cd functions
   npm test
   ```
3. **Analiza jakości kodu:**
   ```bash
   flutter analyze
   ```
4. **Budowa wersji produkcyjnej i wdrożenie:**
   ```bash
   flutter build web --release --pwa-strategy=none
   firebase deploy --only hosting
   ```

---

## 8. Milestone Statistics

- **Oś czasu:** 15 września 2026 → 21 września 2026 (7 dni intensywnego rozwoju)
- **Fazy zrealizowane:** 10 / 10 ukończonych (100%)
- **Plany zrealizowane:** 18 / 18 ukończonych (100%)
- **Zadania Quick Polish:** 6 ukończonych
- **Łączna liczba commitów w kamieniu milowym:** 89 commitów
- **Zmiany w kodzie aplikacji i funkcji:** 56 plików źródłowych (`+17 077` linii dodanych, `-2 449` usuniętych)
- **Autorzy:** Bartosz Jankiewicz (`@bjankiewicz`)
- **Status wdrożenia produkcyjnego:** Aktywne na Firebase Hosting pod adresem [https://lepsza-szkola.web.app](https://lepsza-szkola.web.app)
