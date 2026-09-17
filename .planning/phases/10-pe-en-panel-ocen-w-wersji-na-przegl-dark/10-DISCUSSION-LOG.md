# Phase 10: Pełen panel ocen w wersji na przeglądarkę - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-17
**Phase:** 10-pe-en-panel-ocen-w-wersji-na-przegl-dark
**Areas discussed:** Układ Master-Detail i responsywność, Selekcja przedmiotu, Interakcja kliknięcia w pigułkę oceny, Format szuflady szczegółów oceny

---

## Układ Master-Detail i responsywność

| Option | Description | Selected |
|--------|-------------|----------|
| 1 | Na desktopie (>=1024px) pełny Master-Detail (lewa tabela + prawy inspektor); na tabletach i mobile (<1024px) jednokolumnowa lista z zachowaniem obecnych pigułek i rozwijanych akordeonów ocen. | ✓ |
| 2 | Na desktopie i tabletach (>=768px) Master-Detail (na tabletach bardziej zwarty, np. w proporcji 60/40), a jednokolumnowy tylko na telefonach (<768px). | |
| 3 | Master-Detail na wszystkich ekranach powyżej 600px z poziomym scrollowaniem tabeli. | |

**User's choice:** Opcja 1 (Desktop >=1024px: Master-Detail; Tablety i mobile: jednokolumnowy widok z akordeonami).

---

## Domyślna selekcja przedmiotu na desktopie

| Option | Description | Selected |
|--------|-------------|----------|
| 1 | Domyślnie zaznaczony pierwszy przedmiot z listy; wiersz wyróżniony indygo paskiem po lewej (4px) i jasnym podświetleniem tła, zgodnie z makietą. | |
| 2 | Domyślnie zaznaczony przedmiot z najnowszą wpisaną oceną (najświeższy wpis w dzienniku). | |
| 3 | Domyślnie brak zaznaczenia — prawy panel wyświetla stan pusty z zachętą do wyboru przedmiotu. | ✓ |

**User's choice:** Opcja 3 (Domyślnie brak zaznaczenia — prawy panel wyświetla stan pusty z zachętą do wyboru przedmiotu).

---

## Kliknięcie wiersza przedmiotu vs kliknięcie w pigułkę oceny

| Option | Description | Selected |
|--------|-------------|----------|
| 1 | Kliknięcie wiersza zaznacza przedmiot w prawym inspektorze. Kliknięcie konkretnej pigułki oceny w wierszu zaznacza ten przedmiot ORAZ wysuwa szufladę ze szczegółami tej oceny. | |
| 2 | Kliknięcie wiersza zaznacza przedmiot w inspektorze; pigułki w tabeli są tylko poglądowe — szczegóły oceny klika się z listy w prawym inspektorze. | |
| 3 | Kliknięcie pigułki otwiera szufladę ze szczegółami oceny, ale nie zmienia zaznaczenia w prawym panelu. | ✓ |

**User's choice:** Opcja 3 (Kliknięcie pigułki otwiera szufladę ze szczegółami oceny, ale nie zmienia zaznaczenia w prawym panelu).

---

## Format szuflady szczegółów oceny

| Option | Description | Selected |
|--------|-------------|----------|
| 1 | Wysuwana szuflada z prawej krawędzi ekranu (Side Sheet / Drawer, szerokość ~480-520px) na desktopie z animacją slide-in i przyciemnieniem tła; na telefonach standardowy dolny arkusz (Bottom Sheet). | ✓ |
| 2 | Wysuwana szuflada z prawej strony na każdym urządzeniu (na desktopie 500px, na mobile na całą szerokość ekranu). | |
| 3 | Centrowany dialog modalny na desktopie, a dolny arkusz (Bottom Sheet) na telefonach. | |

**User's choice:** Opcja 1 (Wysuwana szuflada Side Sheet z prawej krawędzi na desktopie; Bottom Sheet na telefonach).

---

## the agent's Discretion

- Tokeny barw Material Design 3 oraz typografia Plus Jakarta Sans zgodnie ze specyfikacją `Academic Precision` (`docs/panel ocen/DESIGN.md` oraz `docs/szczegóły oceny/DESIGN.md`).
- Implementacja wykresu trajektorii średniej (wykres liniowy ze spline i gradientem) oraz histogramu ocen (słupki 1-6).
- Podpięcie przycisku "Przelicz GPA" pod istniejący modal symulacji średniej.

## Deferred Ideas

- None — dyskusja dotyczyła wyłącznie zakresu Fazy 10.
