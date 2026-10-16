---
phase: 261016-cvn-upewnij-si-e-oceny-s-dobrze-prezentowane
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/domain/models/grade.dart
  - lib/domain/models/subject.dart
  - lib/data/repositories/firestore/firestore_grades_data_source.dart
  - lib/data/repositories/firestore/firestore_schedule_data_source.dart
  - lib/presentation/providers/school_providers.dart
  - lib/presentation/screens/grades/grades_screen.dart
  - lib/presentation/screens/grades/average_simulator_modal.dart
  - lib/presentation/screens/grades/widgets/subject_ledger_table.dart
  - lib/presentation/screens/grades/widgets/grade_distribution_card.dart
  - lib/presentation/screens/grades/widgets/weighted_average_kpi_card.dart
  - lib/presentation/screens/grades/widgets/subject_inspector_card.dart
  - lib/presentation/screens/grades/widgets/grade_details_side_sheet.dart
  - lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart
  - functions/src/librus_client.js
  - test/data/repositories/firestore_cache_and_attendance_test.dart
  - test/presentation/screens/grades/grades_presentation_test.dart
autonomous: true
requirements:
  - QUICK-261016-CVN
estimate:
  tokens: 35000
  raw_tokens: 25000
  tasks: 3
  confidence: high
must_haves:
  truths:
    - "Wpisy niebędące ocenami w skali MEN 1–6 (np. '0', '+', '-', 'np', 'bz') oraz oceny z 'Licz do średniej: nie' mają isCountedToAverage=false, numericValue=0.0 i nie zaniżają ani nie zawyżają średniej przedmiotu ani średniej ogólnej"
    - "Rozkład ocen cząstkowych (1–6) zlicza wyłącznie oceny w skali MEN 1–6 wg ich stopnia bazowego (np. '3+' trafia do słupka 3, a '0' oraz '+' nie trafiają do słupka 1 ani 5)"
    - "Liczba jedynek/zagrożeń w karcie rozkładu ocen dokładnie odpowiada liczbie ocen 1 w tabeli poniżej, a nie sumie jedynek i zer"
    - "Przedmioty bez ocen liczonych (np. Biologia, Religia lub przedmioty mające wyłącznie '0' lub '+') wyświetlają '—' w kolumnach ŚR. WAŻ. oraz PRZEW. zamiast zmyślonych wartości 4.80, 5.00 i 3"
    - "Średnia ogólna w stopce tabeli przedmiotów zawsze zgadza się ze średnią ważoną w górnej karcie KPI (usunięty zahardkodowany tekst '4.82')"
    - "Kolumna OSTATNI WPIS w tabeli pokazuje faktyczną datę najnowszego wpisu z przedmiotu, a szuflada szczegółów oceny wylicza prawdziwy wpływ oceny na średnią"
  artifacts:
    - path: "lib/domain/models/grade.dart"
      provides: "Parsowanie wartości ocen MEN 1–6, flaga isMenScaleGrade oraz menScaleBucket (1..6)"
    - path: "lib/data/repositories/firestore/firestore_grades_data_source.dart"
      provides: "Normalizacja ocen z Librusa (obsługa '0', '+', '-', 'Licz do średniej') i wyliczanie średniej przedmiotowej bez fallbacku 5.0"
    - path: "lib/presentation/providers/school_providers.dart"
      provides: "Spójne statystyki rozkładu ocen 1–6, średniej ważonej i wpisów nieklasyfikowanych w gradesDistributionStatsProvider"
    - path: "lib/presentation/screens/grades/widgets/subject_ledger_table.dart"
      provides: "Dynamiczna średnia ogólna w stopce, '—' dla przedmiotów bez ocen liczonych, poprawne przewidywane oceny 1–6 i najnowsza data wpisu"
    - path: "test/presentation/screens/grades/grades_presentation_test.dart"
      provides: "Testy jednostkowe i widgetowe weryfikujące spójność ocen, rozkładu i średnich na rzeczywistym zestawie danych ucznia"
  key_links:
    - from: "lib/data/repositories/firestore/firestore_grades_data_source.dart"
      to: "lib/presentation/providers/school_providers.dart"
      via: "subjectsProvider -> gradesDistributionStatsProvider"
      pattern: "gradesDistributionStatsProvider"
    - from: "lib/presentation/providers/school_providers.dart"
      to: "lib/presentation/screens/grades/widgets/subject_ledger_table.dart"
      via: "ref.watch(gradesDistributionStatsProvider).overallAverage"
      pattern: "gradesDistributionStatsProvider"
