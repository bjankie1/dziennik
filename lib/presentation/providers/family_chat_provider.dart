import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_message.dart';
import 'auth_providers.dart';

/// Repository for real-time Family Chat operations in Firestore (REQ-CHAT-01, D-01, D-04).
class FamilyChatRepository {
  final FirebaseFirestore _firestore;

  FamilyChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final List<ChatMessage> _fallbackMessages = [
    ChatMessage(
      id: 'mock_chat_1',
      familyId: 'jankiewicz_family',
      senderId: 'parent_tata',
      senderName: 'Tata',
      senderRole: 'parent',
      text: 'Cześć Oskar, jak poszła dzisiejsza kartkówka z geografii?',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isReadByStudent: true,
      isReadByParent: true,
    ),
    ChatMessage(
      id: 'mock_chat_2',
      familyId: 'jankiewicz_family',
      senderId: '1234567u',
      senderName: 'Oskar',
      senderRole: 'student',
      text: 'Dostałem 5! Pytania były z mapy Europy.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
      isReadByStudent: true,
      isReadByParent: true,
    ),
  ];

  Stream<List<ChatMessage>> watchMessages(String familyId) async* {
    yield List<ChatMessage>.unmodifiable(_fallbackMessages);
    try {
      final stream = _firestore
          .collection('family_chats')
          .doc(familyId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .limit(100)
          .snapshots();

      await for (final snapshot in stream) {
        if (snapshot.docs.isEmpty) {
          yield List<ChatMessage>.unmodifiable(_fallbackMessages);
        } else {
          final list = snapshot.docs
              .map((doc) => ChatMessage.fromJson(doc.data(), doc.id))
              .toList();
          yield List<ChatMessage>.unmodifiable(list);
        }
      }
    } catch (e) {
      debugPrint('[FamilyChatRepository] watchMessages error: $e');
      yield List<ChatMessage>.unmodifiable(_fallbackMessages);
    }
  }

  Future<bool> sendMessage({
    required String familyId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
    ChatMessageType type = ChatMessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      familyId: familyId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      text: text.trim(),
      createdAt: DateTime.now(),
      type: type,
      metadata: metadata,
      isReadByStudent: senderRole.toLowerCase() == 'student',
      isReadByParent: senderRole.toLowerCase() == 'parent',
    );

    try {
      await _firestore
          .collection('family_chats')
          .doc(familyId)
          .collection('messages')
          .add(msg.toJson());
      return true;
    } catch (e) {
      debugPrint('[FamilyChatRepository] sendMessage firestore error: $e');
      _fallbackMessages.add(msg);
      return true;
    }
  }

  Future<void> markMessagesAsRead({
    required String familyId,
    required bool isStudent,
  }) async {
    try {
      final fieldToUpdate = isStudent ? 'isReadByStudent' : 'isReadByParent';
      final unreadSnap = await _firestore
          .collection('family_chats')
          .doc(familyId)
          .collection('messages')
          .where(fieldToUpdate, isEqualTo: false)
          .limit(50)
          .get();

      if (unreadSnap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in unreadSnap.docs) {
          batch.update(doc.reference, {fieldToUpdate: true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('[FamilyChatRepository] markMessagesAsRead error: $e');
      for (var i = 0; i < _fallbackMessages.length; i++) {
        final m = _fallbackMessages[i];
        if (isStudent && !m.isReadByStudent) {
          _fallbackMessages[i] = m.copyWith(isReadByStudent: true);
        } else if (!isStudent && !m.isReadByParent) {
          _fallbackMessages[i] = m.copyWith(isReadByParent: true);
        }
      }
    }
  }
}

final familyChatRepositoryProvider = Provider<FamilyChatRepository>((ref) {
  return FamilyChatRepository();
});

/// Live stream of messages for the currently logged in user's family
final familyChatMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  final user = ref.watch(appUserProvider);
  final familyId = user?.familyId ?? 'jankiewicz_family';
  final repo = ref.watch(familyChatRepositoryProvider);
  return repo.watchMessages(familyId);
});

/// Unread count for the current user (REQ-CHAT-01, D-04)
final familyChatUnreadCountProvider = Provider<int>((ref) {
  final user = ref.watch(appUserProvider);
  final isStudent = user?.isStudent ?? false;
  final messagesAsync = ref.watch(familyChatMessagesProvider);
  final messages = messagesAsync.value ?? [];

  return messages.where((m) {
    if (isStudent) {
      return !m.isReadByStudent && m.senderRole != 'student';
    } else {
      return !m.isReadByParent && m.senderRole != 'parent';
    }
  }).length;
});
