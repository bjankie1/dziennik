import '../../domain/models/student_profile.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/grade.dart';
import '../../domain/models/lesson_slot.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/message_thread.dart';
import '../../domain/models/teacher_contact.dart';
import '../../domain/models/justification_request.dart';

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
  Future<void> requestJustification(List<String> recordIds, String reason, {DateTime? date});
  Future<List<JustificationRequest>> getJustificationRequests();
  Future<bool> approveJustificationRequest(
    String requestId,
    String pin, {
    List<String>? selectedRecordIds,
  });
  Future<bool> rejectJustificationRequest(String requestId, {String? reason});
  Future<bool> respondJustificationRequest(String requestId, {required String responseText});
  Future<List<TeacherContact>> getTeachers();
  Future<void> sendMessage({
    required List<String> recipientNames,
    required String subject,
    required String body,
    String? replyToId,
  });
  Future<String?> getMessageBody(String msgId, {String? url});
  Future<MessageDetailsResult?> getMessageDetails(String msgId, {String? url});
  Future<void> markMessageAsRead(String msgId, {bool isRead = true});
  Future<void> markAllMessagesAsRead();
  Future<DriveAttachmentInfo> saveAttachmentToDrive({
    required String msgId,
    required String attachmentName,
    required String downloadPath,
    required String accessToken,
    String? folderId,
    String? folderName,
    String? savedBy,
  });
  Future<List<DriveFolderOption>> listDriveFolders({
    required String accessToken,
  });
  Future<DriveFolderOption> createDriveFolder({
    required String accessToken,
    required String folderName,
    bool setAsDefault = false,
  });
  Future<void> moveDriveAttachment({
    required String accessToken,
    required String msgId,
    required List<String> attachmentNames,
    required Map<String, DriveAttachmentInfo> currentDriveAttachments,
    required String targetFolderId,
    required String targetFolderName,
    bool setAsDefault = true,
  });
  Future<DriveFolderOption> getDefaultDriveFolder();
  Future<void> setDefaultDriveFolder(DriveFolderOption folder);
}

