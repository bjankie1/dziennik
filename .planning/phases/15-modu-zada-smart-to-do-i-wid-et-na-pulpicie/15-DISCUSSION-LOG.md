# Phase 15: Moduł zadań (Smart To-Do) i widżet na Pulpicie - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-23
**Phase:** 15-Moduł zadań (Smart To-Do) i widżet na Pulpicie
**Areas discussed:** Model zadań i współpraca Rodzic ↔ Uczeń, Układ i interakcja widoku /zadania, Widżet zadań na Pulpicie, Nawigacja mobilna

---

## 1. Model zadań i współpraca Rodzic ↔ Uczeń

| Option | Description | Selected |
|--------|-------------|----------|
| Przypisanie do roli + atrybucja | „Dla Oskara”, „Dla Rodzica”, „Wspólne” + znacznik kto utworzył i kto odhaczył | ✓ |
| Wspólna pula bez podziału | Wspólna pula bez „Dla kogo”, z widocznym autorem i osobą odhaczającą | |
| Pełna separacja | Każdy widzi domyślnie tylko swoje zadania | |

| Option | Description | Selected |
|--------|-------------|----------|
| 3 priorytety + tag przedmiotu/kategorii | Wysoki 🔴 / Normalny 🔵 / Niski ⚪ + opcjonalny tag przedmiotu lub kategorii | ✓ |
| Tylko 3 poziomy priorytetu | Wysoki / Średni / Niski bez kategorii i przedmiotów | |
| Tylko flaga „Pilne / Ważne” | Gwiazdka + opcjonalny przedmiot szkolny | |

| Option | Description | Selected |
|--------|-------------|----------|
| Ochrona zadań zleconych przez Rodzica | Obaj mogą dodawać/edytować/odhaczać; usunięcie zadania Rodzica przez ucznia zablokowane | ✓ |
| Pełna symetria | Każdy może usuwać każde zadanie | |
| Tylko autor może usunąć/edytować | Edycja i usunięcie tylko przez autora | |

**User's choice:** Przypisanie do roli z atrybucją, 3 priorytety z opcjonalnym przedmiotem/kategorią oraz ochrona zadań zleconych przez Rodzica przed skasowaniem przez ucznia.

---

## 2. Układ i interakcja widoku /zadania

| Option | Description | Selected |
|--------|-------------|----------|
| Pasek Quick Add + przycisk „+ Nowe zadanie” | Szybki pasek na górze z pigułkami + przycisk otwierający pełny modal formularza | ✓ |
| Tylko przycisk „+ Nowe zadanie” | Klasyczny przycisk otwierający modal | |
| Tylko pasek Quick Add inline | Szczegóły dopiero po kliknięciu w utworzone zadanie | |

| Option | Description | Selected |
|--------|-------------|----------|
| Sekcje chronologiczne wewnątrz zakładek | Zaległe, Dzisiaj, Jutro / Nadchodzące, Bez terminu + szybki filtr Moje/Oskara/Wspólne | ✓ |
| Płaska lista | Posortowana po terminie i priorytecie bez sekcji | |
| Tablica Kanban | 3 kolumny na desktopie | |

| Option | Description | Selected |
|--------|-------------|----------|
| Styl spójny z listą Wiadomości (MessagesScreen) | Górny Segmented Control Bar, wiersz akcji Quick Add + FilledButton „+ Nowe zadanie”, lista kart | ✓ |

**User's choice:** Wygląd i układ wzorowany na liście wiadomości (`MessagesScreen`) z paskiem `Quick Add`, przyciskiem `+ Nowe zadanie` oraz chronologicznymi sekcjami zadań.

---

## 3. Widżet zadań na Pulpicie

| Option | Description | Selected |
|--------|-------------|----------|
| W Kolumnie 2 (Środkowa kolumna) | Nad kartą Wiadomości i Komunikatów w 3-kolumnowym Bento Grid | ✓ |
| W Kolumnie 1 (Lewa kolumna) | Pod Harmonogramem dnia i kartą sprawdzianu | |
| W Kolumnie 3 (Prawa kolumna) | Nad Ostatnimi Ocenami i Frekwencją | |

| Option | Description | Selected |
|--------|-------------|----------|
| Do 4–5 najpilniejszych + Quick Add + link | Zaległe + Dzisiaj, odhaczanie 1-kliknięciem z animacją, przycisk „+” i link „Zobacz wszystkie” | ✓ |
| Tylko zadania na dzisiaj bez dodawania | Bez zaległych i bez przycisku „+” | |

**User's choice:** Widżet „Zadania na dziś” na górze Kolumny 2 (nad Wiadomościami i Komunikatami), prezentujący 4–5 najpilniejszych zadań (Zaległe + Dzisiaj) z szybkim odhaczaniem, przyciskiem „+” i przejściem do `/zadania`.

---

## 4. Nawigacja mobilna

| Option | Description | Selected |
|--------|-------------|----------|
| „Zadania” w dolnym pasku + „Czat” w AppHeader na mobile | 6 zakładek w NavigationBar na mobile, Czat Rodzinny jako ikona z badge'em w górnym AppHeader (na desktopie obie w AppSidebar) | ✓ |
| 7 zakładek w dolnym pasku | Wszystkie 7 zakładek w NavigationBar na mobile | |

**User's choice:** W dolnym pasku `NavigationBar` na mobile umieszczamy `Zadania` (razem 6 zakładek), a `Czat Rodzinny` przenosimy na mobile do ikony z licznikiem badge w górnym nagłówku `AppHeader` (z zachowaniem obu pozycji w `AppSidebar` na desktopie).

---

## the agent's Discretion

- Schemat dokumentu w kolekcji Firestore `family_tasks/{familyId}/tasks` oraz reguły bezpieczeństwa `firestore.rules`.
- Zestaw przykładowych zadań startowych (fallback/seed) przy pierwszym uruchomieniu.

## Deferred Ideas

- Automatyczne generowanie zadań przygotowawczych ze sprawdzianów i terminarza (`REQ-TASK-03`) oraz heurystyczne wykrywanie zadań/opłat z wiadomości Librusa (`REQ-TASK-04`) — Faza 16.
