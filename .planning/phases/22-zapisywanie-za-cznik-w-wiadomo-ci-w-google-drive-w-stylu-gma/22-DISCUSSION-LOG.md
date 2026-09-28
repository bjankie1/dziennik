# Phase 22: Zapisywanie załączników wiadomości w Google Drive w stylu Gmail - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-28
**Phase:** 22-zapisywanie-za-cznik-w-wiadomo-ci-w-google-drive-w-stylu-gma
**Areas discussed:** Organizacja plików na Google Drive, Sposób wyboru folderu docelowego, Zachowanie UI w stylu Gmail, Trwałość stanu „Zapisano na Dysku”

---

## Organizacja plików na Google Drive

| Option | Description | Selected |
|--------|-------------|----------|
| Dedykowany folder „EduSync - Załączniki szkolne” z podfolderami wg roku szkolnego | Automatyczna struktura folderów | |
| Jeden wspólny folder „EduSync - Załączniki szkolne” bez podfolderów | Płaski dedykowany folder | |
| Podfoldery wg nadawcy wiadomości | Struktura wg nauczyciela/nadawcy | |
| Zapis bezpośrednio w głównym katalogu „Mój dysk” | Brak dedykowanego folderu | |
| Custom (User write-in) | Wskazany przeze mnie folder, fallback do głównego folderu "Mój dysk" | ✓ |

**User's choice:** Wskazany przeze mnie folder, fallback do głównego folderu "Mój dysk"
**Notes:** Użytkownik chce sam decydować o folderze docelowym, a w razie braku skonfigurowanego folderu pliki mają trafiać bezpośrednio do głównego katalogu „Mój dysk”.

---

## Sposób wskazywania docelowego folderu na Google Drive

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Jak w Gmailu: zapis od razu + przycisk „Zmień folder / Przenieś” w dymku potwierdzenia oraz ustawienie domyślnego folderu w Ustawieniach | Natychmiastowy zapis bez blokowania modalem za każdym razem, z możliwością przeniesienia po zapisie i konfiguracji w Ustawieniach | ✓ |
| Okienko wyboru/wpisania folderu przy każdym kliknięciu „Zapisz na Dysku” | Modal przed każdym zapisem | |
| Tylko konfiguracja docelowego folderu w Ustawieniach | Brak wyboru przy pojedynczym zapisie | |

**User's choice:** (Recommended) Jak w Gmailu: zapis od razu (do domyślnego folderu lub „Mój dysk”) + przycisk „Zmień folder / Przenieś” w dymku potwierdzenia oraz ustawienie domyślnego folderu w Ustawieniach

---

## Zachowanie UI w stylu Gmail

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Dwie ikony na kafelku (Pobierz + Zapisz na Dysku Google) oraz zbiorczy przycisk „Zapisz wszystkie na Dysku” przy >=2 załącznikach | Osobne akcje na kafelku + akcja zbiorcza przy wielu załącznikach | ✓ |
| Dwie ikony na każdym kafelku załącznika (Pobierz + Zapisz na Dysku Google), bez przycisku zbiorczego | Tylko pojedyncze akcje | |
| Kliknięcie załącznika otwiera menu z wyborem | Dodatkowe kliknięcie w menu kontekstowe | |

**User's choice:** (Recommended) Dwie ikony na kafelku (Pobierz + Zapisz na Dysku Google) oraz zbiorczy przycisk „Zapisz wszystkie na Dysku” przy >=2 załącznikach

---

## Stan po zapisaniu („Zapisano na Dysku”)

| Option | Description | Selected |
|--------|-------------|----------|
| (Recommended) Trwały zapis statusu i linku w Firestore — po zapisaniu ikona zmienia się na „Otwórz w Google Drive” dla domowników | Wspólny stan w Firestore z bezpośrednim linkiem do pliku w Google Drive | ✓ |
| Osobny status zapisu per konto Google | Rodzic i Uczeń widzą tylko własne zapisy | |
| Tylko potwierdzenie (SnackBar) bez trwałego zapisywania stanu w Firestore | Stan tymczasowy w sesji | |

**User's choice:** (Recommended) Trwały zapis statusu i linku w Firestore — po zapisaniu ikona zmienia się na „Otwórz w Google Drive” dla domowników

---

## the agent's Discretion

- Szczegóły UI modala wyboru/tworzenia folderu na Google Drive (wywoływanego z „Zmień folder / Przenieś” oraz z ekranu Ustawień).
- Techniczny sposób przekazania pliku między Librus (`sandbox.librus.pl/GetFile/.../get`), Cloud Functions a Google Drive REST API v3 przy użyciu tokenu OAuth z zakresem `drive.file`.

## Deferred Ideas

None.
