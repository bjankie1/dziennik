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

- [ ] **Phase 14: Dostęp ucznia (rola student vs parent) i współdzielony cache danych** — Logowanie kontem Google Oskara, separacja ról (`student` vs `parent`) z blokadą e-usprawiedliwień i PIN dla ucznia oraz Single Source of Truth w Firestore bez duplikowania scrapingu.
- [ ] **Phase 15: Moduł zadań (Smart To-Do) i widżet na Pulpicie** — Dedykowana podstrona `/zadania` w menu bocznym i nawigacji oraz interaktywny widżet zadań w Bento Grid na Pulpicie z szybkim odhaczaniem.
- [ ] **Phase 16: Inteligentne podpowiedzi zadań ze sprawdzianów i wiadomości** — Automatyczne generowanie zadań przygotowawczych ze sprawdzianów i terminarza oraz heurystyczne wykrywanie zadań, opłat i terminów z wiadomości Librusa.
- [ ] **Phase 17: Eksport sprawdzianów do Kalendarza Google i iCal** — Przycisk „Dodaj do Kalendarza Google” w kafelkach sprawdzianów i modalu lekcji oraz pobieranie plików kalendarzowych `.ics`.
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

**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 14 to break down)

### Phase 15: Moduł zadań (Smart To-Do) i widżet na Pulpicie

**Goal**: Wdrożenie pełnoprawnego modułu zarządzania zadaniami ucznia i rodzica z dedykowaną podstroną `/zadania` w menu nawigacyjnym oraz interaktywnym widżetem szybkiej listy zadań w Bento Grid na Pulpicie (desktop oraz mobile).  
**Requirements**: REQ-TASK-01, REQ-TASK-02  
**Depends on**: Phase 14  
**Success Criteria**:
1. W menu bocznym (`AppSidebar`) oraz dolnym pasku nawigacji pojawia się nowa pozycja `/zadania` prowadząca do podstrony To-Do z obsługą deep linkingu go_router.
2. Widok `/zadania` umożliwia tworzenie, edycję, oznaczanie ukończenia i usuwanie zadań wraz z terminami (Due Date), priorytetami i filtrowaniem (Wszystkie, Dzisiaj, Nadchodzące, Ukończone).
3. Karta Bento Grid na Pulpicie (`DashboardScreen`) wyświetla listę najpilniejszych zadań na dany dzień z możliwością natychmiastowego odhaczenia jednym kliknięciem bez opuszczania pulpitu.
4. Zadania są trwale synchronizowane w kolekcji Firestore powiązanej z profilem ucznia z natychmiastową reaktywnością (Riverpod / StreamProvider).

**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 15 to break down)

### Phase 16: Inteligentne podpowiedzi zadań ze sprawdzianów i wiadomości

**Goal**: Automatyzacja tworzenia zadań edukacyjnych i organizacyjnych poprzez generowanie propozycji zadań przygotowawczych do nadchodzących sprawdzianów/kartkówek z planu i terminarza oraz heurystyczne wykrywanie zadań, wpłat i terminów z wiadomości Librusa.  
**Requirements**: REQ-TASK-03, REQ-TASK-04  
**Depends on**: Phase 15  
**Success Criteria**:
1. Przy wykryciu sprawdzianu lub kartkówki w terminarzu/planie lekcji system automatycznie proponuje lub generuje zadanie przygotowania (np. „Powtórka do: Sprawdzian z Chemii”) z sugerowaną datą realizacji (np. 1-2 dni przed terminem).
2. W widoku wątku wiadomości (`/wiadomosci/:id`) mechanizm heurystyczny analizuje treść pod kątem kwot (np. "50 zł", "wpłata"), dat/terminów (np. "do 15 października", "do piątku") oraz zgód i wyświetla wyróżniony baner podpowiedzi zadania („Wykryto zadanie/opłatę”).
3. Kliknięcie podpowiedzi jednym tapnięciem tworzy sformatowane zadanie z wypełnioną nazwą, kwotą/opisem i terminem w module `/zadania`.
4. Użytkownik ma możliwość odrzucenia podpowiedzi lub dostosowania parametrów zadania przed zatwierdzeniem.

**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 16 to break down)

