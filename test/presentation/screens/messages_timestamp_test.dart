import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:edusync/data/repositories/firestore_school_repository.dart';
import 'package:edusync/domain/models/message_thread.dart';
import 'package:edusync/presentation/providers/school_providers.dart';
import 'package:edusync/presentation/providers/tasks_provider.dart';
import 'package:edusync/presentation/screens/messages/messages_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pl_PL', null);
    await initializeDateFormatting('pl', null);
  });

  group('MessageThread.formatTimestamp', () {
    final referenceNow = DateTime(2026, 9, 30, 12, 0);

    test('formats message from today as Dzisiaj, HH:mm', () {
      final ts = DateTime(2026, 9, 30, 8, 42);
      expect(
        MessageThread.formatTimestamp(ts, now: referenceNow),
        'Dzisiaj, 08:42',
      );
    });

    test('formats message from yesterday as Wczoraj, HH:mm', () {
      final ts = DateTime(2026, 9, 29, 14, 5);
      expect(
        MessageThread.formatTimestamp(ts, now: referenceNow),
        'Wczoraj, 14:05',
      );
    });

    test('formats older message from same year with time as d MMM, HH:mm', () {
      final ts = DateTime(2026, 9, 18, 11, 20);
      expect(
        MessageThread.formatTimestamp(ts, now: referenceNow),
        DateFormat('d MMM, HH:mm', 'pl_PL').format(ts),
      );
    });

    test('formats older message without time (00:00:00) as d MMM without 00:00', () {
      final ts = DateTime(2026, 9, 18, 0, 0, 0);
      final formatted = MessageThread.formatTimestamp(ts, now: referenceNow);
      expect(formatted, DateFormat('d MMM', 'pl_PL').format(ts));
      expect(formatted.contains('00:00'), isFalse);
    });

    test('formats message from previous year with year included', () {
      final ts = DateTime(2025, 6, 15, 9, 30);
      expect(
        MessageThread.formatTimestamp(ts, now: referenceNow),
        DateFormat('d MMM yyyy, HH:mm', 'pl_PL').format(ts),
      );
    });
  });

  group('FirestoreSchoolRepository.parseMessageDate', () {
    test('parses standard Librus SQL/ISO datetime string', () {
      final dt = FirestoreSchoolRepository.parseMessageDate('2026-09-28 09:54:12');
      expect(dt.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 28);
      expect(dt.hour, 9);
      expect(dt.minute, 54);
      expect(dt.second, 12);
    });

    test('parses multiline / extra whitespace Librus datetime string', () {
      final dt = FirestoreSchoolRepository.parseMessageDate('2026-09-28\n  09:54:12');
      expect(dt.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 28);
      expect(dt.hour, 9);
      expect(dt.minute, 54);
    });

    test('parses date-only YYYY-MM-DD string', () {
      final dt = FirestoreSchoolRepository.parseMessageDate('2026-09-15');
      expect(dt.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 15);
      expect(dt.hour, 0);
      expect(dt.minute, 0);
    });

    test('parses Polish DD.MM.YYYY HH:MM format', () {
      final dt = FirestoreSchoolRepository.parseMessageDate('28.09.2026 14:30');
      expect(dt.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 28);
      expect(dt.hour, 14);
      expect(dt.minute, 30);
    });

    test('parses serialized Firestore timestamp map with _seconds', () {
      final dt = FirestoreSchoolRepository.parseMessageDate({'_seconds': 1790589252});
      final expected = DateTime.fromMillisecondsSinceEpoch(
        1790589252 * 1000,
        isUtc: true,
      ).toLocal();
      expect(dt, expected);
    });
  });

  testWidgets(
    'MessagesScreen renders actual formatted timestamp for each message card instead of hardcoded mockup string',
    (tester) async {
      final now = DateTime.now();
      final todayMsgTime = DateTime(now.year, now.month, now.day, 8, 42);
      final yesterdayDate = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
      final yesterdayMsgTime = DateTime(
        yesterdayDate.year,
        yesterdayDate.month,
        yesterdayDate.day,
        14,
        10,
      );
      final olderOneTime = DateTime(2026, 9, 18, 11, 25);
      final olderTwoTime = DateTime(2026, 9, 12, 16, 5);

      final threads = [
        MessageThread(
          id: 'msg_1',
          senderName: 'Piwnik Ewa',
          senderInitials: 'PE',
          senderRole: 'Nauczyciel',
          subject: 'Konsultacje z matematyki',
          preview: 'Przypominam o jutrzejszych konsultacjach.',
          body: 'Przypominam o jutrzejszych konsultacjach.',
          timestamp: todayMsgTime,
          isUnread: true,
        ),
        MessageThread(
          id: 'msg_2',
          senderName: 'Sobota Łukasz',
          senderInitials: 'SŁ',
          senderRole: 'Wychowawca',
          subject: 'Informacje na temat egzaminu maturalnego',
          preview: 'Dzień dobry, przesyłam prezentację.',
          body: 'Dzień dobry, przesyłam prezentację.',
          timestamp: yesterdayMsgTime,
          isUnread: true,
        ),
        MessageThread(
          id: 'msg_3',
          senderName: 'e-Usprawiedliwienia',
          senderInitials: 'EU',
          senderRole: 'System Librus',
          subject: 'Przesłano usprawiedliwienie nieobecności',
          preview: 'Usprawiedliwienie zostało zarejestrowane.',
          body: 'Usprawiedliwienie zostało zarejestrowane.',
          timestamp: olderOneTime,
          isUnread: false,
        ),
        MessageThread(
          id: 'msg_4',
          senderName: 'Radomyska Aneta',
          senderInitials: 'RA',
          senderRole: 'Nauczyciel',
          subject: 'Organizacja wyjścia klasowego',
          preview: 'Proszę o potwierdzenie udziału.',
          body: 'Proszę o potwierdzenie udziału.',
          timestamp: olderTwoTime,
          isUnread: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            messagesProvider.overrideWith((ref) async => threads),
            announcementsProvider.overrideWith((ref) async => const []),
            tasksStreamProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: const MaterialApp(
            home: MessagesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final thread in threads) {
        await tester.scrollUntilVisible(
          find.text(thread.senderName),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(thread.senderName), findsOneWidget);
        expect(find.text(thread.formattedTimestamp), findsOneWidget);
      }

      // Verify hardcoded prototype label 'Dzisiaj, 09:15' is not present
      expect(find.text('Dzisiaj, 09:15'), findsNothing);
    },
  );
}
