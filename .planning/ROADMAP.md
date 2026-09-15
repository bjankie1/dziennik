# Roadmap: EduSync

## Overview
Milestone v2.0 skupia się na trzech kluczowych filarach: trwałym powiązaniu konta Librus (autologin), nowoczesnym układzie ocen wg makiety (pigułki ocen z wagami w wierszu przedmiotu, szczegóły po rozwinięciu) oraz interaktywnym module usprawiedliwiania nieobecności (filtrowanie, checkboxy, wysuwany panel szybkiego usprawiedliwienia).

## Phases

- [x] **Phase 1: Naprawa nawigacji planu lekcji i kompaktowy pulpit ocen** — Interaktywny przełącznik dni tygodnia w zakładce Plan oraz siatka kompaktowych kafelków ocen z datami na Pulpicie.
- [x] **Phase 2: Rzeczywista frekwencja (Librus Synergia)** — Scraper modułu nieobecności, statystyki semestralne i podgląd wpisów w zakładce Frekwencja.
- [x] **Phase 3: Rzeczywiste wiadomości i powiadomienia** — Scraper skrzynki odbiorczej Librus, wątki konwersacji i powiadomienia w czasie rzeczywistym.
- [ ] **Phase 4: Bezpieczny autologin i trwałe powiązanie profilu Librus** — Zapisanie i automatyczne wczytywanie powiązania Librus z Firestore po zalogowaniu kontem Google, eliminacja wymogu ponownego podawania loginu.
- [ ] **Phase 5: Nowy interfejs Ocen wg makiety** — Karta średniej ważonej z postępem stypendium i pozycją w klasie, pigułki ocen z wagami w wierszu przedmiotu bez konieczności rozwijania, szczegółowy akordeon ocen.
- [ ] **Phase 6: Moduł usprawiedliwiania nieobecności wg makiety** — Kołowy wykres frekwencji, filtry, checkboxy lekcji pogrupowane dniami, dolny panel wyboru szybkiego powodu i wysyłanie usprawiedliwienia do Librus.

---

## Phase Details

### Phase 4: Bezpieczny autologin i trwałe powiązanie profilu Librus
**Goal**: Użytkownik logujący się przez konto Google nie musi ponownie podawać loginu i hasła Librus, jeśli konto zostało już wcześniej skonfigurowane i powiązane w Firestore.
**Requirements**: REQ-AUTH-01
**Success Criteria**:
  1. Po zalogowaniu Google Auth aplikacja sprawdza w Firestore (`users/{uid}/settings` lub `users/{uid}/profile`), czy istnieje powiązane konto Librus.
  2. Jeśli konto Librus jest sparowane, aplikacja automatycznie przechodzi do głównego widoku pulpitu bez konieczności wyświetlania formularza logowania Librus.
  3. Stan synchronizacji i dane ucznia są natychmiast dostępne.
  4. Wylogowanie i ponowne zalogowanie Google zachowuje powiązanie.

### Phase 5: Nowy interfejs Ocen wg makiety
**Goal**: Implementacja dedykowanego widoku ocen odpowiadającego makiecie graficznej (`media_1789491587201.png`).
**Requirements**: REQ-GRADES-01
**Success Criteria**:
  1. Zakładki semestrów (Semestr 1, Semestr 2, Roczna) na górze ekranu.
  2. Karta podsumowania: średnia ważona, odchylenie (+0.14), wskaźnik stypendium naukowego (próg 4.75) oraz pozycja w klasie.
  3. Lista przedmiotów: wiersz każdego przedmiotu od razu prezentuje pigułki ocen z wagami (np. `5 (w:3)`, `4+ (w:2)`).
  4. Rozwinięcie wiersza przedmiotu prezentuje szczegółowy wykaz ocen z datami, wagami i komentarzami.

### Phase 6: Moduł usprawiedliwiania nieobecności wg makiety
**Goal**: Implementacja nowego widoku frekwencji i formularza usprawiedliwiania odpowiadającego makiecie (`media_1789491681801.png`).
**Requirements**: REQ-ATTN-01
**Success Criteria**:
  1. Okrągły wskaźnik frekwencji (np. 94.2%) oraz stan semestru z celami i licznikami.
  2. Filtry: Wszystkie, Do usprawiedliwienia (X), Usprawiedliwione.
  3. Kafelki dni z etykietami stanu (np. 2 DO DECYZJI) i możliwością zaznaczania checkboxów lekcji.
  4. Pływający dolny panel z licznikiem zaznaczonych lekcji, pigułkami szybkiego powodu (Choroba, Wizyta lekarska, Sprawy rodzinne) oraz akcją wysłania usprawiedliwienia.
