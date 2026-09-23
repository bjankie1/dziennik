# Quick Task 260923-spr Summary: Oznaczenie sprawdzianu w planie lekcji (chip na lekcji + szczegóły i zakres w modalu)

**Status:** Completed & Deployed
**Date:** 2026-09-23

## Root Cause
1. Wydarzenie z Terminarza na dzień `2026-09-29` (`Wtorek`) miało w Librusie postać `rawText: "Nr lekcji: 0sprawdzian4KL, Język angielski"`, `lessonNumber: 0`, `teacher: "Tychańska Magdalena"`, `description: "Unit 5, czasowniki modalne"`, a pole `subject` zostało zapisane jako `"sprawdzian4KL"`.
2. Ponieważ `lessonNumber` wynosił `0`, a `"sprawdzian4kl"` nie pasowało do `"język angielski"`, `FirestoreSchoolRepository._parseTimetableForDay` nie dopasowywało tego sprawdzianu do 6. lekcji we wtorek (`12:40 - 13:25 Język angielski`, nauczyciel `Tychańska Magdalena`).

## Key Changes
1. **Normalizacja przedmiotu i dopasowywanie w `FirestoreSchoolRepository` (`lib/data/repositories/firestore_school_repository.dart`)**:
   - Dodano `_cleanEventSubjectName(event, timetable)`, które wyciąga prawdziwą nazwę przedmiotu (`Język angielski`) z `rawText` (pomijając człony `sprawdzian...` / `kartkówka...`) lub po nauczycielu (`Tychańska Magdalena`).
   - Dzięki temu zarówno na Pulpicie (`Nadchodzący sprawdzian`), jak i w Planie lekcji wydarzenie ma czystą nazwę przedmiotu **`Język angielski (sprawdzian)`** i jest automatycznie przypięte do 6. lekcji we wtorek 29.09 (`Język angielski`, `12:40 - 13:25`).
   - Poprawiono też parser `_parseTerminarzHtml` w `functions/src/librus_client.js` dla przyszłych synchronizacji.
2. **Wyraźny chip na kafelku lekcji (`WeeklyGridView` & `AgendaLessonCard`)**:
   - W widoku siatki tygodniowej (`WeeklyGridView`) lekcja ze sprawdzianem ma wyróżnione tło, niebieski pasek, chip **`[📋 Sprawdzian]`** (lub **`[📋 Kartkówka]`**) z ikoną oraz podgląd zakresu (`Unit 5, czasowniki modalne`). Rozszerzono także siatkę godzinową do 10 lekcji (aby widoczna była 9. lekcja we wtorek `15:15 - 16:00`).
   - W widoku dziennym (`AgendaLessonCard`) oprócz chipu w nagłówku wyświetla się wyróżniony boks z zakresem materiału podanym przez nauczyciela.
3. **Szczegóły sprawdzianu i zakres w modalu lekcji (`LessonDetailsModal`)**:
   - Po kliknięciu w lekcję otwiera się `LessonDetailsModal` z plakietką statusu `Sprawdzian`, sekcją **„ZAPOWIEDZIANY SPRAWDZIAN”**, pełnym **zakresem materiału od nauczyciela** (`Unit 5, czasowniki modalne`), nazwiskiem nauczyciela (`Wpisał(a): Tychańska Magdalena`) oraz przyciskiem **`+ Zadanie dla Oskara: Naucz się`**.
