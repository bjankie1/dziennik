import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edusync/domain/models/grade.dart';
import 'package:edusync/domain/models/subject.dart';
import 'package:edusync/presentation/providers/school_providers.dart';
import 'package:edusync/presentation/screens/grades/grades_screen.dart';

Grade _grade({
  required String id,
  required String value,
  required double numericValue,
  required int weight,
  required bool isCountedToAverage,
  required String subjectName,
  String category = 'sprawdzian',
  DateTime? date,
}) {
  return Grade(
    id: id,
    subjectName: subjectName,
    rawValue: value,
    numericValue: numericValue,
    weight: weight,
    category: GradeCategory.exam,
    categoryName: category,
    comment: 'Test',
    teacher: 'Nauczyciel Testowy',
    date: date ?? DateTime(2026, 10, 10),
    term: 1,
    isCountedToAverage: isCountedToAverage,
  );
}

List<Subject> _buildOskarRealDataset() {
  // Exact 12 subjects from Oskar's Librus snapshot (11010033):
  // Counted grades (9 total, total weight = 31, weighted sum = 93.75, overallAverage = 3.02419 -> 3.02):
  // - Chemia: 5 (w:3) = 15.0 (plus one '0' uncounted) -> avg 5.00
  // - Język angielski: 4 (w:1) + 3 (w:5) + 4- (w:3) = 30.25 / 9 -> avg 3.36
  // - Język polski: 5 (w:1) + 1 (w:4) = 9.0 / 5 (plus three '0's uncounted) -> avg 1.80
  // - Matematyka: 1 (w:5) = 5.0 / 5 -> avg 1.00
  // - Wychowanie fizyczne: 3+ (w:3) + 4 (w:6) = 34.5 / 9 -> avg 3.83
  // Uncounted-only / empty subjects (7):
  // - Biologia: []
  // - Doradztwo zawodowe: []
  // - Etyka: []
  // - Historia: '+' (uncounted)
  // - Język niemiecki: '0' (uncounted)
  // - Religia: []
  // - Zajęcia z wychowawcą: []
  return [
    const Subject(
      id: 'sub_biol',
      name: 'Biologia',
      teacherName: 'Kowal Anna',
      grades: [],
    ),
    Subject(
      id: 'sub_chem',
      name: 'Chemia',
      teacherName: 'Pietrzak Michał',
      grades: [
        _grade(
          id: 'chem_5',
          value: '5',
          numericValue: 5.0,
          weight: 3,
          isCountedToAverage: true,
          subjectName: 'Chemia',
          date: DateTime(2026, 9, 15),
        ),
        _grade(
          id: 'chem_0',
          value: '0',
          numericValue: 0.0,
          weight: 0,
          isCountedToAverage: false,
          subjectName: 'Chemia',
          date: DateTime(2026, 10, 8),
        ),
      ],
    ),
    const Subject(
      id: 'sub_dor',
      name: 'Doradztwo zawodowe',
      teacherName: 'Nowak Jan',
      grades: [],
    ),
    const Subject(
      id: 'sub_ety',
      name: 'Etyka',
      teacherName: 'Wiśniewski Piotr',
      grades: [],
    ),
    Subject(
      id: 'sub_hist',
      name: 'Historia',
      teacherName: 'Ćwikliński Piotr',
      grades: [
        _grade(
          id: 'hist_plus',
          value: '+',
          numericValue: 0.0,
          weight: 0,
          isCountedToAverage: false,
          subjectName: 'Historia',
          category: 'zadanie',
          date: DateTime(2026, 10, 5),
        ),
      ],
    ),
    Subject(
      id: 'sub_ang',
      name: 'Język angielski',
      teacherName: 'Tychańska Magdalena',
      grades: [
        _grade(
          id: 'ang_4',
          value: '4',
          numericValue: 4.0,
          weight: 1,
          isCountedToAverage: true,
          subjectName: 'Język angielski',
          category: 'aktywność',
          date: DateTime(2026, 9, 29),
        ),
        _grade(
          id: 'ang_3',
          value: '3',
          numericValue: 3.0,
          weight: 5,
          isCountedToAverage: true,
          subjectName: 'Język angielski',
          category: 'sprawdzian',
          date: DateTime(2026, 9, 30),
        ),
        _grade(
          id: 'ang_4m',
          value: '4-',
          numericValue: 3.75,
          weight: 3,
          isCountedToAverage: true,
          subjectName: 'Język angielski',
          category: 'odpowiedź ustna',
          date: DateTime(2026, 10, 9),
        ),
      ],
    ),
    Subject(
      id: 'sub_niem',
      name: 'Język niemiecki',
      teacherName: 'Błaszkiewicz Marta',
      grades: [
        _grade(
          id: 'niem_0',
          value: '0',
          numericValue: 0.0,
          weight: 0,
          isCountedToAverage: false,
          subjectName: 'Język niemiecki',
          category: 'zadanie',
          date: DateTime(2026, 9, 30),
        ),
      ],
    ),
    Subject(
      id: 'sub_pol',
      name: 'Język polski',
      teacherName: 'Melska Grażyna',
      grades: [
        _grade(
          id: 'pol_5',
          value: '5',
          numericValue: 5.0,
          weight: 1,
          isCountedToAverage: true,
          subjectName: 'Język polski',
          category: 'aktywność',
          date: DateTime(2026, 9, 10),
        ),
        _grade(
          id: 'pol_0a',
          value: '0',
          numericValue: 0.0,
          weight: 0,
          isCountedToAverage: false,
          subjectName: 'Język polski',
          category: 'Zagadnienia jawne',
          date: DateTime(2026, 9, 30),
        ),
        _grade(
          id: 'pol_1',
          value: '1',
          numericValue: 1.0,
          weight: 4,
          isCountedToAverage: true,
          subjectName: 'Język polski',
          category: 'Zagadnienia jawne',
          date: DateTime(2026, 10, 2),
        ),
        _grade(
          id: 'pol_0b',
          value: '0',
          numericValue: 0.0,
          weight: 0,
          isCountedToAverage: false,
          subjectName: 'Język polski',
          category: 'kartkówka',
          date: DateTime(2026, 10, 9),
        ),
        _grade(
          id: 'pol_0c',
          value: '0',
          numericValue: 0.0,
          weight: 0,
          isCountedToAverage: false,
          subjectName: 'Język polski',
          category: 'Zagadnienia jawne',
          date: DateTime(2026, 10, 16),
        ),
      ],
    ),
    Subject(
      id: 'sub_mat',
      name: 'Matematyka',
      teacherName: 'Duda-Radicchio Wioletta',
      grades: [
        _grade(
          id: 'mat_1',
          value: '1',
          numericValue: 1.0,
          weight: 5,
          isCountedToAverage: true,
          subjectName: 'Matematyka',
          category: 'sprawdzian',
          date: DateTime(2026, 9, 24),
        ),
      ],
    ),
    const Subject(
      id: 'sub_rel',
      name: 'Religia',
      teacherName: 'Kaczmarek Marek',
      grades: [],
    ),
    Subject(
      id: 'sub_wf',
      name: 'Wychowanie fizyczne',
      teacherName: 'Herezo Maciej',
      grades: [
        _grade(
          id: 'wf_3p',
          value: '3+',
          numericValue: 3.5,
          weight: 3,
          isCountedToAverage: true,
          subjectName: 'Wychowanie fizyczne',
          category: 'sprawdzian',
          date: DateTime(2026, 10, 4),
        ),
        _grade(
          id: 'wf_4',
          value: '4',
          numericValue: 4.0,
          weight: 6,
          isCountedToAverage: true,
          subjectName: 'Wychowanie fizyczne',
          category: 'Systematyczność',
          date: DateTime(2026, 10, 4),
        ),
      ],
    ),
    const Subject(
      id: 'sub_zw',
      name: 'Zajęcia z wychowawcą',
      teacherName: 'Sobota Łukasz',
      grades: [],
    ),
  ];
}

