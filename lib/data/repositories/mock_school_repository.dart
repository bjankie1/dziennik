import 'school_repository.dart';
import '../mock/mock_data.dart';
import '../../domain/models/student_profile.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/grade.dart';
import '../../domain/models/lesson_slot.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/message_thread.dart';
import '../../domain/models/teacher_contact.dart';

import '../services/librus_connection_service.dart';

class MockSchoolRepository implements SchoolRepository {
  final LibrusConnectionService _connectionService;

  MockSchoolRepository({LibrusConnectionService? connectionService})
      : _connectionService = connectionService ?? LibrusConnectionService();

  List<AttendanceRecord> _attendance = List.from(MockData.attendanceRecords);
  final List<MessageThread> _messages = List.from(MockData.messages);
  final List<Announcement> _announcements = List.from(MockData.announcements);

  @override
  Future<StudentProfile> getStudentProfile() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final isDemo = await _connectionService.isDemoMode();
    final login = await _connectionService.getConnectedLogin();

    if (!isDemo && login != null && login.isNotEmpty) {
      return StudentProfile(
        id: login,
        name: 'Oskar Jankiewicz',
        className: '4 k Lic',
        schoolName: 'Liceum Ogólnokształcące nr X im. Stefanii Sempołowskiej we Wrocławiu',
        avatarUrl: MockData.student.avatarUrl,
        attendancePercentage: 98.5,
        overallAverage: 5.0,
        previousPeriodAverage: 4.85,
        classRank: 1,
        totalStudentsInClass: 28,
        unreadMessagesCount: 0,
        currentWeek: 'Tydzień B',
        luckyNumber: 18,
      );
    }

    return MockData.student;
  }

  @override
  Future<UpcomingEvent> getUpcomingExam() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return MockData.upcomingExam;
  }

  @override
  Future<List<LessonSlot>> getTodaySchedule() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return MockData.todaySchedule;
  }

  @override
  Future<List<LessonSlot>> getScheduleForDay(int dayOfWeek) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return MockData.todaySchedule;
  }

  @override
  Future<List<Subject>> getSubjects() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return MockData.subjects;
  }

  @override
  Future<List<Grade>> getRecentGrades() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return MockData.recentGrades;
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _attendance;
  }

  @override
  Future<Map<String, dynamic>> getAttendanceStats() async {
    await Future.delayed(const Duration(milliseconds: 50));
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
    await Future.delayed(const Duration(milliseconds: 50));
    return _messages;
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _announcements;
  }

  @override
  Future<void> submitJustification(List<String> recordIds, String reason, {DateTime? date}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _attendance = _attendance.map((rec) {
      final matchesDate = date != null &&
          rec.date.year == date.year &&
          rec.date.month == date.month &&
          rec.date.day == date.day;
      if (recordIds.contains(rec.id) || matchesDate) {
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

  @override
  Future<void> cancelJustification(List<String> recordIds) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _attendance = _attendance.map((rec) {
      if (recordIds.contains(rec.id)) {
        return AttendanceRecord(
          id: rec.id,
          date: rec.date,
          lessonNumber: rec.lessonNumber,
          subjectName: rec.subjectName,
          type: AttendanceType.absent,
          timeSlot: rec.timeSlot,
          justificationStatus: JustificationStatus.none,
          justificationReason: null,
          classroom: rec.classroom,
          teacherName: rec.teacherName,
        );
      }
      return rec;
    }).toList();
  }

  @override
  Future<List<TeacherContact>> getTeachers() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = <TeacherContact>[];
    final seen = <String>{};

    for (final s in MockData.subjects) {
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

    if (!seen.contains('mgr Łukasz Sobota')) {
      list.insert(
        0,
        const TeacherContact(
          id: 'educator',
          name: 'mgr Łukasz Sobota',
          subjectName: 'Wychowawstwo / Informatyka',
          role: 'Wychowawca',
          initials: 'ŁS',
        ),
      );
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
    await Future.delayed(const Duration(milliseconds: 150));
    final now = DateTime.now();
    final newMsgItem = MessageItem(
      id: 'msg_${now.millisecondsSinceEpoch}',
      senderName: MockData.student.name,
      senderRole: 'Uczeń',
      senderInitials: 'OJ',
      timestamp: now,
      body: body,
      isFromMe: true,
    );

    if (replyToId != null) {
      final idx = _messages.indexWhere((t) => t.id == replyToId);
      if (idx != -1) {
        final existing = _messages[idx];
        final updatedMessages = List<MessageItem>.from(existing.messages)..add(newMsgItem);
        _messages[idx] = existing.copyWith(
          preview: 'Ja: $body',
          timestamp: now,
          messages: updatedMessages,
        );
        return;
      }
    }

    // New thread
    final newThread = MessageThread(
      id: 'thread_${now.millisecondsSinceEpoch}',
      senderName: recipientNames.join(', '),
      senderInitials: recipientNames.isNotEmpty && recipientNames.first.isNotEmpty
          ? recipientNames.first[0].toUpperCase()
          : 'N',
      senderRole: 'Nauczyciel',
      subject: subject,
      preview: 'Ja: $body',
      body: body,
      timestamp: now,
      isUnread: false,
      messages: [newMsgItem],
    );
    _messages.insert(0, newThread);
  }

  @override
  Future<String?> getMessageBody(String msgId, {String? url}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final thread = _messages.cast<MessageThread?>().firstWhere((t) => t?.id == msgId, orElse: () => null);
    return thread?.body;
  }

  @override
  Future<void> markMessageAsRead(String msgId, {bool isRead = true}) async {
    final idx = _messages.indexWhere((t) => t.id == msgId);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(isUnread: !isRead);
    }
  }

  @override
  Future<void> markAllMessagesAsRead() async {
    for (int i = 0; i < _messages.length; i++) {
      _messages[i] = _messages[i].copyWith(isUnread: false);
    }
  }
}
