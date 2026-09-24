import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_channels_service.dart';
import '../../domain/models/notification_settings.dart';
import 'auth_providers.dart';

final notificationChannelsServiceProvider =
    Provider<NotificationChannelsService>((ref) {
  return NotificationChannelsService();
});

/// Resolves the canonical student document ID in Firestore (`students/{docId}`)
/// where `sync_service.js` stores notifications and `notification_settings`.
final notificationFamilyDocIdProvider = Provider<String>((ref) {
  final user = ref.watch(appUserProvider);
  final primary = user?.primaryLogin?.trim() ?? '';
  if (primary.isNotEmpty && primary != '7654321r') {
    return primary.replaceAll(RegExp(r'u$', caseSensitive: false), '');
  }
  return '11010033';
});

/// Resolves the active role key (`parent` or `student`) for independent channel settings (`REQ-NOTIF-01`).
final notificationRoleKeyProvider = Provider<String>((ref) {
  final user = ref.watch(appUserProvider);
  return (user?.isStudent ?? false) ? 'student' : 'parent';
});

/// Live Firestore stream of the current user's notification settings (`Telegram Bot` + `Web Push` + categories).
final notificationChannelSettingsProvider =
    StreamProvider<NotificationChannelSettings>((ref) {
  final docId = ref.watch(notificationFamilyDocIdProvider);
  final roleKey = ref.watch(notificationRoleKeyProvider);

  try {
    return FirebaseFirestore.instance
        .collection('students')
        .doc(docId)
        .collection('notification_settings')
        .doc(roleKey)
        .snapshots()
        .map(
          (snap) => NotificationChannelSettings.fromFirestore(
            snap.data(),
            familyId: docId,
            roleKey: roleKey,
          ),
        );
  } catch (_) {
    return Stream.value(
      NotificationChannelSettings(familyId: docId, roleKey: roleKey),
    );
  }
});

/// Live Firestore stream of school notifications (`students/{docId}/notifications`).
final schoolNotificationsStreamProvider =
    StreamProvider<List<SchoolNotificationItem>>((ref) {
  final docId = ref.watch(notificationFamilyDocIdProvider);

  try {
    return FirebaseFirestore.instance
        .collection('students')
        .doc(docId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(25)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => SchoolNotificationItem.fromFirestore(d.id, d.data()))
              .toList(),
        );
  } catch (_) {
    return Stream.value(const <SchoolNotificationItem>[]);
  }
});

/// Count of unread school notifications.
final unreadSchoolNotificationsCountProvider = Provider<int>((ref) {
  final items = ref.watch(schoolNotificationsStreamProvider).value ?? const [];
  return items.where((item) => !item.isRead).length;
});
