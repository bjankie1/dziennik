import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:edusync/domain/models/message_thread.dart';
import 'package:edusync/presentation/providers/school_providers.dart';
import 'package:edusync/data/repositories/mock_school_repository.dart';
import 'package:edusync/presentation/screens/messages/message_thread_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pl_PL', null);
    await initializeDateFormatting('pl', null);
  });

  testWidgets(
    'MessageThreadScreen displays PDF and PPTX attachments for message 2027508',
    (tester) async {
      final thread = MessageThread(
        id: '2027508',
        senderName: 'Sobota Łukasz',
        senderInitials: 'SŁ',
        senderRole: 'Nauczyciel',
        subject: 'Informacje na temat egzaminu maturalnego',
        preview: 'Dzień dobry, przesyłam Państwu obiecaną prezentację.',
        body: 'Dzień dobry,\n\nprzesyłam Państwu obiecaną prezentację.\n\nPozdrawiam,\nŁukasz Sobota',
        timestamp: DateTime(2026, 9, 28, 9, 54),
        isUnread: false,
        attachments: const [
          'matura2027_wrzesien2026_R_U.pdf',
          'matura2027_wrzesien2026_R_U.pptx',
        ],
        attachmentUrls: const {
          'matura2027_wrzesien2026_R_U.pdf': '/wiadomosci/pobierz_zalacznik/2027508/12466101',
          'matura2027_wrzesien2026_R_U.pptx': '/wiadomosci/pobierz_zalacznik/2027508/12466102',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolRepositoryProvider.overrideWithValue(MockSchoolRepository()),
          ],
          child: MaterialApp(
            home: MessageThreadScreen(thread: thread),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Załączniki (2):'), findsOneWidget);
      expect(find.text('matura2027_wrzesien2026_R_U.pdf'), findsOneWidget);
      expect(find.text('matura2027_wrzesien2026_R_U.pptx'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
      expect(find.byIcon(Icons.slideshow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsNWidgets(2));
    },
  );
}
