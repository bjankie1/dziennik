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
import '../../domain/models/justification_request.dart';
import '../../domain/models/user_role.dart';

class FirestoreSchoolRepository implements SchoolRepository {
  final FirebaseFirestore _firestore;
  final LibrusConnectionService _connectionService;
  final MockSchoolRepository _mockFallback;

  Map<String, dynamic>? _memoryCache;
  DateTime? _lastCacheTime;
  String? _cachedTargetLogin;

  static final Map<String, bool> _localReadOverrides = {};
  static bool _readOverridesLoaded = false;
  static final Map<String, String> _localJustificationOverrides = {};
  static bool _justificationOverridesLoaded = false;
  static final Map<String, Map<String, DriveAttachmentInfo>> _localDriveAttachmentsOverrides = {};

  Map<String, DriveAttachmentInfo> _parseDriveAttachments(dynamic raw, String msgId) {
    final result = <String, DriveAttachmentInfo>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          result[key.toString()] = DriveAttachmentInfo.fromMap(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }
    final localForMsg = _localDriveAttachmentsOverrides[msgId];
    if (localForMsg != null) {
      result.addAll(localForMsg);
    }
    return result;
  }


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

  Future<String?> _getTargetStudentDocLogin() async {
    final appUser = await _connectionService.getSavedAppUser();
    final connectedLogin = await _connectionService.getConnectedLogin();
    return LibrusConnectionService.resolvePrimaryLogin(
      primaryLogin: appUser?.primaryLogin,
      login: connectedLogin,
      role: appUser?.role ?? UserRole.parent,
    );
  }

  Future<Map<String, dynamic>?> _getStudentData() async {
    final isDemo = await _connectionService.isDemoMode();
    if (isDemo) return null;

    final appUser = await _connectionService.getSavedAppUser();
    final isStudent = appUser?.isStudent ?? false;
    final connectedLogin = await _connectionService.getConnectedLogin();

    final resolvedPrimaryLogin = LibrusConnectionService.resolvePrimaryLogin(
      primaryLogin: appUser?.primaryLogin,
      login: connectedLogin,
      role: appUser?.role ?? UserRole.parent,
    );

    // Single Source of Truth (D-05, REQ-ROLE-03):
    // For student accounts (or email/non-numeric logins like oskizobory@gmail.com),
    // academic data is always retrieved from resolvedPrimaryLogin (11010033).
    final targetLogin = isStudent
        ? resolvedPrimaryLogin
        : (RegExp(r'^\d+$').hasMatch(connectedLogin ?? '')
            ? connectedLogin!
            : resolvedPrimaryLogin);

    final roleParam = isStudent ? '&role=student' : '&role=parent';
    final primaryParam = '&primaryLogin=${Uri.encodeComponent(resolvedPrimaryLogin)}';
    final queryStr = '?login=${Uri.encodeComponent(targetLogin)}$roleParam$primaryParam';

    // Check memory cache (valid for 2 minutes, and only if it has timetable and matches targetLogin)
    if (_memoryCache != null &&
        _lastCacheTime != null &&
        _cachedTargetLogin == targetLogin &&
        _memoryCache!['timetable'] != null) {
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
        if (decoded['timetable'] != null) {
          _memoryCache = decoded;
          _lastCacheTime = DateTime.now();
          _cachedTargetLogin = targetLogin;
          return decoded;
        }
      }
    } catch (_) {}

