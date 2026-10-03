import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edusync/data/repositories/firestore_school_repository.dart';
import 'package:edusync/data/repositories/firestore/firestore_attendance_data_source.dart';
import 'package:edusync/data/repositories/firestore/firestore_grades_data_source.dart';
import 'package:edusync/data/repositories/firestore/firestore_messages_data_source.dart';
import 'package:edusync/data/repositories/firestore/firestore_schedule_data_source.dart';
import 'package:edusync/data/repositories/firestore/school_data_cache_manager.dart';
import 'package:edusync/domain/models/attendance_record.dart';
import 'package:edusync/domain/models/lesson_slot.dart';

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

  group('FirestoreMessagesDataSource (REQ-ARCH-03, REQ-ARCH-04)', () {
    test(
      'getMessages parses sender roles, bracket signatures, attachments, and read overrides',
      () async {
        final cache = SchoolDataCacheManager();
        cache.seedMemoryCache({
          'login': '11010033',
          'timetable': [
            {'dayOfWeek': 1, 'lessonNumber': 1, 'subject': 'Matematyka'},
          ],
          'messages': [
            {
              'id': 'msg_dir',
              'sender': 'Jan Kowalski [Dyrektor]',
              'subject': 'PILNE: Zebranie ogólne',
              'body': 'Zapraszam na zebranie.',
              'date': '2026-09-10 14:20:00',
              'isRead': true,
              'attachmentFiles': [
                {'name': 'harmonogram.pdf', 'path': '/pobierz/1'},
              ],
            },
            {
              'id': 'msg_educator',
              'sender': 'Sobota Łukasz [Wychowawca]',
              'subject': 'Wycieczka do Warszawy',
              'body': 'Proszę o wpłatę zaliczki.',
              'date': '2026-09-11 08:15:00',
              'isRead': false,
            },
            {
              'id': 'msg_admin_sig',
              'sender': '[Administrator szkoły]',
              'subject': 'Ubezpieczenie szkolne',
              'body':
                  'Informacja o składce.\nPozdrawiam\nKamila Buczek - szkolna Rada Rodziców',
              'date': '2026-09-12 10:00:00',
              'isRead': true,
            },
          ],
        });

        final dataSource = FirestoreMessagesDataSource(cacheManager: cache);
        final messages = await dataSource.getMessages();

        expect(messages, hasLength(3));

        final dirMsg = messages.firstWhere((m) => m.id == 'msg_dir');
        expect(dirMsg.senderRole, 'Dyrektor Szkoły');
        expect(dirMsg.senderName, 'Jan Kowalski');
        expect(dirMsg.senderInitials, 'JK');
        expect(dirMsg.isImportant, isTrue);
        expect(dirMsg.isUnread, isFalse);
        expect(dirMsg.attachments, ['harmonogram.pdf']);
        expect(dirMsg.attachmentUrls['harmonogram.pdf'], '/pobierz/1');

        final eduMsg = messages.firstWhere((m) => m.id == 'msg_educator');
        expect(eduMsg.senderRole, 'Wychowawca');
        expect(eduMsg.senderName, 'Sobota Łukasz');
        expect(eduMsg.isUnread, isTrue);

        final adminMsg = messages.firstWhere((m) => m.id == 'msg_admin_sig');
        expect(adminMsg.senderRole, 'Administrator szkoły');
        expect(
          adminMsg.senderName,
          'Kamila Buczek - szkolna Rada Rodziców (Administrator szkoły)',
        );
      },
    );

    test(
      'parseMessageDate handles SQL/ISO, DMY, and Firestore Timestamp map formats',
      () {
        final sqlDt =
            FirestoreMessagesDataSource.parseMessageDate('2026-09-28 09:54:12');
        expect(sqlDt.year, 2026);
        expect(sqlDt.month, 9);
        expect(sqlDt.day, 28);
        expect(sqlDt.hour, 9);
        expect(sqlDt.minute, 54);
        expect(sqlDt.second, 12);

        final dmyDt =
            FirestoreMessagesDataSource.parseMessageDate('28.09.2026 14:30');
        expect(dmyDt.year, 2026);
        expect(dmyDt.month, 9);
        expect(dmyDt.day, 28);
        expect(dmyDt.hour, 14);
        expect(dmyDt.minute, 30);

        final tsMapDt = FirestoreMessagesDataSource.parseMessageDate({
          '_seconds': 1790589252,
        });
        expect(
          tsMapDt,
          DateTime.fromMillisecondsSinceEpoch(
            1790589252 * 1000,
            isUtc: true,
          ).toLocal(),
        );
      },
    );

    test(
      'markMessageAsRead and markAllMessagesAsRead update cacheManager overrides and in-memory messages',
      () async {
        final cache = SchoolDataCacheManager();
        cache.seedMemoryCache({
          'login': '11010033',
          'timetable': [
            {'dayOfWeek': 1, 'lessonNumber': 1, 'subject': 'Matematyka'},
          ],
          'messages': [
            {
              'id': 'msg_1',
              'sender': 'Sobota Łukasz',
              'subject': 'Wiadomość 1',
              'date': '2026-09-10 08:00:00',
              'isRead': false,
            },
            {
              'id': 'msg_2',
              'sender': 'Pietrzak Michał',
              'subject': 'Wiadomość 2',
              'date': '2026-09-10 09:00:00',
              'isRead': false,
            },
          ],
        });

        final dataSource = FirestoreMessagesDataSource(cacheManager: cache);

        await dataSource.markMessageAsRead('msg_1', isRead: true);
        expect(cache.getReadOverride('msg_1'), isTrue);

        var list = await dataSource.getMessages();
        expect(list.firstWhere((m) => m.id == 'msg_1').isUnread, isFalse);
        expect(list.firstWhere((m) => m.id == 'msg_2').isUnread, isTrue);

        await dataSource.markAllMessagesAsRead();
        expect(cache.getReadOverride('msg_2'), isTrue);

        list = await dataSource.getMessages();
        expect(list.every((m) => !m.isUnread), isTrue);
      },
    );

    test(
      'saveAttachmentToDrive and moveDriveAttachment update cached driveAttachments via MockClient',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('saveAttachmentToDrive')) {
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'driveAttachment': {
                    'driveFileId': 'file_123',
                    'webViewLink': 'https://drive.google.com/file/d/file_123',
                    'folderId': 'folder_abc',
                    'folderName': 'Szkoła 2026',
                    'savedAt': '2026-09-29T10:00:00.000Z',
                    'savedBy': 'Rodzic',
                  },
                }),
              ),
              200,
            );
          }
          if (request.url.path.contains('driveFolder')) {
            return http.Response.bytes(
              utf8.encode(jsonEncode({'ok': true})),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final cache = SchoolDataCacheManager(httpClient: mockClient);
        cache.seedMemoryCache({
          'login': '11010033',
          'timetable': [
            {'dayOfWeek': 1, 'lessonNumber': 1, 'subject': 'Matematyka'},
          ],
          'messages': [
            {
              'id': 'msg_drive',
              'sender': 'Sobota Łukasz',
              'subject': 'Plik do pobrania',
              'date': '2026-09-10 12:00:00',
              'isRead': true,
              'attachments': ['regulamin.pdf'],
            },
          ],
        });

        final dataSource = FirestoreMessagesDataSource(
          cacheManager: cache,
          httpClient: mockClient,
        );

        final savedInfo = await dataSource.saveAttachmentToDrive(
          msgId: 'msg_drive',
          attachmentName: 'regulamin.pdf',
          downloadPath: '/pobierz/regulamin',
          accessToken: 'ya29.mock_token',
          folderId: 'folder_abc',
          folderName: 'Szkoła 2026',
        );

        expect(savedInfo.driveFileId, 'file_123');
        expect(savedInfo.folderName, 'Szkoła 2026');

        var messages = await dataSource.getMessages();
        final thread = messages.firstWhere((m) => m.id == 'msg_drive');
        expect(
          thread.driveAttachments['regulamin.pdf']?.folderId,
          'folder_abc',
        );

        await dataSource.moveDriveAttachment(
          accessToken: 'ya29.mock_token',
          msgId: 'msg_drive',
          attachmentNames: ['regulamin.pdf'],
          currentDriveAttachments: thread.driveAttachments,
          targetFolderId: 'folder_xyz',
          targetFolderName: 'Dokumenty Oskara',
          setAsDefault: true,
        );

        messages = await dataSource.getMessages();
        final updatedThread = messages.firstWhere((m) => m.id == 'msg_drive');
        expect(
          updatedThread.driveAttachments['regulamin.pdf']?.folderId,
          'folder_xyz',
        );
        expect(
          updatedThread.driveAttachments['regulamin.pdf']?.folderName,
          'Dokumenty Oskara',
        );

        final defaultFolder = await dataSource.getDefaultDriveFolder();
        expect(defaultFolder.id, 'folder_xyz');
        expect(defaultFolder.name, 'Dokumenty Oskara');
      },
    );
  });

  group('FirestoreScheduleDataSource (REQ-ARCH-03)', () {
    late SchoolDataCacheManager cache;
    late FirestoreGradesDataSource gradesDS;
    late FirestoreAttendanceDataSource attendanceDS;
    late FirestoreScheduleDataSource scheduleDS;

    setUp(() {
      cache = SchoolDataCacheManager();
      cache.seedMemoryCache({
        'login': '11010033',
        'luckyNumber': 18,
        'overallAverage': 4.85,
        'unreadMessagesCount': 3,
        'lastSyncTime': '2026-09-29T07:30:00.000Z',
        'student': {
          'id': '11010033',
          'name': 'Oskar Jankiewicz',
          'className': '4 k Lic',
          'schoolName': 'LO nr X we Wrocławiu',
          'educator': 'Sobota Łukasz',
        },
        'attendanceStats': {'percentage': 96.4},
        'timetable': [
          {
            'dayOfWeek': 1,
            'lessonNumber': 1,
            'time': '08:00 - 08:45',
            'subject': 'odwołane Matematyka',
            'teacher': 'Sobota Łukasz',
            'room': '204',
            'isCancelled': true,
          },
          {
            'dayOfWeek': 2,
            'lessonNumber': 2,
            'time': '08:55 - 09:40',
            'subject': 'zastępstwo Język polski',
            'teacher': 'Czajkowska Maria',
            'room': '105',
            'isCancelled': false,
          },
          {
            'dayOfWeek': 3,
            'lessonNumber': 3,
            'time': '09:50 - 10:35',
            'subject': 'Język angielski',
            'teacher': 'Kowalska Anna',
            'room': '301',
            'isCancelled': false,
          },
        ],
        'events': [
          {
            'date': '2026-09-23',
            'lessonNumber': 3,
            'type': 'sprawdzian',
            'subject': 'Nr lekcji: 3sprawdzian4KL',
            'rawText': 'Nr lekcji: 3sprawdzian4KL, Język angielski',
            'description': 'Czasy Present Perfect i Past Simple',
            'teacher': 'Kowalska Anna',
          },
        ],
        'upcomingExam': {
          'date': '2026-09-23',
          'lessonNumber': 3,
          'type': 'sprawdzian',
          'subject': 'Nr lekcji: 0sprawdzian4KL',
          'rawText': 'Nr lekcji: 0sprawdzian4KL, Język angielski',
          'description': 'Unit 1-2 Grammar Test',
          'teacher': 'Kowalska Anna',
        },
        'attendance': [
          {
            'id': 'att_wed_3',
            'date': '2026-09-23',
            'lessonNumber': 3,
            'subjectName': 'Język angielski',
            'type': 'late',
            'symbol': 'sp',
            'teacher': 'Kowalska Anna',
          },
          {
            'id': 'att_extra_teacher',
            'date': '2026-09-24',
            'lessonNumber': 4,
            'subjectName': 'Fizyka',
            'type': 'present',
            'symbol': 'ob',
            'teacher': 'Nowak Piotr',
          },
        ],
        'subjects': [
          {
            'id': 'chemia',
            'name': 'Chemia',
            'teacher': 'Pietrzak Michał',
            'currentAverage': 5.0,
            'grades': [],
          },
        ],
        'announcements': [
          {
            'id': 'ann_1',
            'title': 'Dzień Edukacji Narodowej',
            'author': 'Dyrekcja',
            'date': '2026-09-25 10:00:00',
            'content': 'Dzień wolny od zajęć dydaktycznych.',
          },
        ],
      });

      gradesDS = FirestoreGradesDataSource(cacheManager: cache);
      attendanceDS = FirestoreAttendanceDataSource(cacheManager: cache);
      scheduleDS = FirestoreScheduleDataSource(
        cacheManager: cache,
        attendanceDataSource: attendanceDS,
        gradesDataSource: gradesDS,
      );
    });

    test(
      'getStudentProfile, cleanEventSubjectName, and getUpcomingExam resolve clean domain models',
      () async {
        final profile = await scheduleDS.getStudentProfile();
        expect(profile.id, '11010033');
        expect(profile.name, 'Oskar Jankiewicz');
        expect(profile.luckyNumber, 18);
        expect(profile.overallAverage, 4.85);
        expect(profile.attendancePercentage, 96.4);
        expect(profile.unreadMessagesCount, 3);
        expect(profile.lastSyncTime, isNotNull);

        final cleaned = scheduleDS.cleanEventSubjectName(
          {
            'subject': 'Nr lekcji: 0sprawdzian4KL',
            'rawText': 'Nr lekcji: 0sprawdzian4KL, Język angielski',
          },
          cache.memoryCache!['timetable'] as List<dynamic>,
        );
        expect(cleaned, 'Język angielski');

        final exam = await scheduleDS.getUpcomingExam();
        expect(exam, isNotNull);
        expect(exam!.subject, 'Język angielski');
        expect(exam.title, 'Unit 1-2 Grammar Test');
        expect(exam.type, 'Sprawdzian');
      },
    );

    test(
      'getWeekSchedule distinguishes Warsaw trip week (2026-09-14) from regular week (2026-09-21) and overlays events & attendance',
      () async {
        // 1. Warsaw school trip week (Monday 2026-09-14)
        final tripWeek = await scheduleDS.getWeekSchedule(
          weekStart: DateTime(2026, 9, 14),
        );
        final tripMonday = tripWeek[1]!.first;
        expect(tripMonday.subjectName, 'odwołane Matematyka');
        expect(tripMonday.status, LessonStatus.canceled);
        expect(tripMonday.statusNote, 'Lekcja odwołana (Wycieczka)');

        final tripTuesday = tripWeek[2]!.first;
        expect(tripTuesday.subjectName, 'Język polski');
        expect(tripTuesday.status, LessonStatus.substituted);
        expect(tripTuesday.teacher, 'Melska Grażyna');
        expect(tripTuesday.substituteTeacher, 'Czajkowska Maria');

        // 2. Regular week (Monday 2026-09-21)
        final normalWeek = await scheduleDS.getWeekSchedule(
          weekStart: DateTime(2026, 9, 21),
        );
        final normalMonday = normalWeek[1]!.first;
        expect(normalMonday.subjectName, 'Matematyka');
        expect(normalMonday.status, LessonStatus.normal);

        final normalTuesday = normalWeek[2]!.first;
        expect(normalTuesday.subjectName, 'Język polski');
        expect(normalTuesday.status, LessonStatus.normal);
        expect(normalTuesday.teacher, 'Melska Grażyna');
        expect(normalTuesday.substituteTeacher, isNull);

        // Wednesday 2026-09-23 has Sprawdzian event + late attendance overlay
        final normalWednesday = normalWeek[3]!.first;
        expect(normalWednesday.subjectName, 'Język angielski');
        expect(normalWednesday.eventType, 'Sprawdzian');
        expect(
          normalWednesday.eventTitle,
          'Czasy Present Perfect i Past Simple',
        );
        expect(normalWednesday.attendanceType, AttendanceType.late);
      },
    );

    test(
      'getAnnouncements and getTeachers deduplicate across educator, timetable, subjects, and attendance',
      () async {
        final announcements = await scheduleDS.getAnnouncements();
        expect(announcements, hasLength(1));
        expect(announcements.first.title, 'Dzień Edukacji Narodowej');
        expect(announcements.first.publishedDate.year, 2026);

        final teachers = await scheduleDS.getTeachers();
        final teacherNames = teachers.map((t) => t.name).toList();
        expect(teacherNames, contains('Sobota Łukasz'));
        expect(teacherNames, contains('Czajkowska Maria'));
        expect(teacherNames, contains('Kowalska Anna'));
        expect(teacherNames, contains('Pietrzak Michał'));
        expect(teacherNames, contains('Nowak Piotr'));
        // Educator Sobota Łukasz appears both as educator and in timetable -> deduplicated
        expect(
          teacherNames.where((n) => n == 'Sobota Łukasz').length,
          1,
        );
      },
    );
  });

  group('FirestoreSchoolRepository Facade & Isolation (REQ-ARCH-03, REQ-ARCH-04)', () {
    test('firestore_school_repository.dart is strictly under 250 LOC', () {
      final file = File('lib/data/repositories/firestore_school_repository.dart');
      expect(file.existsSync(), isTrue);
      final lineCount = file.readAsLinesSync().length;
      expect(
        lineCount,
        lessThan(250),
        reason:
            'FirestoreSchoolRepository facade must be < 250 LOC (actual: $lineCount)',
      );
    });

    test(
      'delegates SchoolRepository methods and isolates state between two repository instances',
      () async {
        final repoA = FirestoreSchoolRepository();
        final repoB = FirestoreSchoolRepository();

        repoA.cacheManager.seedMemoryCache({
          'login': '11010033',
          'luckyNumber': 7,
          'student': {'name': 'Oskar Jankiewicz', 'className': '4 k Lic'},
          'timetable': [
            {
              'dayOfWeek': 1,
              'lessonNumber': 1,
              'subject': 'Chemia',
              'teacher': 'Pietrzak Michał',
            },
          ],
          'messages': [
            {
              'id': 'msg_shared_id',
              'sender': 'Pietrzak Michał',
              'subject': 'Kartkówka z chemii',
              'date': '2026-09-15 10:00:00',
              'isRead': false,
            },
          ],
        });

        repoB.cacheManager.seedMemoryCache({
          'login': '22020044',
          'luckyNumber': 21,
          'student': {'name': 'Inny Uczeń', 'className': '2 a Lic'},
          'timetable': [
            {
              'dayOfWeek': 1,
              'lessonNumber': 1,
              'subject': 'Biologia',
              'teacher': 'Nowak Ewa',
            },
          ],
          'messages': [
            {
              'id': 'msg_shared_id',
              'sender': 'Nowak Ewa',
              'subject': 'Kartkówka z biologii',
              'date': '2026-09-15 10:00:00',
              'isRead': false,
            },
          ],
        });

        final profileA = await repoA.getStudentProfile();
        final profileB = await repoB.getStudentProfile();
        expect(profileA.luckyNumber, 7);
        expect(profileB.luckyNumber, 21);

        // Initialize repoB's read overrides before repoA mutates SharedPreferences
        await repoB.cacheManager.ensureReadOverridesLoaded();

        // Mark message as read in repoA only
        await repoA.markMessageAsRead('msg_shared_id', isRead: true);

        final msgsA = await repoA.getMessages();
        final msgsB = await repoB.getMessages();
        expect(msgsA.first.isUnread, isFalse);
        expect(msgsB.first.isUnread, isTrue);

        // Static forwarder works identically
        final parsed =
            FirestoreSchoolRepository.parseMessageDate('2026-09-28 09:54:12');
        expect(
          parsed,
          FirestoreMessagesDataSource.parseMessageDate('2026-09-28 09:54:12'),
        );
      },
    );
  });
}
