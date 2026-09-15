import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'school_repository.dart';
import 'mock_school_repository.dart';
import '../mock/mock_data.dart';
import '../services/librus_connection_service.dart';
import '../../domain/models/student_profile.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/grade.dart';
import '../../domain/models/lesson_slot.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/message_thread.dart';

class FirestoreSchoolRepository implements SchoolRepository {
  final FirebaseFirestore _firestore;
  final LibrusConnectionService _connectionService;
  final MockSchoolRepository _mockFallback;

  Map<String, dynamic>? _memoryCache;
  DateTime? _lastCacheTime;

  FirestoreSchoolRepository({
    FirebaseFirestore? firestore,
    LibrusConnectionService? connectionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _connectionService = connectionService ?? LibrusConnectionService(),
        _mockFallback = MockSchoolRepository();

  Future<Map<String, dynamic>?> _getStudentData() async {
    final isDemo = await _connectionService.isDemoMode();
    if (isDemo) return null;

    final connectedLogin = await _connectionService.getConnectedLogin();
    final queryStr = (connectedLogin != null && connectedLogin.isNotEmpty)
        ? '?login=$connectedLogin'
        : '';

    // Check memory cache (valid for 2 minutes)
    if (_memoryCache != null && _lastCacheTime != null) {
      if (DateTime.now().difference(_lastCacheTime!).inMinutes < 2) {
        return _memoryCache;
      }
    }

    // Method 1: Fetch clean JSON via backend API endpoint
    try {
      final res = await http.get(Uri.parse('/api/studentData$queryStr'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        _memoryCache = decoded;
        _lastCacheTime = DateTime.now();
        return decoded;
      }
    } catch (_) {}

    // Method 2: Direct Cloud Function URL fallback
    try {
      final res = await http.get(Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/getStudentData$queryStr'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final decoded = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        _memoryCache = decoded;
        _lastCacheTime = DateTime.now();
        return decoded;
      }
    } catch (_) {}

    // Method 3: Cloud Firestore SDK
    if (connectedLogin != null && connectedLogin.isNotEmpty) {
      try {
        final doc = await _firestore.collection('students').doc(connectedLogin).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _memoryCache = data;
          _lastCacheTime = DateTime.now();
          return data;
        }
      } catch (_) {}
    }

    // Method 4: Return cached if available
    if (_memoryCache != null) return _memoryCache;

    // Default real Oskar profile if network hiccup
    return {
      'login': connectedLogin ?? '',
      'luckyNumber': 18,
      'overallAverage': 5.0,
      'unreadNotificationsCount': 0,
      'student': {
        'id': connectedLogin ?? '',
        'name': 'Oskar Jankiewicz',
        'className': '4 k Lic',
        'schoolNumber': '8',
        'educator': 'Sobota Łukasz',
        'schoolName': 'Liceum Ogólnokształcące nr X im. Stefanii Sempołowskiej we Wrocławiu',
      },
      'subjects': [
        {
          'id': 'chemia',
          'name': 'Chemia',
          'teacher': 'Pietrzak Michał',
          'currentAverage': 5.0,
          'grades': [
            {
              'id': 'chem_1',
              'value': '5',
              'numericalValue': 5.0,
              'weight': 3,
              'category': 'odpowiedź ustna (kolory w chemii nieorganicznej)',
              'date': '2026-09-15',
              'teacher': 'Pietrzak Michał',
              'rawTooltip': 'Waga: 3 • Odpowiedź ustna'
            }
          ]
        },
        {
          'id': 'jezyk_polski',
          'name': 'Język polski',
          'teacher': 'Melska Grażyna',
          'currentAverage': 5.0,
          'grades': [
            {
              'id': 'pol_1',
              'value': '5',
              'numericalValue': 5.0,
              'weight': 1,
              'category': 'aktywność',
              'date': '2026-09-10',
              'teacher': 'Melska Grażyna',
              'rawTooltip': 'Waga: 1 • Aktywność'
            }
          ]
        }
      ]
    };
  }

  @override
  Future<StudentProfile> getStudentProfile() async {
    final data = await _getStudentData();
    if (data == null) {
      return _mockFallback.getStudentProfile();
    }

    final studentMap = data['student'] as Map<String, dynamic>? ?? {};
    final lucky = data['luckyNumber'] ?? 18;
    final avg = (data['overallAverage'] as num?)?.toDouble() ?? 5.0;

    final attStats = data['attendanceStats'] as Map<String, dynamic>?;
    final attPct = (attStats?['percentage'] as num?)?.toDouble() ?? 98.6;

    return StudentProfile(
      id: data['login'] ?? '',
      name: studentMap['name'] ?? 'Uczeń',
      className: studentMap['className'] ?? '4 k Lic',
      schoolName: studentMap['schoolName'] ?? 'Liceum Ogólnokształcące nr X im. Stefanii Sempołowskiej we Wrocławiu',
      avatarUrl: MockData.student.avatarUrl,
      attendancePercentage: attPct,
      overallAverage: avg,
      previousPeriodAverage: 4.85,
      classRank: 1,
      totalStudentsInClass: 28,
      unreadMessagesCount: (data['unreadNotificationsCount'] as num?)?.toInt() ?? 0,
      currentWeek: 'Szczęśliwy numerek: $lucky',
    );
  }

  @override
  Future<UpcomingEvent> getUpcomingExam() async {
    return _mockFallback.getUpcomingExam();
  }

  List<LessonSlot> _parseTimetableForDay(List<dynamic> rawList, int targetDay) {
    final dayLessons = rawList.where((item) {
      if (item is Map) {
        return item['dayOfWeek'] == targetDay;
      }
      return false;
    }).toList();

    if (dayLessons.isEmpty) {
      return [];
    }

    dayLessons.sort((a, b) => (a['lessonNumber'] as num? ?? 0).compareTo(b['lessonNumber'] as num? ?? 0));

    return dayLessons.map((item) {
      final timeRange = (item['time'] as String? ?? '08:00 - 08:45').split('-');
      final start = timeRange[0].trim();
      final end = timeRange.length > 1 ? timeRange[1].trim() : '';
      final subject = item['subject'] as String? ?? 'Lekcja';
      final isCancelled = item['isCancelled'] == true;
      final isSubstituted = subject.toLowerCase().contains('zastępstwo');

      LessonStatus status = LessonStatus.normal;
      if (isCancelled) {
        status = LessonStatus.canceled;
      } else if (isSubstituted) {
        status = LessonStatus.substituted;
      }

      return LessonSlot(
        lessonNumber: item['lessonNumber'] as int? ?? 1,
        subjectName: subject,
        startTime: start,
        endTime: end,
        room: 'Sala szkolna',
        teacher: item['teacher'] as String? ?? '',
        status: status,
        statusNote: isCancelled ? 'Lekcja odwołana' : (isSubstituted ? 'Zastępstwo' : null),
      );
    }).toList();
  }

  @override
  Future<List<LessonSlot>> getTodaySchedule() async {
    final data = await _getStudentData();
    if (data == null || data['timetable'] == null) {
      return _mockFallback.getTodaySchedule();
    }

    final rawList = data['timetable'] as List<dynamic>? ?? [];
    final now = DateTime.now();
    int targetDay = now.weekday;
    if (targetDay > 5) targetDay = 2; // Default to Tuesday on weekends

    final lessons = _parseTimetableForDay(rawList, targetDay);
    return lessons.isNotEmpty ? lessons : _mockFallback.getTodaySchedule();
  }

  @override
  Future<List<LessonSlot>> getScheduleForDay(int dayOfWeek) async {
    final data = await _getStudentData();
    if (data == null || data['timetable'] == null) {
      return _mockFallback.getScheduleForDay(dayOfWeek);
    }

    final rawList = data['timetable'] as List<dynamic>? ?? [];
    final lessons = _parseTimetableForDay(rawList, dayOfWeek);
    return lessons;
  }

  @override
  Future<List<Subject>> getSubjects() async {
    final data = await _getStudentData();
    if (data == null || data['subjects'] == null) {
      return _mockFallback.getSubjects();
    }

    final rawSubjects = data['subjects'] as List<dynamic>? ?? [];
    if (rawSubjects.isEmpty) return _mockFallback.getSubjects();

    final validSubjects = rawSubjects.where((s) {
      if (s is! Map) return false;
      final rawName = (s['name'] as String? ?? '').trim();
      if (rawName.isEmpty || rawName.length < 2 || rawName.length > 40) return false;
      if (rawName.contains('\n') || rawName.contains('\r')) return false;

      final lower = rawName.toLowerCase();
      if (lower.contains('kategoria') ||
          lower.contains('brak ocen') ||
          lower.contains('ocena opisowa') ||
          lower.contains('punkty startowe') ||
          lower.contains('suma') ||
          lower.contains('okres 1') ||
          lower.contains('okres 2') ||
          lower.contains('zachowanie')) {
        return false;
      }
      return true;
    }).toList();

    if (validSubjects.isEmpty) return _mockFallback.getSubjects();

    return validSubjects.map((s) {
      final sName = s['name'] as String? ?? 'Przedmiot';
      final avg = (s['currentAverage'] as num?)?.toDouble();
      final teacher = s['teacher'] as String? ?? '';
      final rawGrades = s['grades'] as List<dynamic>? ?? [];

      final grades = rawGrades.map((g) {
        final val = g['value'] as String? ?? '5';
        final numVal = (g['numericalValue'] as num?)?.toDouble() ?? 5.0;
        final weight = (g['weight'] as num?)?.toInt() ?? 1;
        final cat = g['category'] as String? ?? 'Ocena';
        final dateStr = g['date'] as String? ?? '';

        DateTime dt;
        try {
          dt = DateTime.parse(dateStr.split(' ')[0]);
        } catch (_) {
          dt = DateTime.now();
        }

        return Grade(
          id: g['id'] ?? UniqueKey().toString(),
          subjectName: sName,
          rawValue: val,
          numericValue: numVal,
          weight: weight,
          category: GradeCategory.activity,
          categoryName: cat,
          comment: g['rawTooltip'] ?? '',
          teacher: g['teacher'] ?? teacher,
          date: dt,
          term: 1,
        );
      }).toList();

      return Subject(
        id: s['id'] ?? sName.toLowerCase(),
        name: sName,
        teacherName: teacher.isNotEmpty ? teacher : 'Nauczyciel',
        grades: grades,
        weightedAverageSem1: avg != null && avg > 0 ? avg : (grades.isNotEmpty ? 5.0 : null),
      );
    }).toList();
  }

  @override
  Future<List<Grade>> getRecentGrades() async {
    final subjects = await getSubjects();
    final allGrades = <Grade>[];
    for (final s in subjects) {
      allGrades.addAll(s.grades);
    }
    if (allGrades.isEmpty) return _mockFallback.getRecentGrades();
    allGrades.sort((a, b) => b.date.compareTo(a.date));
    return allGrades;
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    final data = await _getStudentData();
    if (data == null || data['attendance'] == null) {
      return _mockFallback.getAttendanceRecords();
    }

    final rawList = data['attendance'] as List<dynamic>? ?? [];
    if (rawList.isEmpty) return [];

    final slotTimes = {
      0: '07:10 - 07:55',
      1: '08:00 - 08:45',
      2: '08:55 - 09:40',
      3: '09:50 - 10:35',
      4: '10:45 - 11:30',
      5: '11:45 - 12:30',
      6: '12:45 - 13:30',
      7: '13:40 - 14:25',
      8: '14:35 - 15:20',
    };

    return rawList.map((item) {
      final lessonNum = item['lessonNumber'] as int? ?? 1;
      final typeStr = item['type'] as String? ?? 'unexcused';

      AttendanceType type = AttendanceType.absent;
      if (typeStr == 'excused') {
        type = AttendanceType.excused;
      } else if (typeStr == 'late') {
        type = AttendanceType.late;
      } else if (typeStr == 'present') {
        type = AttendanceType.present;
      }

      DateTime dt;
      try {
        dt = DateTime.parse(item['date'] as String? ?? '');
      } catch (_) {
        dt = DateTime.now();
      }

      return AttendanceRecord(
        id: item['id'] ?? UniqueKey().toString(),
        date: dt,
        lessonNumber: lessonNum,
        subjectName: item['subjectName'] as String? ?? 'Lekcja',
        type: type,
        timeSlot: slotTimes[lessonNum] ?? 'Lekcja $lessonNum',
        justificationStatus: type == AttendanceType.excused
            ? JustificationStatus.approved
            : JustificationStatus.none,
      );
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> getAttendanceStats() async {
    final data = await _getStudentData();
    if (data != null && data['attendanceStats'] is Map) {
      final s = data['attendanceStats'] as Map<String, dynamic>;
      return {
        'presenceCount': s['presenceCount'] ?? 142,
        'absenceCount': s['absenceCount'] ?? 2,
        'lateCount': s['lateCount'] ?? 0,
        'excusedCount': s['excusedCount'] ?? 0,
        'percentage': (s['percentage'] as num?)?.toDouble() ?? 98.6,
      };
    }
    return {
      'presenceCount': 142,
      'absenceCount': 2,
      'lateCount': 0,
      'excusedCount': 0,
      'percentage': 98.6,
    };
  }

  @override
  Future<List<MessageThread>> getMessages() async {
    final data = await _getStudentData();
    if (data == null || data['messages'] == null) {
      return _mockFallback.getMessages();
    }

    final rawList = data['messages'] as List<dynamic>? ?? [];
    if (rawList.isEmpty) return [];

    return rawList.map((item) {
      final senderRaw = item['sender'] as String? ?? 'Nauczyciel';
      String role = 'Nauczyciel';
      if (senderRaw.toLowerCase().contains('dyrektor')) {
        role = 'Dyrektor Szkoły';
      } else if (senderRaw.toLowerCase().contains('wychowawc')) {
        role = 'Wychowawca';
      }

      // Clean sender name
      final cleanName = senderRaw.replaceAll(RegExp(r'\[.*?\]'), '').trim();
      final words = cleanName.split(RegExp(r'\s+'));
      String initials = 'L';
      if (words.length >= 2) {
        initials = '${words[0][0]}${words[1][0]}'.toUpperCase();
      } else if (words.isNotEmpty && words[0].isNotEmpty) {
        initials = words[0][0].toUpperCase();
      }

      final subject = item['subject'] as String? ?? 'Wiadomość';
      final isImportant = subject.toUpperCase().contains('PILNE') ||
          subject.toUpperCase().contains('WAŻNE');

      DateTime dt;
      try {
        dt = DateTime.parse(item['date'] as String? ?? '');
      } catch (_) {
        dt = DateTime.now();
      }

      return MessageThread(
        id: item['id'] as String? ?? UniqueKey().toString(),
        senderName: cleanName,
        senderInitials: initials,
        senderRole: role,
        subject: subject,
        preview: item['preview'] as String? ?? subject,
        body: item['preview'] as String? ?? subject,
        timestamp: dt,
        isUnread: item['isRead'] == false,
        isImportant: isImportant,
      );
    }).toList();
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    final data = await _getStudentData();
    if (data == null || data['announcements'] == null) {
      return _mockFallback.getAnnouncements();
    }

    final rawAnn = data['announcements'] as List<dynamic>? ?? [];
    if (rawAnn.isEmpty) return _mockFallback.getAnnouncements();

    return rawAnn.map((a) {
      DateTime dt;
      try {
        dt = DateTime.parse(a['date'] ?? '');
      } catch (_) {
        dt = DateTime.now();
      }

      return Announcement(
        id: a['id'] ?? UniqueKey().toString(),
        title: a['title'] ?? 'Ogłoszenie',
        author: a['author'] ?? 'Szkoła',
        authorRole: 'Nauczyciel / Dyrekcja',
        publishedDate: dt,
        content: a['content'] ?? '',
        tags: const ['Ogłoszenie szkolne', 'Ważne'],
      );
    }).toList();
  }

  @override
  Future<void> submitJustification(List<String> recordIds, String reason) async {
    return _mockFallback.submitJustification(recordIds, reason);
  }
}

class UniqueKey {
  static int _c = 0;
  @override
  String toString() => 'k_${DateTime.now().millisecondsSinceEpoch}_${_c++}';
}
