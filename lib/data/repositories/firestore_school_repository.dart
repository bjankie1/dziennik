import 'dart:convert';
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
    if (allGrades.isEmpty) return _mockFallback.getRecentGrades();
    allGrades.sort((a, b) => b.date.compareTo(a.date));
    return allGrades;
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    await _loadJustificationOverrides();
    final data = await _getStudentData();
    if (data == null || data['attendance'] == null) {
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
            : (type == AttendanceType.excused
                ? JustificationStatus.approved
                : JustificationStatus.none),
        justificationReason: reason,
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
    await _loadJustificationOverrides();
    for (final id in recordIds) {
      _localJustificationOverrides[id] = reason;
    }
    await _saveJustificationOverrides();
    return _mockFallback.submitJustification(recordIds, reason);
  }

  @override
  Future<List<TeacherContact>> getTeachers() async {
    final subjects = await getSubjects();
    final list = <TeacherContact>[];
    final seen = <String>{};

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

    final data = await _getStudentData();
    final studentMap = data?['student'] as Map<String, dynamic>?;
    final educator = studentMap?['educator'] as String?;
    if (educator != null && educator.isNotEmpty && !seen.contains(educator)) {
      final parts = educator.split(' ');
      final initials = parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
      list.insert(
        0,
        TeacherContact(
          id: 'educator',
          name: educator,
          subjectName: 'Wychowawstwo',
          role: 'Wychowawca',
          initials: initials.isNotEmpty ? initials : 'W',
        ),
      );
    }

    if (list.isEmpty) {
      return _mockFallback.getTeachers();
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
