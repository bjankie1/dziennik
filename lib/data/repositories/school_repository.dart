import '../../domain/models/student_profile.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/grade.dart';
import '../../domain/models/lesson_slot.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/message_thread.dart';

abstract class SchoolRepository {
  Future<StudentProfile> getStudentProfile();
  Future<UpcomingEvent> getUpcomingExam();
  Future<List<LessonSlot>> getTodaySchedule();
  Future<List<LessonSlot>> getScheduleForDay(int dayOfWeek);
  Future<List<Subject>> getSubjects();
  Future<List<Grade>> getRecentGrades();
  Future<List<AttendanceRecord>> getAttendanceRecords();
  Future<Map<String, dynamic>> getAttendanceStats();
  Future<List<MessageThread>> getMessages();
  Future<List<Announcement>> getAnnouncements();
  Future<void> submitJustification(List<String> recordIds, String reason);
}
