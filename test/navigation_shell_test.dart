import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:edusync/presentation/screens/main_navigation_screen.dart";
import "package:edusync/presentation/widgets/app_sidebar.dart";
import "package:edusync/presentation/widgets/app_desktop_header.dart";

void main() {
  Widget buildTestWidget({Size screenSize = const Size(1200, 800)}) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const MainNavigationScreen(),
        ),
      ),
    );
  }

  testWidgets("Renders AppSidebar and AppDesktopHeader on Desktop (>=1024px)", (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(screenSize: const Size(1200, 800)));
    await tester.pumpAndSettle();

    // Desktop shell check
    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.byType(AppDesktopHeader), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    // Click on Plan Lekcji in sidebar
    await tester.tap(find.text("Plan Lekcji"));
    await tester.pumpAndSettle();
  });

  testWidgets("Renders mobile NavigationBar and hides AppSidebar on Mobile (<1024px)", (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(screenSize: const Size(400, 800)));
    await tester.pumpAndSettle();

    // Mobile check
    expect(find.byType(AppSidebar), findsNothing);
    expect(find.byType(AppDesktopHeader), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
