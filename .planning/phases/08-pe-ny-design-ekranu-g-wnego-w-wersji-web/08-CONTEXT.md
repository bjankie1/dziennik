# Phase 8: Pełny design ekranu głównego w wersji web - Context

**Created:** 2026-09-16  
**Status:** In Progress (Context Initialized)  
**Reference Design:**
- Mockup Image: docs/start_page_web_v1/screen.png
- HTML Prototype: docs/start_page_web_v1/code.html
- Design Tokens & Specification: docs/start_page_web_v1/DESIGN.md

---

## 1. Vision & Architecture

Ekran główny (Pulpit / Dashboard) w wersji webowej (desktop/tablet) zostaje kompleksowo dostosowany do dedykowanego projektu graficznego przygotowanego w docs/start_page_web_v1/.

Główne założenia architektoniczne:
1. **Dedykowany layout responsywny**:
   - Na ekranach desktopowych (szerokość >= 1024px): 3-kolumnowy Bento Grid z lewym panelem nawigacji (Sidebar) i górnym nagłówkiem (Header).
   - Na ekranach tabletowych (768px - 1023px): 2-kolumnowy Bento Grid z adaptacyjnym układem.
   - Na ekranach mobilnych (< 768px): płynny, 1-kolumnowy scroll z zachowaniem dotychczasowego mobilnego paska nawigacji na dole.
2. **Pełna integracja z rzeczywistymi danymi ucznia (Librus Synergia)**:
   - Imię i nazwisko: Oskar Jankiewicz, klasa: 4 k Lic, szkoła: LO nr X we Wrocławiu.
   - Harmonogram dnia: rzeczywiste lekcje na dany dzień z godzinami, numerami, salami i nauczycielami. Wskaźnik lekcji trwającej („W trakcie”) z paskiem postępu.
   - Oceny: rzeczywiste najnowsze oceny z wagami i średnią ważoną.
   - Frekwencja: rzeczywisty procent frekwencji, pasek celu rocznego (>90%) oraz licznik godzin do usprawiedliwienia z bezpośrednim wywołaniem modalu usprawiedliwiania.
   - Wiadomości i komunikaty: rzeczywiste wątki wiadomości (w tym nieprzeczytane) z filtrami i bezpośrednim przejściem do odpowiedzi/wątku.
   - Szczęśliwy numerek: rzeczywisty szczęśliwy numerek ze szkoły.

---

## 2. Key Components Breakdown

### A. Navigation Sidebar (Desktop >= 1024px)
- Logo EduSync + nazwa szkoły ("LO nr X im. Stefanii Sempołowskiej").
- Selektor semestru ("Semestr 1 / 2024-2025").
- Menu nawigacji z ikonami i aktywnym stanem (fioletowe tło Color(0xFF3525CD) / Color(0xFF4F46E5)):
  - Pulpit (aktywny)
  - Oceny i Średnie
  - Plan Lekcji
  - Frekwencja
  - Wiadomości i Ogłoszenia (z dynamicznym badge liczby nieprzeczytanych)
- Dolny widżet: status synchronizacji dziennika ("Aktualizacja: Dzisiaj, HH:MM").

### B. Header Bar
- Wyszukiwarka globalna z placeholderem "Szukaj w ocenach, planie, wiadomościach...".
- Ikona powiadomień z badge.
- Pigułka profilu ucznia: Avatar, "Oskar Jankiewicz", "Klasa 4 k Lic" + menu wylogowania/przełączania.

### C. Top Welcome & Metric Banner
- Nagłówek: "Dzień dobry, Oskar! 👋" + pigułki stanu ("Tydzień B • Semestr 1", "Stan normalny").
- Linia podsumowania dnia: aktualna data, godziny rozpoczęcia i zakończenia zajęć oraz liczba lekcji.
- Kafelki mini-metryk:
  - Średnia ważona (np. 4.82 / Top 5%)
  - Frekwencja (np. 98.6% / Cel: >90%)
  - Wiadomości (liczba nieprzeczytanych)
  - Szczęśliwy numerek / Sprawdziany

### D. 3-Column Bento Grid
1. **Kolumna lewa: Harmonogram na dziś**
   - Karta "Harmonogram na dziś" (licznik zrealizowanych lekcji).
   - Lista lekcji dnia z wyróżnieniem lekcji trwającej, odwołanych, zastępstw i planowych.
   - Przycisk "Pełny plan lekcji na cały tydzień →".
   - Karta "Nadchodzący sprawdzian" (countdown, przedmiot, zakres).

2. **Kolumna środkowa: Wiadomości i Komunikaty**
   - Karta "Wiadomości i Komunikaty" z linkiem "Otwórz skrzynkę →".
   - Pigułki filtrów: "Nieprzeczytane (X)", "Wszystkie", "Ogłoszenia (Y)".
   - Wątki wiadomości ze statusem PILNE / DYREKCJA, nadawcą, datą i akcją "Odpowiedz".
   - Karta wydarzenia szkolnego (np. Dzień Wolny / Konferencja).

3. **Kolumna prawa: Oceny, Frekwencja i Szybkie Akcje**
   - Karta "Ostatnie oceny" z trendem do średniej, pigułkami ocen z wagami i linkiem do wszystkich ocen.
   - Karta "Frekwencja" z paskiem postępu celu rocznego, ostrzeżeniem o godzinach do usprawiedliwienia i przyciskiem "Szybkie usprawiedliwienie (PIN)".
   - Skróty szybkich akcji: Zadania domowe, Kontakt z wychowawcą, Zgłoś nieobecność.
