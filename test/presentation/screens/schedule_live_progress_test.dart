import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:edusync/domain/models/lesson_slot.dart';
import 'package:edusync/presentation/providers/school_providers.dart';
import 'package:edusync/presentation/screens/dashboard/widgets/dashboard_schedule_column.dart';
import 'package:edusync/presentation/screens/schedule/widgets/agenda_lesson_card.dart';
import 'package:edusync/presentation/screens/schedule/widgets/weekly_grid_view.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pl_PL');
  });

  group('LessonSlot time helper methods', () {
    const lesson = LessonSlot(
      lessonNumber: 2,
      subjectName: 'Język Polski',
      startTime: '08:50',
      endTime: '09:35',
      room: '204',
      teacher: 'mgr E. Dąbrowska',
      status: LessonStatus.normal,
    );

    const canceledLesson = LessonSlot(
      lessonNumber: 1,
      subjectName: 'Fizyka',
      startTime: '08:00',
      endTime: '08:45',
      room: '114',
      teacher: 'dr R. Czarnecki',
      status: LessonStatus.canceled,
    );

    final day = DateTime(2026, 10, 7);

    test('isHappeningAt returns true from startTime inclusive to endTime exclusive on the same day', () {
      expect(lesson.isHappeningAt(DateTime(2026, 10, 7, 8, 49, 59), lessonDate: day), isFalse);
      expect(lesson.isHappeningAt(DateTime(2026, 10, 7, 8, 50, 0), lessonDate: day), isTrue);
      expect(lesson.isHappeningAt(DateTime(2026, 10, 7, 9, 12, 30), lessonDate: day), isTrue);
      expect(lesson.isHappeningAt(DateTime(2026, 10, 7, 9, 34, 59), lessonDate: day), isTrue);
      expect(lesson.isHappeningAt(DateTime(2026, 10, 7, 9, 35, 0), lessonDate: day), isFalse);
      // Different day
      expect(lesson.isHappeningAt(DateTime(2026, 10, 8, 9, 10, 0), lessonDate: day), isFalse);
      // Canceled lesson is never happening
      expect(canceledLesson.isHappeningAt(DateTime(2026, 10, 7, 8, 20, 0), lessonDate: day), isFalse);
    });

    test('isCompletedAt returns true at or after endTime on same day or on past days', () {
      expect(lesson.isCompletedAt(DateTime(2026, 10, 7, 8, 30, 0), lessonDate: day), isFalse);
      expect(lesson.isCompletedAt(DateTime(2026, 10, 7, 9, 15, 0), lessonDate: day), isFalse);
      expect(lesson.isCompletedAt(DateTime(2026, 10, 7, 9, 35, 0), lessonDate: day), isTrue);
      expect(lesson.isCompletedAt(DateTime(2026, 10, 7, 12, 0, 0), lessonDate: day), isTrue);
      // Past day
      expect(lesson.isCompletedAt(DateTime(2026, 10, 8, 7, 0, 0), lessonDate: day), isTrue);
      // Future day
      expect(lesson.isCompletedAt(DateTime(2026, 10, 6, 15, 0, 0), lessonDate: day), isFalse);
      // Canceled lesson returns false for isCompletedAt
      expect(canceledLesson.isCompletedAt(DateTime(2026, 10, 7, 10, 0, 0), lessonDate: day), isFalse);
    });

    test('progressAt and remainingMinutesAt compute accurate live progress and round remaining minutes up', () {
      // Before lesson
      expect(lesson.progressAt(DateTime(2026, 10, 7, 8, 40, 0), lessonDate: day), 0.0);
      expect(lesson.remainingMinutesAt(DateTime(2026, 10, 7, 8, 40, 0), lessonDate: day), 0);

      // Halfway through 45-min lesson (22m 30s = 1350s / 2700s = 0.5)
      final halfway = DateTime(2026, 10, 7, 9, 12, 30);
      expect(lesson.progressAt(halfway, lessonDate: day), closeTo(0.5, 0.001));
      expect(lesson.remainingMinutesAt(halfway, lessonDate: day), 23);

      // Last 20 seconds of lesson -> remainingMinutesAt should be 1 (not 0)
      final lastSeconds = DateTime(2026, 10, 7, 9, 34, 40);
      expect(lesson.remainingMinutesAt(lastSeconds, lessonDate: day), 1);

      // After lesson
      expect(lesson.progressAt(DateTime(2026, 10, 7, 9, 35, 0), lessonDate: day), 1.0);
      expect(lesson.remainingMinutesAt(DateTime(2026, 10, 7, 9, 35, 0), lessonDate: day), 0);
    });
  });

  group('CurrentTimeNotifier & UI live progress updates without page reload', () {
    const sampleLessons = [
      LessonSlot(
        lessonNumber: 1,
        subjectName: 'Matematyka',
        startTime: '08:00',
        endTime: '08:45',
        room: '101',
        teacher: 'mgr A. Nowak',
        status: LessonStatus.normal,
      ),
      LessonSlot(
        lessonNumber: 2,
        subjectName: 'Język Polski',
        startTime: '08:50',
        endTime: '09:35',
        room: '204',
        teacher: 'mgr E. Dąbrowska',
        status: LessonStatus.normal,
      ),
    ];

    testWidgets(
      'DashboardScheduleColumn updates LinearProgressIndicator and remaining minutes when currentTimeProvider advances',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final now = ref.watch(currentTimeProvider);
                      return DashboardScheduleColumn(
                        lessons: sampleLessons,
                        now: now,
                        isWeekend: false,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final container = ProviderScope.containerOf(tester.element(find.byType(DashboardScheduleColumn)));

        // Set time to 08:15 (15 min into 45 min lesson 1 -> progress 1/3, 30 min left)
        container.read(currentTimeProvider.notifier).setNow(DateTime(2026, 10, 7, 8, 15));
        await tester.pump();

        expect(find.text('0 / 2 zrealizowane'), findsOneWidget);
        expect(find.text('W TRAKCIE'), findsOneWidget);
        expect(find.text('PLANOWO'), findsOneWidget);
        expect(find.text('ZREALIZOWANO'), findsNothing);
        expect(find.text('Zostało 30 min'), findsOneWidget);

        var indicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
        expect(indicator.value, closeTo(1 / 3, 0.01));

        // Advance time to 08:30 (30 min into lesson 1 -> progress 2/3, 15 min left)
        container.read(currentTimeProvider.notifier).setNow(DateTime(2026, 10, 7, 8, 30));
        await tester.pump();

        expect(find.text('Zostało 15 min'), findsOneWidget);
        indicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
        expect(indicator.value, closeTo(2 / 3, 0.01));
      },
    );

    testWidgets(
      'DashboardScheduleColumn transitions completed lesson to ZREALIZOWANO and activates next lesson as W TRAKCIE automatically',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final now = ref.watch(currentTimeProvider);
                      return DashboardScheduleColumn(
                        lessons: sampleLessons,
                        now: now,
                        isWeekend: false,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final container = ProviderScope.containerOf(tester.element(find.byType(DashboardScheduleColumn)));

        // At 08:40 -> Lesson 1 is W TRAKCIE, Lesson 2 is PLANOWO
        container.read(currentTimeProvider.notifier).setNow(DateTime(2026, 10, 7, 8, 40));
        await tester.pump();

        expect(find.text('0 / 2 zrealizowane'), findsOneWidget);
        expect(find.text('W TRAKCIE'), findsOneWidget);
        expect(find.text('PLANOWO'), findsOneWidget);
        expect(find.text('ZREALIZOWANO'), findsNothing);

        // Advance time to 08:55 -> Lesson 1 is ZREALIZOWANO, Lesson 2 is W TRAKCIE (40 min left)
        container.read(currentTimeProvider.notifier).setNow(DateTime(2026, 10, 7, 8, 55));
        await tester.pump();

        expect(find.text('1 / 2 zrealizowane'), findsOneWidget);
        expect(find.text('ZREALIZOWANO'), findsOneWidget);
        expect(find.text('W TRAKCIE'), findsOneWidget);
        expect(find.text('PLANOWO'), findsNothing);
        expect(find.text('Zostało 40 min'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'AgendaLessonCard and WeeklyGridView render live progress for LessonStatus.normal lessons and update when time changes',
      (tester) async {
        final lessonDate = DateTime(2026, 10, 7); // Wednesday
        final monday = DateTime(2026, 10, 5);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      AgendaLessonCard(
                        slot: sampleLessons[0],
                        date: lessonDate,
                      ),
                      SizedBox(
                        width: 1100,
                        child: WeeklyGridView(
                          currentWeekMonday: monday,
                          weekMap: {3: sampleLessons},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        final container = ProviderScope.containerOf(tester.element(find.byType(AgendaLessonCard)));

        // Set time to 08:20 on 2026-10-07 (Lesson 1 is 08:00-08:45 -> 25 min left)
        container.read(currentTimeProvider.notifier).setNow(DateTime(2026, 10, 7, 8, 20));
        await tester.pump();

        expect(find.text('Trwa teraz • Zostało 25 min'), findsOneWidget);
        // Both AgendaLessonCard and WeeklyGridView render a LinearProgressIndicator for the live lesson
        expect(find.byType(LinearProgressIndicator), findsNWidgets(2));

        // Advance time to 08:50 -> Lesson 1 is completed ('Zrealizowano' in AgendaLessonCard), Lesson 2 is live in WeeklyGridView
        container.read(currentTimeProvider.notifier).setNow(DateTime(2026, 10, 7, 8, 50));
        await tester.pump();

        expect(find.text('Zrealizowano'), findsOneWidget);
        expect(find.textContaining('Trwa teraz'), findsNothing);
      },
    );
  });
}
