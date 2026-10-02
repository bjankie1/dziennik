# Phase 23: Podgląd szczegółów próśb o usprawiedliwienie i oczekujących wniosków - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-02
**Phase:** 23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni
**Areas discussed:** Sposób podglądu szczegółów prośby ucznia na Pulpicie i we Frekwencji, Sposób podglądu i zarządzania „X wnioski czekają na wychowawcę”, Zakres informacji o pojedynczej lekcji w podglądzie oraz możliwość częściowej akceptacji/cofania

---

## Sposób podglądu szczegółów prośby ucznia na Pulpicie i we Frekwencji

| Option | Description | Selected |
|--------|-------------|----------|
| Rozwijana lista pod banerem + skrót na banerze | Na banerze pokaż skrót dat i przedmiotów + przycisk „Zobacz szczegóły (6 lekcji)”, który rozwija listę lekcji pod banerem | |
| Kliknięcie w baner otwiera dedykowany modal | Kliknięcie w baner otwiera dedykowany modal ze szczegółową listą 6 lekcji oraz przyciskami Zatwierdź (PIN) / Odrzuć | ✓ |
| Zawsze rozwinięta lista w banerze | Lista wszystkich lekcji z prośby jest zawsze rozwinięta bezpośrednio wewnątrz żółtego banera | |

**User's choice:** Kliknięcie w baner otwiera dedykowany modal ze szczegółową listą 6 lekcji oraz przyciskami Zatwierdź (PIN) / Odrzuć.

---

## Sposób podglądu i zarządzania „X wnioski czekają na wychowawcę”

| Option | Description | Selected |
|--------|-------------|----------|
| Rozwijany baner + pigułka filtra „Oczekujące (7)” | Rozwijany baner „7 wnioski czekają na wychowawcę” (kliknięcie rozwija pogrupowaną dniami listę tych 7 lekcji z powodem i opcją cofnięcia pojedynczego lub wszystkich wniosków) + dodatkowa pigułka filtra „Oczekujące (7)” obok „Do usprawiedliwienia” | ✓ |
| Tylko rozwijana lista w banerze | Tylko rozwijana lista bezpośrednio w banerze „7 wnioski czekają na wychowawcę” (bez nowej zakładki w filtrach) | |
| Osobne okno modalne | Kliknięcie w baner otwiera osobne okno modalne z listą oczekujących wniosków | |

**User's choice:** Rozwijany baner „7 wnioski czekają na wychowawcę” + dodatkowa pigułka filtra „Oczekujące (7)” obok „Do usprawiedliwienia”.

---

## Zakres informacji o pojedynczej lekcji i częściowa akceptacja

| Option | Description | Selected |
|--------|-------------|----------|
| Pełne wiersze pogrupowane dniami + checkboxy częściowej akceptacji | Pełne wiersze pogrupowane dniami: Data i dzień tygodnia, Nr lekcji + godziny (np. Lekcja 3 • 09:45–10:30), Przedmiot, Nauczyciel oraz powód / możliwość odznaczenia poszczególnych lekcji przed zatwierdzeniem PIN-em | ✓ |
| Tylko zwięzła lista bez odznaczania | Tylko zwięzła lista (Data, Nr lekcji, Przedmiot, Powód) bez możliwości odznaczania pojedynczych lekcji | |

**User's choice:** Pełne wiersze pogrupowane dniami: Data i dzień tygodnia, Nr lekcji + godziny, Przedmiot, Nauczyciel oraz powód / możliwość odznaczenia poszczególnych lekcji przed zatwierdzeniem PIN-em.

---

## the agent's Discretion

- Szczegóły animacji rozwijania banera oczekujących wniosków oraz przekazania wybranych `recordIds` przy częściowej akceptacji prośby.

## Deferred Ideas

None.
