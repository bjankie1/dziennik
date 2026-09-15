import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/school_repository.dart';
import '../../data/repositories/firestore_school_repository.dart';
import '../../domain/models/student_profile.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/grade.dart';
import '../../domain/models/lesson_slot.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/message_thread.dart';

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return FirestoreSchoolRepository();
});

class CurrentNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final currentNavIndexProvider =
    NotifierProvider<CurrentNavIndexNotifier, int>(CurrentNavIndexNotifier.new);

final studentProfileProvider = FutureProvider<StudentProfile>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getStudentProfile();
});

final upcomingExamProvider = FutureProvider<UpcomingEvent>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getUpcomingExam();
});

final todayScheduleProvider = FutureProvider<List<LessonSlot>>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getTodaySchedule();
});

final dayScheduleProvider = FutureProvider.family<List<LessonSlot>, int>((ref, dayOfWeek) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getScheduleForDay(dayOfWeek);
});

final attendanceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getAttendanceStats();
});

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getSubjects();
});

final recentGradesProvider = FutureProvider<List<Grade>>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getRecentGrades();
});

class AttendanceNotifier extends AsyncNotifier<List<AttendanceRecord>> {
  @override
  Future<List<AttendanceRecord>> build() async {
    final repo = ref.read(schoolRepositoryProvider);
    return repo.getAttendanceRecords();
  }

  Future<void> submitJustification(List<String> recordIds, String reason) async {
    state = const AsyncValue.loading();
    final repo = ref.read(schoolRepositoryProvider);
    await repo.submitJustification(recordIds, reason);
    state = AsyncValue.data(await repo.getAttendanceRecords());
  }
}

final attendanceProvider =
    AsyncNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>(AttendanceNotifier.new);

final messagesProvider = FutureProvider<List<MessageThread>>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getMessages();
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getAnnouncements();
});
