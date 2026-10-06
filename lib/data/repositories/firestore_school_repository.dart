import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/attendance_record.dart';
import '../../domain/models/grade.dart';
import '../../domain/models/justification_request.dart';
import '../../domain/models/lesson_slot.dart';
import '../../domain/models/message_thread.dart';
import '../../domain/models/student_profile.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/teacher_contact.dart';
import '../services/librus_connection_service.dart';
import 'firestore/firestore_attendance_data_source.dart';
import 'firestore/firestore_grades_data_source.dart';
import 'firestore/firestore_justifications_data_source.dart';
import 'firestore/firestore_messages_data_source.dart';
import 'firestore/firestore_schedule_data_source.dart';
import 'firestore/school_data_cache_manager.dart';
import 'mock_school_repository.dart';
import 'school_repository.dart';

class FirestoreSchoolRepository implements SchoolRepository {
  late final SchoolDataCacheManager cacheManager;
  late final FirestoreGradesDataSource gradesDataSource;
  late final FirestoreAttendanceDataSource attendanceDataSource;
  late final FirestoreJustificationsDataSource justificationsDataSource;
  late final FirestoreMessagesDataSource messagesDataSource;
  late final FirestoreScheduleDataSource scheduleDataSource;

  FirestoreSchoolRepository({
    FirebaseFirestore? firestore,
    LibrusConnectionService? connectionService,
    MockSchoolRepository? mockFallback,
    http.Client? httpClient,
    SchoolDataCacheManager? cacheManager,
    FirestoreGradesDataSource? gradesDataSource,
    FirestoreAttendanceDataSource? attendanceDataSource,
    FirestoreJustificationsDataSource? justificationsDataSource,
    FirestoreMessagesDataSource? messagesDataSource,
    FirestoreScheduleDataSource? scheduleDataSource,
  }) {
    final fallback = mockFallback ?? MockSchoolRepository();
    final cache = cacheManager ??
        SchoolDataCacheManager(
          firestore: firestore,
          connectionService: connectionService,
          httpClient: httpClient,
        );
    this.cacheManager = cache;
    this.gradesDataSource = gradesDataSource ??
        FirestoreGradesDataSource(cacheManager: cache, mockFallback: fallback);
    this.attendanceDataSource = attendanceDataSource ??
        FirestoreAttendanceDataSource(
          cacheManager: cache,
          mockFallback: fallback,
          httpClient: httpClient,
        );
    this.justificationsDataSource = justificationsDataSource ??
        FirestoreJustificationsDataSource(
          cacheManager: cache,
          attendanceDataSource: this.attendanceDataSource,
          mockFallback: fallback,
          httpClient: httpClient,
        );
    this.messagesDataSource = messagesDataSource ??
        FirestoreMessagesDataSource(
          cacheManager: cache,
          mockFallback: fallback,
          httpClient: httpClient,
        );
    this.scheduleDataSource = scheduleDataSource ??
        FirestoreScheduleDataSource(
          cacheManager: cache,
          attendanceDataSource: this.attendanceDataSource,
          gradesDataSource: this.gradesDataSource,
          mockFallback: fallback,
        );
  }

  FirestoreGradesDataSource get _g => gradesDataSource;
  FirestoreAttendanceDataSource get _a => attendanceDataSource;
  FirestoreJustificationsDataSource get _j => justificationsDataSource;
  FirestoreMessagesDataSource get _m => messagesDataSource;
  FirestoreScheduleDataSource get _s => scheduleDataSource;

  static DateTime parseMessageDate(dynamic raw, {DateTime? fallback}) =>
      FirestoreMessagesDataSource.parseMessageDate(raw, fallback: fallback);

  @override
  Future<StudentProfile> getStudentProfile() => _s.getStudentProfile();
  @override
  Future<UpcomingEvent?> getUpcomingExam() => _s.getUpcomingExam();
  @override
  Future<List<LessonSlot>> getTodaySchedule() => _s.getTodaySchedule();
  @override
  Future<List<LessonSlot>> getScheduleForDay(int day) =>
      _s.getScheduleForDay(day);
  @override
  Future<Map<int, List<LessonSlot>>> getWeekSchedule({DateTime? weekStart}) =>
      _s.getWeekSchedule(weekStart: weekStart);
  @override
  Future<List<Subject>> getSubjects() => _g.getSubjects();
  @override
  Future<List<Grade>> getRecentGrades() => _g.getRecentGrades();
  @override
  Future<List<AttendanceRecord>> getAttendanceRecords() =>
      _a.getAttendanceRecords();
  @override
  Future<Map<String, dynamic>> getAttendanceStats() => _a.getAttendanceStats();
  @override
  Future<List<MessageThread>> getMessages() => _m.getMessages();
  @override
  Future<List<Announcement>> getAnnouncements() => _s.getAnnouncements();

