# Roadmap: EduSync

## Overview
Dojście od prototypu opartego na danych mockowych do pełnoprawnego, w 100% zasilanego danymi z Librusa dziennika z naprawioną nawigacją planu, kompaktowym widokiem ocen oraz rzeczywistą frekwencją i wiadomościami.

## Phases

- [x] **Phase 1: Naprawa nawigacji planu lekcji i kompaktowy pulpit ocen** — Interaktywny przełącznik dni tygodnia w zakładce Plan oraz siatka kompaktowych kafelków ocen z datami na Pulpicie.
- [x] **Phase 2: Rzeczywista frekwencja (Librus Synergia)** — Scraper modułu nieobecności, statystyki semestralne i podgląd wpisów w zakładce Frekwencja.
- [x] **Phase 3: Rzeczywiste wiadomości i powiadomienia** — Scraper skrzynki odbiorczej Librus, wątki konwersacji i powiadomienia w czasie rzeczywistym.

---

## Phase Details

### Phase 1: Naprawa nawigacji planu lekcji i kompaktowy pulpit ocen
**Goal**: Użytkownik może płynnie przeglądać lekcje na każdy dzień tygodnia w zakładce Plan, a na pulpicie widzi więcej ocen w zwartej formie z datami.
**Requirements**: REQ-01, REQ-02
**Success Criteria**:
  1. Kliknięcie dowolnego dnia tygodnia (Poniedziałek – Piątek) w `ScheduleScreen` natychmiast filtruje i wyświetla lekcje przypisane do tego dnia z bazy Firestore.
  2. Kafelki ostatnich ocen na `DashboardScreen` są bardziej zwarte (np. 2 kolumny lub responsywny grid), pozwalając zobaczyć więcej ocen bez długiego przewijania.
  3. Przy każdej ocenie na pulpicie wyświetlana jest czytelna data wystawienia (np. `15.09` lub `10 wrz`).

### Phase 2: Rzeczywista frekwencja (Librus Synergia)
**Goal**: Zakładka Frekwencja prezentuje rzeczywiste obecności, nieobecności i spóźnienia Oskara zamiast danych demonstracyjnych z 2024 roku.
**Requirements**: REQ-03
**Success Criteria**:
  1. `LibrusClient` w Cloud Functions pobiera dane z `https://synergia.librus.pl/przegladaj_nb/uczen`.
  2. Baza Firestore zawiera aktualną frekwencję semestralną oraz listę wpisów.
  3. Zakładka Frekwencja w EduSync wyświetla aktualny stan bez odwołań do MockData.

### Phase 3: Rzeczywiste wiadomości i powiadomienia
**Goal**: Zakładka Wiadomości prezentuje prawdziwą skrzynkę odbiorczą Librusa (wiadomości od nauczycieli i dyrekcji).
**Requirements**: REQ-04
**Success Criteria**:
  1. `LibrusClient` pobiera listę wiadomości z `https://synergia.librus.pl/wiadomosci/1/5`.
  2. Wiadomości są zapisywane w Firestore i prezentowane w `MessagesScreen`.
  3. Wykrywanie nowych wiadomości w cyklu 30-minutowym generuje alerty w podkolekcji `notifications`.
