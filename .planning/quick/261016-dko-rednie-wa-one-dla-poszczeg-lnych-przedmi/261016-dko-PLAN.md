---
phase: 261016-dko-rednie-wa-one-dla-poszczeg-lnych-przedmi
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - functions/src/librus_client.js
  - functions/src/sync_service.js
  - functions/index.js
  - functions/test/grades_normalization.test.js
  - lib/data/repositories/firestore/firestore_grades_data_source.dart
  - lib/presentation/screens/grades/grades_screen.dart
  - lib/presentation/screens/grades/average_simulator_modal.dart
  - lib/presentation/screens/grades/grade_details_modal.dart
  - lib/presentation/screens/grades/widgets/subject_ledger_table.dart
  - lib/presentation/screens/grades/widgets/subject_inspector_card.dart
  - lib/presentation/screens/grades/widgets/grade_details_side_sheet.dart
  - lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart
  - lib/presentation/widgets/common/grade_badge_pill.dart
  - lib/core/services/school_ai_context_builder.dart
  - test/data/repositories/firestore_cache_and_attendance_test.dart
  - test/presentation/screens/grades/grades_presentation_test.dart
autonomous: true
requirements:
  - QUICK-261016-DKO
must_haves:
  truths:
    - "Każdy przedmiot wylicza średnią ważoną wyłącznie z ocen w skali MEN 1–6 posiadających 'Licz do średniej: tak' i wagę > 0 (Chemia: 5.00, Język angielski: 3.36, Język polski: 1.80, Matematyka: 1.00, Wychowanie fizyczne: 3.83)"
    - "Przedmioty bez ocen (Biologia, Doradztwo zawodowe, Etyka, Religia, Zajęcia z wychowawcą) oraz przedmioty posiadające wyłącznie wpisy nieklasyfikowane '+' lub '0' (Historia, Język niemiecki) prezentują '—' zamiast fałszywych średnich 4.80 lub 5.00"
    - "Endpoint Cloud Functions getStudentData oraz syncStudentData automatycznie normalizuje i leczy wcześniej zapisane dokumenty w Firestore (usuwając wagi z ocen '0' i '+' oraz przeliczając currentAverage i overallAverage = 3.02)"
    - "Zaktualizowana aplikacja webowa i funkcje Cloud Functions są wdrożone na produkcję (https://lepsza-szkola.web.app)"
  artifacts:
    - path: "functions/src/librus_client.js"
      provides: "parseMenGradeValue i normalizeStudentGradesData dla danych z Librusa i dokumentów Firestore"
    - path: "functions/index.js"
      provides: "Normalizacja i auto-healing dokumentu students/{login} w getStudentData"
    - path: "functions/test/grades_normalization.test.js"
      provides: "Testy jednostkowe normalizacji ocen i średnich przedmiotowych na rzeczywistym zestawie danych Oskara"
    - path: "lib/presentation/screens/grades/widgets/subject_ledger_table.dart"
      provides: "Tabela przedmiotów z chronologicznym sortowaniem ocen i rzeczywistymi średnimi ważonymi"
  key_links:
    - from: "functions/index.js"
      to: "functions/src/librus_client.js"
      via: "normalizeStudentGradesData(data)"
      pattern: "normalizeStudentGradesData"
    - from: "lib/presentation/screens/grades/grades_screen.dart"
      to: "lib/presentation/screens/grades/widgets/subject_inspector_card.dart"
      via: "przekazanie aktywnego term oraz initialSubjectId do symulatora"
      pattern: "SubjectInspectorCard"
---

<objective>
Naprawa wyliczania i prezentacji średnich ważonych dla poszczególnych przedmiotów (zarówno w warstwie backendu/Firestore `getStudentData` i `librus_client.js`, jak i we wszystkich widokach Flutter desktop/mobile) oraz wdrożenie poprawki na produkcję (`functions` + `hosting`).

Purpose: Wcześniej zeskrobowany dokument w Firestore (`students/11010033`) oraz niewdrożona wersja webowa powodowały, że wpisy informacyjne `0` (Chemia, J. niemiecki, J. polski) i `+` (Historia) miały przypisaną wagę `1` (zaniżając średnią z Chemii do `3.75` zamiast `5.00`, z J. polskiego do `1.13`/`1.29` zamiast `1.80`, a dla Historii ustawiając `5.00`), natomiast puste przedmioty wyświetlały na sztywno `4.80` / `5.00`.
Output: Znormalizowany backend Cloud Functions leczący dane z cache Firestore w locie, spójne widoki UI ocen (desktop + mobile + inspektor + symulator GPA) z testami oraz wdrożenie na `https://lepsza-szkola.web.app`.
</objective>

