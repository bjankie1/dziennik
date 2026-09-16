import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:edusync/presentation/screens/dashboard/dashboard_screen.dart";

void main() {
  Widget buildTestWidget({Size screenSize = const Size(1200, 800)}) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const DashboardScreen(),
        ),
      ),
    );
  }

  testWidgets("Renders Desktop Bento Grid components on Desktop (>= 1024px)", (tester) async {
    tester.view.physicalSize = const Size(1280, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(screenSize: const Size(1280, 850)));
    await tester.pumpAndSettle();

    // Verify key sections from docs/start_page_web_v1/code.html
    expect(find.textContaining("Dzień dobry"), findsOneWidget);
    expect(find.text("Harmonogram na dziś"), findsOneWidget);
    expect(find.text("Wiadomości i Komunikaty"), findsOneWidget);
    expect(find.text("Ostatnie oceny"), findsOneWidget);
    expect(find.text("Frekwencja"), findsOneWidget);
    expect(find.text("Szybkie usprawiedliwienie (PIN)"), findsOneWidget);
    expect(find.text("Zadania domowe"), findsOneWidget);
    expect(find.text("Kontakt z wychowawcą"), findsOneWidget);
    expect(find.text("Zgłoś nieobecność"), findsOneWidget);
  });

  testWidgets("Renders mobile dashboard view on Mobile (< 1024px)", (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(screenSize: const Size(400, 800)));
    await tester.pumpAndSettle();

    expect(find.text("DZISIEJSZY PLAN ZAJĘĆ"), findsOneWidget);
    expect(find.text("OSTATNIE OCENY"), findsOneWidget);
  });
}
