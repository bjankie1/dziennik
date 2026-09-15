import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edusync/main.dart';

void main() {
  testWidgets('EduSync app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EduSyncApp(),
      ),
    );

    // Initial frame check
    expect(find.byType(EduSyncApp), findsOneWidget);
  });
}
