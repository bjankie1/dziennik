import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationChannelSettings {
  final String familyId;
  final String roleKey; // 'parent' or 'student'
  final bool telegramEnabled;
  final String? telegramChatId;
  final String? telegramUsername;
  final String? telegramBotToken;
  final String telegramBotUsername;
  final String? pairingCode;
  final DateTime? pairingCodeExpiresAt;
  final bool webPushEnabled;
  final bool notifyGrades;
  final bool notifyMessages;
  final bool notifyExams;
  final bool notifyFamilyChat;
  final DateTime? telegramPairedAt;
  final DateTime? lastTelegramSentAt;

  const NotificationChannelSettings({
    required this.familyId,
    required this.roleKey,
    this.telegramEnabled = false,
    this.telegramChatId,
    this.telegramUsername,
    this.telegramBotToken,
    this.telegramBotUsername = 'EduSyncSzkolnyBot',
    this.pairingCode,
    this.pairingCodeExpiresAt,
    this.webPushEnabled = false,
    this.notifyGrades = true,
    this.notifyMessages = true,
    this.notifyExams = true,
    this.notifyFamilyChat = true,
    this.telegramPairedAt,
    this.lastTelegramSentAt,
  });

  bool get isTelegramPaired =>
      telegramChatId != null && telegramChatId!.trim().isNotEmpty;

  bool get hasActivePairingCode {
    if (pairingCode == null || pairingCode!.trim().isEmpty) return false;
    if (pairingCodeExpiresAt == null) return true;
    return pairingCodeExpiresAt!.isAfter(DateTime.now());
  }

  bool isCategoryEnabled(String type) {
    switch (type) {
      case 'grade':
        return notifyGrades;
      case 'message':
      case 'announcement':
        return notifyMessages;
      case 'exam':
        return notifyExams;
      case 'justification':
        return true;
      case 'family_chat':
        return notifyFamilyChat;
      default:
        return true;
    }
  }

  factory NotificationChannelSettings.fromFirestore(
    Map<String, dynamic>? data, {
    required String familyId,
    required String roleKey,
  }) {
    if (data == null) {
      return NotificationChannelSettings(
        familyId: familyId,
        roleKey: roleKey,
      );
    }

    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return NotificationChannelSettings(
      familyId: familyId,
      roleKey: roleKey,
      telegramEnabled: data['telegramEnabled'] == true,
      telegramChatId: data['telegramChatId']?.toString(),
      telegramUsername: data['telegramUsername']?.toString(),
      telegramBotToken: data['telegramBotToken']?.toString(),
      telegramBotUsername:
          (data['telegramBotUsername']?.toString() ?? '').trim().isNotEmpty
              ? data['telegramBotUsername'].toString().trim()
              : 'EduSyncSzkolnyBot',
      pairingCode: data['pairingCode']?.toString(),
      pairingCodeExpiresAt: parseDate(data['pairingCodeExpiresAt']),
      webPushEnabled: data['webPushEnabled'] == true,
      notifyGrades: data['notifyGrades'] != false,
      notifyMessages: data['notifyMessages'] != false,
      notifyExams: data['notifyExams'] != false,
      notifyFamilyChat: data['notifyFamilyChat'] != false,
      telegramPairedAt: parseDate(data['telegramPairedAt']),
      lastTelegramSentAt: parseDate(data['lastTelegramSentAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'roleKey': roleKey,
      'telegramEnabled': telegramEnabled,
      'telegramChatId': telegramChatId,
      'telegramUsername': telegramUsername,
      'telegramBotToken': telegramBotToken,
      'telegramBotUsername': telegramBotUsername,
      'pairingCode': pairingCode,
      'pairingCodeExpiresAt': pairingCodeExpiresAt != null
          ? Timestamp.fromDate(pairingCodeExpiresAt!)
          : null,
      'webPushEnabled': webPushEnabled,
      'notifyGrades': notifyGrades,
      'notifyMessages': notifyMessages,
      'notifyExams': notifyExams,
      'notifyFamilyChat': notifyFamilyChat,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class SchoolNotificationItem {
  final String id;
  final String type; // 'grade', 'message', 'announcement', 'exam', 'family_chat', 'system'
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  const SchoolNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  factory SchoolNotificationItem.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime ts = DateTime.now();
    final rawTs = data['timestamp'];
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    }

    return SchoolNotificationItem(
      id: id,
      type: (data['type'] ?? 'system').toString(),
      title: (data['title'] ?? 'Powiadomienie').toString(),
      body: (data['body'] ?? '').toString(),
      timestamp: ts,
      isRead: data['isRead'] == true,
    );
  }
}
