import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edusync/data/repositories/firestore/firestore_messages_data_source.dart';
import 'package:edusync/data/repositories/firestore/school_data_cache_manager.dart';
import 'package:edusync/data/repositories/firestore_school_repository.dart';
import 'package:edusync/domain/models/message_thread.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'librus_is_connected': true,
      'librus_login_name': '11010033',
      'librus_demo_mode': false,
      'app_user_role': 'parent',
      'app_user_primary_login': '11010033',
    });
  });

  group('Message Archiving & Auto-Archive (REQ-MSG-ARCH-01, REQ-MSG-ARCH-02)', () {
    test(
      'MessageThread.isSystemJustificationConfirmation detects Librus justification confirmation messages',
      () {
        expect(
          MessageThread.isSystemJustificationConfirmation(
            sender: 'Usprawiedliwienia [System Librus]',
            subject: 'Zaakceptowano usprawiedliwienie nieobecności',
          ),
          isTrue,
        );
        expect(
          MessageThread.isSystemJustificationConfirmation(
            sender: 'Sobota Łukasz [Wychowawca]',
            subject: 'Usprawiedliwienie zostało zaakceptowane',
            body: 'Twoje usprawiedliwienie zostało zaakceptowane przez wychowawcę.',
          ),
          isTrue,
        );
        expect(
          MessageThread.isSystemJustificationConfirmation(
            sender: 'Sobota Łukasz [Wychowawca]',
            subject: 'Wycieczka klasowa',
            body: 'Proszę o dostarczenie zgód.',
          ),
          isFalse,
        );
      },
    );

    test(
      'auto-archives and marks as read system justification confirmation messages unless user unarchives',
      () async {
        final cache = SchoolDataCacheManager();
        cache.seedMemoryCache({
          'login': '11010033',
          'timetable': [
            {'dayOfWeek': 1, 'lessonNumber': 1, 'subject': 'Matematyka'},
          ],
          'messages': [
            {
              'id': 'msg_just_1',
              'sender': 'Usprawiedliwienia',
              'subject': 'Zaakceptowano usprawiedliwienie (2026-10-02)',
              'body': 'Wychowawca zaakceptował usprawiedliwienie nieobecności.',
              'date': '2026-10-02 10:00:00',
              'isRead': false,
            },
            {
              'id': 'msg_regular_1',
              'sender': 'Sobota Łukasz [Wychowawca]',
              'subject': 'Zebranie z rodzicami',
              'body': 'Zapraszam w czwartek o 17:00.',
              'date': '2026-10-02 12:00:00',
              'isRead': false,
            },
          ],
        });

        final dataSource = FirestoreMessagesDataSource(cacheManager: cache);
        final threads = await dataSource.getMessages();

        final justMsg = threads.firstWhere((m) => m.id == 'msg_just_1');
        expect(justMsg.isAutoArchived, isTrue);
        expect(justMsg.isArchived, isTrue);
        expect(
          justMsg.isUnread,
          isFalse,
          reason: 'Auto-archived justification confirmations must be marked read (D-03)',
        );

        final regMsg = threads.firstWhere((m) => m.id == 'msg_regular_1');
        expect(regMsg.isAutoArchived, isFalse);
        expect(regMsg.isArchived, isFalse);
        expect(regMsg.isUnread, isTrue);

        // User explicitly unarchives the auto-archived message
        await dataSource.archiveMessage('msg_just_1', isArchived: false);
        final afterUnarchive = await dataSource.getMessages();
        final restoredMsg = afterUnarchive.firstWhere((m) => m.id == 'msg_just_1');
        expect(restoredMsg.isArchived, isFalse);
      },
    );

    test(
      'manual archiveMessage persists to SharedPreferences and memoryCache',
      () async {
        final repo = FirestoreSchoolRepository();
        repo.cacheManager.seedMemoryCache({
          'login': '11010033',
          'timetable': [
            {'dayOfWeek': 1, 'lessonNumber': 1, 'subject': 'Matematyka'},
          ],
          'messages': [
            {
              'id': 'msg_100',
              'sender': 'Kowalska Anna',
              'subject': 'Konkurs matematyczny',
              'body': 'Szczegóły konkursu.',
              'date': '2026-10-01 09:00:00',
              'isRead': true,
            },
          ],
        });

        await repo.archiveMessage('msg_100', isArchived: true);

        final threads = await repo.getMessages();
        expect(threads.single.isArchived, isTrue);
        expect(
          repo.cacheManager.memoryCache?['archivedMessageOverrides']?['msg_100'],
          isTrue,
        );

        final prefs = await SharedPreferences.getInstance();
        final saved = json.decode(
          prefs.getString(SchoolDataCacheManager.prefArchiveOverrides) ?? '{}',
        ) as Map<String, dynamic>;
        expect(saved['msg_100'], isTrue);
      },
    );
  });
}
