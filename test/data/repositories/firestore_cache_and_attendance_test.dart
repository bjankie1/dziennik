import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edusync/data/repositories/firestore/firestore_attendance_data_source.dart';
import 'package:edusync/data/repositories/firestore/firestore_grades_data_source.dart';
import 'package:edusync/data/repositories/firestore/firestore_justifications_data_source.dart';
import 'package:edusync/data/repositories/firestore/school_data_cache_manager.dart';
import 'package:edusync/domain/models/attendance_record.dart';
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

  group('SchoolDataCacheManager — Instance-Scoped Cache & Overrides (REQ-ARCH-04)', () {
    test('two instances maintain completely independent caches and overrides', () async {
      final cacheA = SchoolDataCacheManager();
      final cacheB = SchoolDataCacheManager();

      cacheA.seedMemoryCache({
        'login': '11010033',
        'timetable': [
          {'dayOfWeek': 1, 'lessonNumber': 1, 'subject': 'Matematyka'},
        ],
        'messages': [
          {'id': 'msg_1', 'isRead': false},
        ],
      });
      cacheB.seedMemoryCache({
        'login': '99999999',
        'timetable': [
          {'dayOfWeek': 1, 'lessonNumber': 1, 'subject': 'Fizyka'},
        ],
        'messages': [
          {'id': 'msg_1', 'isRead': false},
        ],
      }, targetLogin: '99999999');

      await cacheA.setReadOverride('msg_1', true);
      await cacheA.setJustificationOverrides(['att_1'], 'Choroba');
      cacheA.updateCachedMessageDriveAttachment(
        'msg_1',
        'zgoda.pdf',
        DriveAttachmentInfo(
          driveFileId: 'drive_1',
          webViewLink: 'https://drive.google.com/file/d/drive_1/view',
          savedAt: DateTime(2026, 9, 28, 10, 0),
        ),
      );

      // Verify cacheA has overrides applied
      expect(cacheA.getReadOverride('msg_1'), isTrue);
      expect(cacheA.getJustificationOverride('att_1'), 'Choroba');
      expect(
        cacheA.parseDriveAttachments(null, 'msg_1').containsKey('zgoda.pdf'),
        isTrue,
      );
      expect(
        (cacheA.memoryCache!['messages'] as List).first['isRead'],
        isTrue,
      );

      // Verify cacheB is completely isolated in memory
      expect(cacheB.getReadOverride('msg_1'), isNull);
      expect(cacheB.getJustificationOverride('att_1'), isNull);
      expect(cacheB.parseDriveAttachments(null, 'msg_1'), isEmpty);
      expect(
        (cacheB.memoryCache!['messages'] as List).first['isRead'],
        isFalse,
      );
      expect(cacheB.memoryCache!['login'], '99999999');
    });

    test('resetting SharedPreferences and constructing new instance loads clean state', () async {
      final cache1 = SchoolDataCacheManager();
      await cache1.setReadOverride('msg_old', true);
      await cache1.setJustificationOverrides(['att_old'], 'Stary powód');
      expect(cache1.getReadOverride('msg_old'), isTrue);
      expect(cache1.getJustificationOverride('att_old'), 'Stary powód');

      // Reset SharedPreferences (simulating a subsequent unit test or cleared session)
      SharedPreferences.setMockInitialValues({
        SchoolDataCacheManager.prefReadOverrides: jsonEncode({'msg_fresh': false}),
        SchoolDataCacheManager.prefJustificationOverrides:
            jsonEncode({'att_fresh': 'Nowy powód'}),
      });

      final cache2 = SchoolDataCacheManager();
      await cache2.ensureReadOverridesLoaded();
      await cache2.ensureJustificationOverridesLoaded();

      expect(cache2.getReadOverride('msg_old'), isNull);
      expect(cache2.getReadOverride('msg_fresh'), isFalse);
      expect(cache2.getJustificationOverride('att_old'), isNull);
      expect(cache2.getJustificationOverride('att_fresh'), 'Nowy powód');
    });

    test('TTL cache hit skips HTTP call and invalidateMemoryCache triggers fresh fetch', () async {
      int httpCallCount = 0;
      final mockClient = MockClient((request) async {
        httpCallCount++;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'login': '11010033',
              'luckyNumber': 24,
              'timetable': [
                {'dayOfWeek': 1, 'lessonNumber': 1, 'subject': 'Chemia'},
              ],
            }),
          ),
          200,
        );
      });

      final cache = SchoolDataCacheManager(
        httpClient: mockClient,
        cacheTtl: const Duration(minutes: 2),
      );

      cache.seedMemoryCache({
        'login': '11010033',
        'luckyNumber': 18,
        'timetable': [
          {'dayOfWeek': 1, 'lessonNumber': 1, 'subject': 'Matematyka'},
        ],
      }, targetLogin: '11010033');

      // 1. Within TTL -> returns cached map without hitting HTTP
      final hitData = await cache.getStudentData();
      expect(httpCallCount, 0);
      expect(hitData?['luckyNumber'], 18);

      // 2. After invalidation -> fetches fresh data from /api/studentData
      cache.invalidateMemoryCache();
      final freshData = await cache.getStudentData();
      expect(httpCallCount, 1);
      expect(freshData?['luckyNumber'], 24);
    });
  });

  group('FirestoreGradesDataSource (REQ-ARCH-03)', () {
    test('filters invalid subjects, resolves teachers from timetable, estimates percentage, and sorts recent grades', () async {
      final cache = SchoolDataCacheManager();
      cache.seedMemoryCache({
        'login': '11010033',
        'timetable': [
          {
            'dayOfWeek': 1,
            'lessonNumber': 2,
            'subject': 'Zastępstwo Fizyka',
            'teacher': 'Nowak Jan (JN)',
          },
        ],
        'subjects': [
          {'id': 'kat', 'name': 'Kategoria', 'grades': []},
          {'id': 'zach', 'name': 'Zachowanie', 'grades': []},
          {'id': 'suma', 'name': 'Suma punktów', 'grades': []},
          {
            'id': 'fiz',
            'name': 'Fizyka',
            'teacher': '',
            'currentAverage': 4.5,
            'grades': [
              {
                'id': 'g_older',
                'value': '4',
                'numericalValue': 4.0,
                'weight': 2,
                'category': 'kartkówka',
                'date': '2026-09-10',
                'rawTooltip': 'Kategoria: kartkówka<br>Waga: 2<br>Komentarz: Ruch jednostajny',
              },
              {
                'id': 'g_newer',
                'value': '5',
                'numericalValue': 5.0,
                'weight': 3,
                'category': 'sprawdzian',
                'date': '2026-09-25',
                'rawTooltip': 'Wynik: 94%<br>Komentarz: Dynamika',
              },
            ],
          },
        ],
      });

      final gradesDs = FirestoreGradesDataSource(cacheManager: cache);
      final subjects = await gradesDs.getSubjects();

      expect(subjects.length, 1);
      final fizyka = subjects.first;
      expect(fizyka.name, 'Fizyka');
      expect(fizyka.teacherName, 'Nowak Jan');
      expect(fizyka.grades.length, 2);

      final olderGrade = fizyka.grades.firstWhere((g) => g.id == 'g_older');
      expect(olderGrade.percentage, 75);
      expect(olderGrade.comment, 'Ruch jednostajny');
      expect(olderGrade.teacher, 'Nowak Jan');

      final newerGrade = fizyka.grades.firstWhere((g) => g.id == 'g_newer');
      expect(newerGrade.percentage, 94);
      expect(newerGrade.comment, 'Dynamika');

      final recent = await gradesDs.getRecentGrades();
      expect(recent.map((g) => g.id).toList(), ['g_newer', 'g_older']);
    });
  });

  group('FirestoreAttendanceDataSource (REQ-ARCH-03, REQ-ARCH-04)', () {
    test('enriches missing teacher/room/subject from timetable and applies justification overrides', () async {
      final submittedPayloads = <Map<String, dynamic>>[];
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/submitJustification') {
          submittedPayloads.add(
            jsonDecode(request.body) as Map<String, dynamic>,
          );
          return http.Response(jsonEncode({'ok': true}), 200);
        }
        return http.Response('{}', 404);
      });

      final cache = SchoolDataCacheManager(httpClient: mockClient);
      // 2026-09-21 is Monday (weekday == 1)
      cache.seedMemoryCache({
        'login': '11010033',
        'timetable': [
          {
            'dayOfWeek': 1,
            'lessonNumber': 1,
            'subject': 'odwołane Język polski',
            'teacher': 'Czajkowska Maria',
            'room': '204',
          },
          {
            'dayOfWeek': 1,
            'lessonNumber': 2,
            'subject': 'Matematyka',
            'teacher': 'Kowalski Piotr',
            'room': 'Sala szkolna',
          },
        ],
        'justifications': [
          {
            'period': '2026-09-21 (lekcja 2)',
            'status': 'Zaakceptowano',
            'content': 'Konkurs matematyczny',
          },
        ],
        'attendance': [
          {
            'id': 'att_1',
            'date': '2026-09-21',
            'lessonNumber': 1,
            'subjectName': 'Lekcja',
            'type': 'unexcused',
            'symbol': 'nb',
          },
          {
            'id': 'att_2',
            'date': '2026-09-21',
            'lessonNumber': 2,
            'subjectName': 'Matematyka',
            'type': 'unexcused',
            'symbol': 'nb',
            'classroom': 'Sala szkolna',
          },
        ],
      });

      final attendanceDs = FirestoreAttendanceDataSource(
        cacheManager: cache,
        httpClient: mockClient,
      );

      final records = await attendanceDs.getAttendanceRecords();
      expect(records.length, 2);

      final rec1 = records.firstWhere((r) => r.id == 'att_1');
      expect(rec1.subjectName, 'Język polski');
      expect(rec1.teacherName, 'Melska Grażyna');
      expect(rec1.classroom, '204');
      expect(rec1.type, AttendanceType.absent);
      expect(rec1.justificationStatus, JustificationStatus.none);

      final rec2 = records.firstWhere((r) => r.id == 'att_2');
      expect(rec2.teacherName, 'Kowalski Piotr');
      expect(rec2.classroom, isNull); // 'Sala szkolna' normalized to null
      expect(rec2.type, AttendanceType.excused);
      expect(rec2.justificationStatus, JustificationStatus.approved);
      expect(rec2.justificationReason, 'Konkurs matematyczny');

      // Submit justification for att_1
      await attendanceDs.submitJustification(['att_1'], 'Wizyta lekarska');
      expect(submittedPayloads.length, 1);
      expect(submittedPayloads.first['reason'], 'Wizyta lekarska');
      expect(submittedPayloads.first['hoursByDate'], {
        '2026-09-21': [1],
      });

      final afterSubmit = await attendanceDs.getAttendanceRecords();
      final updatedRec1 = afterSubmit.firstWhere((r) => r.id == 'att_1');
      expect(updatedRec1.justificationStatus, JustificationStatus.requested);
      expect(updatedRec1.justificationReason, 'Wizyta lekarska');

      // Cancel justification for att_1
      await attendanceDs.cancelJustification(['att_1']);
      final afterCancel = await attendanceDs.getAttendanceRecords();
      final cancelledRec1 = afterCancel.firstWhere((r) => r.id == 'att_1');
      expect(cancelledRec1.justificationStatus, JustificationStatus.none);
      expect(cancelledRec1.justificationReason, isNull);
    });
  });

  group('FirestoreJustificationsDataSource — Full & Partial PIN Approval (REQ-ARCH-03)', () {
    test('approveJustificationRequest with selectedRecordIds sends partial hoursByDate and removes deselected override', () async {
      final reviewPayloads = <Map<String, dynamic>>[];
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/reviewJustificationRequest') {
          reviewPayloads.add(
            jsonDecode(request.body) as Map<String, dynamic>,
          );
          return http.Response(jsonEncode({'ok': true}), 200);
        }
        return http.Response('{}', 404);
      });

      final cache = SchoolDataCacheManager(httpClient: mockClient);
      cache.seedMemoryCache({
        'login': '11010033',
        'timetable': [
          {
            'dayOfWeek': 2,
            'lessonNumber': 1,
            'subject': 'Chemia',
            'teacher': 'Pietrzak Michał',
          },
          {
            'dayOfWeek': 2,
            'lessonNumber': 2,
            'subject': 'Biologia',
            'teacher': 'Kowal Anna',
          },
        ],
        'attendance': [
          {
            'id': 'att_1',
            'date': '2026-09-22',
            'lessonNumber': 1,
            'subjectName': 'Chemia',
            'type': 'unexcused',
            'symbol': 'nb',
          },
          {
            'id': 'att_2',
            'date': '2026-09-22',
            'lessonNumber': 2,
            'subjectName': 'Biologia',
            'type': 'unexcused',
            'symbol': 'nb',
          },
        ],
        'justificationRequests': [
          {
            'id': 'req_partial_1',
            'studentLogin': '11010033u',
            'studentName': 'Oskar Jankiewicz',
            'familyId': 'jankiewicz_family',
            'primaryLogin': '11010033',
            'recordIds': ['att_1', 'att_2'],
            'lessonNumbers': [1, 2],
            'subjectNames': ['Chemia', 'Biologia'],
            'date': '2026-09-22',
            'reason': 'Badania kontrolne',
            'status': 'pendingParentApproval',
            'requestedAt': '2026-09-22T15:00:00.000',
          },
        ],
      });

      // Seed initial overrides on both att_1 and att_2 to verify deselected att_2 is removed
      await cache.setJustificationOverrides(
        ['att_1', 'att_2'],
        'Wstępna prośba',
      );
      expect(cache.getJustificationOverride('att_1'), 'Wstępna prośba');
      expect(cache.getJustificationOverride('att_2'), 'Wstępna prośba');

      final attendanceDs = FirestoreAttendanceDataSource(
        cacheManager: cache,
        httpClient: mockClient,
      );
      final justificationsDs = FirestoreJustificationsDataSource(
        cacheManager: cache,
        attendanceDataSource: attendanceDs,
        httpClient: mockClient,
      );

      final approved = await justificationsDs.approveJustificationRequest(
        'req_partial_1',
        '1234',
        selectedRecordIds: ['att_1'],
      );

      expect(approved, isTrue);
      expect(reviewPayloads.length, 1);
      final payload = reviewPayloads.first;
      expect(payload['requestId'], 'req_partial_1');
      expect(payload['action'], 'approve');
      expect(payload['pin'], '1234');
      expect(payload['selectedRecordIds'], ['att_1']);
      expect(payload['selectedLessonNumbers'], [1]);
      expect(payload['hoursByDate'], {
        '2026-09-22': [1],
      });

      // Selected att_1 keeps requested override with request reason; unselected att_2 is removed
      expect(cache.getJustificationOverride('att_1'), 'Badania kontrolne');
      expect(cache.getJustificationOverride('att_2'), isNull);
    });

    test('approveJustificationRequest without selectedRecordIds approves all request recordIds', () async {
      final reviewPayloads = <Map<String, dynamic>>[];
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/reviewJustificationRequest') {
          reviewPayloads.add(
            jsonDecode(request.body) as Map<String, dynamic>,
          );
          return http.Response(jsonEncode({'ok': true}), 200);
        }
        return http.Response('{}', 404);
      });

      final cache = SchoolDataCacheManager(httpClient: mockClient);
      cache.seedMemoryCache({
        'login': '11010033',
        'timetable': [
          {
            'dayOfWeek': 2,
            'lessonNumber': 1,
            'subject': 'Chemia',
            'teacher': 'Pietrzak Michał',
          },
          {
            'dayOfWeek': 2,
            'lessonNumber': 2,
            'subject': 'Biologia',
            'teacher': 'Kowal Anna',
          },
        ],
        'attendance': [
          {
            'id': 'att_1',
            'date': '2026-09-22',
            'lessonNumber': 1,
            'subjectName': 'Chemia',
            'type': 'unexcused',
            'symbol': 'nb',
          },
          {
            'id': 'att_2',
            'date': '2026-09-22',
            'lessonNumber': 2,
            'subjectName': 'Biologia',
            'type': 'unexcused',
            'symbol': 'nb',
          },
        ],
        'justificationRequests': [
          {
            'id': 'req_full_1',
            'studentLogin': '11010033u',
            'studentName': 'Oskar Jankiewicz',
            'familyId': 'jankiewicz_family',
            'primaryLogin': '11010033',
            'recordIds': ['att_1', 'att_2'],
            'lessonNumbers': [1, 2],
            'subjectNames': ['Chemia', 'Biologia'],
            'date': '2026-09-22',
            'reason': 'Choroba',
            'status': 'pendingParentApproval',
            'requestedAt': '2026-09-22T15:00:00.000',
          },
        ],
      });

      final attendanceDs = FirestoreAttendanceDataSource(
        cacheManager: cache,
        httpClient: mockClient,
      );
      final justificationsDs = FirestoreJustificationsDataSource(
        cacheManager: cache,
        attendanceDataSource: attendanceDs,
        httpClient: mockClient,
      );

      final approved = await justificationsDs.approveJustificationRequest(
        'req_full_1',
        '1234',
      );

      expect(approved, isTrue);
      expect(reviewPayloads.length, 1);
      final payload = reviewPayloads.first;
      expect(payload['selectedRecordIds'], ['att_1', 'att_2']);
      expect(payload['selectedLessonNumbers'], [1, 2]);
      expect(payload['hoursByDate'], {
        '2026-09-22': [1, 2],
      });
      expect(cache.getJustificationOverride('att_1'), 'Choroba');
      expect(cache.getJustificationOverride('att_2'), 'Choroba');
    });
  });
}