### Phase 17: Eksport sprawdzianów do Kalendarza Google i iCal

**Goal**: Bezproblemowa integracja sprawdzianów, kartkówek i wydarzeń szkolnych z zewnętrznymi kalendarzami użytkownika poprzez bezpośrednie generowanie linków do Kalendarza Google oraz uniwersalnych plików `.ics` (iCal / Apple Calendar / Outlook).  
**Requirements**: REQ-CAL-01, REQ-CAL-02  
**Depends on**: Phase 14  
**Success Criteria**:
1. Kafelki sprawdzianów w terminarzu, widżecie Bento Grid oraz w modalu szczegółów lekcji posiadają przycisk „Dodaj do Kalendarza Google”, otwierający w nowej karcie predefiniowane wydarzenie z poprawnym tytułem, zakresem, datą i godzinami zajęć.
2. Każde wydarzenie/sprawdzian udostępnia opcję pobrania pliku `.ics` ze sformatowanym standardem RFC 5545 (strefa Europe/Warsaw, opis, lokalizacja sali).
3. Użytkownik może pobrać zbiorczy plik `.ics` dla wszystkich nadchodzących sprawdzianów w danym miesiącu/semestrze jednym kliknięciem.
4. Generowanie linków i plików `.ics` działa bezbłędnie na urządzeniach stacjonarnych i mobilnych (obsługa pobierania w przeglądarce).

**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 17 to break down)

### Phase 18: Powiadomienia w czasie rzeczywistym: Telegram Bot i Web Push

**Goal**: Stworzenie wielokanałowego systemu powiadomień natychmiastowych o kluczowych zdarzeniach szkolnych (nowa ocena, nowa wiadomość, nadchodzący sprawdzian) z wykorzystaniem bota Telegram oraz powiadomień Web Push w przeglądarce.  
**Requirements**: REQ-NOTIF-01, REQ-NOTIF-02, REQ-NOTIF-03  
**Depends on**: Phase 14  
**Success Criteria**:
1. Integracja Telegram Bot w Firebase Cloud Functions z generowaniem jednorazowego 6-cyfrowego kodu parowania w ustawieniach aplikacji, umożliwiającego powiązanie czatu Telegram rodzica lub ucznia z ich kontem.
2. Wykrycie w cyklu synchronizacji nowej oceny, nowej wiadomości lub dodanego sprawdzianu powoduje natychmiastowe wysłanie sformatowanego powiadomienia na powiązany czat Telegram z kluczowymi szczegółami (przedmiot, ocena, waga, nadawca).
3. Aplikacja webowa rejestruje Service Worker i obsługuje subskrypcję Web Push API (VAPID / FCM), wyświetlając natywne powiadomienia w przeglądarce po uzyskaniu zgody użytkownika.
4. W ustawieniach użytkownik może niezależnie włączać i wyłączać kanały powiadomień (Telegram / Web Push) oraz kategorie zdarzeń.

**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 18 to break down)

### Phase 19: Raporty tygodniowe (Piątkowy briefing sprawdzianów i planu)

**Goal**: Automatyczne generowanie i dostarczanie zwięzłego, ustrukturyzowanego podsumowania nadchodzącego tygodnia szkolnego w każdy piątek wieczorem do rodzica i ucznia za pośrednictwem bota Telegram.  
**Requirements**: REQ-REPORT-01, REQ-REPORT-02  
**Depends on**: Phase 18  
**Success Criteria**:
1. Zadanie Cloud Scheduler uruchamiane w każdy piątek o godz. 18:00 (Europe/Warsaw) agreguje plan lekcji, zaplanowane sprawdziany, kartkówki oraz zadania domowe na nadchodzący tydzień (poniedziałek–piątek).
2. Cloud Function formatuje czytelny, estetyczny raport Markdown (z podziałem na dni, listą sprawdzianów, ważnymi ogłoszeniami i zadaniami).
3. Raport jest automatycznie wysyłany przez bota Telegram do wszystkich sparowanych kont (rodzic oraz uczeń).
4. W przypadku braku sprawdzianów w danym tygodniu raport zawiera pozytywny komunikat podsumowujący (spokojny tydzień) wraz z ramowym planem zajęć.

**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 19 to break down)
