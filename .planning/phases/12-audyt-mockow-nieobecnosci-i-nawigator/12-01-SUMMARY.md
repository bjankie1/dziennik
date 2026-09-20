# Plan 12-01: Audyt mocków, ujednolicenie profilu ucznia i czyste stany puste — Summary

**Phase:** 12 — audyt-mockow-nieobecnosci-i-nawigator  
**Plan ID:** 12-01  
**Status:** Completed  
**Completed Date:** 2026-09-20  

---

## 1. Executive Summary

Plan 12-01 zrealizował pełny audyt i eliminację sztucznych danych testowych (mocków i fallbacków) w aplikacji EduSync:
1. **Całkowite odcięcie mocków:** W `FirestoreSchoolRepository` odcięto nieuprawnione fallbacki do `MockData` w trybie zalogowania do Librusa (`data != null`). Puste zbiory (brak zajęć, brak ocen, brak ogłoszeń, brak sprawdzianów) zwracają puste listy lub `null`.
2. **Ukrywanie karty sprawdzianu (D-04):** Na Pulpicie (`DashboardScreen`) w przypadku braku nadchodzącego sprawdzianu sekcja jest całkowicie pomijana w drzewie widgetów, pozwalając harmonogramowi zająć pełną wysokość.
3. **Prawidłowa obsługa szczęśliwego numerka (D-10):** Wyeliminowano sztuczne wartości `9` i `18`. W weekendy chip wyświetla neutralny stan „Brak losowania w weekend”, a w dni robocze bez losowania „Brak losowania dzisiaj”. Scraper `librus_client.js` inicjalizuje i parsuje numerek do `0` zamiast fallbacku do `18`.
4. **Dynamiczny profil i kontakt z wychowawcą (D-09, D-11):** Dodano pole `educator` do modelu `StudentProfile`. Wychowawca (`Sobota Łukasz`) jest dynamicznie wstrzykiwany na początek listy nauczycieli oraz w skrócie szybkiego kontaktu. Wyeliminowano twardo zakodowane ciągi `mgr Krzysztof Wiśniewski`, `Klasa 3B LO` i `Liceum Ogólnokształcące im. KEN` ze wszystkich produkcyjnych ekranów.

---

## 2. Tasks Completed & Commit Log

| Task | Opis | Commity |
|---|---|---|
| **Task 1** | Rozszerzenie modelu `StudentProfile` (pole `educator`), uelastycznienie sygnatury `UpcomingEvent?`, odcięcie mock fallbacków w `FirestoreSchoolRepository` | `440436a` (`feat(12-01): student profile educator field and cutoff mock fallbacks in repository`) |
| **Task 2** | Porządki w `DashboardScreen`: całkowite ukrywanie kafelka sprawdzianu, neutralny chip numerka w weekendy/dni wolne, dynamiczny wychowawca w kafelku szybkiego kontaktu | `f71a2f4` (`feat(12-01): clean dashboard exam card, weekend lucky number, dynamic homeroom teacher`) |
| **Task 3** | Czyszczenie widoku ocen (`GradesScreen`, `GradeDetailsSideSheet`, `WeightedAverageKpiCard`, `AverageTrajectoryCard`), nawigatora tygodni oraz scrapera w `functions/src/librus_client.js` | `d02a8e3` (`feat(12-01): remove hardcoded KEN and 3B LO, clean scraper defaults`) |

---

## 3. Decisions & Adherence

- **D-04 (Ukrywanie karty sprawdzianu):** Zaimplementowano warunek `if (exam != null) ...` w `_buildDesktopScheduleColumn`, likwidując sztuczny boks informacyjny o braku sprawdzianów.
- **D-05 (Odcięcie mocków):** Wszystkie metody `FirestoreSchoolRepository` zwracają czyste dane z backendu; puste dni w planie lekcji nie podmieniają się na lekcje demonstracyjne Mai Kowalskiej.
- **D-09 (Wychowawca):** `educator` jest mapowany z danych Librusa (`Sobota Łukasz`) i eksponowany w profilu ucznia oraz liście kontaktów.
- **D-10 (Szczęśliwy numerek):** Neutralny chip w weekendy („Brak losowania w weekend”), domyślna wartość `0` w `FirestoreSchoolRepository` oraz scraperze w cloud functions.
- **D-11 (Dynamiczny profil w ocenach):** Usunięto statyczne stringi `Klasa 3B LO` i `Liceum Ogólnokształcące im. KEN`. Nagłówki pobierają dane z `studentProfileProvider`.

---

## 4. Verification & Quality Gates

- `flutter analyze`: **No issues found!** (0 błędów, 0 ostrzeżeń).
- Grep audyt: Frazy `Wiśniewski` oraz `3B LO` występują wyłącznie w pliku demonstracyjnym `mock_data.dart` oraz przycisku logowania demo; fraza `KEN` została całkowicie wyeliminowana z kodu `lib/`.
