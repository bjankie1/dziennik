# EduSync • Lepsza Szkoła

## What This Is
EduSync to niezależna, nowoczesna aplikacja webowa i mobilna dziennika szkolnego dla uczniów i rodziców korzystających z systemu Librus Synergia. Umożliwia wygodny, bezpłatny podgląd ocen, planu lekcji, frekwencji, wiadomości oraz szczęśliwego numerka bez konieczności opłacania komercyjnej subskrypcji Librus Mobilny.

## Core Value
Błyskawiczny, czytelny i niezależny dostęp do rzeczywistych danych edukacyjnych ucznia (LO nr X we Wrocławiu) w czasie rzeczywistym, z automatyczną synchronizacją w tle.

## Current Milestone: v3.0 Dostęp Ucznia, Smart Zadania, Kalendarz & Powiadomienia

**Goal:** Wzbogacenie aplikacji o bezpieczny dostęp dla Oskara (ucznia) z współdzielonym cachem danych i kontrolą uprawnień rodzica, system zarządzania zadaniami z inteligentnymi podpowiedziami z wiadomości i planu lekcji, bezpośredni eksport sprawdzianów do Kalendarza Google (.ics / link) oraz wielokanałowe powiadomienia (Telegram Bot + Web Push) z cotygodniowym piątkowym raportem planu i sprawdzianów.

**Target features:**
- **Dostęp dla Oskara (ucznia):** Logowanie kontem Google Oskara powiązane z tym samym profilem ucznia w Firestore. Współdzielony cache danych (brak podwójnego scrapingu), dostęp w trybie ucznia (brak uprawnień rodzica do wysyłania e-usprawiedliwień i zmiany PIN).
- **Obsługa zadań (Smart To-Do):** Dedykowana podstrona `/zadania` w menu bocznym oraz widżet na Pulpicie Bento Grid. Automatyczne generowanie zadań przygotowania do sprawdzianu/kartkówki z planu lekcji oraz inteligentne podpowiedzi zadań podczas czytania wiadomości z kwotami/terminami (np. wpłata na wycieczkę).
- **Eksport do Kalendarza Google:** Przycisk „Dodaj do Kalendarza Google” (bezpośredni link webowy do Google Calendar z wypełnioną datą, godziną i zakresem sprawdzianu) oraz uniwersalny plik `.ics` do pobrania.
- **Powiadomienia Telegram Bot & Web Push:** Lekki bot Telegram wysyłający natychmiastowe prywatne alerty o nowych ocenach, wiadomościach i sprawdzianach na telefon rodzica i ucznia + powiadomienia Web Push w przeglądarce.
- **Raporty tygodniowe (Piątkowy briefing):** Automatyczny raport wysyłany w każdy piątek wieczorem (przez bota Telegram) z podsumowaniem nadchodzących sprawdzianów, kartkówek i planu na kolejny tydzień.

## Requirements

### Validated (v1.0)
- [x] Reverse-engineering autoryzacji Librus Synergia (OAuth2 / ciasteczka `DZIENNIKSID`, `SDZIENNIKSID`).
- [x] Wdrożenie backendu synchronizującego w Google Cloud Functions v2 (`europe-west3`).
- [x] Integracja z Cloud Firestore i automatycznym harmonogramem Cloud Scheduler (co 30 minut).
- [x] Naprawa nawigacji planu lekcji (przełącznik Pon-Pt).
- [x] Kompaktowy pulpit ocen z datami dodania.
- [x] Rzeczywista frekwencja i rzeczywiste wiadomości z Librusa.
- [x] Dynamiczne wskaźniki (badges) w dolnym pasku nawigacji.