---

<objective>
Naprawa parsowania, kalkulacji i prezentacji ocen cząstkowych, średnich ważonych oraz rozkładu ocen 1–6 w całym module ocen i na pulpicie.

Purpose: W danych z Librusa wpisy informacyjne takie jak `0` (brak zaliczenia/nieobecność na kartkówce) oraz `+` (aktywność/zadanie) nie posiadają wagi ani flagi `Licz do średniej: tak`. Dotychczas były traktowane jako oceny liczone do średniej z wagą `1` (`0` zaniżało średnią Chemii do `3.75`, Języka polskiego do `1.29` i ogólną do `2.74`, a w rozkładzie 1–6 przez `.clamp(1, 6)` wpadało do słupka `1`, generując fałszywe `6 ocen 1` / `6 zagrożeń`; z kolei `+` z Historii otrzymywało fallback `5.0`, a `3+` z WF przez `.round()` trafiało do słupka `4` zamiast `3`). Ponadto przedmioty bez ocen liczonych pokazywały zahardkodowane `4.80` / `5.00` i przewidywaną ocenę `3`, a stopka tabeli miała zahardkodowany tekst `'4.82'`.
Output: Spójny model ocen MEN 1–6 vs wpisów nieklasyfikowanych (`0`, `+`, `-`, `np`, `bz`), poprawne wyliczanie średnich przedmiotowych i ogólnej, dokładny rozkład 1–6, brak zahardkodowanych wartości (`4.82`, `4.80`, `5.00`, `+0.06 pkt`) oraz testy regresyjne.
</objective>

<execution_context>
@~/.gemini/antigravity/gsd-core/workflows/execute-plan.md
@~/.gemini/antigravity/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@lib/domain/models/grade.dart
@lib/domain/models/subject.dart
@lib/data/repositories/firestore/firestore_grades_data_source.dart
@lib/data/repositories/firestore/firestore_schedule_data_source.dart
@lib/presentation/providers/school_providers.dart
@lib/presentation/screens/grades/grades_screen.dart
@lib/presentation/screens/grades/widgets/subject_ledger_table.dart
@lib/presentation/screens/grades/widgets/grade_distribution_card.dart
@lib/presentation/screens/grades/widgets/weighted_average_kpi_card.dart
@lib/presentation/screens/grades/widgets/subject_inspector_card.dart
@lib/presentation/screens/grades/widgets/grade_details_side_sheet.dart
@lib/presentation/screens/grades/average_simulator_modal.dart
@functions/src/librus_client.js
</context>

<tasks>

