# Summary 12-02: Frekwencja w planie lekcji i stała szerokość przełącznika tygodni

**Phase:** 12 — audyt-mockow-nieobecnosci-i-nawigator  
**Plan ID:** 12-02  
**Requirements:** REQ-TIMETABLE-05, REQ-TIMETABLE-06  
**Decisions Covered:** D-01, D-02, D-03, D-06, D-07, D-08, D-09  
**Execution Date:** 2026-09-20  

---

## 1. Executive Summary

W ramach planu 12-02 zrealizowano wzbogacenie planu lekcji o informacje o frekwencji oraz ustabilizowano poziome położenie przycisków w przełączniku tygodni:
1. **Model `LessonSlot` & Repozytorium:** Rozszerzono model slotu lekcyjnego o status frekwencji (`attendanceType`), status e-usprawiedliwienia (`attendanceJustificationStatus`) oraz notatkę rodzica (`attendanceNote`). W `FirestoreSchoolRepository` skorelowano pobieraną frekwencję (w tym lokalne wnioski rodzica) ze slotami w `getTodaySchedule`, `getScheduleForDay` oraz `getWeekSchedule`.
2. **Stała szerokość `WeekNavigatorBar`:** Przypięto przyciski nawigacyjne `[<]` i `[>]` do skrajnych krawędzi kontenera o zablokowanej szerokości 430px (na desktopie/tabletach) z elastycznym środkiem `Expanded`. Wielokrotne klikanie strzałki w prawo `[>]` nie przesuwa już kursora myszy o żaden piksel, niezależnie od obecności etykiety „Aktualny” czy długości nazwy miesiąca. Poniżej 500px na telefonach pasek elastycznie dopasowuje się do szerokości ekranu (`double.infinity`).
3. **Pigułki i bloki frekwencji (D-01, D-02, D-03):**
   - W siatce tygodniowej (`WeeklyGridView`) obok numeru sali renderowana jest kompaktowa pigułka informująca o nieobecności (czerwona), usprawiedliwieniu (szmaragdowa), weryfikacji (bursztynowa), zwolnieniu (błękitna) lub spóźnieniu (żółta).
   - W widoku agendy (`AgendaLessonCard`) dodano pigułkę w nagłówku oraz pełny banerek z powodem rodzica i statusem akceptacji przez wychowawcę.
   - W modalu szczegółów lekcji (`LessonDetailsModal`) zaimplementowano pełną sekcję frekwencji z opisem decyzji wychowawcy, podglądem powodu rodzica oraz bezpośrednim przyciskiem akcji „Zgłoś e-usprawiedliwienie”, otwierającym `JustificationModal`.

---

## 2. Tasks Executed & Commits

| Zadanie | Opis | Commit |
|---------|------|--------|
| **Task 1** | Rozszerzenie `LessonSlot` o frekwencję i korelacja w `FirestoreSchoolRepository` | `93dbc81` (`feat(12-02): enrich lesson slots with attendance records and justification status`) |
| **Task 2** | Stała szerokość przełącznika tygodni w `WeekNavigatorBar` z przypiętymi przyciskami `[<]` i `[>]` | `676c1db` (`feat(12-02): fixed width week navigator bar with pinned chevron buttons and dynamic educator`) |
| **Task 3** | Pigułki i bloki frekwencji w `WeeklyGridView`, `AgendaLessonCard` oraz `LessonDetailsModal` | `2d0a8ef` (`feat(12-02): visual attendance badges in weekly grid, agenda, and lesson details modal`) |

---

## 3. Verification & Quality Gate

1. **Analiza statyczna Dart/Flutter:**
   - Polecenie `flutter analyze` zakończone sukcesem: `No issues found!`.
2. **Pakiet testów integracyjnych w `functions/`:**
   - Polecenie `npm test` w `functions/` przeszło bezbłędnie (18 testów ukończonych sukcesem, w tym testy parsowania frekwencji i uzgadniania statusów e-usprawiedliwień).
3. **Kryteria akceptacji:**
   - **Widoczność statusów w siatce (D-01, D-02):** Zrealizowano pigułki kolorystyczne i dedykowany badge „Weryfikacja” dla wniosków oczekujących.
   - **Szczegóły frekwencji (D-03):** Karta agendy i modal szczegółów wyświetlają powód oraz status decyzji wychowawcy, z opcją złożenia e-usprawiedliwienia.
   - **Nieruchomy przełącznik (D-06, D-07, D-08):** Pasek ma stałą szerokość 430px z `Expanded` w środku, a strzałka `>` nie przesuwa się przy klikaniu.
