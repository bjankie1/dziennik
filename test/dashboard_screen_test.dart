import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:edusync/data/repositories/mock_school_repository.dart";
import "package:edusync/data/services/librus_connection_service.dart";
import "package:edusync/presentation/providers/auth_providers.dart";
import "package:edusync/presentation/providers/school_providers.dart";
import "package:edusync/presentation/screens/dashboard/dashboard_screen.dart";

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
            textScaler: const TextScaler.linear(0.5),
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

  testWidgets("Renders mobile dashboard view on Mobile (< 1024px)", (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(screenSize: const Size(500, 1400)));
    await tester.pumpAndSettle();

    expect(find.text("DZISIEJSZY PLAN ZAJĘĆ"), findsOneWidget);
    expect(find.text("OSTATNIE OCENY"), findsOneWidget);
  });
}