<task type="tracer">
  <name>Task 1: End-to-end normalizacja ocen MEN 1–6 i wpisów nieklasyfikowanych (0, +, -, np, bz) w modelu, źródłach danych, providerze i scraperze Librus</name>
  <files>
    lib/domain/models/grade.dart,
    lib/domain/models/subject.dart,
    lib/data/repositories/firestore/firestore_grades_data_source.dart,
    lib/data/repositories/firestore/firestore_schedule_data_source.dart,
    lib/presentation/providers/school_providers.dart,
    functions/src/librus_client.js
  </files>
  <action>
    1. W `lib/domain/models/grade.dart`:
       - Dodaj statyczny parser `Grade.tryParseMenValue(String rawValue)` zwracający `double?` dla ocen w skali MEN 1–6:
         - Dopasuj oczyszczony `rawValue.trim()` do wzorca `^([1-6])([+-])?$|^([+-])([1-6])$`. Jeśli pasuje, oblicz wartość bazową `1..6` oraz modyfikator (`+` dodaje `0.5`, `-` odejmuje `0.25`, np. `3+` -> `3.5`, `4-` -> `3.75`).
         - Jeśli nie pasuje, sprawdź `double.tryParse(rawValue.trim())` — zwróć wartość tylko wtedy, gdy mieści się w przedziale `[1.0, 6.0]`. Dla `'0'`, `'+'`, `'-'`, `'np'`, `'bz'`, `'nb'`, `'zw'`, `'nk'` zwróć `null`.
       - Dodaj gettery w `Grade`:
         - `bool get isMenScaleGrade => numericValue >= 1.0 && numericValue <= 6.0;`
         - `int? get menScaleBucket`: jeśli `!isMenScaleGrade`, zwróć `null`. W przeciwnym razie wyciągnij cyfrę wiodącą `1..6` z `rawValue` (`RegExp(r'[1-6]').firstMatch(rawValue)`), aby `3+` (`3.5`) zawsze trafiało do koszyka `3`, a `4-` (`3.75`) do koszyka `4`. Jako fallback (gdy `rawValue` nie zawiera cyfry `1..6`) użyj `numericValue.floor().clamp(1, 6)`.

    2. W `lib/domain/models/subject.dart`:
       - Zaktualizuj `calculateWeightedAverage(int term)`:
         - Dla `term == 3` (Klasyfikacja Roczna) bierz wszystkie oceny przedmiotu, a dla `term == 1` lub `2` filtruj po `g.term == term`.
         - Uwzględniaj wyłącznie oceny spełniające `g.isCountedToAverage && g.isMenScaleGrade && g.weight > 0`.
         - Zwróć `0.0`, gdy brak takich ocen lub suma wag wynosi `0`.
       - Dodaj pomocniczą metodę `int? predictedGradeForTerm(int term)` wyliczającą przewidywaną ocenę w pełnej skali 1–6 (`>=5.50` -> 6, `>=4.75` -> 5, `>=3.75` -> 4, `>=2.75` -> 3, `>=1.75` -> 2, `<1.75` -> 1) lub zwracającą `predictedGrade`, a gdy przedmiot nie ma żadnej średniej liczonej (`avg <= 0` i `predictedGrade == null`) zwracającą `null`.

    3. W `lib/data/repositories/firestore/firestore_grades_data_source.dart`:
       - Podczas mapowania każdej oceny w `getSubjects()`:
         - Wyznacz `parsedMen = Grade.tryParseMenValue(val)`. Jeśli `parsedMen != null`, użyj `parsedMen` jako `numVal`. Jeśli `parsedMen == null`, sprawdź czy `val.trim()` to `'0'` lub symbol nieklasyfikowany (`+`, `-`, `np`, `bz` itp.) — w takim przypadku `numVal = 0.0` (nigdy nie podstawiaj fallbacku `5.0` dla `+` ani dla innych znaków).
         - Wyznacz `isCountedToAverage`:
           - Jeśli `numVal < 1.0 || numVal > 6.0`, ustaw `false`.
           - W przeciwnym razie, jeśli `g['isCountedToAverage'] is bool`, użyj tej wartości (chyba że `tooltip` jawnie zawiera `Licz do średniej: nie`).
           - W przeciwnym razie sprawdź `tooltip`: jeśli pasuje `Licz do średniej:\s*nie` -> `false`; jeśli pasuje `Licz do średniej:\s*tak` -> `true`; jeśli `tooltip` ma pełny format Librusa (`Kategoria:` i `Nauczyciel:`), ale nie ma `Licz do średniej: tak` -> `false`; w pozostałych przypadkach (np. krótkie fikstury testowe) -> `true`.
         - Wyznacz `weight`:
           - Sprawdź `RegExp(r'Waga:\s*(\d+)', caseSensitive: false).firstMatch(tooltip)`.
           - Jeśli `!isCountedToAverage` lub `numVal < 1.0`, użyj wagi z `tooltip` tylko jeśli jawnie wystąpiła, w przeciwnym razie `weight = 0` (eliminuje fałszywe `w:1` przy `0` i `+` z Librusa).
           - Dla ocen liczonych użyj wagi z `tooltip` lub `(g['weight'] as num?)?.toInt() ?? 1`; jeśli `weight <= 0`, ustaw `isCountedToAverage = false`.
         - Estymację `pct` wykonuj wyłącznie dla `numVal >= 1.0`.
       - Przy tworzeniu `Subject`:
         - Oblicz średnią ważoną bezpośrednio z przefiltrowanych ocen liczonych przedmiotu (`countedGrades`).
         - Ustaw `weightedAverageSem1` na wyliczoną średnią z `countedGrades` (lub gdy `grades.isEmpty` i `avg != null && avg > 0`, użyj `avg`; nigdy nie używaj fallbacku `grades.isNotEmpty ? 5.0 : null`, który dla przedmiotu z samym `0` lub `+` ustawiał średnią `5.00`).

    4. W `lib/data/repositories/firestore/firestore_schedule_data_source.dart`:
       - W `getStudentProfile()`: jeśli `data['subjects']` jest niepustą listą, wylicz `overallAverage` ze znormalizowanych przedmiotów z `gradesDataSource.getSubjects()` (ważona średnia wszystkich ocen liczonych), a tylko gdy brak ocen liczonych (np. w testach bez `subjects`), użyj `(data['overallAverage'] as num?)?.toDouble() ?? 0.0`.

    5. W `lib/presentation/providers/school_providers.dart` (`GradesDistributionStats` i `gradesDistributionStatsProvider`):
       - Dodaj pole `final int otherGradesCount;` (domyślnie `0`) w `GradesDistributionStats`.
       - W `gradesDistributionStatsProvider`:
         - Dla każdej oceny użyj `final bucket = g.menScaleBucket;`.
         - Jeśli `bucket != null`: zwiększ `counts[bucket]` oraz `total` (dzięki czemu `totalGrades` i słupki 1–6 zliczają wyłącznie oceny w skali 1–6, `0` nie wpada do słupka `1`, a `3+` trafia do słupka `3`).
         - Jeśli `bucket == null`: zwiększ `otherGradesCount`.
         - `subjectsWithGrades` zwiększaj dla przedmiotów posiadających co najmniej jedną ocenę w skali MEN 1–6 (lub liczoną do średniej) w wybranym okresie.
         - Do `weightedSum`, `totalWeight` i `indexedCountedGrades` dodawaj wyłącznie oceny spełniające `g.isCountedToAverage && g.isMenScaleGrade && g.weight > 0`.

    6. W `functions/src/librus_client.js` (`fetchGrades`):
       - Zaktualizuj parsowanie w backendzie tak, by rozpoznawało wyłącznie oceny `1..6` (z opcjonalnym `+`/`-`), sprawdzało `Licz do średniej:\s*(tak|nie)` w `tooltip`, dla `0`, `+`, `-`, `np`, `bz` zapisywało `numericalValue: 0`, `weight: 0`, `isCountedToAverage: false`, a `subjAvg` oraz `overallAverage` liczyło jako średnią ważoną wyłącznie z ocen liczonych.
  </action>
  <verify>
    <automated>flutter test test/data/repositories/firestore_cache_and_attendance_test.dart test/data/repositories/firestore_messages_and_schedule_test.dart</automated>
  </verify>
  <done>
    Model `Grade`, `Subject`, `FirestoreGradesDataSource`, `gradesDistributionStatsProvider` oraz `librus_client.js` poprawnie odróżniają oceny MEN 1–6 od wpisów `0`/`+`/`-`/`np`/`bz`, nie przypisują im fałszywej średniej `5.00` ani wagi `1`, nie wrzucają `0` do słupka `1` rozkładu ocen i prawidłowo klasyfikują `3+` do słupka `3`.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Spójna prezentacja ocen, średnich, przewidywanych ocen i szczegółów w widokach GradesScreen, SubjectLedgerTable, kartach KPI, inspektorze i szufladzie szczegółów</name>
  <files>
    lib/presentation/screens/grades/widgets/subject_ledger_table.dart,
    lib/presentation/screens/grades/widgets/grade_distribution_card.dart,
    lib/presentation/screens/grades/widgets/weighted_average_kpi_card.dart,
    lib/presentation/screens/grades/widgets/subject_inspector_card.dart,
    lib/presentation/screens/grades/widgets/grade_details_side_sheet.dart,
    lib/presentation/screens/grades/grades_screen.dart,
    lib/presentation/screens/grades/average_simulator_modal.dart,
    lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart
  </files>
  <behavior>
    - Test 1: Stopka `SubjectLedgerTable` wyświetla dynamiczną średnią ogólną z `gradesDistributionStatsProvider` (np. `3.02` lub `—`), a nie zahardkodowane `4.82`.
    - Test 2: Wiersze przedmiotów bez ocen liczonych (brak ocen lub wyłącznie wpis `0` / `+`) pokazują `—` w kolumnie `ŚR. WAŻ.` oraz `—` w kolumnie `PRZEW.` zamiast `4.80`, `5.00` i `3`.
    - Test 3: Pigułki wpisów nieklasyfikowanych (`0`, `+`) nie wyświetlają sufiksu `w:1` / `(w:1)`, a kolumna `OSTATNI WPIS` pokazuje datę najnowszego wpisu przedmiotu.
    - Test 4: `GradeDistributionCard` stosuje poprawną polską odmianę (`1 zagrożenie`, `2 zagrożenia`, `5 zagrożeń`) i informuje o ewentualnych wpisach poza skalą 1–6 (`otherGradesCount`).
  </behavior>
  <action>
    1. W `lib/presentation/screens/grades/widgets/subject_ledger_table.dart`:
       - W `build()` odczytaj `final stats = ref.watch(gradesDistributionStatsProvider);` i w stopce tabeli zastąp zahardkodowane `'4.82'` dynamiczną wartością `stats.overallAverage > 0 ? stats.overallAverage.toStringAsFixed(2) : '—'`.
       - W `_buildTableRow`:
         - Oblicz `final avg = s.calculateWeightedAverage(term);`. Jeśli `avg <= 0`, wyświetl `avgStr = '—'` w neutralnym kolorze `AppColors.outline` (usuń fallback `s.weightedAverageSem1?.toStringAsFixed(2) ?? '4.80'`).
         - Dla kolumny `PRZEW.` użyj `s.predictedGradeForTerm(term)`: gdy zwraca `null`, wyświetl `'—'` na neutralnym tle `AppColors.surfaceContainerLow` z tekstem `AppColors.outline`; gdy zwraca ocenę `1..6`, dobierz semantyczne kolory tła i tekstu (5–6 zielony, 4 niebieski, 3 bursztynowy, 1–2 czerwony).
         - Dla kolumny `OSTATNI WPIS`: wyznacz najnowszy wpis z `gradesList` po dacie (`gradesList.reduce((a, b) => b.date.isBefore(a.date) ? a : b)` zamiast `gradesList.first`, które zwracało najstarszą ocenę).
       - W `_buildGradePill`:
         - Dla wpisów poza skalą MEN (`!grade.isMenScaleGrade`, np. `0`, `+`, `-`, `np`, `bz`): użyj czytelnego stylu informacyjnego (dla `+` jasna zieleń `0xFFDCFCE7` / `0xFF15803D`, dla `0` i pozostałych neutralny `AppColors.surfaceContainerHigh` / `AppColors.onSurfaceVariant`).
         - Dla ocen `1` i `2` o dowolnej wadze użyj wyraźnej kolorystyki ostrzegawczej/błędu, aby jedynki z wagą 1 lub 4 były spójnie oznaczone.
         - Wyświetlaj etykietę `'w:${grade.weight}'` wyłącznie wtedy, gdy `grade.isCountedToAverage && grade.weight > 0`.

    2. W `lib/presentation/screens/grades/widgets/grade_distribution_card.dart`:
       - Dodaj funkcję polskiej odmiany dla liczby jedynek/zagrożeń (`1 zagrożenie`, `2–4 zagrożenia`, `5+ zagrożeń`).
       - Jeśli `stats.otherGradesCount > 0`, obok podpisu `'ocen w skali 1–6'` (lub `'ocen wpisanych w semestrze'`) wyświetl zwięzłą informację pomocniczą `'(+${stats.otherGradesCount} wpisów: 0/+)'`, aby suma słupków 1–6 oraz liczba dodatkowych znaków były całkowicie przejrzyste.

    3. W `lib/presentation/screens/grades/widgets/weighted_average_kpi_card.dart`:
       - W stopce karty (`Ostatnia ocena: ...`): wyświetlaj wagę tylko wtedy, gdy `lastGrade.isCountedToAverage && lastGrade.weight > 0`, a ikonę ostrzeżenia pokazuj tylko dla ocen w skali MEN `< 2.0` (`lastGrade.isMenScaleGrade && lastGrade.numericValue < 2.0`).

    4. W `lib/presentation/screens/grades/widgets/subject_inspector_card.dart`:
       - Zastąp fallback `'4.80'` wartością `'—'`, gdy `avg <= 0`.
       - W sekcji `'Podpowiedź EduSync AI'` wylicz rzeczywistą symulowaną średnią przedmiotu po otrzymaniu oceny `5` z wagą `3` (zamiast sztywnego `avg + 0.12` i obietnicy „oceny celującej" przy średniej `1.80`), dopasowując opis słowny do wynikowego progu.
       - W `_buildGradeItem` dla ocen nieliczonych (`!grade.isCountedToAverage || grade.weight <= 0`) wyświetl `'Nieliczona do średniej • Data: $dateStr'` zamiast `'Waga: ${grade.weight} • Data: $dateStr'`.

    5. W `lib/presentation/screens/grades/widgets/grade_details_side_sheet.dart`:
       - Zastąp zahardkodowane wartości w sekcji `'WPŁYW NA ŚREDNIĄ'` (`+0.06 pkt`, `Przed: 4.86`, `Teraz: 4.92`, `Pozycja w top 5% rocznika`) rzeczywistym wyliczeniem średniej przedmiotu przed i po tej ocenie; jeśli `!grade.isCountedToAverage`, wyświetl czytelny komunikat `'Wpis nie jest wliczany do średniej ważonej'`.
       - W `'KARTA EWIDENCYJNA OCENY'`:
         - Dla wpisów poza skalą MEN opis słowny ustaw na `'Wpis informacyjny'` / `'Aktywność (+)'` / `'Brak zaliczenia (0)'`, a procent pokazuj wyłącznie gdy `grade.percentage != null` (usuń fallback `?? 100`).
         - W wierszu `'Waga oceny'` pokazuj `'— (Nieliczona)'` gdy `!grade.isCountedToAverage || grade.weight <= 0`.
         - W wierszu `'Licz do średniej'` pokazuj `'TAK (Wliczana)'` (zielony badge) lub `'NIE (Nieliczona)'` (neutralny badge) zgodnie z `grade.isCountedToAverage`.
       - Zastąp sztuczny domyślny komentarz `'Świetna wypowiedź, bezbłędna terminologia naukowa...'` neutralnym `'Brak dodatkowego komentarza nauczyciela.'`.

    6. W `lib/presentation/screens/grades/grades_screen.dart`, `lib/presentation/screens/grades/average_simulator_modal.dart` oraz `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart`:
       - W `GradesScreen` (widok mobilny): używaj `subject.calculateWeightedAverage(_selectedTerm)` i wyświetlaj `'—'` zamiast `'0.00'` dla przedmiotów bez ocen liczonych; ukryj `(w:...)` dla wpisów nieliczonych; przekaż `overallAvg` do `AverageSimulatorModal` zamiast fallbacku `4.82`.
       - W `AverageSimulatorModal`: wyliczaj symulowaną średnią ogólną jako średnią ważoną wszystkich ocen liczonych ze wszystkich przedmiotów powiększoną o symulowaną ocenę (zamiast dodawania sztucznego `4.5` dla przedmiotów bez ocen), a dla przedmiotu bez ocen pokazuj `'—'` zamiast `4.00`.
       - W `DashboardMetricsColumn`: dla ocen nieliczonych wyświetlaj `${grade.categoryName} • nieliczona` zamiast `waga ${grade.weight}`.
  </action>
  <verify>
    <automated>flutter analyze lib/domain/models/grade.dart lib/domain/models/subject.dart lib/data/repositories/firestore/firestore_grades_data_source.dart lib/presentation/providers/school_providers.dart lib/presentation/screens/grades/</automated>
  </verify>
  <done>
    Wszystkie widoki ocen (karty KPI, rozkład 1–6, tabela przedmiotów i jej stopka, prawy panel inspektora, szuflada szczegółów, symulator GPA oraz widok mobilny) prezentują spójne, wyliczone z rzeczywistych danych wartości bez żadnych zahardkodowanych liczb `4.82`, `4.80`, `5.00`, `3` ani `+0.06`.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Testy jednostkowe i widgetowe dla rzeczywistego zestawu ocen ucznia (0, +, 3+, 4-, puste przedmioty)</name>
  <files>
    test/data/repositories/firestore_cache_and_attendance_test.dart,
    test/presentation/screens/grades/grades_presentation_test.dart
  </files>
  <behavior>
    - Test 1 (`firestore_cache_and_attendance_test.dart`): `FirestoreGradesDataSource` parsuje rzeczywiste dane z wpisami `'0'`, `'+'`, `'3+'`, `'4-'`, `'1'`, `'5'` oraz pustymi przedmiotami — wpisy `'0'` i `'+'` mają `isCountedToAverage == false`, `numericValue == 0.0`, `weight == 0`, średnia Chemii (`5 w:3` i `0`) wynosi `5.00`, Języka polskiego (`5 w:1`, `1 w:4` i trzy `0`) wynosi `1.80`, a Historii (`+`) i Języka niemieckiego (`0`) mają `weightedAverageSem1 == null` i `calculateWeightedAverage(1) == 0.0`.
    - Test 2 (`grades_presentation_test.dart`): `gradesDistributionStatsProvider` dla tego zestawu wylicza `overallAverage` = `3.02` (`93.75 / 31`), `counts` = `{1: 2, 2: 0, 3: 2, 4: 3, 5: 2, 6: 0}`, `totalGrades` = `9`, `otherGradesCount` = `6`.
    - Test 3 (`grades_presentation_test.dart`): Widget `GradesScreen` (desktop 1440x900) wyświetla identyczną średnią ważoną `3.02` w górnej karcie `WeightedAverageKpiCard` oraz w stopce `SubjectLedgerTable` (`Średnia ogólna: 3.02`), `2 zagrożenia` w `GradeDistributionCard`, `—` dla przedmiotów bez ocen liczonych (Biologia, Historia, Język niemiecki) i brak jakiegokolwiek tekstu `4.82` lub `4.80`.
  </behavior>
  <action>
    1. Rozbuduj `test/data/repositories/firestore_cache_and_attendance_test.dart` o test w grupie `FirestoreGradesDataSource` sprawdzający pełną normalizację wpisów `'0'`, `'+'`, `'3+'`, `'4-'` z rzeczywistymi tooltipami Librusa.
    2. Utwórz `test/presentation/screens/grades/grades_presentation_test.dart` testujący:
       - `Grade.tryParseMenValue` i `Grade.menScaleBucket` dla pełnego zakresu ocen (`1`, `1+`, `2-`, `3+`, `4-`, `5`, `6`, `0`, `+`, `-`, `np`, `bz`),
       - `gradesDistributionStatsProvider` na zestawie danych odpowiadającym zrzutowi ekranu użytkownika,
       - renderowanie `GradesScreen` na szerokości desktopowej (`1440x900`) potwierdzające zgodność średniej na górze i na dole (`3.02`), poprawny rozkład słupków (`1` -> 2, `3` -> 2, `4` -> 3, `5` -> 2), brak `4.82` i `4.80` oraz poprawne wyświetlanie `—` dla przedmiotów bez ocen liczonych.
  </action>
  <verify>
    <automated>flutter test test/data/repositories/firestore_cache_and_attendance_test.dart test/presentation/screens/grades/grades_presentation_test.dart</automated>
  </verify>
  <done>
    Wszystkie testy jednostkowe i widgetowe przechodzą na zielono, potwierdzając wyeliminowanie wszystkich rozbieżności ze zrzutu ekranu.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Librus HTML/JSON -> FirestoreGradesDataSource | Zewnętrzne ciągi tekstowe ocen (`value`, `rawTooltip`) z Librus Synergia mogą zawierać znaki nienumeryczne (`+`, `-`, `0`, `np`, `bz`) lub niepełne metadane |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-261016-01 | Tampering / Data Integrity | `FirestoreGradesDataSource` & `Grade.tryParseMenValue` | medium | mitigate | Ścisła walidacja regexem skali MEN 1–6 (`^([1-6])([+-])?$`) i odrzucanie wartości spoza przedziału `[1.0, 6.0]` przed wliczeniem do średniej ważonej lub histogramu |
| T-261016-SC | Tampering | npm/pip/cargo/pub installs | low | accept | Brak nowych zależności zewnętrznych w zadaniu |
</threat_model>

<verification>
- `flutter analyze` bez błędów w zmodyfikowanych plikach
- `flutter test test/data/repositories/firestore_cache_and_attendance_test.dart test/presentation/screens/grades/grades_presentation_test.dart`
</verification>

<success_criteria>
- Średnia ważona na górze (`WeightedAverageKpiCard`) i średnia ogólna na dole tabeli (`SubjectLedgerTable`) pokazują dokładnie tę samą wartość wyliczoną z ocen liczonych.
- Wpisy `0` oraz `+` nie są wliczane do średniej ważonej, nie mają dopisanej fałszywej wagi `w:1` i nie wpadają do słupka `1` ani `5` w rozkładzie ocen.
- Ocena `3+` trafia do słupka `3` w rozkładzie ocen 1–6 (zamiast `4`).
- Przedmioty bez ocen liczonych pokazują `—` w kolumnach `ŚR. WAŻ.` i `PRZEW.` zamiast `4.80`, `5.00` i `3`.
</success_criteria>

<output>
Create `.planning/quick/261016-cvn-upewnij-si-e-oceny-s-dobrze-prezentowane/261016-cvn-SUMMARY.md` when done
</output>
