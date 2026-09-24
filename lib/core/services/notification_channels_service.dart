import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/notification_settings.dart';
import '../utils/web_push_browser_helper_stub.dart'
    if (dart.library.js_interop) '../utils/web_push_browser_helper_web.dart';

class NotificationChannelsService {
  static const String _functionsBaseUrl =
      'https://europe-west3-lepsza-szkola.cloudfunctions.net';

  final FirebaseFirestore _firestore;

  NotificationChannelsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _settingsRef(
    String familyId,
    String roleKey,
  ) {
    return _firestore
        .collection('students')
        .doc(familyId)
        .collection('notification_settings')
        .doc(roleKey);
  }

  /// Generates a 6-digit one-time pairing code valid for 15 minutes and stores it in Firestore (`REQ-NOTIF-01`).
  Future<String> generatePairingCode({
    required String familyId,
    required String roleKey,
    String? botToken,
    String? botUsername,
  }) async {
    final random = Random.secure();
    final code = (100000 + random.nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    final updates = <String, dynamic>{
      'familyId': familyId,
      'roleKey': roleKey,
      'pairingCode': code,
      'pairingCodeExpiresAt': Timestamp.fromDate(expiresAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (botToken != null && botToken.trim().isNotEmpty) {
      updates['telegramBotToken'] = botToken.trim();
    }
    if (botUsername != null && botUsername.trim().isNotEmpty) {
      updates['telegramBotUsername'] = botUsername.trim().replaceAll('@', '');
    }

    await _settingsRef(familyId, roleKey).set(updates, SetOptions(merge: true));

    await _firestore.collection('telegram_pairing_codes').doc(code).set({
      'code': code,
      'familyId': familyId,
      'roleKey': roleKey,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return code;
  }

  /// Saves manual or updated notification channel settings.
  Future<void> updateSettings({
    required String familyId,
    required String roleKey,
    required Map<String, dynamic> patch,
  }) async {
    await _settingsRef(familyId, roleKey).set(
      {
        ...patch,
        'familyId': familyId,
        'roleKey': roleKey,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Disconnects Telegram chat from current account role.
  Future<void> disconnectTelegram({
    required String familyId,
    required String roleKey,
  }) async {
    await _settingsRef(familyId, roleKey).set(
      {
        'telegramEnabled': false,
        'telegramChatId': null,
        'telegramUsername': null,
        'pairingCode': null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Verifies a 6-digit pairing code using Telegram Bot API `getUpdates` (direct + Cloud Function fallback).
  Future<({bool paired, String? chatId, String? username, String? error})>
      verifyPairingCode({
    required String familyId,
    required String roleKey,
    required String pairingCode,
    String? botToken,
  }) async {
    final trimmedCode = pairingCode.trim();
    final trimmedToken = (botToken ?? '').trim();

    // 1. Direct Telegram Bot API check if token is provided
    if (trimmedToken.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://api.telegram.org/bot$trimmedToken/getUpdates?limit=50',
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final results = (decoded['result'] as List<dynamic>?) ?? [];
          for (int i = results.length - 1; i >= 0; i--) {
            final item = results[i] as Map<String, dynamic>;
            final msg = (item['message'] ?? item['edited_message'])
                as Map<String, dynamic>?;
            if (msg == null) continue;
            final text = (msg['text'] ?? '').toString().trim();
            final chat = msg['chat'] as Map<String, dynamic>?;
            if (chat == null) continue;

            if (text == '/start $trimmedCode' ||
                text == trimmedCode ||
                text.contains(trimmedCode)) {
              final chatId = chat['id'].toString();
              final from = msg['from'] as Map<String, dynamic>?;
              final username = (from?['username'] ??
                      from?['first_name'] ??
                      chat['title'] ??
                      'Telegram')
                  .toString();

              await _settingsRef(familyId, roleKey).set(
                {
                  'telegramEnabled': true,
                  'telegramChatId': chatId,
                  'telegramUsername': username,
                  'telegramBotToken': trimmedToken,
                  'pairingCode': null,
                  'telegramPairedAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                },
                SetOptions(merge: true),
              );

              final roleLabel =
                  roleKey == 'student' ? 'Uczeń (Oskar)' : 'Rodzic';
              await sendTelegramDirectMessage(
                botToken: trimmedToken,
                chatId: chatId,
                htmlText:
                    '✅ <b>EduSync (Lepsza Szkoła) — Połączono!</b>\n\n'
                    'Twój czat Telegram został pomyślnie powiązany z kontem: <b>$roleLabel</b>.\n'
                    'Od teraz otrzymasz natychmiastowe powiadomienia o nowych ocenach, wiadomościach, sprawdzianach i czacie rodzinnym.',
              );

              return (
                paired: true,
                chatId: chatId,
                username: username,
                error: null,
              );
            }
          }
        }
      } catch (_) {
        // Fall through to Cloud Function
      }
    }

    // 2. Cloud Function fallback (uses server-side TELEGRAM_BOT_TOKEN if configured)
    try {
      final uri = Uri.parse('$_functionsBaseUrl/verifyTelegramPairing');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'familyId': familyId,
              'roleKey': roleKey,
              'pairingCode': trimmedCode,
              if (trimmedToken.isNotEmpty) 'botToken': trimmedToken,
            }),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['paired'] == true) {
        return (
          paired: true,
          chatId: data['chatId']?.toString(),
          username: data['username']?.toString(),
          error: null,
        );
      }
      return (
        paired: false,
        chatId: null,
        username: null,
        error: data['error']?.toString() ??
            'Nie wykryto jeszcze wiadomości "/start $trimmedCode" u bota.',
      );
    } catch (e) {
      return (
        paired: false,
        chatId: null,
        username: null,
        error:
            'Wyślij komendę "/start $trimmedCode" do bota na Telegramie lub wpisz swój Chat ID ręcznie poniżej.',
      );
    }
  }

  /// Sends an HTML message directly via Telegram Bot API or Cloud Function.
  Future<bool> sendTelegramDirectMessage({
    required String? botToken,
    required String chatId,
    required String htmlText,
  }) async {
    final trimmedToken = (botToken ?? '').trim();
    final trimmedChatId = chatId.trim();
    if (trimmedChatId.isEmpty) return false;

    if (trimmedToken.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://api.telegram.org/bot$trimmedToken/sendMessage',
        );
        final resp = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'chat_id': trimmedChatId,
                'text': htmlText,
                'parse_mode': 'HTML',
                'disable_web_page_preview': true,
              }),
            )
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) return true;
      } catch (_) {}
    }

    // Cloud Function fallback
    try {
      final uri = Uri.parse('$_functionsBaseUrl/sendTestTelegramNotification');
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'chatId': trimmedChatId,
              if (trimmedToken.isNotEmpty) 'botToken': trimmedToken,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sends a test Telegram notification to verify connection (`REQ-NOTIF-02`).
  Future<bool> sendTestTelegram({
    required NotificationChannelSettings settings,
    required String studentName,
  }) async {
    if (!settings.isTelegramPaired) return false;
    final roleLabel =
        settings.roleKey == 'student' ? 'Uczeń ($studentName)' : 'Rodzic';

    final htmlText =
        '🔔 <b>Test powiadomienia • EduSync (Lepsza Szkoła)</b>\n\n'
        'Kanał Telegram dla konta <b>$roleLabel</b> działa prawidłowo!\n\n'
        '📌 Przykład alertu:\n'
        '🎓 <b>Nowa ocena: 5 (Język angielski)</b>\n'
        '📝 Sprawdzian • Waga: 3 • Nauczyciel: M. Nowak\n\n'
        '🔗 <a href="https://lepsza-szkola.web.app/pulpit">Otwórz Pulpit EduSync</a>';

    return sendTelegramDirectMessage(
      botToken: settings.telegramBotToken,
      chatId: settings.telegramChatId!,
      htmlText: htmlText,
    );
  }

  /// Returns current browser notification permission (`granted`, `denied`, `default`, `unsupported`).
  String getWebPushPermission() => getBrowserNotificationPermission();

  /// Returns true if `/sw-notifications.js` Service Worker is registered.
  bool isSwActive() => isServiceWorkerReady();

  /// Requests browser notification permission and enables Web Push (`REQ-NOTIF-03`).
  Future<String> requestAndEnableWebPush({
    required String familyId,
    required String roleKey,
  }) async {
    final perm = await requestBrowserNotificationPermission();
    final enabled = perm == 'granted';

    await updateSettings(
      familyId: familyId,
      roleKey: roleKey,
      patch: {
        'webPushEnabled': enabled,
        'webPushPermissionStatus': perm,
      },
    );

    if (enabled) {
      showBrowserNotification(
        title: 'EduSync • Powiadomienia Web Push aktywne!',
        body:
            'Będziesz otrzymywać natychmiastowe powiadomienia o ocenach, wiadomościach i sprawdzianach w przeglądarce.',
        tag: 'edusync-webpush-welcome',
        url: '/pulpit',
      );
    }

    return perm;
  }

  /// Shows a native Web Push browser notification via Service Worker (`REQ-NOTIF-03`).
  bool triggerWebPush({
    required String title,
    required String body,
    String? tag,
    String? url,
  }) {
    return showBrowserNotification(
      title: title,
      body: body,
      tag: tag,
      url: url,
    );
  }
}