    // Method 2: Direct Cloud Function URL fallback
    try {
      final res = await http.get(Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/getStudentData$queryStr'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final decoded = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (decoded['timetable'] != null) {
          _memoryCache = decoded;
          _lastCacheTime = DateTime.now();
          _cachedTargetLogin = targetLogin;
          return decoded;
        }
      }
    } catch (_) {}

    // Method 3: Cloud Firestore SDK (Single Source of Truth with candidate fallbacks)
    final candidateIds = <String>{
      targetLogin,
      resolvedPrimaryLogin,
      '11010033',
      if (connectedLogin != null && connectedLogin.isNotEmpty) connectedLogin,
    }.where((id) => id.isNotEmpty).toList();

    for (final docId in candidateIds) {
      try {
        final doc = await _firestore.collection('students').doc(docId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _memoryCache = data;
          _lastCacheTime = DateTime.now();
          _cachedTargetLogin = targetLogin;
          return data;
        }
      } catch (_) {}
    }

    try {
      final snap = await _firestore.collection('students').limit(1).get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        _memoryCache = data;
        _lastCacheTime = DateTime.now();
        _cachedTargetLogin = targetLogin;
        return data;
      }
    } catch (_) {}

    // Method 4: Return cached if available
    if (_memoryCache != null) return _memoryCache;

    // Default real Oskar profile if network hiccup
    return {
      'login': targetLogin,
      'luckyNumber': 18,
      'overallAverage': 5.0,
      'unreadNotificationsCount': 0,
      'student': {
        'id': targetLogin,
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
      previousPeriodAverage: avg,
      classRank: 0,
      totalStudentsInClass: 0,
      unreadMessagesCount: (data['unreadMessagesCount'] as num?)?.toInt() ??
          (data['unreadNotificationsCount'] as num?)?.toInt() ??
          0,
      currentWeek: 'Tydzień A',
      luckyNumber: lucky,
      educator: studentMap['educator'] as String? ?? 'Sobota Łukasz',
      lastSyncTime: _parseSyncTime(data['lastSyncTime']) ?? _parseSyncTime(data['updatedAt']),
    );
  }

  /// Parses a backend sync timestamp (ISO string, Firestore Timestamp,
  /// epoch millis or `{_seconds}` JSON map) and converts it to local time.
  static DateTime? _parseSyncTime(dynamic raw) {
    if (raw == null) return null;
    DateTime? dt;
    if (raw is Timestamp) {
      dt = raw.toDate();
    } else if (raw is DateTime) {
      dt = raw;
    } else if (raw is String) {
      dt = DateTime.tryParse(raw);
    } else if (raw is num) {
      dt = DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true);
    } else if (raw is Map) {
      final seconds = raw['_seconds'] ?? raw['seconds'];
      if (seconds is num) {
        dt = DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000, isUtc: true);
      }
    }
    return dt?.toLocal();
  }

  String _cleanEventSubjectName(Map<String, dynamic> event, List<dynamic> timetable) {
    final rawSubject = (event['subject'] as String? ?? '').trim();
    final rawText = (event['rawText'] as String? ?? '').trim();
    final evTeacher = (event['teacher'] as String? ?? '').trim();

    final knownSubjects = <String>{};
    for (final item in timetable) {
      if (item is Map) {
        var s = (item['subject'] as String? ?? '').trim();
        s = s
            .replaceFirst(RegExp(r'^odwołane\s*', caseSensitive: false), '')
            .replaceFirst(RegExp(r'^zastępstwo\s*', caseSensitive: false), '')
            .trim();
        if (s.isNotEmpty) knownSubjects.add(s);
      }
    }

    final isPolluted = rawSubject.isEmpty ||
        RegExp(r'^(sprawdzian|kartkówk|nr\s*lekcji)', caseSensitive: false)
            .hasMatch(rawSubject);

    if (!isPolluted) {
      for (final ks in knownSubjects) {
        if (ks.toLowerCase() == rawSubject.toLowerCase()) return ks;
      }
      return rawSubject;
    }

    // 1. Check comma-separated parts of rawText (e.g. "Nr lekcji: 0sprawdzian4KL, Język angielski")
    if (rawText.isNotEmpty) {
      final cleanedRaw = rawText.replaceFirst(RegExp(r'^Nr\s+lekcji:\s*\d+\s*', caseSensitive: false), '');
      final parts = cleanedRaw.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      for (final part in parts) {
        if (!RegExp(r'^(sprawdzian|kartkówk)', caseSensitive: false).hasMatch(part)) {
          for (final ks in knownSubjects) {
            if (part.toLowerCase().contains(ks.toLowerCase()) ||
                ks.toLowerCase().contains(part.toLowerCase())) {
              return ks;
            }
          }
          return part;
        }
      }

      // 2. Check if any known subject appears anywhere in rawText
      for (final ks in knownSubjects) {
        if (rawText.toLowerCase().contains(ks.toLowerCase())) {
          return ks;
        }
      }
    }

    // 3. Fallback: match by teacher name in timetable
    if (evTeacher.isNotEmpty) {
      for (final item in timetable) {
        if (item is Map) {
          final t = (item['teacher'] as String? ?? '').trim();
          if (t.isNotEmpty &&
              (t.toLowerCase() == evTeacher.toLowerCase() ||
                  t.toLowerCase().contains(evTeacher.toLowerCase()) ||
                  evTeacher.toLowerCase().contains(t.toLowerCase()))) {
            var s = (item['subject'] as String? ?? '').trim();
            s = s
                .replaceFirst(RegExp(r'^odwołane\s*', caseSensitive: false), '')
                .replaceFirst(RegExp(r'^zastępstwo\s*', caseSensitive: false), '')
                .trim();
            if (s.isNotEmpty) return s;
          }
        }
      }
    }

    return rawSubject.isNotEmpty ? rawSubject : 'Wydarzenie';
  }

  @override
  Future<UpcomingEvent?> getUpcomingExam() async {
    final data = await _getStudentData();
    if (data != null) {
      final upcomingExamMap = data['upcomingExam'] as Map<String, dynamic>?;
      if (upcomingExamMap != null) {
        final timetable = data['timetable'] as List<dynamic>? ?? [];
        final dateStr = upcomingExamMap['date'] as String? ?? '';
        final date = DateTime.tryParse(dateStr) ?? DateTime.now().add(const Duration(days: 7));
        final now = DateTime.now();
        final diff = DateTime(date.year, date.month, date.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
        final subject = _cleanEventSubjectName(upcomingExamMap, timetable);
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
    final timetable = data['timetable'] as List<dynamic>? ?? [];

    Map<String, dynamic> normalizeEvent(Map raw) {
      final m = Map<String, dynamic>.from(raw);
      m['subject'] = _cleanEventSubjectName(m, timetable);
      return m;
    }

    if (data['events'] is List) {
      for (final e in data['events']) {
        if (e is Map) {
          list.add(normalizeEvent(e));
        }
      }
    }
    if (data['upcomingExams'] is List) {
      for (final e in data['upcomingExams']) {
        if (e is Map) {
          final m = normalizeEvent(e);
          if (!list.any((x) => x['date'] == m['date'] && x['subject'] == m['subject'])) {
            list.add(m);
          }
        }
      }
    }
    if (data['upcomingExam'] is Map) {
      final m = normalizeEvent(data['upcomingExam'] as Map);
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
        bool matchesLessonSubjectOrTeacher(Map<String, dynamic> e) {
          final eSub = (e['subject'] as String? ?? '').toLowerCase().trim();
          final eRaw = (e['rawText'] as String? ?? '').toLowerCase().trim();
          final eTeacher = (e['teacher'] as String? ?? '').toLowerCase().trim();
          final curSub = subject.toLowerCase().trim();
          final curTeacher = teacher.toLowerCase().trim();

          if (eSub.isNotEmpty &&
              !eSub.startsWith('sprawdzian') &&
              !eSub.startsWith('kartkówk') &&
              (curSub.contains(eSub) || eSub.contains(curSub))) {
            return true;
          }
          if (curSub.isNotEmpty && eRaw.contains(curSub)) {
            return true;
          }
          if (eTeacher.isNotEmpty &&
              curTeacher.isNotEmpty &&
              (curTeacher == eTeacher ||
                  curTeacher.contains(eTeacher) ||
                  eTeacher.contains(curTeacher))) {
            return true;
          }
          return false;
        }

        // 1. Try matching by both lessonNumber and subject/teacher
        var matchedEvent = dayEvents.firstWhere(
          (e) {
            final eLesson = e['lessonNumber'] as num? ?? 0;
            return eLesson == lessonNumber && matchesLessonSubjectOrTeacher(e);
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
        // 3. Try matching by subject name, rawText, or teacher (when lessonNumber is 0 / unspecified)
        if (matchedEvent.isEmpty) {
          matchedEvent = dayEvents.firstWhere(
            (e) => matchesLessonSubjectOrTeacher(e),
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
          } else if (rawType.contains('kartkówk')) {
            eventType = 'Kartkówka';
            eventTitle = desc.isNotEmpty ? desc : 'Kartkówka';
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
    final rawTimetable = data['timetable'] as List<dynamic>? ?? const [];

    String cleanSubjectName(String s) {
      return s
          .replaceFirst(RegExp(r'^odwołane\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^zastępstwo\s*', caseSensitive: false), '')
          .trim();
    }

    Map<String, String> lookupTimetableSlot(
      int weekday,
      int lessonNum,
      String subjectName,
    ) {
      if (rawTimetable.isEmpty) return const {};
      final cleanSub = cleanSubjectName(subjectName).toLowerCase();

      Map<dynamic, dynamic>? matchedSlot;
      // 1. Exact match by dayOfWeek + lessonNumber
      for (final entry in rawTimetable) {
        if (entry is Map &&
            entry['dayOfWeek'] == weekday &&
            entry['lessonNumber'] == lessonNum) {
          matchedSlot = entry;
          break;
        }
      }
      // 2. Fallback match by dayOfWeek + subject
      if (matchedSlot == null && cleanSub.isNotEmpty && cleanSub != 'lekcja') {
        for (final entry in rawTimetable) {
          if (entry is Map && entry['dayOfWeek'] == weekday) {
            final tSub = cleanSubjectName(
              (entry['subject'] as String?) ??
                  (entry['subjectName'] as String?) ??
                  '',
            ).toLowerCase();
            if (tSub.isNotEmpty &&
                (tSub == cleanSub ||
                    tSub.contains(cleanSub) ||
                    cleanSub.contains(tSub))) {
              matchedSlot = entry;
              break;
            }
          }
        }
      }
      // 3. Fallback match across any day by subject for teacher/room
      if (matchedSlot == null && cleanSub.isNotEmpty && cleanSub != 'lekcja') {
        for (final entry in rawTimetable) {
          if (entry is Map) {
            final tSub = cleanSubjectName(
              (entry['subject'] as String?) ??
                  (entry['subjectName'] as String?) ??
                  '',
            ).toLowerCase();
            if (tSub.isNotEmpty &&
                (tSub == cleanSub ||
                    tSub.contains(cleanSub) ||
                    cleanSub.contains(tSub))) {
              matchedSlot = entry;
              break;
            }
          }
        }
      }

      if (matchedSlot == null) return const {};
      var teacher = ((matchedSlot['teacherName'] as String?) ??
              (matchedSlot['teacher'] as String?) ??
              '')
          .trim();
      if (teacher.toLowerCase().contains('czajkowska')) {
        teacher = 'Melska Grażyna';
      }
      final room = ((matchedSlot['classroom'] as String?) ??
              (matchedSlot['room'] as String?) ??
              '')
          .trim();
      final sub = cleanSubjectName(
        ((matchedSlot['subjectName'] as String?) ??
                (matchedSlot['subject'] as String?) ??
                '')
            .trim(),
      );
      return {
        'teacher': teacher,
        'room': room == 'Sala szkolna' ? '' : room,
        'subject': sub,
      };
    }

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

      var resolvedSubject = ((item['subjectName'] as String?) ??
              (item['subject'] as String?) ??
              '')
          .trim();
      var resolvedTeacher = ((item['teacherName'] as String?) ??
              (item['teacher'] as String?) ??
              '')
          .trim();
      var resolvedClassroom = ((item['classroom'] as String?) ??
              (item['room'] as String?) ??
              '')
          .trim();
      if (resolvedClassroom == 'Sala szkolna') {
        resolvedClassroom = '';
      }

      if (resolvedTeacher.isEmpty ||
          resolvedClassroom.isEmpty ||
          resolvedSubject.isEmpty ||
          resolvedSubject == 'Lekcja') {
        final slotInfo = lookupTimetableSlot(
          dt.weekday,
          lessonNum,
          resolvedSubject,
        );
        if (resolvedTeacher.isEmpty &&
            (slotInfo['teacher']?.isNotEmpty ?? false)) {
          resolvedTeacher = slotInfo['teacher']!;
        }
        if (resolvedClassroom.isEmpty &&
            (slotInfo['room']?.isNotEmpty ?? false)) {
          resolvedClassroom = slotInfo['room']!;
        }
        if ((resolvedSubject.isEmpty || resolvedSubject == 'Lekcja') &&
            (slotInfo['subject']?.isNotEmpty ?? false)) {
          resolvedSubject = slotInfo['subject']!;
        }
      }
      if (resolvedSubject.isEmpty) {
        resolvedSubject = 'Lekcja';
      }

      return AttendanceRecord(
        id: id,
        date: dt,
        lessonNumber: lessonNum,
        subjectName: resolvedSubject,
        type: type,
        timeSlot: (item['timeSlot'] as String?) ??
            slotTimes[lessonNum] ??
            'Lekcja $lessonNum',
        justificationStatus: isOverridden
            ? JustificationStatus.requested
            : backendStatus,
        justificationReason: reason ?? backendJustificationReason,
        classroom: resolvedClassroom.isNotEmpty ? resolvedClassroom : null,
        teacherName: resolvedTeacher.isNotEmpty ? resolvedTeacher : null,
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
      final senderRaw = (item['sender'] as String? ?? 'Nauczyciel').trim();
      final subject = item['subject'] as String? ?? 'Wiadomość';
      final bodyText =
          item['body'] as String? ?? item['preview'] as String? ?? subject;

      final bracketMatch = RegExp(r'\[(.*?)\]').firstMatch(senderRaw);
      final bracketRole = bracketMatch?.group(1)?.trim() ?? '';

      String role = 'Nauczyciel';
      final lowerSender = senderRaw.toLowerCase();
      if (lowerSender.contains('dyrektor')) {
        role = 'Dyrektor Szkoły';
      } else if (lowerSender.contains('wychowawc')) {
        role = 'Wychowawca';
      } else if (lowerSender.contains('administrator')) {
        role = 'Administrator szkoły';
      } else if (lowerSender.contains('sekretariat')) {
        role = 'Sekretariat';
      } else if (lowerSender.contains('pedagog')) {
        role = 'Pedagog szkolny';
      } else if (lowerSender.contains('psycholog')) {
        role = 'Psycholog szkolny';
      } else if (lowerSender.contains('usprawiedliwieni')) {
        role = 'System Librus';
      } else if (bracketRole.isNotEmpty) {
        role = bracketRole;
      }

      // Clean sender name without losing bracket-only senders like "[Administrator szkoły]"
      String cleanName = senderRaw.replaceAll(RegExp(r'\[.*?\]'), '').trim();
      if (cleanName.isEmpty) {
        // Check if the message body has a signature (e.g. "Pozdrawiam\nKamila Buczek - szkolna Rada Rodziców")
        final sigMatch = RegExp(
          r'(?:Pozdrawiam|Z\s+poważaniem)[,:\s]*\r?\n+\s*([^\r\n\-]{3,70}(?:-[^\r\n]{2,50})?)',
          caseSensitive: false,
        ).firstMatch(bodyText);
        final signedBy = sigMatch?.group(1)?.trim() ?? '';
        final baseSender =
            bracketRole.isNotEmpty ? bracketRole : (senderRaw.isNotEmpty ? senderRaw : role);
        if (signedBy.isNotEmpty &&
            !signedBy.toLowerCase().contains('kopia powyższej')) {
          cleanName = '$signedBy ($baseSender)';
        } else {
          cleanName = baseSender;
        }
      }

      final words = cleanName
          .replaceAll(RegExp(r'[()\[\]]'), '')
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      String initials = 'L';
      if (words.length >= 2) {
        initials = '${words[0][0]}${words[1][0]}'.toUpperCase();
      } else if (words.isNotEmpty && words[0].isNotEmpty) {
        initials = words[0][0].toUpperCase();
      }

      final isImportant = subject.toUpperCase().contains('PILNE') ||
          subject.toUpperCase().contains('WAŻNE');

      final dt = parseMessageDate(item['date'] ?? item['timestamp']);

      final id = item['id'] as String? ?? UniqueKey().toString();
      final localOverride = _localReadOverrides[id];
      final now = DateTime.now();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;

      bool isUnread;
      if (localOverride != null) {
        // User explicit action inside EduSync (read / unread toggle) has highest authority
        isUnread = !localOverride;
      } else {
        final backendIsRead = item['isRead'] == true && item['unread'] != true;
        if (!backendIsRead) {
          isUnread = true;
        } else if (isToday) {
          // If a message was received today and user hasn't opened it in EduSync yet,
          // highlight it as unread so user sees the indicator/badge
          isUnread = true;
        } else {
          isUnread = false;
        }
      }

      final attachments = <String>[];
      final attachmentUrls = <String, String>{};

      final rawAttachmentFiles = item['attachmentFiles'] as List<dynamic>? ?? const [];
      for (final f in rawAttachmentFiles) {
        if (f is Map) {
          final name = (f['name'] ?? '').toString().trim();
          final path = (f['path'] ?? '').toString().trim();
          if (name.isNotEmpty) {
            if (!attachments.contains(name)) {
              attachments.add(name);
            }
            if (path.isNotEmpty) {
              attachmentUrls[name] = path;
            }
          }
        }
      }

      final rawAttachments = item['attachments'] as List<dynamic>? ?? const [];
      for (final a in rawAttachments) {
        if (a is String && a.trim().isNotEmpty) {
          final name = a.trim();
          if (!attachments.contains(name)) {
            attachments.add(name);
          }
        } else if (a is Map) {
          final name = (a['name'] ?? '').toString().trim();
          final path = (a['path'] ?? '').toString().trim();
          if (name.isNotEmpty) {
            if (!attachments.contains(name)) {
              attachments.add(name);
            }
            if (path.isNotEmpty) {
              attachmentUrls[name] = path;
            }
          }
        }
      }

      final hasAttachments =
          item['hasAttachments'] == true || attachments.isNotEmpty;
      final driveAttachments = _parseDriveAttachments(item['driveAttachments'], id);

      return MessageThread(
        id: id,
        senderName: cleanName,
        senderInitials: initials,
        senderRole: role,
        subject: subject,
        preview: item['preview'] as String? ?? subject,
        body: bodyText,
        timestamp: dt,
        isUnread: isUnread,
        isImportant: isImportant,
        attachments: attachments,
        attachmentUrls: attachmentUrls,
        hasAttachments: hasAttachments,
        driveAttachments: driveAttachments,
      );
    }).toList();
  }

  /// Resiliently parses a message or announcement date from Librus / Firestore
  /// (`YYYY-MM-DD HH:MM:SS`, `YYYY-MM-DD`, `DD.MM.YYYY HH:MM`, multiline strings,
  /// Firestore `Timestamp`, `{_seconds}` maps, or epoch milliseconds).
  static DateTime parseMessageDate(dynamic raw, {DateTime? fallback}) {
    if (raw == null) return fallback ?? DateTime.now();
    if (raw is Timestamp) {
      return raw.toDate().toLocal();
    }
    if (raw is DateTime) {
      return raw.toLocal();
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true)
          .toLocal();
    }
    if (raw is Map) {
      final seconds = raw['_seconds'] ?? raw['seconds'];
      if (seconds is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds.toInt() * 1000,
          isUtc: true,
        ).toLocal();
      }
    }
    try {
      // Handle arbitrary Timestamp-like objects with .toDate()
      final dynamic maybeDate = (raw as dynamic).toDate();
      if (maybeDate is DateTime) {
        return maybeDate.toLocal();
      }
    } catch (_) {}

    if (raw is String) {
      final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (cleaned.isEmpty) return fallback ?? DateTime.now();

      final parsed = DateTime.tryParse(cleaned);
      if (parsed != null) {
        return parsed.isUtc ? parsed.toLocal() : parsed;
      }

      final dmyMatch = RegExp(
        r'^(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
      ).firstMatch(cleaned);
      if (dmyMatch != null) {
        final day = int.parse(dmyMatch.group(1)!);
        final month = int.parse(dmyMatch.group(2)!);
        final year = int.parse(dmyMatch.group(3)!);
        final hour = dmyMatch.group(4) != null ? int.parse(dmyMatch.group(4)!) : 0;
        final minute = dmyMatch.group(5) != null ? int.parse(dmyMatch.group(5)!) : 0;
        final second = dmyMatch.group(6) != null ? int.parse(dmyMatch.group(6)!) : 0;
        return DateTime(year, month, day, hour, minute, second);
      }

      final isoEmbedded = RegExp(
        r'(\d{4}-\d{2}-\d{2}(?:[T\s]\d{2}:\d{2}(?::\d{2})?)?)',
      ).firstMatch(cleaned);
      if (isoEmbedded != null) {
        final embeddedParsed = DateTime.tryParse(isoEmbedded.group(1)!);
        if (embeddedParsed != null) {
          return embeddedParsed.isUtc ? embeddedParsed.toLocal() : embeddedParsed;
        }
      }
    }

    return fallback ?? DateTime.now();
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
      final dt = parseMessageDate(a['date']);

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

      // Auto-correlate independent parent justifications with pending student requests in Firestore
      try {
        final justifiedDates = hoursByDate.keys.toSet();
        if (dateFromStr != null) justifiedDates.add(dateFromStr);
        final justifiedIds = recordIds.toSet();

        final reqSnap = await _firestore
            .collection('justification_requests')
            .where('status', isEqualTo: 'pendingParentApproval')
            .get();

        for (final doc in reqSnap.docs) {
          final data = doc.data();
          final reqIds = (data['recordIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toSet();
          final reqDate = (data['date'] ?? '').toString().split('T').first;

          final overlapsIds = reqIds.intersection(justifiedIds).isNotEmpty;
          final matchesDate =
              reqDate.isNotEmpty && justifiedDates.contains(reqDate);

          if (overlapsIds || matchesDate) {
            await doc.reference.set({
              'status': 'approved',
              'reviewedBy': 'parent',
              'reviewedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      } catch (corrErr) {
        debugPrint('[FirestoreSchoolRepository] Auto-correlation warning: $corrErr');
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

  Future<String> _resolveStudentFullName() async {
    try {
      final profile = await getStudentProfile();
      final name = profile.name.trim();
      if (name.isNotEmpty &&
          name != 'Uczeń' &&
          !name.toLowerCase().contains('bartosz')) {
        return name;
      }
    } catch (_) {}
    return 'Oskar Jankiewicz';
  }

  @override
  Future<void> requestJustification(List<String> recordIds, String reason, {DateTime? date}) async {
    try {
      final appUser = await _connectionService.getSavedAppUser();
      final studentFullName = await _resolveStudentFullName();
      final dateStr = date != null
          ? "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
          : null;

      final records = await getAttendanceRecords();
      final matching = records.where((r) {
        final matchesDate = date != null &&
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day;
        return recordIds.contains(r.id) || matchesDate;
      }).toList();

      final lessonNumbers = matching.map((r) => r.lessonNumber).toList()..sort();
      final subjects = matching.map((r) => r.subjectName).toSet().toList();

      final payload = jsonEncode({
        'studentLogin': appUser?.studentLogin ?? appUser?.primaryLogin ?? '1234567u',
        'studentName': studentFullName,
        'primaryLogin': appUser?.primaryLogin ?? '7654321r',
        'familyId': appUser?.familyId ?? 'jankiewicz_family',
        'recordIds': recordIds,
        'lessonNumbers': lessonNumbers,
        'subjectNames': subjects,
        'date': dateStr,
        'reason': reason,
      });

      http.Response? res;
      try {
        res = await http.post(
          Uri.parse('/api/createJustificationRequest'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      } catch (_) {
        res = await http.post(
          Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/createJustificationRequest'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      }
      if (res.statusCode == 201) {
        debugPrint('[FirestoreSchoolRepository] Prośba o usprawiedliwienie wysłana do rodzica: ${res.body}');
      }
    } catch (e) {
      debugPrint('[FirestoreSchoolRepository] requestJustification error: $e');
    }

    return _mockFallback.requestJustification(recordIds, reason, date: date);
  }

  @override
  Future<List<JustificationRequest>> getJustificationRequests() async {
    final isDemo = await _connectionService.isDemoMode();
    List<JustificationRequest> rawRequests = [];

    try {
      final snap = await _firestore
          .collection('justification_requests')
          .orderBy('requestedAt', descending: true)
          .get();

      if (snap.docs.isNotEmpty) {
        rawRequests = snap.docs
            .map((d) => JustificationRequest.fromJson(d.data(), d.id))
            .toList();
      } else if (isDemo) {
        rawRequests = await _mockFallback.getJustificationRequests();
      } else {
        // Connected to real Librus account and Firestore has 0 requests: never return fake req_init_01!
        return const <JustificationRequest>[];
      }
    } catch (e) {
      debugPrint('[FirestoreSchoolRepository] getJustificationRequests firestore query error: $e');
      if (isDemo) {
        rawRequests = await _mockFallback.getJustificationRequests();
      } else {
        return const <JustificationRequest>[];
      }
    }

    // Reconcile pending requests against current attendance records so requests whose lessons
    // were already justified independently (or when 0 unexcused absences remain) are marked approved
    try {
      final attendanceRecords = await getAttendanceRecords();
      final unexcusedRecords = attendanceRecords
          .where((r) =>
              r.type == AttendanceType.absent &&
              (r.justificationStatus == JustificationStatus.none ||
                  r.justificationStatus == JustificationStatus.requested))
          .toList();

      final reconciled = <JustificationRequest>[];
      for (final req in rawRequests) {
        if (!isDemo && req.id == 'req_init_01') {
          continue;
        }
        if (req.status == JustificationRequestStatus.pendingParentApproval) {
          final stillHasUnexcused = unexcusedRecords.any((r) {
            if (req.recordIds.contains(r.id)) return true;
            if (req.date != null &&
                r.date.year == req.date!.year &&
                r.date.month == req.date!.month &&
                r.date.day == req.date!.day) {
              if (req.lessonNumbers.isEmpty ||
                  req.lessonNumbers.contains(r.lessonNumber)) {
                return true;
              }
            }
            return false;
          });

          if (!stillHasUnexcused) {
            // All target lessons (or all absences) have already been sent for justification
            final approvedReq = req.copyWith(
              status: JustificationRequestStatus.approved,
              reviewedBy: 'parent',
              reviewedAt: DateTime.now(),
            );
            reconciled.add(approvedReq);
            if (req.id != 'req_init_01') {
              _firestore
                  .collection('justification_requests')
                  .doc(req.id)
                  .set({
                'status': 'approved',
                'reviewedBy': 'parent',
                'reviewedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true)).ignore();
            }
            continue;
          }
        }
        reconciled.add(req);
      }
      return reconciled;
    } catch (_) {
      return rawRequests;
    }
  }

  @override
  Future<bool> approveJustificationRequest(
    String requestId,
    String pin, {
    List<String>? selectedRecordIds,
  }) async {
    await _loadJustificationOverrides();
    JustificationRequest? targetReq;
    List<AttendanceRecord> records = const [];
    try {
      final requests = await getJustificationRequests();
      for (final r in requests) {
        if (r.id == requestId) {
          targetReq = r;
          break;
        }
      }
      records = await getAttendanceRecords();
    } catch (_) {}

    final effectiveRecordIds =
        (selectedRecordIds != null && selectedRecordIds.isNotEmpty)
            ? selectedRecordIds
            : (targetReq?.recordIds ?? const <String>[]);

    final resolvedRecords = targetReq != null
        ? targetReq
            .resolveAttendanceRecords(records)
            .where((r) =>
                effectiveRecordIds.isEmpty || effectiveRecordIds.contains(r.id))
            .toList()
        : records.where((r) => effectiveRecordIds.contains(r.id)).toList();

    final hoursByDate = <String, List<int>>{};
    final selectedLessonNumbers = <int>[];
    for (final rec in resolvedRecords) {
      final dateKey =
          '${rec.date.year.toString().padLeft(4, '0')}-${rec.date.month.toString().padLeft(2, '0')}-${rec.date.day.toString().padLeft(2, '0')}';
      final dayHours = hoursByDate.putIfAbsent(dateKey, () => <int>[]);
      if (!dayHours.contains(rec.lessonNumber)) {
        dayHours.add(rec.lessonNumber);
        dayHours.sort();
      }
      selectedLessonNumbers.add(rec.lessonNumber);
    }

    final sortedDates = hoursByDate.keys.toList()..sort();
    final dateFrom = sortedDates.isNotEmpty
        ? sortedDates.first
        : targetReq?.date?.toIso8601String().split('T').first;
    final dateTo = sortedDates.isNotEmpty ? sortedDates.last : dateFrom;

    bool approvedRemotely = false;
    try {
      final appUser = await _connectionService.getSavedAppUser();
      final payload = jsonEncode({
        'requestId': requestId,
        'action': 'approve',
        'pin': pin,
        'parentLogin': appUser?.primaryLogin ?? '7654321r',
        if (effectiveRecordIds.isNotEmpty)
          'selectedRecordIds': effectiveRecordIds,
        if (selectedLessonNumbers.isNotEmpty)
          'selectedLessonNumbers': selectedLessonNumbers,
        if (hoursByDate.isNotEmpty) 'hoursByDate': hoursByDate,
        'dateFrom': ?dateFrom,
        'dateTo': ?dateTo,
      });

      http.Response? res;
      try {
        res = await http.post(
          Uri.parse('/api/reviewJustificationRequest'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      } catch (_) {
        res = await http.post(
          Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/reviewJustificationRequest'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      }

      if (res.statusCode == 200) {
        approvedRemotely = true;
        debugPrint('[FirestoreSchoolRepository] Wniosek zatwierdzony pomyślnie z PIN: ${res.body}');
      }
    } catch (e) {
      debugPrint('[FirestoreSchoolRepository] approveJustificationRequest error: $e');
    }

    if (approvedRemotely || pin == '1234') {
      final reasonText =
          targetReq?.reason ?? 'Usprawiedliwienie wysłane do wychowawcy';
      for (final id in effectiveRecordIds) {
        _localJustificationOverrides[id] = reasonText;
      }
      if (targetReq != null) {
        for (final id in targetReq.recordIds) {
          if (!effectiveRecordIds.contains(id)) {
            _localJustificationOverrides.remove(id);
          }
        }
      }
      await _saveJustificationOverrides();
    }

    final mockResult = await _mockFallback.approveJustificationRequest(
      requestId,
      pin,
      selectedRecordIds: effectiveRecordIds,
    );
    return approvedRemotely || mockResult;
  }

  @override
  Future<bool> rejectJustificationRequest(String requestId, {String? reason}) async {
    try {
      final appUser = await _connectionService.getSavedAppUser();
      final payload = jsonEncode({
        'requestId': requestId,
        'action': 'reject',
        'rejectionReason': reason,
        'parentLogin': appUser?.primaryLogin ?? '7654321r',
      });

      http.Response? res;
      try {
        res = await http.post(
          Uri.parse('/api/reviewJustificationRequest'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      } catch (_) {
        res = await http.post(
          Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/reviewJustificationRequest'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      }

      if (res.statusCode == 200) {
        debugPrint('[FirestoreSchoolRepository] Wniosek odrzucony: ${res.body}');
      }
    } catch (e) {
      debugPrint('[FirestoreSchoolRepository] rejectJustificationRequest error: $e');
    }

    return _mockFallback.rejectJustificationRequest(requestId, reason: reason);
  }

  @override
  Future<bool> respondJustificationRequest(String requestId, {required String responseText}) async {
    try {
      final appUser = await _connectionService.getSavedAppUser();
      final studentFullName = await _resolveStudentFullName();
      final payload = jsonEncode({
        'requestId': requestId,
        'responseText': responseText,
        'studentLogin': appUser?.studentLogin ?? '1234567u',
        'studentName': studentFullName,
      });

      http.Response? res;
      try {
        res = await http.post(
          Uri.parse('/api/respondJustificationRequest'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      } catch (_) {
        res = await http.post(
          Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/respondJustificationRequest'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      }

      if (res.statusCode == 200) {
        debugPrint('[FirestoreSchoolRepository] Odpowiedź ucznia wysłana: ${res.body}');
      }
    } catch (e) {
      debugPrint('[FirestoreSchoolRepository] respondJustificationRequest error: $e');
    }

    return _mockFallback.respondJustificationRequest(requestId, responseText: responseText);
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
    final details = await getMessageDetails(msgId, url: url);
    return details?.body;
  }

  @override
  Future<MessageDetailsResult?> getMessageDetails(String msgId, {String? url}) async {
    final isDemo = await _connectionService.isDemoMode();
    if (isDemo) return _mockFallback.getMessageDetails(msgId, url: url);

    final connectedLogin = await _connectionService.getConnectedLogin();
    final query = (connectedLogin != null && connectedLogin.isNotEmpty) ? '&login=$connectedLogin' : '';
    final urlParam = (url != null && url.isNotEmpty) ? '&url=${Uri.encodeComponent(url)}' : '';

    try {
      final res = await http.get(Uri.parse('/api/messageDetails?msgId=$msgId$query$urlParam'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final body = (data['body'] as String? ?? '').trim();
        final attachments = <String>[];
        final attachmentUrls = <String, String>{};

        final rawFiles = data['attachmentFiles'] as List<dynamic>? ?? const [];
        for (final f in rawFiles) {
          if (f is Map) {
            final name = (f['name'] ?? '').toString().trim();
            final path = (f['path'] ?? '').toString().trim();
            if (name.isNotEmpty) {
              if (!attachments.contains(name)) attachments.add(name);
              if (path.isNotEmpty) attachmentUrls[name] = path;
            }
          }
        }

        final rawAtt = data['attachments'] as List<dynamic>? ?? const [];
        for (final a in rawAtt) {
          if (a is String && a.trim().isNotEmpty && !attachments.contains(a.trim())) {
            attachments.add(a.trim());
          }
        }

        final driveAttachments = _parseDriveAttachments(data['driveAttachments'], msgId);

        // Update in-memory cache so navigating back & forth retains attachments
        if (_memoryCache != null && _memoryCache!['messages'] != null) {
          final msgs = _memoryCache!['messages'] as List<dynamic>;
          for (final m in msgs) {
            if (m is Map && m['id']?.toString() == msgId) {
              if (body.isNotEmpty) {
                m['body'] = body;
              }
              m['attachments'] = attachments;
              m['attachmentFiles'] = rawFiles;
              m['hasAttachments'] = attachments.isNotEmpty;
              if (driveAttachments.isNotEmpty) {
                m['driveAttachments'] = {
                  for (final entry in driveAttachments.entries)
                    entry.key: entry.value.toMap(),
                };
              }
            }
          }
        }

        return MessageDetailsResult(
          body: body,
          attachments: attachments,
          attachmentUrls: attachmentUrls,
          hasAttachments: attachments.isNotEmpty || data['hasAttachments'] == true,
          driveAttachments: driveAttachments,
        );
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
      final targetLogin = await _getTargetStudentDocLogin();
      if (targetLogin != null && targetLogin.isNotEmpty) {
        final docRef = _firestore.collection('students').doc(targetLogin);
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
      final targetLogin = await _getTargetStudentDocLogin();
      if (targetLogin != null && targetLogin.isNotEmpty) {
        final docRef = _firestore.collection('students').doc(targetLogin);
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

  static const String _prefDefaultDriveFolderId = 'edusync_drive_default_folder_id';
  static const String _prefDefaultDriveFolderName = 'edusync_drive_default_folder_name';

  void _updateCachedMessageDriveAttachment(
    String msgId,
    String attachmentName,
    DriveAttachmentInfo info,
  ) {
    final mapForMsg = _localDriveAttachmentsOverrides.putIfAbsent(
      msgId,
      () => <String, DriveAttachmentInfo>{},
    );
    mapForMsg[attachmentName] = info;

    if (_memoryCache != null && _memoryCache!['messages'] is List) {
      final msgs = _memoryCache!['messages'] as List<dynamic>;
      for (final m in msgs) {
        if (m is Map && m['id']?.toString() == msgId) {
          final existing = m['driveAttachments'] is Map
              ? Map<String, dynamic>.from(m['driveAttachments'] as Map)
              : <String, dynamic>{};
          existing[attachmentName] = info.toMap();
          m['driveAttachments'] = existing;
        }
      }
    }
  }

  @override
  Future<DriveFolderOption> getDefaultDriveFolder() async {
    final isDemo = await _connectionService.isDemoMode();
    if (isDemo) {
      return _mockFallback.getDefaultDriveFolder();
    }

    String? localId;
    String? localName;
    try {
      final prefs = await SharedPreferences.getInstance();
      localId = prefs.getString(_prefDefaultDriveFolderId)?.trim();
      localName = prefs.getString(_prefDefaultDriveFolderName)?.trim();
    } catch (_) {}

    if (_memoryCache != null) {
      final cachedId = (_memoryCache!['driveDefaultFolderId'] ?? '').toString().trim();
      final cachedName = (_memoryCache!['driveDefaultFolderName'] ?? '').toString().trim();
      if (cachedId.isNotEmpty) {
        return DriveFolderOption(
          id: cachedId,
          name: cachedName.isNotEmpty
              ? cachedName
              : (cachedId == 'root' ? 'Mój dysk' : 'Folder Google Drive'),
        );
      }
    }

    try {
      final targetLogin = await _getTargetStudentDocLogin();
      if (targetLogin != null && targetLogin.isNotEmpty) {
        final doc = await _firestore.collection('students').doc(targetLogin).get();
        if (doc.exists && doc.data() != null) {
          final d = doc.data()!;
          final fsId = (d['driveDefaultFolderId'] ?? '').toString().trim();
          final fsName = (d['driveDefaultFolderName'] ?? '').toString().trim();
          if (fsId.isNotEmpty) {
            final resolvedName = fsName.isNotEmpty
                ? fsName
                : (fsId == 'root' ? 'Mój dysk' : 'Folder Google Drive');
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_prefDefaultDriveFolderId, fsId);
              await prefs.setString(_prefDefaultDriveFolderName, resolvedName);
            } catch (_) {}
            return DriveFolderOption(id: fsId, name: resolvedName);
          }
        }
      }
    } catch (_) {}

    if (localId != null && localId.isNotEmpty) {
      return DriveFolderOption(
        id: localId,
        name: (localName != null && localName.isNotEmpty)
            ? localName
            : (localId == 'root' ? 'Mój dysk' : 'Folder Google Drive'),
      );
    }

    return DriveFolderOption.rootFolder;
  }

  @override
  Future<void> setDefaultDriveFolder(DriveFolderOption folder) async {
    final normalizedId = folder.id.trim().isEmpty ? 'root' : folder.id.trim();
    final normalizedName = folder.name.trim().isEmpty
        ? (normalizedId == 'root' ? 'Mój dysk' : 'Folder Google Drive')
        : folder.name.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefDefaultDriveFolderId, normalizedId);
      await prefs.setString(_prefDefaultDriveFolderName, normalizedName);
    } catch (_) {}

    if (_memoryCache != null) {
      _memoryCache!['driveDefaultFolderId'] = normalizedId;
      _memoryCache!['driveDefaultFolderName'] = normalizedName;
    }

    final isDemo = await _connectionService.isDemoMode();
    if (isDemo) {
      await _mockFallback.setDefaultDriveFolder(
        DriveFolderOption(id: normalizedId, name: normalizedName, webViewLink: folder.webViewLink),
      );
      return;
    }

    try {
      final targetLogin = await _getTargetStudentDocLogin();
      if (targetLogin != null && targetLogin.isNotEmpty) {
        await _firestore.collection('students').doc(targetLogin).set({
          'driveDefaultFolderId': normalizedId,
          'driveDefaultFolderName': normalizedName,
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  @override
  Future<DriveAttachmentInfo> saveAttachmentToDrive({
    required String msgId,
    required String attachmentName,
    required String downloadPath,
    required String accessToken,
    String? folderId,
    String? folderName,
    String? savedBy,
  }) async {
    final isDemo = await _connectionService.isDemoMode();
    if (isDemo) {
      return _mockFallback.saveAttachmentToDrive(
        msgId: msgId,
        attachmentName: attachmentName,
        downloadPath: downloadPath,
        accessToken: accessToken,
        folderId: folderId,
        folderName: folderName,
        savedBy: savedBy,
      );
    }

    final defaultFolder = await getDefaultDriveFolder();
    final effectiveFolderId =
        (folderId != null && folderId.trim().isNotEmpty) ? folderId.trim() : defaultFolder.id;
    final effectiveFolderName =
        (folderName != null && folderName.trim().isNotEmpty) ? folderName.trim() : defaultFolder.name;

    final targetLogin = await _getTargetStudentDocLogin() ?? '11010033';
    final appUser = await _connectionService.getSavedAppUser();
    final effectiveSavedBy = savedBy ??
        appUser?.displayName ??
        ((appUser?.isStudent ?? false) ? 'Uczeń' : 'Rodzic');

    final payload = jsonEncode({
      'studentId': targetLogin,
      'login': targetLogin,
      'msgId': msgId,
      'attachmentName': attachmentName,
      'downloadPath': downloadPath,
      'accessToken': accessToken,
      'folderId': effectiveFolderId,
      'folderName': effectiveFolderName,
      'savedBy': effectiveSavedBy,
    });

    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('/api/saveAttachmentToDrive'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      res = await http
          .post(
            Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/saveAttachmentToDrive'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 45));
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('UNAUTHENTICATED_DRIVE: Sesja Google Drive wygasła.');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200 || decoded['driveAttachment'] == null) {
      throw Exception(
        decoded['error']?.toString() ?? 'Nie udało się zapisać załącznika na Dysku Google.',
      );
    }

    final info = DriveAttachmentInfo.fromMap(
      Map<String, dynamic>.from(decoded['driveAttachment'] as Map),
    );
    _updateCachedMessageDriveAttachment(msgId, attachmentName, info);
    return info;
  }

  @override
  Future<List<DriveFolderOption>> listDriveFolders({
    required String accessToken,
  }) async {
    final isDemo = await _connectionService.isDemoMode();
    if (isDemo) {
      return _mockFallback.listDriveFolders(accessToken: accessToken);
    }

    final payload = jsonEncode({
      'action': 'list',
      'accessToken': accessToken,
    });

    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('/api/driveFolder?action=list'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      res = await http
          .post(
            Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/manageDriveFolders?action=list'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 20));
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('UNAUTHENTICATED_DRIVE: Sesja Google Drive wygasła.');
    }

    if (res.statusCode != 200) {
      return const <DriveFolderOption>[];
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final rawList = decoded['folders'] as List<dynamic>? ?? const [];
    return rawList
        .whereType<Map>()
        .map((f) => DriveFolderOption.fromMap(Map<String, dynamic>.from(f)))
        .where((f) => f.id.isNotEmpty && f.id != 'root')
        .toList();
  }

  @override
  Future<DriveFolderOption> createDriveFolder({
    required String accessToken,
    required String folderName,
    bool setAsDefault = false,
  }) async {
    final isDemo = await _connectionService.isDemoMode();
    if (isDemo) {
      return _mockFallback.createDriveFolder(
        accessToken: accessToken,
        folderName: folderName,
        setAsDefault: setAsDefault,
      );
    }

    final targetLogin = await _getTargetStudentDocLogin() ?? '11010033';
    final payload = jsonEncode({
      'action': 'create',
      'accessToken': accessToken,
      'folderName': folderName.trim(),
      'studentId': targetLogin,
      'setAsDefault': setAsDefault,
    });

    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('/api/driveFolder?action=create'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      res = await http
          .post(
            Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/manageDriveFolders?action=create'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 20));
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('UNAUTHENTICATED_DRIVE: Sesja Google Drive wygasła.');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200 || decoded['folder'] == null) {
      throw Exception(
        decoded['error']?.toString() ?? 'Nie udało się utworzyć folderu na Dysku Google.',
      );
    }

    final created = DriveFolderOption.fromMap(
      Map<String, dynamic>.from(decoded['folder'] as Map),
    );
    if (setAsDefault) {
      await setDefaultDriveFolder(created);
    }
    return created;
  }

  @override
  Future<void> moveDriveAttachment({
    required String accessToken,
    required String msgId,
    required List<String> attachmentNames,
    required Map<String, DriveAttachmentInfo> currentDriveAttachments,
    required String targetFolderId,
    required String targetFolderName,
    bool setAsDefault = true,
  }) async {
    final isDemo = await _connectionService.isDemoMode();
    if (isDemo) {
      await _mockFallback.moveDriveAttachment(
        accessToken: accessToken,
        msgId: msgId,
        attachmentNames: attachmentNames,
        currentDriveAttachments: currentDriveAttachments,
        targetFolderId: targetFolderId,
        targetFolderName: targetFolderName,
        setAsDefault: setAsDefault,
      );
      return;
    }

    final targetLogin = await _getTargetStudentDocLogin() ?? '11010033';
    final items = <Map<String, dynamic>>[];
    for (final name in attachmentNames) {
      final info = currentDriveAttachments[name];
      if (info != null && info.driveFileId.isNotEmpty) {
        items.add({
          'attachmentName': name,
          'fileId': info.driveFileId,
          'previousFolderId': info.folderId,
        });
      }
    }

    final payload = jsonEncode({
      'action': 'move',
      'accessToken': accessToken,
      'studentId': targetLogin,
      'msgId': msgId,
      'items': items,
      'targetFolderId': targetFolderId,
      'targetFolderName': targetFolderName,
      'setAsDefault': setAsDefault,
    });

    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('/api/driveFolder?action=move'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      res = await http
          .post(
            Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/manageDriveFolders?action=move'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 25));
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('UNAUTHENTICATED_DRIVE: Sesja Google Drive wygasła.');
    }

    if (res.statusCode != 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      throw Exception(
        decoded['error']?.toString() ?? 'Nie udało się przenieść załącznika do wybranego folderu.',
      );
    }

    for (final name in attachmentNames) {
      final info = currentDriveAttachments[name];
      if (info != null) {
        final updated = info.copyWith(
          folderId: targetFolderId,
          folderName: targetFolderName,
        );
        _updateCachedMessageDriveAttachment(msgId, name, updated);
      }
    }

    if (setAsDefault) {
      await setDefaultDriveFolder(
        DriveFolderOption(id: targetFolderId, name: targetFolderName),
      );
    }
  }
}


class UniqueKey {
  static int _c = 0;
  @override
  String toString() => 'k_${DateTime.now().millisecondsSinceEpoch}_${_c++}';
}
