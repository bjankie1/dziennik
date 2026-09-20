import '../../domain/models/student_profile.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/grade.dart';
import '../../domain/models/lesson_slot.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/message_thread.dart';
import '../../domain/models/teacher_contact.dart';

abstract class SchoolRepository {
  Future<StudentProfile> getStudentProfile();
  Future<UpcomingEvent?> getUpcomingExam();
  Future<List<LessonSlot>> getTodaySchedule();
  Future<List<LessonSlot>> getScheduleForDay(int dayOfWeek);
  Future<Map<int, List<LessonSlot>>> getWeekSchedule({DateTime? weekStart});
  Future<List<Subject>> getSubjects();
  Future<List<Grade>> getRecentGrades();
  Future<List<AttendanceRecord>> getAttendanceRecords();
  Future<Map<String, dynamic>> getAttendanceStats();
  Future<List<MessageThread>> getMessages();
  Future<List<Announcement>> getAnnouncements();
  Future<void> submitJustification(List<String> recordIds, String reason, {DateTime? date});
  Future<void> cancelJustification(List<String> recordIds);
  Future<List<TeacherContact>> getTeachers();
  Future<void> sendMessage({
    required List<String> recipientNames,
    required String subject,
    required String body,
    String? replyToId,
  });
  Future<String?> getMessageBody(String msgId, {String? url});
  Future<void> markMessageAsRead(String msgId, {bool isRead = true});
  Future<void> markAllMessagesAsRead();
}
