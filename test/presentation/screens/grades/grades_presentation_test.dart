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
  // Counted grades (9 total, total weight = 31, weighted sum = 93.75, overallAverage = 3.02419 -> 3.02):
  // - Chemia: 5 (w:3) = 15.0 (plus one '0' uncounted) -> avg 5.00
  // - Język polski: 5 (w:1) + 1 (w:4) = 9.0 (plus three '0's uncounted) -> avg 1.80
  // - Matematyka: 1 (w:4) + 3 (w:8) = 28.0 -> avg 2.33
  // - Wychowanie fizyczne: 3+ (w:4) = 14.0 -> avg 3.50
  // - Język angielski: 4- (w:1) + 4 (w:3) + 4 (w:3) = 27.75 -> avg 3.96
  // Uncounted-only / empty subjects:
  // - Historia: '+' (uncounted)
  // - Język niemiecki: '0' (uncounted)
  // - Biologia: []
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
          date: DateTime(2026, 9, 20),
        ),
        _grade(
          id: 'chem_0',
          value: '0',
          numericValue: 0.0,
          weight: 0,
          isCountedToAverage: false,
          subjectName: 'Chemia',
          date: DateTime(2026, 10, 5),
        ),
      ],
    ),
    Subject(
      id: 'sub_hist',
      name: 'Historia',
      teacherName: 'Mazur Piotr',
      grades: [
        _grade(
          id: 'hist_plus',
          value: '+',
          numericValue: 0.0,
          weight: 0,
          isCountedToAverage: false,
          subjectName: 'Historia',
          category: 'aktywność',
          date: DateTime(2026, 9, 18),
        ),
      ],
    ),
    Subject(
      id: 'sub_ang',
      name: 'Język angielski',
      teacherName: 'Wiśniewska Ewa',
      grades: [
        _grade(
          id: 'ang_4m',
          value: '4-',
          numericValue: 3.75,
          weight: 1,
          isCountedToAverage: true,
          subjectName: 'Język angielski',
          date: DateTime(2026, 9, 15),
        ),
        _grade(
          id: 'ang_4a',
          value: '4',
          numericValue: 4.0,
          weight: 3,
          isCountedToAverage: true,
          subjectName: 'Język angielski',
          date: DateTime(2026, 9, 29),
        ),
        _grade(
          id: 'ang_4b',
          value: '4',
          numericValue: 4.0,
          weight: 3,
          isCountedToAverage: true,
          subjectName: 'Język angielski',
          date: DateTime(2026, 10, 8),
        ),
      ],
    ),
    Subject(
      id: 'sub_niem',
      name: 'Język niemiecki',
      teacherName: 'Schmidt Anna',
      grades: [
        _grade(
          id: 'niem_0',
          value: '0',
          numericValue: 0.0,
          weight: 0,
          isCountedToAverage: false,
          subjectName: 'Język niemiecki',
          date: DateTime(2026, 10, 2),
        ),
      ],
    ),
    Subject(
      id: 'sub_pol',
      name: 'Język polski',
      teacherName: 'Kowalska Anna',
      grades: [
        _grade(
          id: 'pol_5',
          value: '5',
          numericValue: 5.0,
          weight: 1,
          isCountedToAverage: true,
          subjectName: 'Język polski',
          date: DateTime(2026, 9, 12),
        ),
        _grade(
          id: 'pol_1',
          value: '1',
          numericValue: 1.0,
          weight: 4,
          isCountedToAverage: true,
          subjectName: 'Język polski',
          date: DateTime(2026, 9, 25),
        ),
        _grade(
          id: 'pol_0a',
          value: '0',
          numericValue: 0.0,
          weight: 0,
          isCountedToAverage: false,
          subjectName: 'Język polski',
          date: DateTime(2026, 10, 1),
        ),
        _grade(
          id: 'pol_0b',
          value: '0',
          numericValue: 0.0,
          weight: 0,
          isCountedToAverage: false,
          subjectName: 'Język polski',
          date: DateTime(2026, 10, 6),
        ),
        _grade(
          id: 'pol_0c',
          value: '0',
          numericValue: 0.0,
          weight: 0,
          isCountedToAverage: false,
          subjectName: 'Język polski',
          date: DateTime(2026, 10, 12),
        ),
      ],
    ),
    Subject(
      id: 'sub_mat',
      name: 'Matematyka',
      teacherName: 'Nowicki Paweł',
      grades: [
        _grade(
          id: 'mat_1',
          value: '1',
          numericValue: 1.0,
          weight: 4,
          isCountedToAverage: true,
          subjectName: 'Matematyka',
          date: DateTime(2026, 9, 22),
        ),
        _grade(
          id: 'mat_3',
          value: '3',
          numericValue: 3.0,
          weight: 8,
          isCountedToAverage: true,
          subjectName: 'Matematyka',
          date: DateTime(2026, 10, 4),
        ),
      ],
    ),
    Subject(
      id: 'sub_wf',
      name: 'Wychowanie fizyczne',
      teacherName: 'Zając Marek',
      grades: [
        _grade(
          id: 'wf_3p',
          value: '3+',
          numericValue: 3.5,
          weight: 4,
          isCountedToAverage: true,
          subjectName: 'Wychowanie fizyczne',
          date: DateTime(2026, 9, 28),
        ),
      ],
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
        weight: 4,
        isCountedToAverage: true,
        subjectName: 'Wychowanie fizyczne',
      );
      final g4m = _grade(
        id: '2',
        value: '4-',
        numericValue: 3.75,
        weight: 1,
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

  testWidgets('GradesScreen (desktop) renders 3.02 in KPI and table footer, 2 zagrożenia, — for ungraded subjects, and no hardcoded 4.82/4.80', (tester) async {
    tester.view.physicalSize = const Size(2000, 1200);
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

    // Subject averages for Chemia (5.00) and Język polski (1.80)
    expect(find.text('5.00'), findsWidgets);
    expect(find.text('1.80'), findsWidgets);

    // Never renders hardcoded mock values
    expect(find.text('4.82'), findsNothing);
    expect(find.text('4.80'), findsNothing);

    // Shows 2 zagrożenia badge in GradeDistributionCard
    expect(find.textContaining('2 zagrożenia'), findsOneWidget);

    // Shows '—' for subjects without counted grades (Biologia, Historia, Język niemiecki)
    expect(find.text('—'), findsAtLeastNWidgets(3));

    // Shows (+6 wpisów: 0/+) subtitle on GradeDistributionCard
    expect(find.textContaining('ocen w skali 1–6 (+6 wpisów: 0/+)'), findsOneWidget);
  });
}
