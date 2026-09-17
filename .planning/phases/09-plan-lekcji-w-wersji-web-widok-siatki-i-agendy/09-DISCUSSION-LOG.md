# Phase 9: Plan lekcji w wersji web (Widok siatki i agendy) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-17
**Phase:** 09-plan-lekcji-w-wersji-web-widok-siatki-i-agendy
**Areas discussed:** Domyślny widok i zachowanie responsywne, Pasek statystyk i dane lekcji w Agendzie

---

## Domyślny widok i zachowanie responsywne

| Option | Description | Selected |
|--------|-------------|----------|
| Siatka na desktopie, Agenda na mobile | Domyślna siatka tygodniowa dla szerokich ekranów (>=1024px) i agenda dla telefonów z przełącznikiem | ✓ |
| Zapamiętywanie ostatniego trybu | SharedPreferences przechowuje ostatni wybór użytkownika | |
| Zawsze Agenda | Zawsze agenda jako domyślny widok | |

**User's choice:** Siatka tygodniowa (Pon–Pt) na desktopie, a Agenda na mobile, z przełącznikiem w nagłówku.

---

## Synchronizacja dnia przy przełączaniu

| Option | Description | Selected |
|--------|-------------|----------|
| Synchronizacja wybranego dnia | Przełączenie do Agendy lub kliknięcie dnia w Siatce otwiera dokładnie ten sam dzień | ✓ |
| Zawsze dzień bieżący | Agenda zawsze startuje na bieżącym dniu (dzisiaj) | |

**User's choice:** Synchronizacja wybranego dnia — kliknięcie dnia w Siatce lub przełączenie do Agendy otwiera dokładnie ten sam dzień.

---

## Responsywność na tabletach (768px – 1023px)

| Option | Description | Selected |
|--------|-------------|----------|
| Siatka z poziomym scrollem | Min. 900px szerokości z horyzontalnym przewijaniem | |
| Domyślnie Agenda na tabletach | Agenda jako domyślny widok dla tabletów | |
| Kompaktowa siatka bez przewijania | Skrócone nazwy przedmiotów i sal, aby zmieścić 5 kolumn na ekranie | ✓ |

**User's choice:** Kompaktowa siatka bez przewijania (skrócone nazwy przedmiotów i sal, aby zmieścić 5 kolumn).

---

## Interakcja z kafelkiem w Siatce

| Option | Description | Selected |
|--------|-------------|----------|
| Modal / okno dialogowe ze szczegółami | Pełny podgląd tematu, sali, zadań bez opuszczania Siatki | ✓ |
| Przełączenie do Agendy | Przełącza na widok Agendy danego dnia z podświetleniem lekcji | |
| Popover / tooltip | Lekki popover nad kafelkiem | |

**User's choice:** Modal / okno dialogowe ze szczegółami lekcji (temat, sala, nauczyciel, zadania domowe, powód zastępstwa) bez opuszczania Siatki.

---

## Pasek 4 kafelków podsumowania tygodnia

| Option | Description | Selected |
|--------|-------------|----------|
| Kafelki interaktywne | Kliknięcie kafelka (np. Zastępstwa lub Sprawdziany) podświetla lub filtruje powiązane lekcje | ✓ |
| Kafelki tylko informacyjne | Tylko prezentacja liczb bez akcji | |

**User's choice:** Kafelki interaktywne — kliknięcie kafelka (np. Zastępstwa lub Sprawdziany) podświetla lub filtruje powiązane lekcje w siatce.

---

## Lekcja aktywna na żywo w Agendzie

| Option | Description | Selected |
|--------|-------------|----------|
| Pełny styl z makiety | Pulsujący wskaźnik na żywo, licznik czasu do końca i powiększony boks tematu | ✓ |
| Uproszczony wskaźnik | Stała plakietka "W trakcie" | |

**User's choice:** Styl z makiety — pulsujący wskaźnik na żywo, dynamiczny licznik czasu do końca lekcji (minuty) i wyróżniony boks tematu/zadań.

---

## Prezentacja odwołań i zastępstw

| Option | Description | Selected |
|--------|-------------|----------|
| Pełny styl z makiety | Przekreślenie pierwotnych danych, kolorowe paski statusów oraz ramka z powodem zmiany/nową salą | ✓ |
| Prostsze oznaczenie | Pigułka statusu bez przekreśleń i boksów | |

**User's choice:** Pełny styl z makiety — przekreślenie pierwotnych danych, kolorowe paski statusów oraz ramka z powodem zmiany/nową salą.

---

## Rozszerzenie modelu danych lekcji

| Option | Description | Selected |
|--------|-------------|----------|
| Wzbogacenie LessonSlot | Opcjonalne topic, homework, materials i integracja z terminarzem z ukrywaniem pustych pól | ✓ |
| Tylko podstawowe dane | Bez rozszerzania modelu | |

**User's choice:** Wzbogacenie LessonSlot o opcjonalne topic, homework, materials i powiązanie z terminarzem, z ukrywaniem sekcji gdy brak danych.

---

## the agent's Discretion

- Tokeny kolorystyczne zgodne z paletą Academic Precision i Material 3.
- Nawigacja tygodniowa (poprzedni/następny tydzień, wskaźnik bieżącego tygodnia, przycisk "Dzisiaj").