<execution_context>
@~/.gemini/antigravity/gsd-core/workflows/execute-plan.md
@~/.gemini/antigravity/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/config.json
@.planning/quick/261016-cvn-upewnij-si-e-oceny-s-dobrze-prezentowane/261016-cvn-SUMMARY.md
@functions/src/librus_client.js
@functions/src/sync_service.js
@functions/index.js
@lib/data/repositories/firestore/firestore_grades_data_source.dart
@lib/presentation/screens/grades/grades_screen.dart
@lib/presentation/screens/grades/widgets/subject_ledger_table.dart
@lib/presentation/screens/grades/widgets/subject_inspector_card.dart
@lib/presentation/screens/grades/average_simulator_modal.dart
</context>

<tasks>

<task type="tracer">
  <name>Task 1: Normalizacja i auto-healing ocen oraz średnich ważonych w backendzie (librus_client.js, sync_service.js, index.js) i FirestoreGradesDataSource</name>
  <files>
    functions/src/librus_client.js,
    functions/src/sync_service.js,
    functions/index.js,
    functions/test/grades_normalization.test.js,
    lib/data/repositories/firestore/firestore_grades_data_source.dart
  </files>
  <action>
    1. W `functions/src/librus_client.js`:
       - Wyeksportuj funkcję `parseMenGradeValue(rawValue)` rozpoznającą wyłącznie oceny w skali MEN `1..6` z opcjonalnym `+` (`+0.5`) i `-` (`-0.25`) w przedziale `[1.0, 6.0]`, a dla `0`, `+`, `-`, `np`, `bz`, `nb` zwracającą `null`.
       - Wyeksportuj funkcję `normalizeStudentGradesData(studentData)` (mutującą kopię lub obiekt wejściowy i zwracającą `{ data, changed }`), która dla każdego przedmiotu w `studentData.subjects` i każdej oceny w `subject.grades`:
         - Wyznacza `parsedMen = parseMenGradeValue(g.value)`. Jeśli `parsedMen === null`, ustawia `numericalValue = 0`, `isCountedToAverage = false`, `weight = 0`.
         - Dla ocen w skali MEN (`parsedMen !== null`) sprawdza `rawTooltip`:
           - `explicitCountNo = /Licz do średniej:\s*nie/i.test(tooltip)`
           - `explicitCountYes = /Licz do średniej:\s*tak/i.test(tooltip)`
           - `weightMatch = tooltip.match(/Waga:\s*(\d+)/i)`
           - `hasFullLibrusTooltip = /Kategoria:/i.test(tooltip) && /Nauczyciel:/i.test(tooltip)`
           - Jeśli `explicitCountNo` -> `isCountedToAverage = false`, `weight = 0`.
           - W przeciwnym razie jeśli `explicitCountYes` -> `isCountedToAverage = true`, `weight = parsedWeight ?? (g.weight > 0 ? g.weight : 1)`.
           - W przeciwnym razie jeśli `hasFullLibrusTooltip` -> `isCountedToAverage = parsedWeight !== null && parsedWeight > 0`, `weight = isCountedToAverage ? parsedWeight : 0`.
           - W przeciwnym razie -> `isCountedToAverage = g.isCountedToAverage !== false && (parsedWeight ?? g.weight ?? 1) > 0`, `weight = isCountedToAverage ? (parsedWeight ?? g.weight ?? 1) : 0`.
         - Przelicza `subject.currentAverage`: suma `g.numericalValue * g.weight` podzielona przez sumę `g.weight` wyłącznie dla ocen z `g.isCountedToAverage && g.numericalValue >= 1.0 && g.numericalValue <= 6.0 && g.weight > 0`, zaokrąglona do 2 miejsc po przecinku (`parseFloat((weightedSum / weightSum).toFixed(2))`), lub `0` gdy brak ocen liczonych do średniej.
         - Przelicza `studentData.overallAverage` po wszystkich liczonych ocenach ze wszystkich przedmiotów (`parseFloat((totalWeightedSum / totalWeightSum).toFixed(2))` lub `0`).
       - Użyj tej samej logiki w `LibrusClient.fetchGrades()`.
    2. W `functions/index.js` (`exports.getStudentData`) oraz `functions/src/sync_service.js` (`syncStudentData` — w tym dla odczytu z cache dla roli `student` i blokady rate-limit):
       - Przed zwróceniem danych ucznia wywołaj `normalizeStudentGradesData(docData)`.
       - W `exports.getStudentData`, jeśli `changed === true` (czyli w Firestore były stare, zanieczyszczone średnie np. `Chemia: 3.75`, `Język polski: 1.13`, `Historia: 5`, `overallAverage: 2.16`), zapisz znormalizowane `subjects` i `overallAverage` z powrotem do `doc.ref.set({ subjects: data.subjects, overallAverage: data.overallAverage }, { merge: true }).catch(() => {})`, aby dokument w Firestore został natychmiast wyleczony.
    3. W `lib/data/repositories/firestore/firestore_grades_data_source.dart`:
       - Usuń gałąź `else if (grades.isEmpty && avg != null && avg > 0) { computedAvg = avg; }` (linie 215-217), aby przedmiot bez ocen liczonych do średniej nigdy nie dziedziczył nieaktualnej liczby z pola `currentAverage`.
    4. Utwórz `functions/test/grades_normalization.test.js` weryfikujący na dokładnym zrzucie danych Oskara z Firestore (`11010033`), że `normalizeStudentGradesData` wylicza:
       - `Biologia`, `Doradztwo zawodowe`, `Etyka`, `Religia`, `Zajęcia z wychowawcą` -> `currentAverage: 0`
       - `Chemia` (`5 w:3` + `0`) -> `currentAverage: 5`
       - `Historia` (`+`) -> `currentAverage: 0`, `isCountedToAverage: false`, `weight: 0`, `numericalValue: 0`
       - `Język angielski` (`4 w:1`, `3 w:5`, `4- w:3`) -> `currentAverage: 3.36`
       - `Język niemiecki` (`0`) -> `currentAverage: 0`, `isCountedToAverage: false`, `weight: 0`
       - `Język polski` (`5 w:1`, `1 w:4`, trzy razy `0`) -> `currentAverage: 1.8`
       - `Matematyka` (`1 w:5`) -> `currentAverage: 1`
       - `Wychowanie fizyczne` (`3+ w:3`, `4 w:6`) -> `currentAverage: 3.83`
       - `overallAverage` -> `3.02` (`93.75 / 31`).
  </action>
  <verify>
    <automated>node --test functions/test/grades_normalization.test.js</automated>
  </verify>
  <done>Testy `grades_normalization.test.js` przechodzą, a `getStudentData` i `syncStudentData` zwracają oraz zapisują znormalizowane średnie ważone dla wszystkich przedmiotów.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Spójność średnich przedmiotowych, sortowania ocen, inspektora i symulatora w UI Flutter (desktop + mobile) oraz testy</name>
  <files>
    lib/presentation/screens/grades/grades_screen.dart,
    lib/presentation/screens/grades/average_simulator_modal.dart,
    lib/presentation/screens/grades/grade_details_modal.dart,
    lib/presentation/screens/grades/widgets/subject_ledger_table.dart,
    lib/presentation/screens/grades/widgets/subject_inspector_card.dart,
    lib/presentation/screens/grades/widgets/grade_details_side_sheet.dart,
    lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart,
    lib/presentation/widgets/common/grade_badge_pill.dart,
    lib/core/services/school_ai_context_builder.dart,
    test/data/repositories/firestore_cache_and_attendance_test.dart,
    test/presentation/screens/grades/grades_presentation_test.dart
  </files>
  <behavior>
    - Test 1: `SubjectLedgerTable` i mobilny `GradesScreen` dla pełnego zestawu 12 przedmiotów Oskara wyświetlają dokładne średnie przedmiotowe (`Chemia` -> `5.00`, `Język angielski` -> `3.36`, `Język polski` -> `1.80`, `Matematyka` -> `1.00`, `Wychowanie fizyczne` -> `3.83`), `—` dla pozostałych 7 przedmiotów (w tym `Historia` z `+` i `Język niemiecki` z `0`), oraz `3.02` jako średnią ogólną w nagłówku KPI i stopce tabeli.
    - Test 2: `SubjectInspectorCard` przyjmuje wybrany `term` i po wybraniu przedmiotu (np. `Język polski` lub `Historia`) pokazuje właściwą średnią ważoną (`1.80` / `—`), chronologicznie posortowane oceny z tego okresu oraz otwiera `AverageSimulatorModal` z domyślnie zaznaczonym wybranym przedmiotem i obsługą wag `1..6`.
  </behavior>
  <action>
    1. W `lib/presentation/screens/grades/widgets/subject_ledger_table.dart`:
       - W `_buildTableRow` posortuj `gradesList` chronologicznie po `date` (`final gradesList = (term == 3 ? [...s.grades] : s.grades.where((g) => g.term == term).toList())..sort((a, b) => a.date.compareTo(b.date));`), aby pigułki ocen w wierszu każdego przedmiotu były ułożone od najstarszej do najnowszej, a `lastGrade` wskazywało najnowszą ocenę.
    2. W `lib/presentation/screens/grades/widgets/subject_inspector_card.dart`:
       - Dodaj pole `final int term;` (domyślnie `1`) do `SubjectInspectorCard`.
       - W `_buildPopulatedState` użyj `s.calculateWeightedAverage(term)` zamiast zahardkodowanego `1` oraz przefiltruj i posortuj `gradesList` wg `term` i `date`.
       - W `_buildGradeItem` zabezpiecz `DateFormat('d MMM', 'pl').format(grade.date)` blokiem `try/catch` z fallbackiem `dd.MM`.
    3. W `lib/presentation/screens/grades/grades_screen.dart`:
       - Przekaż `term: term` do `SubjectInspectorCard`, a w `onSimulateGpa` przekaż `initialSubjectId: selectedSubject?.id` oraz `term: term` do `AverageSimulatorModal.show`.
       - W widoku mobilnym (`_buildSubjectCard`) przefiltruj i posortuj oceny przedmiotu wg `_selectedTerm` (`termGrades`), wyświetlij `'Brak ocen'` gdy lista jest pusta, użyj `termGrades.length` w nagłówku szczegółowego wykazu oraz przekaż `initialSubjectId: subject.id` i `term: _selectedTerm` do `AverageSimulatorModal.show`.
    4. W `lib/presentation/screens/grades/average_simulator_modal.dart`:
       - Dodaj opcjonalne parametry `{String? initialSubjectId, int term = 1}` do `AverageSimulatorModal` i `AverageSimulatorModal.show`.
       - W `initState` ustaw `_selectedSubjectId` na `initialSubjectId` (jeśli istnieje na liście `widget.subjects`), a w przeciwnym razie na pierwszy przedmiot posiadający oceny liczone do średniej (lub `widget.subjects.first.id`).
       - Uwzględnij `widget.term` przy liczeniu `curSubAvg`, `_calculateSimulatedSubjectAverage` i `_calculateSimulatedOverallAverage`.
       - Rozszerz wybór wag z `[1, 2, 3, 4]` do `[1, 2, 3, 4, 5, 6]` wewnątrz `Wrap(spacing: 8, runSpacing: 8, ...)`, aby wspierać rzeczywiste wagi z Librusa (`w:5`, `w:6`).
    5. W `lib/presentation/screens/grades/grade_details_modal.dart`, `lib/presentation/screens/grades/widgets/grade_details_side_sheet.dart`, `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart`, `lib/presentation/widgets/common/grade_badge_pill.dart` i `lib/core/services/school_ai_context_builder.dart`:
       - Zabezpiecz `DateFormat(..., 'pl')` przed brakiem inicjalizacji locale w testach.
       - Dla wpisów nieliczonych do średniej (`!grade.isCountedToAverage || grade.weight <= 0`) wyświetlaj `'Nieliczona'` zamiast `'waga 0'` w `DashboardMobileView`, `GradeDetailsModal` i `SchoolAiContextBuilder`.
       - W `GradeBadgePill.resolveGradeColors` obsłuż `rawValue.trim() == '+'` kolorem `(AppColors.secondaryContainer, AppColors.onSecondaryContainer)`.
    6. Zaktualizuj `test/presentation/screens/grades/grades_presentation_test.dart` oraz `test/data/repositories/firestore_cache_and_attendance_test.dart`, aby pokryć wszystkie 12 przedmiotów i rzeczywiste wagi ocen Oskara z Librusa (`w:1`, `w:3`, `w:4`, `w:5`, `w:6`) oraz zachowanie `SubjectInspectorCard` i `AverageSimulatorModal`.
  </action>
  <verify>
    <automated>flutter test test/data/repositories/firestore_cache_and_attendance_test.dart test/presentation/screens/grades/grades_presentation_test.dart</automated>
  </verify>
  <done>Wszystkie testy jednostkowe i widgetowe przechodzą, a widoki desktop i mobile prezentują identyczne, poprawne średnie ważone dla każdego przedmiotu.</done>
