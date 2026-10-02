import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:edusync/core/services/notification_channels_service.dart';
import 'package:edusync/data/repositories/mock_school_repository.dart';
import 'package:edusync/domain/models/notification_settings.dart';
import 'package:edusync/presentation/providers/notification_settings_provider.dart';
import 'package:edusync/presentation/providers/school_providers.dart';
import 'package:edusync/presentation/widgets/modals/notification_settings_modal.dart';

void main() {
  group('NotificationChannelsService.fetchBotUsername', () {
    test('returns bot username without @ when Telegram getMe succeeds', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.telegram.org/bot7123456:AAH_TEST/getMe',
        );
        return http.Response(
          jsonEncode({
            'ok': true,
            'result': {
              'id': 123456789,
              'is_bot': true,
              'first_name': 'Dziennik Oskar',
              'username': '@OskarDziennik_bot',
            },
          }),
          200,
        );
      });

      final service = NotificationChannelsService(httpClient: mockClient);
      final username = await service.fetchBotUsername('  7123456:AAH_TEST  ');
      expect(username, 'OskarDziennik_bot');
    });

    test('returns null for empty token or HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'ok': false, 'error_code': 401}),
          401,
        );
      });

      final service = NotificationChannelsService(httpClient: mockClient);
      expect(await service.fetchBotUsername(''), isNull);
      expect(await service.fetchBotUsername('invalid_token'), isNull);
    });
  });

  testWidgets(
    'NotificationSettingsModal toggles step-by-step Telegram guide with 4 steps, Invalid bot passed warning, and reveals Bot Token field',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'ok': true,
            'result': {
              'id': 123,
              'is_bot': true,
              'first_name': 'Dziennik',
              'username': 'OskarDziennik_bot',
            },
          }),
          200,
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolRepositoryProvider.overrideWithValue(MockSchoolRepository()),
            notificationChannelsServiceProvider.overrideWithValue(
              NotificationChannelsService(httpClient: mockClient),
            ),
            notificationChannelSettingsProvider.overrideWith(
              (ref) => Stream.value(
                const NotificationChannelSettings(
                  familyId: '11010033',
                  roleKey: 'parent',
                ),
              ),
            ),
            schoolNotificationsStreamProvider.overrideWith(
              (ref) => Stream.value(const <SchoolNotificationItem>[]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: NotificationSettingsModal(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final guideButton = find.byKey(
        const ValueKey('telegram_step_by_step_guide_button'),
      );
      expect(guideButton, findsOneWidget);
      expect(
        find.text('Instrukcja krok po kroku (Jak połączyć?)'),
        findsOneWidget,
      );

      // Expand step-by-step guide
      await tester.tap(guideButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Instrukcja krok po kroku: Jak skonfigurować powiadomienia Telegram',
        ),
        findsOneWidget,
      );
      expect(find.text('Krok 1'), findsOneWidget);
      expect(find.text('Krok 2'), findsOneWidget);
      expect(find.text('Krok 3'), findsOneWidget);
      expect(find.text('Krok 4'), findsOneWidget);
      expect(find.text('Kopiuj /newbot'), findsOneWidget);
      expect(find.text('Otwórz @BotFather'), findsOneWidget);
      expect(
        find.textContaining('Invalid bot passed'),
        findsWidgets,
      );

      // Verify clicking 'Pokaż pole Tokenu poniżej' reveals the Bot Token input field
      final showTokenFieldBtn = find.byKey(
        const ValueKey('telegram_guide_show_token_field_button'),
      );
      await tester.ensureVisible(showTokenFieldBtn);
      await tester.pumpAndSettle();
      await tester.tap(showTokenFieldBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Telegram Bot Token (@BotFather)'),
        findsOneWidget,
      );
    },
  );
}
