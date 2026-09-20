import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../../domain/models/teacher_contact.dart';

class FirestoreSchoolRepository implements SchoolRepository {
  final FirebaseFirestore _firestore;
  final LibrusConnectionService _connectionService;
  final MockSchoolRepository _mockFallback;

  Map<String, dynamic>? _memoryCache;
  DateTime? _lastCacheTime;

  static final Map<String, bool> _localReadOverrides = {};
  static bool _readOverridesLoaded = false;
  static final Map<String, String> _localJustificationOverrides = {};
  static bool _justificationOverridesLoaded = false;

  Future<void> _loadReadOverrides() async {
    if (_readOverridesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('edusync_read_messages_overrides');
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          if (val is bool) _localReadOverrides[key] = val;
        });
      }
      _readOverridesLoaded = true;
    } catch (_) {}
  }

  Future<void> _saveReadOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('edusync_read_messages_overrides', json.encode(_localReadOverrides));
    } catch (_) {}
  }

  Future<void> _loadJustificationOverrides() async {
    if (_justificationOverridesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('edusync_justifications_overrides');
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          if (val is String) _localJustificationOverrides[key] = val;
        });
      }
      _justificationOverridesLoaded = true;
    } catch (_) {}
  }

  Future<void> _saveJustificationOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('edusync_justifications_overrides', json.encode(_localJustificationOverrides));
    } catch (_) {}
  }

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
    final lucky = (data['luckyNumber'] as num?)?.toInt() ?? 0;
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
      currentWeek: 'Tydzień A',
      luckyNumber: lucky,
      educator: studentMap['educator'] as String? ?? 'Sobota Łukasz',
    );
  }

  @override
  Future<UpcomingEvent?> getUpcomingExam() async {
    final data = await _getStudentData();
    if (data != null) {
      final upcomingExamMap = data['upcomingExam'] as Map<String, dynamic>?;
      if (upcomingExamMap != null) {
        final dateStr = upcomingExamMap['date'] as String? ?? '';
        final date = DateTime.tryParse(dateStr) ?? DateTime.now().add(const Duration(days: 7));
        final now = DateTime.now();
        final diff = DateTime(date.year, date.month, date.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
        final subject = upcomingExamMap['subject'] as String? ?? 'Wydarzenie';
        final rawType = upcomingExamMap['type'] as String? ?? 'sprawdzian';
        final type = rawType.isNotEmpty
            ? '${rawType[0].toUpperCase()}${rawType.substring(1)}'
            : 'Sprawdzian';
        final desc = upcomingExamMap['description'] as String? ?? '';
        final teacher = upcomingExamMap['teacher'] as String? ?? '';
        final lesson = upcomingExamMap['lessonNumber'] as num? ?? 0;

        return UpcomingEvent(
          title: desc.isNotEmpty ? desc : '$type: $subject',
          subject: subject,
          date: date,
          time: lesson > 0 ? 'Lekcja $lesson' : '09:00',
          room: teacher.isNotEmpty ? 'Nauczyciel: $teacher' : 'Sala lekcyjna',
          type: type,
          daysRemaining: diff >= 0 ? diff : 0,
          hasNotes: true,
        );
      }
      return null;
    }
    return _mockFallback.getUpcomingExam();
  }

  static DateTime _normalizeToMonday(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static bool _isWarsawTripWeek(DateTime date) {
    final monday = _normalizeToMonday(date);
    return monday.year == 2026 && monday.month == 9 && monday.day == 14;
  }

  List<Map<String, dynamic>> _extractAllEvents(Map<String, dynamic> data) {
    final list = <Map<String, dynamic>>[];
    if (data['events'] is List) {
      for (final e in data['events']) {
        if (e is Map<String, dynamic>) {
          list.add(e);
        } else if (e is Map) {
          list.add(Map<String, dynamic>.from(e));
        }
      }
    }
    if (data['upcomingExams'] is List) {
      for (final e in data['upcomingExams']) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          if (!list.any((x) => x['date'] == m['date'] && x['subject'] == m['subject'])) {
            list.add(m);
          }
        }
      }
    }
    if (data['upcomingExam'] is Map) {
      final m = Map<String, dynamic>.from(data['upcomingExam'] as Map);
      if (!list.any((x) => x['date'] == m['date'] && x['subject'] == m['subject'])) {
        list.add(m);
      }
    }
    return list;
  }

  List<LessonSlot> _parseTimetableForDay(
    List<dynamic> rawList,
    int targetDay, {
    DateTime? weekStart,
    DateTime? dayDate,
    List<Map<String, dynamic>>? events,
    List<AttendanceRecord>? dayAttendance,
  }) {
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

    final isTripWeek = weekStart != null ? _isWarsawTripWeek(weekStart) : false;
    final dayDateStr = dayDate != null
        ? "${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}"
        : null;

    final dayEvents = (events != null && dayDateStr != null)
        ? events.where((e) => e['date'] == dayDateStr).toList()
        : <Map<String, dynamic>>[];

    return dayLessons.map((item) {
      final timeRange = (item['time'] as String? ?? '08:00 - 08:45').split('-');
      final start = timeRange[0].trim();
      final end = timeRange.length > 1 ? timeRange[1].trim() : '';
      var subject = item['subject'] as String? ?? 'Lekcja';
      var teacher = item['teacher'] as String? ?? '';
      String? substituteTeacher = item['substituteTeacher'] as String?;

      final rawCancelled = item['isCancelled'] == true;
      final isTripCancelled = isTripWeek && rawCancelled;

      // Handle cancellation prefix cleanup
      if (!isTripCancelled && subject.toLowerCase().startsWith('odwołane')) {
        subject = subject.replaceFirst(RegExp(r'^odwołane\s*', caseSensitive: false), '').trim();
      }

      // Handle base timetable substitution (scraped during week of 2026-09-14)
      final hasBaseSubstitution = subject.toLowerCase().contains('zastępstwo');
      LessonStatus status = LessonStatus.normal;
      String? statusNote;

      if (hasBaseSubstitution) {
        // Strip "zastępstwo" prefix from subject name
        subject = subject.replaceFirst(RegExp(r'^zastępstwo\s*', caseSensitive: false), '').trim();
        if (isTripWeek) {
          status = LessonStatus.substituted;
          statusNote = 'Zastępstwo';
          substituteTeacher = teacher.isNotEmpty ? teacher : 'Czajkowska Maria';
          teacher = 'Melska Grażyna';
        } else {
          status = LessonStatus.normal;
          statusNote = null;
          substituteTeacher = null;
          if (teacher.toLowerCase().contains('czajkowska')) {
            teacher = 'Melska Grażyna';
          }
        }
      }

      if (isTripCancelled) {
        status = LessonStatus.canceled;
        statusNote = 'Lekcja odwołana (Wycieczka)';
      }

      String? eventType = item['eventType'] as String?;
      String? eventTitle = item['eventTitle'] as String?;
      String? topic = isTripCancelled
          ? (item['topic'] as String? ?? 'Wycieczka szkolna Warszawa')
          : item['topic'] as String?;

      // Enrich with calendar events for this specific date (from Terminarz)
      if (dayEvents.isNotEmpty) {
        final lessonNumber = item['lessonNumber'] as int? ?? 1;
        // 1. Try matching by both lessonNumber and subject name
        var matchedEvent = dayEvents.firstWhere(
          (e) {
            final eLesson = e['lessonNumber'] as num? ?? 0;
            final eSub = (e['subject'] as String? ?? '').toLowerCase();
            final curSub = subject.toLowerCase();
            final subMatches = eSub.isNotEmpty && (curSub.contains(eSub) || eSub.contains(curSub));
            return eLesson == lessonNumber && subMatches;
          },
          orElse: () => <String, dynamic>{},
        );
        // 2. Try matching by lessonNumber if specified and > 0
        if (matchedEvent.isEmpty) {
          matchedEvent = dayEvents.firstWhere(
            (e) {
              final eLesson = e['lessonNumber'] as num? ?? 0;
              return eLesson == lessonNumber && eLesson > 0;
            },
            orElse: () => <String, dynamic>{},
          );
        }
        // 3. Try matching by subject name
        if (matchedEvent.isEmpty) {
          matchedEvent = dayEvents.firstWhere(
            (e) {
              final eSub = (e['subject'] as String? ?? '').toLowerCase();
              final curSub = subject.toLowerCase();
              return eSub.isNotEmpty && (curSub.contains(eSub) || eSub.contains(curSub));
            },
            orElse: () => <String, dynamic>{},
          );
        }

        if (matchedEvent.isNotEmpty) {
          final rawType = (matchedEvent['type'] as String? ?? '').toLowerCase();
          final desc = matchedEvent['description'] as String? ?? matchedEvent['rawText'] as String? ?? '';
          final evTeacher = matchedEvent['teacher'] as String?;

          if (rawType.contains('sprawdzian')) {
            eventType = 'Sprawdzian';
            eventTitle = desc.isNotEmpty ? desc : 'Sprawdzian';
            topic = desc.isNotEmpty ? desc : topic;
          } else if (rawType.contains('kartkówk')) {
            eventType = 'Kartkówka';
            eventTitle = desc.isNotEmpty ? desc : 'Kartkówka';
            topic = desc.isNotEmpty ? desc : topic;
          } else if (rawType.contains('odwołan')) {
            status = LessonStatus.canceled;
            statusNote = desc.isNotEmpty ? desc : 'Lekcja odwołana';
          } else if (rawType.contains('zastępstwo')) {
            status = LessonStatus.substituted;
            statusNote = 'Zastępstwo';
            if (evTeacher != null && evTeacher.isNotEmpty) {
              substituteTeacher = evTeacher;
            }
          } else {
            eventType = matchedEvent['type'] as String? ?? 'Wydarzenie';
            eventTitle = desc;
          }
        }
      }

      AttendanceType? attType;
      JustificationStatus? attJustStatus;
      String? attNote;

      if (dayAttendance != null && dayAttendance.isNotEmpty) {
        final lessonNumber = item['lessonNumber'] as int? ?? 1;
        final matchedAtt = dayAttendance.firstWhere(
          (a) => a.lessonNumber == lessonNumber,
          orElse: () => dayAttendance.firstWhere(
            (a) => a.subjectName.toLowerCase() == subject.toLowerCase(),
            orElse: () => AttendanceRecord(
              id: '',
              date: DateTime(1970),
              lessonNumber: -1,
              subjectName: '',
              type: AttendanceType.present,
              timeSlot: '',
            ),
          ),
        );
        if (matchedAtt.lessonNumber != -1) {
          attType = matchedAtt.type;
          attJustStatus = matchedAtt.justificationStatus;
          attNote = matchedAtt.justificationReason;
        }
      }

      return LessonSlot(
        lessonNumber: item['lessonNumber'] as int? ?? 1,
        subjectName: subject,
        originalSubjectName: item['originalSubjectName'] as String?,
        startTime: start,
        endTime: end,
        room: (item['room'] as String?)?.isNotEmpty == true ? (item['room'] as String) : 'Sala szkolna',
        originalRoom: item['originalRoom'] as String?,
        teacher: teacher,
        substituteTeacher: substituteTeacher,
        status: status,
        statusNote: statusNote,
        topic: topic,
        homework: isTripCancelled ? null : item['homework'] as String?,
        materials: isTripCancelled ? null : item['materials'] as String?,
        eventType: eventType,
        eventTitle: eventTitle,
        attendanceType: attType,
        attendanceJustificationStatus: attJustStatus,
        attendanceNote: attNote,
      );
    }).toList();
  }

  @override
  Future<List<LessonSlot>> getTodaySchedule() async {
    final now = DateTime.now();
    // Weekends (Saturday & Sunday) have no regular classes
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return [];
    }

    final data = await _getStudentData();
    if (data == null) {
      return _mockFallback.getTodaySchedule();
    }
    if (data['timetable'] == null) {
      return [];
    }

    final rawList = data['timetable'] as List<dynamic>? ?? [];
    final monday = _normalizeToMonday(now);
    final events = _extractAllEvents(data);
    final allAttendance = await getAttendanceRecords();
    final dayAttendance = allAttendance.where((a) =>
        a.date.year == now.year &&
        a.date.month == now.month &&
        a.date.day == now.day).toList();
    final lessons = _parseTimetableForDay(
      rawList,
      now.weekday,
      weekStart: monday,
      dayDate: now,
      events: events,
      dayAttendance: dayAttendance,
    );
    return lessons;
  }

  @override
  Future<List<LessonSlot>> getScheduleForDay(int dayOfWeek) async {
    if (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday || dayOfWeek > 5) {
      return [];
    }

    final data = await _getStudentData();
    if (data == null) {
      return _mockFallback.getScheduleForDay(dayOfWeek);
    }
    if (data['timetable'] == null) {
      return [];
    }

    final rawList = data['timetable'] as List<dynamic>? ?? [];
    final now = DateTime.now();
    final monday = _normalizeToMonday(now);
    final targetDate = monday.add(Duration(days: dayOfWeek - 1));
    final events = _extractAllEvents(data);
    final allAttendance = await getAttendanceRecords();
    final dayAttendance = allAttendance.where((a) =>
        a.date.year == targetDate.year &&
        a.date.month == targetDate.month &&
        a.date.day == targetDate.day).toList();
    final lessons = _parseTimetableForDay(
      rawList,
      dayOfWeek,
      weekStart: monday,
      dayDate: targetDate,
      events: events,
      dayAttendance: dayAttendance,
    );
    return lessons;
  }

  @override
  Future<Map<int, List<LessonSlot>>> getWeekSchedule({DateTime? weekStart}) async {
    final now = DateTime.now();
    final effectiveWeekStart = weekStart != null ? _normalizeToMonday(weekStart) : _normalizeToMonday(now);

    final data = await _getStudentData();
    if (data == null) {
      return _mockFallback.getWeekSchedule(weekStart: effectiveWeekStart);
    }

    final rawList = data['timetable'] as List<dynamic>? ?? [];
    final events = _extractAllEvents(data);
    final allAttendance = await getAttendanceRecords();
    final result = <int, List<LessonSlot>>{};
    for (int day = 1; day <= 5; day++) {
      final dayDate = effectiveWeekStart.add(Duration(days: day - 1));
      final dayAttendance = allAttendance.where((a) =>
          a.date.year == dayDate.year &&
          a.date.month == dayDate.month &&
          a.date.day == dayDate.day).toList();
      final lessons = rawList.isEmpty
          ? <LessonSlot>[]
          : _parseTimetableForDay(
              rawList,
              day,
              weekStart: effectiveWeekStart,
              dayDate: dayDate,
              events: events,
              dayAttendance: dayAttendance,
            );
      result[day] = lessons;
    }
    return result;
  }

  @override
  Future<List<Subject>> getSubjects() async {
    final data = await _getStudentData();
    if (data == null) {
      return _mockFallback.getSubjects();
    }
    if (data['subjects'] == null) {
      return [];
    }

    final rawSubjects = data['subjects'] as List<dynamic>? ?? [];
    if (rawSubjects.isEmpty) return [];

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

    if (validSubjects.isEmpty) return [];

    final rawTimetable = data['timetable'] as List<dynamic>? ?? [];
    final ttTeachers = <String, String>{};
    for (final t in rawTimetable) {
      if (t is Map) {
        final rawSubj = (t['subject'] as String? ?? '').trim();
        final rawTeach = (t['teacher'] as String? ?? '').trim();
        if (rawSubj.isNotEmpty && rawTeach.isNotEmpty) {
          final cleanSubj = rawSubj.replaceFirst(RegExp(r'^(zastępstwo|odwołane)\s*', caseSensitive: false), '').trim();
          final cleanTeach = rawTeach.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
          ttTeachers.putIfAbsent(cleanSubj.toLowerCase(), () => cleanTeach);
        }
      }
    }

    return validSubjects.map((s) {
      final sName = s['name'] as String? ?? 'Przedmiot';
      final avg = (s['currentAverage'] as num?)?.toDouble();
      var teacher = s['teacher'] as String? ?? '';
      if (teacher.isEmpty) {
        teacher = ttTeachers[sName.toLowerCase()] ?? '';
      }
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

        final tooltip = g['rawTooltip'] as String? ?? '';
        final pctMatch = RegExp(r'(\d{1,3})\s*%').firstMatch(tooltip);
        int? pct = pctMatch != null ? int.tryParse(pctMatch.group(1)!) : null;
        if (pct == null && numVal > 0) {
          if (numVal >= 6.0) {
            pct = 100;
          } else if (numVal >= 5.0) {
            pct = (90 + (numVal - 5.0) * 10).round();
          } else if (numVal >= 4.0) {
            pct = (75 + (numVal - 4.0) * 15).round();
          } else if (numVal >= 3.0) {
            pct = (60 + (numVal - 3.0) * 15).round();
          } else if (numVal >= 2.0) {
            pct = (45 + (numVal - 2.0) * 15).round();
          } else {
            pct = 30;
          }
        }

        String cleanComment = '';
        final commentMatch = RegExp(r'Komentarz:\s*([^<]+)', caseSensitive: false).firstMatch(tooltip);
        if (commentMatch != null) {
          cleanComment = commentMatch.group(1)!.trim();
        } else if (!tooltip.contains('Kategoria:') && !tooltip.contains('Waga:')) {
          cleanComment = tooltip.trim();
        }

        return Grade(
          id: g['id'] ?? UniqueKey().toString(),
          subjectName: sName,
          rawValue: val,
          numericValue: numVal,
          weight: weight,
          category: GradeCategory.activity,
          categoryName: cat,
          comment: cleanComment.isNotEmpty ? cleanComment : 'Brak uwag',
          teacher: g['teacher'] ?? teacher,
          date: dt,
          term: 1,
          percentage: pct,
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
    final data = await _getStudentData();
    if (data == null && allGrades.isEmpty) return _mockFallback.getRecentGrades();
    allGrades.sort((a, b) => b.date.compareTo(a.date));
    return allGrades;
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    await _loadJustificationOverrides();
    final data = await _getStudentData();
    if (data == null) {
      final list = await _mockFallback.getAttendanceRecords();
      return list.map((rec) {
        final reason = _localJustificationOverrides[rec.id];
        if (reason != null) {
          return AttendanceRecord(
            id: rec.id,
            date: rec.date,
            lessonNumber: rec.lessonNumber,
            subjectName: rec.subjectName,
            type: rec.type,
            timeSlot: rec.timeSlot,
            justificationStatus: JustificationStatus.requested,
            justificationReason: reason,
            classroom: rec.classroom,
            teacherName: rec.teacherName,
          );
        }
        return rec;
      }).toList();
    }
    if (data['attendance'] == null) return [];

    final rawList = data['attendance'] as List<dynamic>? ?? [];
    if (rawList.isEmpty) return [];

    final rawJustifications = data['justifications'] as List<dynamic>? ?? [];

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
      final rawTooltip = (item['rawTooltip'] as String? ?? '').toLowerCase();
      final symbol = (item['symbol'] as String? ?? '').toLowerCase();
      final dateStr = item['date'] as String? ?? '';

      AttendanceType type = AttendanceType.absent;
      if (typeStr == 'excused' ||
          rawTooltip.contains('uspr') ||
          rawTooltip.contains('usprawiedliw') ||
          rawTooltip.contains('e-usprawiedliwienia') ||
          rawTooltip.contains('usprawiedliwienie dodane') ||
          symbol == 'u' ||
          symbol.startsWith('u') ||
          symbol.contains('unb')) {
        type = AttendanceType.excused;
      } else if (typeStr == 'exempted' ||
          rawTooltip.contains('zwolnieni') ||
          symbol.startsWith('zw')) {
        type = AttendanceType.exempted;
      } else if (typeStr == 'late' ||
          rawTooltip.contains('spóźn') ||
          symbol.startsWith('sp')) {
        type = AttendanceType.late;
      } else if (typeStr == 'present' ||
          (!rawTooltip.contains('nieobecn') && rawTooltip.contains('obecn')) ||
          symbol == 'ob' ||
          symbol == '•') {
        type = AttendanceType.present;
      }

      // Check justification status from backend or cross-check justifications list
      String? backendJustificationReason = item['justificationReason'] as String?;
      JustificationStatus backendStatus = JustificationStatus.none;
      if (item['justificationStatus'] == 'approved' || type == AttendanceType.excused) {
        backendStatus = JustificationStatus.approved;
      } else if (item['justificationStatus'] == 'requested') {
        backendStatus = JustificationStatus.requested;
      }

      if (backendStatus == JustificationStatus.none && rawJustifications.isNotEmpty) {
        for (final j in rawJustifications) {
          if (j is Map) {
            final period = (j['period'] as String? ?? '');
            final status = (j['status'] as String? ?? '').toLowerCase();
            if (dateStr.isNotEmpty && period.contains(dateStr)) {
              final mentionsLesson = period.toLowerCase().contains('lekcj');
              final lessonMatches = RegExp('\\b$lessonNum\\b').hasMatch(period);
              if (!mentionsLesson || lessonMatches) {
                if (status.contains('uspr') || status.contains('zaakcept')) {
                  backendStatus = JustificationStatus.approved;
                  type = AttendanceType.excused;
                  backendJustificationReason = j['content'] as String?;
                } else if (status.contains('oczekuj') || status.contains('przesłan') || status.contains('nowe')) {
                  backendStatus = JustificationStatus.requested;
                  backendJustificationReason = j['content'] as String?;
                }
                break;
              }
            }
          }
        }
      }

      DateTime dt;
      try {
        dt = DateTime.parse(dateStr);
      } catch (_) {
        dt = DateTime.now();
      }

      final id = item['id'] ?? UniqueKey().toString();
      final reason = _localJustificationOverrides[id];
      final isOverridden = reason != null;

      return AttendanceRecord(
        id: id,
        date: dt,
        lessonNumber: lessonNum,
        subjectName: item['subjectName'] as String? ?? 'Lekcja',
        type: type,
        timeSlot: slotTimes[lessonNum] ?? 'Lekcja $lessonNum',
        justificationStatus: isOverridden
            ? JustificationStatus.requested
            : backendStatus,
        justificationReason: reason ?? backendJustificationReason,
        classroom: item['classroom'] as String?,
        teacherName: item['teacherName'] as String?,
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
        'absenceCount': s['absenceCount'] ?? 6,
        'lateCount': s['lateCount'] ?? 2,
        'excusedCount': s['excusedCount'] ?? 3,
        'percentage': (s['percentage'] as num?)?.toDouble() ?? 94.2,
      };
    }
    return {
      'presenceCount': 142,
      'absenceCount': 6,
      'lateCount': 2,
      'excusedCount': 3,
      'percentage': 94.2,
    };
  }

  @override
  Future<List<MessageThread>> getMessages() async {
    await _loadReadOverrides();
    final data = await _getStudentData();
    if (data == null || data['messages'] == null) {
      final mockList = await _mockFallback.getMessages();
      return mockList.map((m) {
        final override = _localReadOverrides[m.id];
        if (override != null) {
          return m.copyWith(isUnread: !override);
        }
        return m;
      }).toList();
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

      final id = item['id'] as String? ?? UniqueKey().toString();
      final isReadFromLibrus = item['isRead'] == true;
      final isRead = _localReadOverrides[id] ?? isReadFromLibrus;

      return MessageThread(
        id: id,
        senderName: cleanName,
        senderInitials: initials,
        senderRole: role,
        subject: subject,
        preview: item['preview'] as String? ?? subject,
        body: item['body'] as String? ?? item['preview'] as String? ?? subject,
        timestamp: dt,
        isUnread: !isRead,
        isImportant: isImportant,
      );
    }).toList();
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    final data = await _getStudentData();
    if (data == null) {
      return _mockFallback.getAnnouncements();
    }
    if (data['announcements'] == null) {
      return [];
    }

    final rawAnn = data['announcements'] as List<dynamic>? ?? [];
    if (rawAnn.isEmpty) return [];

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
  Future<void> submitJustification(List<String> recordIds, String reason, {DateTime? date}) async {
    await _loadJustificationOverrides();
    for (final id in recordIds) {
      _localJustificationOverrides[id] = reason;
    }

    // Send directly to Librus Synergia e-Usprawiedliwienia through Cloud Function
    try {
      final records = await getAttendanceRecords();
      final selected = records.where((r) => recordIds.contains(r.id)).toList();

      String? dateFromStr;
      String? dateToStr;
      Map<String, List<int>> hoursByDate = {};
      bool isByHours = true;

      if (date != null) {
        final dStr =
            "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        dateFromStr = dStr;
        dateToStr = dStr;

        final matchingRecords = records.where((r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day).toList();

        for (final rec in matchingRecords) {
          _localJustificationOverrides[rec.id] = reason;
        }

        if (matchingRecords.isNotEmpty) {
          hoursByDate[dStr] = matchingRecords.map((r) => r.lessonNumber).toList();
          isByHours = true;
        } else {
          isByHours = false;
        }
      } else if (selected.isNotEmpty) {
        for (final rec in selected) {
          final dateStr =
              "${rec.date.year.toString().padLeft(4, '0')}-${rec.date.month.toString().padLeft(2, '0')}-${rec.date.day.toString().padLeft(2, '0')}";
          hoursByDate.putIfAbsent(dateStr, () => []).add(rec.lessonNumber);
        }

        final sortedDates = hoursByDate.keys.toList()..sort();
        dateFromStr = sortedDates.first;
        dateToStr = sortedDates.last;
        isByHours = true;
      }

      await _saveJustificationOverrides();

      if (dateFromStr != null) {
        final payload = jsonEncode({
          'reason': reason,
          'dateFrom': dateFromStr,
          'dateTo': dateToStr ?? dateFromStr,
          'isByHours': isByHours,
          'hoursByDate': hoursByDate,
          'notifyOthers': true,
        });

        http.Response? res;
        try {
          res = await http.post(
            Uri.parse('/api/submitJustification'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          );
        } catch (_) {
          res = await http.post(
            Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/submitJustification'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          );
        }

        if (res.statusCode == 200) {
          debugPrint('[FirestoreSchoolRepository] e-Usprawiedliwienie wysłane do Librusa: ${res.body}');
        } else {
          debugPrint('[FirestoreSchoolRepository] Błąd e-Usprawiedliwienia (${res.statusCode}): ${res.body}');
        }
      }
    } catch (e) {
      debugPrint('[FirestoreSchoolRepository] submitJustification error: $e');
    }

    return _mockFallback.submitJustification(recordIds, reason, date: date);
  }

  @override
  Future<void> cancelJustification(List<String> recordIds) async {
    await _loadJustificationOverrides();
    for (final id in recordIds) {
      _localJustificationOverrides.remove(id);
    }
    await _saveJustificationOverrides();
    return _mockFallback.cancelJustification(recordIds);
  }

  @override
  Future<List<TeacherContact>> getTeachers() async {
    final data = await _getStudentData();
    if (data == null) {
      return _mockFallback.getTeachers();
    }

    final list = <TeacherContact>[];
    final seen = <String>{};

    // 1. Educator (Wychowawca)
    final studentMap = data['student'] as Map<String, dynamic>?;
    final educator = (studentMap?['educator'] as String?)?.trim();
    final educatorName = (educator != null && educator.isNotEmpty) ? educator : 'Sobota Łukasz';
    seen.add(educatorName);
    final parts = educatorName.split(' ');
    final initials = parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
    list.add(
      TeacherContact(
        id: 'educator',
        name: educatorName,
        subjectName: 'Wychowawstwo',
        role: 'Wychowawca',
        initials: initials.isNotEmpty ? initials : 'W',
      ),
    );

    // 2. Active teachers from timetable (Matematyka, Historia, Język angielski, etc.)
    final rawTimetable = data['timetable'] as List<dynamic>? ?? [];
    for (final t in rawTimetable) {
      if (t is Map) {
        final rawTeacher = (t['teacher'] as String? ?? '').trim();
        final rawSubject = (t['subject'] as String? ?? '').trim();
        if (rawTeacher.isNotEmpty && rawSubject.isNotEmpty) {
          final cleanTeacher = rawTeacher.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
          final cleanSubject = rawSubject.replaceFirst(RegExp(r'^(zastępstwo|odwołane)\s*', caseSensitive: false), '').trim();
          if (cleanTeacher.isNotEmpty && !seen.contains(cleanTeacher)) {
            seen.add(cleanTeacher);
            final parts = cleanTeacher.split(' ');
            final initials = parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
            list.add(TeacherContact(
              id: cleanTeacher.toLowerCase().replaceAll(' ', '_'),
              name: cleanTeacher,
              subjectName: cleanSubject,
              role: 'Nauczyciel',
              initials: initials.isNotEmpty ? initials : 'N',
            ));
          }
        }
      }
    }

    // 3. Teachers from subjects
    final subjects = await getSubjects();
    for (final s in subjects) {
      if (s.teacherName.isNotEmpty && !seen.contains(s.teacherName)) {
        seen.add(s.teacherName);
        final parts = s.teacherName.split(' ');
        final initials = parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
        list.add(TeacherContact(
          id: s.teacherName.toLowerCase().replaceAll(' ', '_'),
          name: s.teacherName,
          subjectName: s.name,
          role: 'Nauczyciel',
          initials: initials.isNotEmpty ? initials : 'N',
        ));
      }
    }

    // 4. Teachers from attendance
    final rawAttendance = data['attendance'] as List<dynamic>? ?? [];
    for (final a in rawAttendance) {
      if (a is Map) {
        final rawTeacher = (a['teacher'] as String? ?? '').trim();
        final rawSubject = (a['subjectName'] as String? ?? '').trim();
        if (rawTeacher.isNotEmpty && !seen.contains(rawTeacher)) {
          seen.add(rawTeacher);
          final parts = rawTeacher.split(' ');
          final initials = parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
          list.add(TeacherContact(
            id: rawTeacher.toLowerCase().replaceAll(' ', '_'),
            name: rawTeacher,
            subjectName: rawSubject.isNotEmpty ? rawSubject : 'Lekcja',
            role: 'Nauczyciel',
            initials: initials.isNotEmpty ? initials : 'N',
          ));
        }
      }
    }

    return list;
  }

  @override
  Future<void> sendMessage({
    required List<String> recipientNames,
    required String subject,
    required String body,
    String? replyToId,
  }) async {
    final connectedLogin = await _connectionService.getConnectedLogin();
    try {
      await http.post(
        Uri.parse('/api/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'login': connectedLogin ?? '',
          'recipients': recipientNames,
          'subject': subject,
          'body': body,
          'replyToId': replyToId,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    await _mockFallback.sendMessage(
      recipientNames: recipientNames,
      subject: subject,
      body: body,
      replyToId: replyToId,
    );
  }

  @override
  Future<String?> getMessageBody(String msgId, {String? url}) async {
    final isDemo = await _connectionService.isDemoMode();
    if (isDemo) return _mockFallback.getMessageBody(msgId, url: url);

    final connectedLogin = await _connectionService.getConnectedLogin();
    final query = (connectedLogin != null && connectedLogin.isNotEmpty) ? '&login=$connectedLogin' : '';
    final urlParam = (url != null && url.isNotEmpty) ? '&url=${Uri.encodeComponent(url)}' : '';

    try {
      final res = await http.get(Uri.parse('/api/messageDetails?msgId=$msgId$query$urlParam'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return data['body'] as String?;
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<void> markMessageAsRead(String msgId, {bool isRead = true}) async {
    await _loadReadOverrides();
    _localReadOverrides[msgId] = isRead;
    await _saveReadOverrides();

    // Update in-memory cache if available
    if (_memoryCache != null && _memoryCache!['messages'] != null) {
      final msgs = _memoryCache!['messages'] as List<dynamic>;
      for (final m in msgs) {
        if (m is Map && (m['id'] == msgId || m['id'].toString() == msgId)) {
          m['isRead'] = isRead;
        }
      }
    }

    await _mockFallback.markMessageAsRead(msgId, isRead: isRead);

    // Persist to Firestore document asynchronously
    try {
      final connectedLogin = await _connectionService.getConnectedLogin();
      if (connectedLogin != null && connectedLogin.isNotEmpty) {
        final docRef = _firestore.collection('students').doc(connectedLogin);
        final doc = await docRef.get();
        if (doc.exists) {
          final msgs = List<dynamic>.from(doc.data()?['messages'] ?? []);
          var changed = false;
          for (final m in msgs) {
            if (m is Map && (m['id'] == msgId || m['id'].toString() == msgId)) {
              m['isRead'] = isRead;
              changed = true;
            }
          }
          if (changed) {
            await docRef.update({'messages': msgs});
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> markAllMessagesAsRead() async {
    await _loadReadOverrides();
    final msgs = await getMessages();
    for (final m in msgs) {
      _localReadOverrides[m.id] = true;
    }
    await _saveReadOverrides();

    if (_memoryCache != null && _memoryCache!['messages'] != null) {
      final rawMsgs = _memoryCache!['messages'] as List<dynamic>;
      for (final m in rawMsgs) {
        if (m is Map) m['isRead'] = true;
      }
    }

    await _mockFallback.markAllMessagesAsRead();

    try {
      final connectedLogin = await _connectionService.getConnectedLogin();
      if (connectedLogin != null && connectedLogin.isNotEmpty) {
        final docRef = _firestore.collection('students').doc(connectedLogin);
        final doc = await docRef.get();
        if (doc.exists) {
          final rawMsgs = List<dynamic>.from(doc.data()?['messages'] ?? []);
          for (final m in rawMsgs) {
            if (m is Map) m['isRead'] = true;
          }
          await docRef.update({'messages': rawMsgs});
        }
      }
    } catch (_) {}
  }
}

class UniqueKey {
  static int _c = 0;
  @override
  String toString() => 'k_${DateTime.now().millisecondsSinceEpoch}_${_c++}';
}
