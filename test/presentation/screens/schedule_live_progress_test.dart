import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edusync/domain/models/lesson_slot.dart';
import 'package:edusync/presentation/providers/school_providers.dart';

void main() {
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

  group('CurrentTimeNotifier reactivity', () {
    testWidgets('Updating currentTimeProvider via setNow rebuilds watching widgets without reload', (tester) async {
      final initialTime = DateTime(2026, 10, 7, 8, 55);
      final updatedTime = DateTime(2026, 10, 7, 9, 20);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final now = ref.watch(currentTimeProvider);
                return Text('TIME:${now.hour}:${now.minute}');
              },
            ),
          ),
        ),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(Consumer)));
      container.read(currentTimeProvider.notifier).setNow(initialTime);
      await tester.pump();
      expect(find.text('TIME:8:55'), findsOneWidget);

      container.read(currentTimeProvider.notifier).setNow(updatedTime);
      await tester.pump();
      expect(find.text('TIME:9:20'), findsOneWidget);
    });
  });
}
