# Phase 11: Dyskretne odpytywanie serwerów Librus (rate limiting, harmonogram nocny) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-18  
**Phase:** 11-dyskretne-odpytywanie-serwerow-librus  
**Areas discussed:** Harmonogram godzinowy i całkowita cisza nocna, Sekwencyjność zapytań, profil przeglądarki, zarządzanie sesją i dynamiczny backoff  

---

## Harmonogram godzinowy i całkowita cisza nocna

| Opcja | Opis | Wybrano |
|-------|------|---------|
| 22:30 – 06:30 | Naturalny czas spoczynku, brak ruchu w nocy | ✓ |
| 23:00 – 06:00 | Krótsze okno uśpienia | |
| 22:00 – 07:00 | Rozszerzone okno spokoju nocnego | |

**Decyzja użytkownika:** 22:30 – 06:30 jako godziny ciszy nocnej bez żadnych automatycznych zapytań.

---

## Częstotliwość w dni szkolne (Pn-Pt 07:00–16:30)

| Opcja | Opis | Wybrano |
|-------|------|---------|
| Co 30-40 minut z jitterem | Losowe przesunięcie (+/- 3-7 minut) zapobiegające powtarzalności | ✓ |
| Co 15-20 minut | Częstsze sprawdzanie ocen i zastępstw | |
| Co 60 minut | Bardzo rzadkie sprawdzanie | |

**Decyzja użytkownika:** Co 30–40 minut z losowym jitterem.

---

## Częstotliwość w weekendy i popołudnia

| Opcja | Opis | Wybrano |
|-------|------|---------|
| W weekendy 2 razy na dobę | Sprawdzanie np. o 11:00 i 19:00 | ✓ |
| Co 2-3 godziny w godz. 09:00-21:00 | Umiarkowana częstotliwość | |
| Brak zapytań w weekendy | Wyłącznie manualne odświeżanie | |

**Decyzja użytkownika:** W weekendy tylko 2 razy dziennie (11:00 i 19:00). W dni powszednie po 16:30 co 60 minut.

---

## Ręczne odświeżenie (Manual sync) w nocy

| Opcja | Opis | Wybrano |
|-------|------|---------|
| Zezwól z cooldownem | Pobierz dane z serwera na żądanie użytkownika z limitem min. 2 minuty | ✓ |
| Blokada w nocy | Wyświetl komunikat i użyj wyłącznie lokalnego cache | |

**Decyzja użytkownika:** Zezwól na żądanie użytkownika z cooldownem 2 minuty.

---

## Sekwencyjność pobierania modułów

| Opcja | Opis | Wybrano |
|-------|------|---------|
| Sekwencyjne z przerwą 1.0 – 2.5s | Imitacja człowieka klikającego w zakładki dziennika | ✓ |
| Krótsze opóźnienie 0.5 – 1.0s | Szybsze wykonanie Cloud Function | |
| Paczki po 2 zapytania | Grupowanie zapytań | |

**Decyzja użytkownika:** Sekwencyjne odpytywanie z losową przerwą 1.0 – 2.5 sekundy.

---

## Profil przeglądarki i nagłówki HTTP

| Opcja | Opis | Wybrano |
|-------|------|---------|
| Nowoczesny User-Agent + pełne nagłówki | Aktualny Chrome/Safari, nagłówki Accept, Accept-Language, Sec-Ch-Ua | ✓ |
| Pula 3-4 User-Agentów | Rotacja losowych przeglądarek | |

**Decyzja użytkownika:** Nowoczesny User-Agent i komplet nagłówków prawdziwej przeglądarki.

---

## Zarządzanie sesją Librus

| Opcja | Opis | Wybrano |
|-------|------|---------|
| Utrzymywanie ciasteczek sesji | Logowanie OAuth tylko po faktycznym wygaśnięciu sesji | ✓ |
| Logowanie od nowa za każdym razem | Nowa sesja przy każdym wywołaniu | |

**Decyzja użytkownika:** Utrzymywanie sesji w pamięci/Firestore, eliminacja zbędnych logowań OAuth.

---

## Obsługa limitów i błędów (429 / 503)

| Opcja | Opis | Wybrano |
|-------|------|---------|
| Dynamiczny backoff 15–30 min | Wstrzymanie zapytań i serwowanie z cache | ✓ |
| Cichy fallback na 1 godzinę | Brak prób przez 60 minut | |

**Decyzja użytkownika:** Dynamiczny backoff 15–30 minut z natychmiastowym serwowaniem danych z cache.
