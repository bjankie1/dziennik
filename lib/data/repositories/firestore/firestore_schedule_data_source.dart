import '../../../domain/models/attendance_record.dart';
import '../../../domain/models/lesson_slot.dart';
import '../../../domain/models/message_thread.dart';
import '../../../domain/models/student_profile.dart';
import '../../../domain/models/teacher_contact.dart';
import '../../mock/mock_data.dart';
import '../mock_school_repository.dart';
import 'firestore_attendance_data_source.dart';
import 'firestore_grades_data_source.dart';
import 'firestore_messages_data_source.dart';
import 'school_data_cache_manager.dart';

class FirestoreScheduleDataSource {
  final SchoolDataCacheManager cacheManager;
  final FirestoreAttendanceDataSource attendanceDataSource;
  final FirestoreGradesDataSource gradesDataSource;
  final MockSchoolRepository mockFallback;

  FirestoreScheduleDataSource({
    required this.cacheManager,
    required this.attendanceDataSource,
    required this.gradesDataSource,
    MockSchoolRepository? mockFallback,
  }) : mockFallback = mockFallback ?? MockSchoolRepository();

  Future<StudentProfile> getStudentProfile() async {
    final data = await cacheManager.getStudentData();
    if (data == null) {
      return mockFallback.getStudentProfile();
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
      schoolName: studentMap['schoolName'] ??
          'Liceum Ogólnokształcące nr X im. Stefanii Sempołowskiej we Wrocławiu',
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
      lastSyncTime: SchoolDataCacheManager.parseSyncTime(data['lastSyncTime']) ??
          SchoolDataCacheManager.parseSyncTime(data['updatedAt']),
    );
  }

