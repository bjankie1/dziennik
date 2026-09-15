import 'school_repository.dart';
import '../mock/mock_data.dart';
import '../../domain/models/student_profile.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/grade.dart';
import '../../domain/models/lesson_slot.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/message_thread.dart';

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
        currentWeek: 'Szczęśliwy numerek: 18',
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
  Future<void> submitJustification(List<String> recordIds, String reason) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _attendance = _attendance.map((rec) {
      if (recordIds.contains(rec.id)) {
        return AttendanceRecord(
          id: rec.id,
          date: rec.date,
          lessonNumber: rec.lessonNumber,
          subjectName: rec.subjectName,
          type: rec.type,
          timeSlot: rec.timeSlot,
          justificationStatus: JustificationStatus.requested,
          justificationReason: reason,
        );
      }
      return rec;
    }).toList();
  }
}