### Validated (v2.0)
- [x] **REQ-AUTH-01 (Bezpieczny autologin):** Trwałe zapamiętanie powiązania konta Librus pod profilem Google w Firestore, odporność na F5 i odświeżenie przeglądarki na klatce 0.
- [x] **REQ-GRADES-01-08 (Wizualny i pełen panel ocen):** Zakładki semestrów, pigułki ocen, akordeon, układ Master-Detail 8+4, histogram MEN 1-6, wykres trajektorii Béziera, szuflada boczna z kalkulatorem GPA.
- [x] **REQ-ATTN-01-06 (Moduł usprawiedliwiania nieobecności):** Wykres kołowy z podwójnym ringiem, filtry, zgrupowane lekcje, dock z szybkimi powodami i PIN rodzica.
- [x] **REQ-MSG-04-08 (Moduł wiadomości):** Widok Gmail, bezpośrednie odpowiedzi, autocomplete, pełna treść i liczniki badge.
- [x] **REQ-DASH-02 (Desktop Bento Grid):** 3-kolumnowy dashboard z harmonogramem na żywo i wspólnym paskiem bocznym.
- [x] **REQ-TIMETABLE-01-06 (Plan lekcji siatka i agenda):** Przełącznik trybów, podsumowanie tygodnia, statusy frekwencji i stały nawigator 430px.
- [x] **REQ-STEALTH-01-04 & REQ-SCHED-01 (Dyskretny backend):** Profil Chrome 133, sekwencyjny fetch, jitter, test sesji, dynamiczny backoff 429/503 i cisza nocna.
- [x] **REQ-AUDIT-01 & REQ-ROUTING-01-02 (Audyt i Routing):** Czyste stany puste bez mocków, polskie ścieżki w go_router i deep linking zasobów.

### Active Scope (v3.0)
- [ ] **REQ-ROLE-01 (Dostęp ucznia / rola):** Logowanie kontem Google Oskara powiązane z tym samym profilem ucznia w Firestore. Dostęp w trybie student (brak uprawnień rodzica do usprawiedliwień i PIN).
- [ ] **REQ-ROLE-02 (Współdzielony cache):** Dzielenie pamięci podręcznej i danych pobieranych z Librusa w Firestore – brak ponownego pobierania tych samych danych przez ucznia.
- [ ] **REQ-TASK-01 (Moduł To-Do):** Dedykowana podstrona `/zadania` w menu bocznym i nawigacji z listą zadań, terminami i filtrami.
- [ ] **REQ-TASK-02 (Widget zadań na Pulpicie):** Karta zadań w Bento Grid na Pulpicie z szybkim oznaczaniem ukończenia.
- [ ] **REQ-TASK-03 (Inteligentne podpowiedzi zadań):** Wykrywanie zadań/opłat z wiadomości Librusa oraz automatyczne podpowiedzi przygotowania do sprawdzianu z terminarza.
- [ ] **REQ-CAL-01 (Eksport do Kalendarza Google):** Bezpośredni link „Dodaj do Kalendarza Google” oraz plik `.ics` dla sprawdzianów i wydarzeń.
- [ ] **REQ-NOTIF-01 (Telegram Bot & Web Push):** Bot Telegram do natychmiastowych powiadomień na telefonie (oceny, wiadomości, sprawdziany) oraz obsługa Web Push w przeglądarce.
- [ ] **REQ-NOTIF-02 (Piątkowy raport tygodniowy):** Automatyczny raport wysyłany w piątek wieczorem z planem sprawdzianów i zadań na nadchodzący tydzień.

### Out of Scope
- Płatne moduły komercyjne Librusa — celem jest wolny, niezależny dostęp.
- Modyfikacja danych po stronie serwera szkoły poza oficjalną funkcją usprawiedliwień.

## Context & Constraints
- Frontend: Flutter Web (Material Design 3, Plus Jakarta Sans, go_router, Riverpod 3.x).
- Backend: Node.js 20, Axios, Tough-Cookie, Cheerio, Firebase Functions v2 (`europe-west3`).
- Powiadomienia: Telegram Bot API (webhook/polling w Cloud Functions), Web Push API (Firebase Cloud Messaging / VAPID).
- Bezpieczeństwo: Dane sesyjne i hasła przetwarzane w izolacji chmurowej użytkownika. Żadne poświadczenia nie trafiają do repozytorium.

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state