  String cleanEventSubjectName(
    Map<String, dynamic> event,
    List<dynamic> timetable,
  ) {
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
      final cleanedRaw = rawText.replaceFirst(
        RegExp(r'^Nr\s+lekcji:\s*\d+\s*', caseSensitive: false),
        '',
      );
      final parts = cleanedRaw
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      for (final part in parts) {
        if (!RegExp(r'^(sprawdzian|kartkówk)', caseSensitive: false)
            .hasMatch(part)) {
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
                .replaceFirst(
                  RegExp(r'^zastępstwo\s*', caseSensitive: false),
                  '',
                )
                .trim();
            if (s.isNotEmpty) return s;
          }
        }
      }
    }

    return rawSubject.isNotEmpty ? rawSubject : 'Wydarzenie';
  }

  Future<UpcomingEvent?> getUpcomingExam() async {
    final data = await cacheManager.getStudentData();
    if (data != null) {
      final upcomingExamMap = data['upcomingExam'] as Map<String, dynamic>?;
      if (upcomingExamMap != null) {
        final timetable = data['timetable'] as List<dynamic>? ?? [];
        final dateStr = upcomingExamMap['date'] as String? ?? '';
        final date =
            DateTime.tryParse(dateStr) ?? DateTime.now().add(const Duration(days: 7));
        final now = DateTime.now();
        final diff = DateTime(date.year, date.month, date.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
        final subject = cleanEventSubjectName(upcomingExamMap, timetable);
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
    return mockFallback.getUpcomingExam();
  }

  static DateTime normalizeToMonday(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static bool isWarsawTripWeek(DateTime date) {
    final monday = normalizeToMonday(date);
    return monday.year == 2026 && monday.month == 9 && monday.day == 14;
  }

  List<Map<String, dynamic>> extractAllEvents(Map<String, dynamic> data) {
    final list = <Map<String, dynamic>>[];
    final timetable = data['timetable'] as List<dynamic>? ?? [];

    Map<String, dynamic> normalizeEvent(Map raw) {
      final m = Map<String, dynamic>.from(raw);
      m['subject'] = cleanEventSubjectName(m, timetable);
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
          if (!list.any(
            (x) => x['date'] == m['date'] && x['subject'] == m['subject'],
          )) {
            list.add(m);
          }
        }
      }
    }
    if (data['upcomingExam'] is Map) {
      final m = normalizeEvent(data['upcomingExam'] as Map);
      if (!list.any(
        (x) => x['date'] == m['date'] && x['subject'] == m['subject'],
      )) {
        list.add(m);
      }
    }
    return list;
  }

  List<LessonSlot> parseTimetableForDay(
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

    dayLessons.sort(
      (a, b) => (a['lessonNumber'] as num? ?? 0)
          .compareTo(b['lessonNumber'] as num? ?? 0),
    );

    final isTripWeek = weekStart != null ? isWarsawTripWeek(weekStart) : false;
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
        subject = subject
            .replaceFirst(RegExp(r'^odwołane\s*', caseSensitive: false), '')
            .trim();
      }

      // Handle base timetable substitution (scraped during week of 2026-09-14)
      final hasBaseSubstitution = subject.toLowerCase().contains('zastępstwo');
      LessonStatus status = LessonStatus.normal;
      String? statusNote;

      if (hasBaseSubstitution) {
        // Strip "zastępstwo" prefix from subject name
        subject = subject
            .replaceFirst(RegExp(r'^zastępstwo\s*', caseSensitive: false), '')
            .trim();
        if (isTripWeek) {
          status = LessonStatus.substituted;
          statusNote = 'Zastępstwo';
          substituteTeacher =
              teacher.isNotEmpty ? teacher : 'Czajkowska Maria';
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
          final rawType =
              (matchedEvent['type'] as String? ?? '').toLowerCase();
          final desc = matchedEvent['description'] as String? ??
              matchedEvent['rawText'] as String? ??
              '';
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
        room: (item['room'] as String?)?.isNotEmpty == true
            ? (item['room'] as String)
            : 'Sala szkolna',
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

  Future<List<LessonSlot>> getTodaySchedule() async {
    final now = DateTime.now();
    // Weekends (Saturday & Sunday) have no regular classes
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return [];
    }

    final data = await cacheManager.getStudentData();
    if (data == null) {
      return mockFallback.getTodaySchedule();
    }
    if (data['timetable'] == null) {
      return [];
    }

    final rawList = data['timetable'] as List<dynamic>? ?? [];
    final monday = normalizeToMonday(now);
    final events = extractAllEvents(data);
    final allAttendance = await attendanceDataSource.getAttendanceRecords();
    final dayAttendance = allAttendance
        .where(
          (a) =>
              a.date.year == now.year &&
              a.date.month == now.month &&
              a.date.day == now.day,
        )
        .toList();
    final lessons = parseTimetableForDay(
      rawList,
      now.weekday,
      weekStart: monday,
      dayDate: now,
      events: events,
      dayAttendance: dayAttendance,
    );
    return lessons;
  }

  Future<List<LessonSlot>> getScheduleForDay(int dayOfWeek) async {
    if (dayOfWeek == DateTime.saturday ||
        dayOfWeek == DateTime.sunday ||
        dayOfWeek > 5) {
      return [];
    }

    final data = await cacheManager.getStudentData();
    if (data == null) {
      return mockFallback.getScheduleForDay(dayOfWeek);
    }
    if (data['timetable'] == null) {
      return [];
    }

    final rawList = data['timetable'] as List<dynamic>? ?? [];
    final now = DateTime.now();
    final monday = normalizeToMonday(now);
    final targetDate = monday.add(Duration(days: dayOfWeek - 1));
    final events = extractAllEvents(data);
    final allAttendance = await attendanceDataSource.getAttendanceRecords();
    final dayAttendance = allAttendance
        .where(
          (a) =>
              a.date.year == targetDate.year &&
              a.date.month == targetDate.month &&
              a.date.day == targetDate.day,
        )
        .toList();
    final lessons = parseTimetableForDay(
      rawList,
      dayOfWeek,
      weekStart: monday,
      dayDate: targetDate,
      events: events,
      dayAttendance: dayAttendance,
    );
    return lessons;
  }

  Future<Map<int, List<LessonSlot>>> getWeekSchedule({
    DateTime? weekStart,
  }) async {
    final now = DateTime.now();
    final effectiveWeekStart = weekStart != null
        ? normalizeToMonday(weekStart)
        : normalizeToMonday(now);

    final data = await cacheManager.getStudentData();
    if (data == null) {
      return mockFallback.getWeekSchedule(weekStart: effectiveWeekStart);
    }

    final rawList = data['timetable'] as List<dynamic>? ?? [];
    final events = extractAllEvents(data);
    final allAttendance = await attendanceDataSource.getAttendanceRecords();
    final result = <int, List<LessonSlot>>{};
    for (int day = 1; day <= 5; day++) {
      final dayDate = effectiveWeekStart.add(Duration(days: day - 1));
      final dayAttendance = allAttendance
          .where(
            (a) =>
                a.date.year == dayDate.year &&
                a.date.month == dayDate.month &&
                a.date.day == dayDate.day,
          )
          .toList();
      final lessons = rawList.isEmpty
          ? <LessonSlot>[]
          : parseTimetableForDay(
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

  Future<List<Announcement>> getAnnouncements() async {
    final data = await cacheManager.getStudentData();
    if (data == null) {
      return mockFallback.getAnnouncements();
    }
    if (data['announcements'] == null) {
      return [];
    }

    final rawAnn = data['announcements'] as List<dynamic>? ?? [];
    if (rawAnn.isEmpty) return [];

    return rawAnn.map((a) {
      final dt = FirestoreMessagesDataSource.parseMessageDate(a['date']);

      return Announcement(
        id: a['id'] ?? cacheManager.generateUniqueId(),
        title: a['title'] ?? 'Ogłoszenie',
        author: a['author'] ?? 'Szkoła',
        authorRole: 'Nauczyciel / Dyrekcja',
        publishedDate: dt,
        content: a['content'] ?? '',
        tags: const ['Ogłoszenie szkolne', 'Ważne'],
      );
    }).toList();
  }

  Future<List<TeacherContact>> getTeachers() async {
    final data = await cacheManager.getStudentData();
    if (data == null) {
      return mockFallback.getTeachers();
    }

    final list = <TeacherContact>[];
    final seen = <String>{};

    // 1. Educator (Wychowawca)
    final studentMap = data['student'] as Map<String, dynamic>?;
    final educator = (studentMap?['educator'] as String?)?.trim();
    final educatorName =
        (educator != null && educator.isNotEmpty) ? educator : 'Sobota Łukasz';
    seen.add(educatorName);
    final parts = educatorName.split(' ');
    final initials = parts
        .map((p) => p.isNotEmpty ? p[0] : '')
        .take(2)
        .join()
        .toUpperCase();
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
          final cleanTeacher =
              rawTeacher.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
          final cleanSubject = rawSubject
              .replaceFirst(
                RegExp(r'^(zastępstwo|odwołane)\s*', caseSensitive: false),
                '',
              )
              .trim();
          if (cleanTeacher.isNotEmpty && !seen.contains(cleanTeacher)) {
            seen.add(cleanTeacher);
            final parts = cleanTeacher.split(' ');
            final initials = parts
                .map((p) => p.isNotEmpty ? p[0] : '')
                .take(2)
                .join()
                .toUpperCase();
            list.add(
              TeacherContact(
                id: cleanTeacher.toLowerCase().replaceAll(' ', '_'),
                name: cleanTeacher,
                subjectName: cleanSubject,
                role: 'Nauczyciel',
                initials: initials.isNotEmpty ? initials : 'N',
              ),
            );
          }
        }
      }
    }

    // 3. Teachers from subjects
    final subjects = await gradesDataSource.getSubjects();
    for (final s in subjects) {
      if (s.teacherName.isNotEmpty && !seen.contains(s.teacherName)) {
        seen.add(s.teacherName);
        final parts = s.teacherName.split(' ');
        final initials = parts
            .map((p) => p.isNotEmpty ? p[0] : '')
            .take(2)
            .join()
            .toUpperCase();
        list.add(
          TeacherContact(
            id: s.teacherName.toLowerCase().replaceAll(' ', '_'),
            name: s.teacherName,
            subjectName: s.name,
            role: 'Nauczyciel',
            initials: initials.isNotEmpty ? initials : 'N',
          ),
        );
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
          final initials = parts
              .map((p) => p.isNotEmpty ? p[0] : '')
              .take(2)
              .join()
              .toUpperCase();
          list.add(
            TeacherContact(
              id: rawTeacher.toLowerCase().replaceAll(' ', '_'),
              name: rawTeacher,
              subjectName: rawSubject.isNotEmpty ? rawSubject : 'Lekcja',
              role: 'Nauczyciel',
              initials: initials.isNotEmpty ? initials : 'N',
            ),
          );
        }
      }
    }

    return list;
  }
}
