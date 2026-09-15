# EduSync • Lepsza Szkoła

## What This Is
EduSync to niezależna, nowoczesna aplikacja webowa i mobilna dziennika szkolnego dla uczniów i rodziców korzystających z systemu Librus Synergia. Umożliwia wygodny, bezpłatny podgląd ocen, planu lekcji, frekwencji, wiadomości oraz szczęśliwego numerka bez konieczności opłacania komercyjnej subskrypcji Librus Mobilny.

## Core Value
Błyskawiczny, czytelny i niezależny dostęp do rzeczywistych danych edukacyjnych ucznia (LO nr X we Wrocławiu) w czasie rzeczywistym, z automatyczną synchronizacją w tle co 30 minut.

## Requirements

### Validated
- [x] Reverse-engineering autoryzacji Librus Synergia (OAuth2 / ciasteczka `DZIENNIKSID`, `SDZIENNIKSID`).
- [x] Wdrożenie backendu synchronizującego w Google Cloud Functions v2 (`europe-west3`).
- [x] Integracja z Cloud Firestore i automatycznym harmonogramem Cloud Scheduler (co 30 minut).
- [x] Trwałe powiązanie konta Librus w Firestore pod kontem użytkownika Google.
- [x] Podstawowy pulpit z profilem ucznia (Oskar Jankiewicz, 4 k Lic), szczęśliwym numerkiem (18) i ogłoszeniami.

### Active Scope
- [ ] **REQ-01 (Plan lekcji):** Naprawa przełączania dni tygodnia w zakładce Plan (dynamiczne filtrowanie lekcji dla Pon/Wt/Śr/Czw/Pt).
- [ ] **REQ-02 (Pulpit - Oceny):** Kompaktowy układ kafelków ocen na pulpicie (zamiast pełnej szerokości), umożliwiający pokazanie większej liczby ocen jednocześnie, z widoczną datą dodania każdej oceny.
- [ ] **REQ-03 (Frekwencja):** Implementacja scrapera rzeczywistej frekwencji z `https://synergia.librus.pl/przegladaj_nb/uczen`, zapis w Firestore i wyeliminowanie danych demo.
- [ ] **REQ-04 (Wiadomości):** Implementacja scrapera rzeczywistych wiadomości z `https://synergia.librus.pl/wiadomosci/1/5`, zapis w Firestore i wyeliminowanie danych demo.

### Out of Scope
- Płatne moduły komercyjne Librusa — celem jest wolny, niezależny dostęp.
- Modyfikacja danych po stronie serwera szkoły — wyłącznie odczyt i usprawiedliwienia.

## Context & Constraints
- Frontend: Flutter Web (Material Design 3, Plus Jakarta Sans).
- Backend: Node.js 20, Axios, Tough-Cookie, Cheerio, Firebase Functions v2.
- Bezpieczeństwo: Dane sesyjne i hasła przetwarzane w izolacji chmurowej użytkownika.