</task>

<task type="auto">
  <name>Task 3: Walidacja, budowa wersji webowej i wdrożenie Cloud Functions oraz Firebase Hosting na produkcję</name>
  <files>
    functions/src/librus_client.js,
    functions/src/sync_service.js,
    functions/index.js
  </files>
  <action>
    1. Uruchom pełną analizę statyczną `flutter analyze` oraz testy backendu `npm --prefix functions test`.
    2. Zbuduj produkcyjną aplikację webową poleceniem `flutter build web --release` (zgodnie z `.planning/config.json` -> `deploy.verify_before_deploy`).
    3. Wdróż zaktualizowane funkcje Cloud Functions oraz Firebase Hosting poleceniem:
       `firebase deploy --only functions:getStudentData,functions:syncNow,functions:scheduledLibrusSync,hosting`
    4. Zweryfikuj na żywo endpoint produkcyjny `https://europe-west3-lepsza-szkola.cloudfunctions.net/getStudentData?login=11010033`, potwierdzając, że zwraca wyleczone średnie ważone:
       - `Chemia`: `5`
       - `Język angielski`: `3.36`
       - `Język polski`: `1.8`
       - `Matematyka`: `1`
       - `Wychowanie fizyczne`: `3.83`
       - `Historia`, `Język niemiecki`, `Biologia`, `Doradztwo zawodowe`, `Etyka`, `Religia`, `Zajęcia z wychowawcą`: `0`
       - `overallAverage`: `3.02`
  </action>
  <verify>
    <automated>flutter analyze && npm --prefix functions test && curl -s "https://europe-west3-lepsza-szkola.cloudfunctions.net/getStudentData?login=11010033" | node -e 'const assert = require("assert"); const d = JSON.parse(require("fs").readFileSync(0, "utf8")); const byName = Object.fromEntries((d.subjects || []).map(s => [s.name, s])); assert.strictEqual(byName["Chemia"].currentAverage, 5); assert.strictEqual(byName["Język angielski"].currentAverage, 3.36); assert.strictEqual(byName["Język polski"].currentAverage, 1.8); assert.strictEqual(byName["Matematyka"].currentAverage, 1); assert.strictEqual(byName["Wychowanie fizyczne"].currentAverage, 3.83); assert.strictEqual(byName["Historia"].currentAverage, 0); assert.strictEqual(byName["Język niemiecki"].currentAverage, 0); assert.strictEqual(d.overallAverage, 3.02); console.log("LIVE VERIFIED OK");'</automated>
  </verify>
  <done>Funkcje Cloud Functions i aplikacja webowa na `https://lepsza-szkola.web.app` są wdrożone, a produkcyjny endpoint zwraca wyleczone średnie przedmiotowe i ogólną średnią ważoną `3.02`.</done>
