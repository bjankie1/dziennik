# EduSync • Lepsza Szkoła

## What This Is
EduSync to niezależna, nowoczesna aplikacja webowa i mobilna dziennika szkolnego dla uczniów i rodziców korzystających z systemu Librus Synergia. Umożliwia wygodny, bezpłatny podgląd ocen, planu lekcji, frekwencji, wiadomości oraz szczęśliwego numerka bez konieczności opłacania komercyjnej subskrypcji Librus Mobilny.

## Core Value
Błyskawiczny, czytelny i niezależny dostęp do rzeczywistych danych edukacyjnych ucznia (LO nr X we Wrocławiu) w czasie rzeczywistym, z automatyczną synchronizacją w tle co 30 minut.

## Current Milestone
**Milestone v2.0**: Usprawiedliwianie nieobecności, trwały autologin oraz rozbudowany widok ocen z wagami.

## Requirements

### Validated (v1.0)
- [x] Reverse-engineering autoryzacji Librus Synergia (OAuth2 / ciasteczka `DZIENNIKSID`, `SDZIENNIKSID`).
- [x] Wdrożenie backendu synchronizującego w Google Cloud Functions v2 (`europe-west3`).
- [x] Integracja z Cloud Firestore i automatycznym harmonogramem Cloud Scheduler (co 30 minut).
- [x] Naprawa nawigacji planu lekcji (przełącznik Pon-Pt).
- [x] Kompaktowy pulpit ocen z datami dodania.
- [x] Rzeczywista frekwencja i rzeczywiste wiadomości z Librusa.
- [x] Dynamiczne wskaźniki (badges) w dolnym pasku nawigacji.

### Active Scope (v2.0)
- [ ] **REQ-AUTH-01 (Bezpieczny autologin):** Trwałe zapamiętanie powiązania konta Librus pod profilem Google w Firestore (`users/{uid}/settings` / `credentials`). Brak konieczności ponownego wpisywania loginu Librus po wylogowaniu i ponownym zalogowaniu kontem Google.
- [ ] **REQ-GRADES-01 (Wizualny widok ocen wg makiety):** Przełącznik semestrów, karta średniej ważonej z pozycją w klasie i stypendium naukowym, wiersze przedmiotów od razu prezentujące pigułki ocen cząstkowych z wagami, szczegółowy akordeon ocen z wagą, datą i komentarzem.
- [ ] **REQ-ATTN-01 (Moduł usprawiedliwiania nieobecności wg makiety):** Wykres kołowy frekwencji, filtry (Wszystkie, Do usprawiedliwienia, Usprawiedliwione), lista zgłoszeń z checkboxami pogrupowana dniami, wysuwany panel szybkiego wyboru powodu (Choroba, Lekarz, Rodzina) oraz wysyłanie wniosku do Librus Synergia.

### Out of Scope
- Płatne moduły komercyjne Librusa — celem jest wolny, niezależny dostęp.
- Modyfikacja danych po stronie serwera szkoły poza oficjalną funkcją usprawiedliwień.

## Context & Constraints
- Frontend: Flutter Web (Material Design 3, Plus Jakarta Sans).
- Backend: Node.js 20, Axios, Tough-Cookie, Cheerio, Firebase Functions v2 (`europe-west3`).
- Bezpieczeństwo: Dane sesyjne i hasła przetwarzane w izolacji chmurowej użytkownika. Żadne poświadczenia nie trafiają do repozytorium.