  @override
  Future<void> submitJustification(List<String> recordIds, String reason, {DateTime? date}) =>
      _a.submitJustification(recordIds, reason, date: date);
  @override
  Future<void> cancelJustification(List<String> ids) => _a.cancelJustification(ids);
  @override
  Future<void> requestJustification(List<String> recordIds, String reason, {DateTime? date}) =>
      _j.requestJustification(recordIds, reason, date: date);
  @override
  Future<List<JustificationRequest>> getJustificationRequests() => _j.getJustificationRequests();
  @override
  Future<bool> approveJustificationRequest(String requestId, String pin, {List<String>? selectedRecordIds}) =>
      _j.approveJustificationRequest(requestId, pin, selectedRecordIds: selectedRecordIds);
  @override
  Future<bool> rejectJustificationRequest(String id, {String? reason}) =>
      _j.rejectJustificationRequest(id, reason: reason);
  @override
  Future<bool> respondJustificationRequest(String id, {required String responseText}) =>
      _j.respondJustificationRequest(id, responseText: responseText);

  @override
  Future<List<TeacherContact>> getTeachers() => _s.getTeachers();
  @override
  Future<void> sendMessage({
    required List<String> recipientNames,
    required String subject,
    required String body,
    String? replyToId,
    String? senderName,
    String? senderRole,
  }) => _m.sendMessage(recipientNames: recipientNames, subject: subject, body: body, replyToId: replyToId, senderName: senderName, senderRole: senderRole);
  @override
  Future<String?> getMessageBody(String msgId, {String? url}) => _m.getMessageBody(msgId, url: url);
  @override
  Future<MessageDetailsResult?> getMessageDetails(String id, {String? url}) => _m.getMessageDetails(id, url: url);
  @override
  Future<void> markMessageAsRead(String msgId, {bool isRead = true}) => _m.markMessageAsRead(msgId, isRead: isRead);
  @override
  Future<void> markAllMessagesAsRead() => _m.markAllMessagesAsRead();
  @override
  Future<void> archiveMessage(String msgId, {bool isArchived = true}) =>
      _m.archiveMessage(msgId, isArchived: isArchived);

  @override
  Future<DriveAttachmentInfo> saveAttachmentToDrive({
    required String msgId,
    required String attachmentName,
    required String downloadPath,
    required String accessToken,
    String? folderId,
    String? folderName,
    String? savedBy,
  }) =>
      _m.saveAttachmentToDrive(
        msgId: msgId,
        attachmentName: attachmentName,
        downloadPath: downloadPath,
        accessToken: accessToken,
        folderId: folderId,
        folderName: folderName,
        savedBy: savedBy,
      );
  @override
  Future<List<DriveFolderOption>> listDriveFolders({
    required String accessToken,
  }) =>
      _m.listDriveFolders(accessToken: accessToken);
  @override
  Future<DriveFolderOption> createDriveFolder({
    required String accessToken,
    required String folderName,
    bool setAsDefault = false,
  }) =>
      _m.createDriveFolder(
        accessToken: accessToken,
        folderName: folderName,
        setAsDefault: setAsDefault,
      );
  @override
  Future<void> moveDriveAttachment({
    required String accessToken,
    required String msgId,
    required List<String> attachmentNames,
    required Map<String, DriveAttachmentInfo> currentDriveAttachments,
    required String targetFolderId,
    required String targetFolderName,
    bool setAsDefault = true,
  }) =>
      _m.moveDriveAttachment(
        accessToken: accessToken,
        msgId: msgId,
        attachmentNames: attachmentNames,
        currentDriveAttachments: currentDriveAttachments,
        targetFolderId: targetFolderId,
        targetFolderName: targetFolderName,
        setAsDefault: setAsDefault,
      );
  @override
  Future<DriveFolderOption> getDefaultDriveFolder() =>
      _m.getDefaultDriveFolder();
  @override
  Future<void> setDefaultDriveFolder(DriveFolderOption folder) =>
      _m.setDefaultDriveFolder(folder);
}
