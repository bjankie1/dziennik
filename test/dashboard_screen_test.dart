import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:edusync/data/repositories/mock_school_repository.dart";
import "package:edusync/data/services/librus_connection_service.dart";
import "package:edusync/domain/models/lesson_slot.dart";
import "package:edusync/presentation/providers/auth_providers.dart";
import "package:edusync/presentation/providers/school_providers.dart";
import "package:edusync/presentation/screens/dashboard/dashboard_screen.dart";
import "package:edusync/presentation/screens/dashboard/widgets/dashboard_schedule_column.dart";

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    await initializeDateFormatting("pl_PL");
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildTestWidget({Size screenSize = const Size(1200, 800)}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        schoolRepositoryProvider.overrideWithValue(
          MockSchoolRepository(
            connectionService: LibrusConnectionService(prefs: prefs),
          ),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            textScaler: const TextScaler.linear(1.0),
          ),
          child: const DashboardScreen(),
        ),
      ),
    );
  }

  testWidgets("Renders Desktop Bento Grid components on Desktop (>= 1024px)", (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(screenSize: const Size(1440, 1000)));
    await tester.pumpAndSettle();

    // Verify key sections from docs/start_page_web_v1/code.html
    expect(find.textContaining("Dzień dobry"), findsWidgets);
    expect(find.text("Harmonogram na dziś"), findsOneWidget);
    expect(find.text("Wiadomości i Komunikaty"), findsOneWidget);
    expect(find.text("Ostatnie oceny"), findsOneWidget);
    expect(find.text("Frekwencja"), findsOneWidget);
    expect(find.text("Kontakt z wychowawcą"), findsOneWidget);
    expect(find.text("Zgłoś nieobecność"), findsOneWidget);
  });

  testWidgets("Renders Desktop Bento Grid without overflow at narrow desktop width (1024px)", (tester) async {
    tester.view.physicalSize = const Size(1024, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(screenSize: const Size(1024, 1000)));
    await tester.pumpAndSettle();

    expect(find.text("Harmonogram na dziś"), findsOneWidget);
    expect(find.text("Wiadomości i Komunikaty"), findsOneWidget);
    expect(find.text("Frekwencja"), findsOneWidget);
  });

  testWidgets("Renders mobile dashboard view on Mobile (< 1024px) including 360px width", (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(screenSize: const Size(500, 1400)));
    await tester.pumpAndSettle();

    expect(find.text("DZISIEJSZY PLAN ZAJĘĆ"), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text("OSTATNIE OCENY"),
      300.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("OSTATNIE OCENY"), findsOneWidget);

    tester.view.physicalSize = const Size(360, 1200);
    await tester.pumpWidget(buildTestWidget(screenSize: const Size(360, 1200)));
    await tester.pumpAndSettle();

    expect(find.text("DZISIEJSZY PLAN ZAJĘĆ"), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text("OSTATNIE OCENY"),
      300.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("OSTATNIE OCENY"), findsOneWidget);
  });

  testWidgets("DashboardScheduleColumn renders all lesson statuses and long subject/room/teacher names in narrow 280px container without overflow", (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final now = DateTime(2026, 10, 7, 10, 0);
    final lessons = <LessonSlot>[
      const LessonSlot(
        lessonNumber: 1,
        startTime: "08:00",
        endTime: "08:45",
        subjectName: "Edukacja dla bezpieczeństwa",
        teacher: "mgr Krzysztof Brzęczyszczykiewicz",
        room: "204 (budynek główny)",
        status: LessonStatus.completed,
      ),
      const LessonSlot(
        lessonNumber: 2,
        startTime: "08:55",
        endTime: "09:40",
        subjectName: "Wychowanie fizyczne",
        teacher: "mgr Małgorzata Kowalska-Nowak",
        room: "gimnastyczna (budynek B)",
        status: LessonStatus.canceled,
        statusNote: "Lekcja odwołana z powodu zawodów międzyszkolnych",
      ),
      const LessonSlot(
        lessonNumber: 3,
        startTime: "09:50",
        endTime: "10:35",
        subjectName: "Biznes i zarządzanie",
        teacher: "dr hab. Aleksander Wojciechowski-Zieliński",
        room: "312A",
        status: LessonStatus.inProgress,
      ),
      const LessonSlot(
        lessonNumber: 4,
        startTime: "10:45",
        endTime: "11:30",
        subjectName: "Język angielski rozszerzony",
        teacher: "mgr Anna Nowak",
        room: "105",
        status: LessonStatus.substituted,
        substituteTeacher: "mgr Katarzyna Wiśniewska-Kamińska",
      ),
      const LessonSlot(
        lessonNumber: 5,
        startTime: "11:45",
        endTime: "12:30",
        subjectName: "Historia i teraźniejszość",
        teacher: "mgr Piotr Zieliński",
        room: "208",
        status: LessonStatus.normal,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 1200),
              textScaler: TextScaler.linear(1.0),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Center(
                  child: SizedBox(
                    width: 280,
                    child: DashboardScheduleColumn(
                      lessons: lessons,
                      now: now,
                      isWeekend: false,
                      exam: UpcomingEvent(
                        subject: "Edukacja dla bezpieczeństwa",
                        title: "Pierwsza pomoc przedmedyczna i ewakuacja budynku",
                        type: "Sprawdzian wiadomości",
                        date: DateTime(2026, 10, 9),
                        time: "08:55",
                        daysRemaining: 2,
                        room: "Sala 204 (budynek główny)",
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Harmonogram na dziś"), findsOneWidget);
    expect(find.text("2 / 5 zrealizowane"), findsOneWidget);
    expect(find.text("ZREALIZOWANO"), findsOneWidget);
    expect(find.text("ODWOŁANE"), findsOneWidget);
    expect(find.text("W TRAKCIE"), findsOneWidget);
    expect(find.text("ZASTĘPSTWO"), findsOneWidget);
    expect(find.text("PLANOWO"), findsOneWidget);
    expect(find.textContaining("Edukacja dla bezpieczeństwa"), findsWidgets);
    expect(find.textContaining("Wychowanie fizyczne"), findsOneWidget);
    expect(find.textContaining("Biznes i zarządzanie"), findsOneWidget);
    expect(find.text("Zostało 35 min"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
