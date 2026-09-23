# Quick Task 260923-spr Plan: Oznaczenie sprawdzianu w planie lekcji (chip na lekcji + szczegóły i zakres w modalu)

## Goal
Sprawdzian widoczny na Pulpicie (np. 29.09 z Języka angielskiego: „Unit 5, czasowniki modalne”, nauczyciel Tychańska Magdalena) musi być widoczny w **Planie lekcji** (zarówno w widoku Siatki tygodniowej, jak i Agendy) jako wyraźny **chip** na odpowiedniej lekcji, a po kliknięciu w lekcję (`LessonDetailsModal`) musi wyświetlać pełną informację o sprawdzianie wraz z zakresem materiału podanym przez nauczyciela.

## Root Cause
1. W Librus Terminarz wydarzenie z 29.09 ma postać `rawText: "Nr lekcji: 0sprawdzian4KL, Język angielski"`, `lessonNumber: 0`, `teacher: "Tychańska Magdalena"`, `description: "Unit 5, czasowniki modalne"`.
2. Parser `_parseTerminarzHtml` w `librus_client.js` brał pierwszy człon przed przecinkiem (`"sprawdzian4KL"`) zamiast drugiego (`"Język angielski"`), przez co pole `subject` zawierało `"sprawdzian4KL"`.
3. W `FirestoreSchoolRepository._parseTimetableForDay` dopasowanie zdarzenia z Terminarza do lekcji nr 6 (`Język angielski`, `12:40 - 13:25`, `Tychańska Magdalena`) kończyło się niepowodzeniem, ponieważ `lessonNumber` wynosił `0`, a `"sprawdzian4kl"` nie pasowało do `"język angielski"`.

## Tasks
1. **`lib/data/repositories/firestore_school_repository.dart`**:
   - Dodać metodę `_cleanEventSubjectName(Map<String, dynamic> event, List<dynamic> timetable)`, która wyciąga właściwą nazwę przedmiotu (np. `Język angielski`) z `rawText` (pomijając człony zaczynające się od `sprawdzian`/`kartkówka`) lub dopasowuje po nauczycielu (`Tychańska Magdalena`).
   - Zastosować normalizację w `getUpcomingExam()` (aby na Pulpicie wyświetlało się `Język angielski (sprawdzian)` zamiast `sprawdzian4KL (sprawdzian)`) oraz w `_extractAllEvents()` i `_parseTimetableForDay()`.
   - W `_parseTimetableForDay()` rozszerzyć dopasowywanie wydarzeń z Terminarza do lekcji o oczyszczoną nazwę przedmiotu, zawartość `rawText` oraz nazwisko nauczyciela (`e['teacher'] == item['teacher']`).
2. **`lib/presentation/screens/schedule/widgets/weekly_grid_view.dart` & `agenda_lesson_card.dart`**:
   - Na kafelku lekcji w siatce tygodniowej (`WeeklyGridView`) wyświetlać wyraźny chip `[📋 Sprawdzian]` / `[📋 Kartkówka]` wraz z podglądem zakresu (`Unit 5, czasowniki modalne`).
   - Na karcie lekcji w widoku dziennym (`AgendaLessonCard`) wyświetlać chip z ikoną w prawym górnym rogu oraz wyróżniony boks z zakresem sprawdzianu.
3. **`lib/presentation/screens/schedule/widgets/lesson_details_modal.dart`**:
   - W modalu szczegółów lekcji wyświetlać dedykowaną sekcję **„Zapowiedziany sprawdzian / kartkówka”** z pełnym **zakresem materiału od nauczyciela** (`Unit 5, czasowniki modalne`), nauczycielem oraz przyciskiem **`+ Zadanie dla Oskara: Naucz się`**.
4. **`functions/src/librus_client.js`**:
   - Poprawić `_parseTerminarzHtml`, aby przy podziale `text.split(/,|\n/)` wybierał człon niebędący słowem `sprawdzian...`/`kartkówka...`.