</task>

</tasks>

<verification>
- `node --test functions/test/grades_normalization.test.js`
- `flutter test test/data/repositories/firestore_cache_and_attendance_test.dart test/presentation/screens/grades/grades_presentation_test.dart`
- `flutter analyze`
- Weryfikacja live `getStudentData?login=11010033` po wdrożeniu Firebase Functions i Hosting
</verification>

<success_criteria>
- Wszystkie przedmioty z ocenami cząstkowymi w skali MEN 1–6 pokazują średnią ważoną zgodną z wagami ocen z Librusa (`Chemia`: `5.00`, `Język angielski`: `3.36`, `Język polski`: `1.80`, `Matematyka`: `1.00`, `Wychowanie fizyczne`: `3.83`, `Średnia ogólna`: `3.02`).
- Wpisy `0` oraz `+` mają `isCountedToAverage: false` i `weight: 0` zarówno w nowym scrapingu, jak i w danych serwowanych z cache Firestore przez `getStudentData`.
- Przedmioty bez ocen liczonych do średniej wyświetlają `—` zamiast `4.80` lub `5.00`.
- Zmiany są zbudowane i wdrożone na `https://lepsza-szkola.web.app` oraz Cloud Functions.
</success_criteria>

<output>
After completion, create `.planning/quick/261016-dko-rednie-wa-one-dla-poszczeg-lnych-przedmi/261016-dko-SUMMARY.md`
</output>