void main() {
  group('Grade MEN 1-6 parsing and bucketing', () {
    test('tryParseMenValue parses 1-6 with +/- modifiers and rejects 0, +, -, np, bz', () {
      expect(Grade.tryParseMenValue('1'), 1.0);
      expect(Grade.tryParseMenValue('1+'), 1.5);
      expect(Grade.tryParseMenValue('2-'), 1.75);
      expect(Grade.tryParseMenValue('3+'), 3.5);
      expect(Grade.tryParseMenValue('4-'), 3.75);
      expect(Grade.tryParseMenValue('5'), 5.0);
      expect(Grade.tryParseMenValue('6'), 6.0);

      expect(Grade.tryParseMenValue('0'), isNull);
      expect(Grade.tryParseMenValue('+'), isNull);
      expect(Grade.tryParseMenValue('-'), isNull);
      expect(Grade.tryParseMenValue('np'), isNull);
      expect(Grade.tryParseMenValue('bz'), isNull);
      expect(Grade.tryParseMenValue('nb'), isNull);
    });

    test('menScaleBucket maps 3+ to 3, 4- to 4, and returns null for 0 and +', () {
      final g3p = _grade(
        id: '1',
        value: '3+',
        numericValue: 3.5,
        weight: 3,
        isCountedToAverage: true,
        subjectName: 'Wychowanie fizyczne',
      );
      final g4m = _grade(
        id: '2',
        value: '4-',
        numericValue: 3.75,
        weight: 3,
        isCountedToAverage: true,
        subjectName: 'Język angielski',
      );
      final g0 = _grade(
        id: '3',
        value: '0',
        numericValue: 0.0,
        weight: 0,
        isCountedToAverage: false,
        subjectName: 'Język polski',
      );
      final gPlus = _grade(
        id: '4',
        value: '+',
        numericValue: 0.0,
        weight: 0,
        isCountedToAverage: false,
        subjectName: 'Historia',
      );

      expect(g3p.menScaleBucket, 3);
      expect(g4m.menScaleBucket, 4);
      expect(g0.menScaleBucket, isNull);
      expect(gPlus.menScaleBucket, isNull);
    });
  });

  group('gradesDistributionStatsProvider — Real Librus Dataset', () {
    test('computes exact overall weighted average 3.02 (93.75 / 31) and MEN 1-6 histogram without 0/+ pollution', () async {
      final dataset = _buildOskarRealDataset();
      final container = ProviderContainer(
        overrides: [
          subjectsProvider.overrideWith((ref) async => dataset),
        ],
      );
      addTearDown(container.dispose);

      await container.read(subjectsProvider.future);
      final stats = container.read(gradesDistributionStatsProvider);

      expect(stats.overallAverage, closeTo(93.75 / 31, 0.0001));
      expect(stats.overallAverage.toStringAsFixed(2), '3.02');
      expect(stats.totalGrades, 9);
      expect(stats.otherGradesCount, 6);
      expect(stats.counts, {
        1: 2,
        2: 0,
        3: 2,
        4: 3,
        5: 2,
        6: 0,
      });
    });
  });

  testWidgets('GradesScreen (desktop) renders all 12 subjects with exact weighted averages (Chemia 5.00, Angielski 3.36, Polski 1.80, Matematyka 1.00, WF 3.83), inspector, and GPA simulator with weights 1..6', (tester) async {
    tester.view.physicalSize = const Size(2000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final dataset = _buildOskarRealDataset();
    final container = ProviderContainer(
      overrides: [
        subjectsProvider.overrideWith((ref) async => dataset),
      ],
    );
    addTearDown(container.dispose);

    await container.read(subjectsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: GradesScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Overall average 3.02 appears both in WeightedAverageKpiCard and SubjectLedgerTable footer
    expect(find.text('3.02'), findsAtLeastNWidgets(2));

    // Exact subject averages for all 5 graded subjects
    expect(find.text('5.00'), findsWidgets);
    expect(find.text('3.36'), findsWidgets);
    expect(find.text('1.80'), findsWidgets);
    expect(find.text('1.00'), findsWidgets);
    expect(find.text('3.83'), findsWidgets);

    // Never renders hardcoded mock values
    expect(find.text('4.82'), findsNothing);
    expect(find.text('4.80'), findsNothing);

    // Shows 2 zagrożenia badge in GradeDistributionCard
    expect(find.textContaining('2 zagrożenia'), findsOneWidget);

    // Shows '—' for the 7 subjects without counted grades
    expect(find.text('—'), findsAtLeastNWidgets(7));

    // Shows (+6 wpisów: 0/+) subtitle on GradeDistributionCard
    expect(find.textContaining('ocen w skali 1–6 (+6 wpisów: 0/+)'), findsOneWidget);

    // Selecting 'Język polski' populates SubjectInspectorCard without DateFormat crash
    await tester.tap(find.text('Język polski').first);
    await tester.pumpAndSettle();
    expect(find.text('REJESTR OCEN CZĄSTKOWYCH (5)'), findsOneWidget);

    // Clicking 'Symuluj ocenę dla tego przedmiotu' opens AverageSimulatorModal pre-selected to Język polski and supports Waga 5 & Waga 6
    await tester.tap(find.text('Symuluj ocenę dla tego przedmiotu'));
    await tester.pumpAndSettle();
    expect(find.text('Symulator Średniej "Co jeśli"'), findsOneWidget);
    expect(find.text(' (było 1.80)'), findsOneWidget);
    expect(find.text('Waga 5'), findsOneWidget);
    expect(find.text('Waga 6'), findsOneWidget);
  });

  testWidgets('GradesScreen (mobile) renders exact subject averages, Brak ocen for empty subjects, and opens simulator for selected subject', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final dataset = _buildOskarRealDataset();
    final container = ProviderContainer(
      overrides: [
        subjectsProvider.overrideWith((ref) async => dataset),
      ],
    );
    addTearDown(container.dispose);

    await container.read(subjectsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: GradesScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3.02'), findsWidgets);
    expect(find.text('5.00'), findsWidgets);
    expect(find.text('1.80'), findsWidgets);
    expect(find.text('1.00'), findsWidgets);
    expect(find.text('Brak ocen'), findsAtLeastNWidgets(5));
  });

  testWidgets('GradeDistributionCard aligns all 6 histogram bars and grade labels on the exact same horizontal baseline without overflow', (tester) async {
    tester.view.physicalSize = const Size(2000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Skewed dataset where grade 1 has count 7 (matching the user screenshot where bar 1 was pushed down)
    final skewedDataset = [
      Subject(
        id: 'sub_skew',
        name: 'Matematyka',
        teacherName: 'Nauczyciel Testowy',
        grades: [
          for (int i = 0; i < 7; i++)
            _grade(
              id: 'g1_$i',
              value: '1',
              numericValue: 1.0,
              weight: 3,
              isCountedToAverage: true,
              subjectName: 'Matematyka',
            ),
          _grade(
            id: 'g3_1',
            value: '3+',
            numericValue: 3.5,
            weight: 2,
            isCountedToAverage: true,
            subjectName: 'Matematyka',
          ),
          _grade(
            id: 'g4_1',
            value: '4',
            numericValue: 4.0,
            weight: 2,
            isCountedToAverage: true,
            subjectName: 'Matematyka',
          ),
          _grade(
            id: 'g4_2',
            value: '4-',
            numericValue: 3.75,
            weight: 2,
            isCountedToAverage: true,
            subjectName: 'Matematyka',
          ),
          _grade(
            id: 'g5_1',
            value: '5',
            numericValue: 5.0,
            weight: 4,
            isCountedToAverage: true,
            subjectName: 'Matematyka',
          ),
        ],
      ),
    ];

    for (final dataset in [_buildOskarRealDataset(), skewedDataset]) {
      final container = ProviderContainer(
        overrides: [
          subjectsProvider.overrideWith((ref) async => dataset),
        ],
      );
      await container.read(subjectsProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: GradesScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no overflow or rendering exceptions
      expect(tester.takeException(), isNull);

      final bar1BottomDy = tester.getBottomLeft(find.byKey(const ValueKey('grade_bar_1'))).dy;
      final label1BottomDy = tester.getBottomLeft(find.byKey(const ValueKey('grade_label_1'))).dy;
      final label1CenterDy = tester.getCenter(find.byKey(const ValueKey('grade_label_1'))).dy;

      for (int gradeNum = 1; gradeNum <= 6; gradeNum++) {
        final barFinder = find.byKey(ValueKey('grade_bar_$gradeNum'));
        final labelFinder = find.byKey(ValueKey('grade_label_$gradeNum'));

        expect(barFinder, findsOneWidget, reason: 'Missing grade_bar_$gradeNum');
        expect(labelFinder, findsOneWidget, reason: 'Missing grade_label_$gradeNum');

        final barBottomDy = tester.getBottomLeft(barFinder).dy;
        final labelBottomDy = tester.getBottomLeft(labelFinder).dy;
        final labelCenterDy = tester.getCenter(labelFinder).dy;

        expect(
          barBottomDy,
          equals(bar1BottomDy),
          reason: 'Bar $gradeNum bottom dy ($barBottomDy) must match bar 1 bottom dy ($bar1BottomDy)',
        );
        expect(
          labelBottomDy,
          equals(label1BottomDy),
          reason: 'Label $gradeNum bottom dy ($labelBottomDy) must match label 1 bottom dy ($label1BottomDy)',
        );
        expect(
          labelCenterDy,
          equals(label1CenterDy),
          reason: 'Label $gradeNum center dy ($labelCenterDy) must match label 1 center dy ($label1CenterDy)',
        );
      }

      container.dispose();
    }
  });
}
