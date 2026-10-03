import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:edusync/data/repositories/mock_school_repository.dart';
import 'package:edusync/domain/models/lesson_slot.dart';
import 'package:edusync/presentation/providers/school_providers.dart';
import 'package:edusync/presentation/screens/schedule/schedule_screen.dart';
import 'package:edusync/presentation/screens/schedule/widgets/agenda_view.dart';
import 'package:edusync/presentation/screens/schedule/widgets/weekly_grid_view.dart';
import 'package:edusync/presentation/screens/schedule/widgets/weekly_summary_banner.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pl_PL');
  });

  final sampleWeekMap = <int, List<LessonSlot>>{
    1: const [
      LessonSlot(
        lessonNumber: 1,
        subjectName: 'Język polski',
        startTime: '08:00',
        endTime: '08:45',
        room: 'Sala szkolna',
        teacher: 'Melska Grażyna',
        status: LessonStatus.normal,
      ),
    ],
  };

  Widget buildTestSchedule(Size viewportSize) {
    return ProviderScope(
      overrides: [
        schoolRepositoryProvider.overrideWithValue(MockSchoolRepository()),
        weekScheduleProvider.overrideWith((ref) async => sampleWeekMap),
        upcomingExamProvider.overrideWith((ref) async => null),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: viewportSize),
        child: MaterialApp(
          home: SizedBox(
            width: viewportSize.width,
            height: viewportSize.height,
            child: const ScheduleScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'Narrow viewport (<900px) automatically renders AgendaView immediately near the top without manual Siatka/Agenda toggle or school address',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestSchedule(const Size(600, 900)));
    await tester.pumpAndSettle();

    // No manual Siatka / Agenda segmented buttons
    expect(find.text('Siatka'), findsNothing);
    expect(find.text('Agenda'), findsNothing);

    // Automatically renders AgendaView, not WeeklyGridView
    expect(find.byType(AgendaView), findsOneWidget);
    expect(find.byType(WeeklyGridView), findsNothing);

    // AgendaView starts above WeeklySummaryBanner
    final agendaTop = tester.getTopLeft(find.byType(AgendaView)).dy;
    final bannerTop = tester.getTopLeft(find.byType(WeeklySummaryBanner)).dy;
    expect(agendaTop, lessThan(100));
    expect(agendaTop, lessThan(bannerTop));
  });

  testWidgets(
      'Wide viewport (>=900px) automatically renders WeeklyGridView at the top with AgendaView and WeeklySummaryBanner below it',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestSchedule(const Size(1280, 900)));
    await tester.pumpAndSettle();

    expect(find.byType(WeeklyGridView), findsOneWidget);
    expect(find.byType(AgendaView), findsOneWidget);

    final gridTop = tester.getTopLeft(find.byType(WeeklyGridView)).dy;
    final agendaTop = tester.getTopLeft(find.byType(AgendaView)).dy;
    expect(gridTop, lessThan(100));
    expect(agendaTop, greaterThan(gridTop));
  });
}
