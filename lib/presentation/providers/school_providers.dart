import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/school_repository.dart';
import '../../data/repositories/firestore_school_repository.dart';
import '../../domain/models/student_profile.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/grade.dart';
import '../../domain/models/lesson_slot.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/message_thread.dart';
import '../../domain/models/teacher_contact.dart';

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

final weekScheduleProvider = FutureProvider<Map<int, List<LessonSlot>>>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getWeekSchedule();
});

enum WeekScheduleFilter { none, substitutions, exams, canceled }

class WeekScheduleFilterNotifier extends Notifier<WeekScheduleFilter> {
  @override
  WeekScheduleFilter build() => WeekScheduleFilter.none;

  void setFilter(WeekScheduleFilter filter) => state = filter;
  void toggleFilter(WeekScheduleFilter filter) {
    state = state == filter ? WeekScheduleFilter.none : filter;
  }
}

final weekScheduleFilterProvider =
    NotifierProvider<WeekScheduleFilterNotifier, WeekScheduleFilter>(WeekScheduleFilterNotifier.new);

class SelectedScheduleDayNotifier extends Notifier<int> {
  @override
  int build() {
    final now = DateTime.now();
    return (now.weekday - 1).clamp(0, 4); // 0=Pn .. 4=Pt
  }

  void setDay(int dayIndex) => state = dayIndex;
}

final selectedScheduleDayProvider =
    NotifierProvider<SelectedScheduleDayNotifier, int>(SelectedScheduleDayNotifier.new);

class WeeklyScheduleStats {
  final int totalHours;
  final int substitutionsCount;
  final int examsCount;
  final int canceledCount;

  const WeeklyScheduleStats({
    required this.totalHours,
    required this.substitutionsCount,
    required this.examsCount,
    required this.canceledCount,
  });
}

final weeklyScheduleStatsProvider = Provider<WeeklyScheduleStats>((ref) {
  final weekAsync = ref.watch(weekScheduleProvider);
  return weekAsync.when(
    data: (weekMap) {
      int total = 0;
      int substitutions = 0;
      int exams = 0;
      int canceled = 0;

      for (final lessons in weekMap.values) {
        total += lessons.length;
        for (final slot in lessons) {
          if (slot.status == LessonStatus.substituted) substitutions++;
          if (slot.status == LessonStatus.canceled) canceled++;
          if (slot.eventType != null || (slot.topic != null && slot.topic!.toLowerCase().contains('sprawdzian'))) {
            exams++;
          }
        }
      }

      return WeeklyScheduleStats(
        totalHours: total,
        substitutionsCount: substitutions,
        examsCount: exams,
        canceledCount: canceled,
      );
    },
    loading: () => const WeeklyScheduleStats(totalHours: 32, substitutionsCount: 2, examsCount: 2, canceledCount: 1),
    error: (err, stack) => const WeeklyScheduleStats(totalHours: 0, substitutionsCount: 0, examsCount: 0, canceledCount: 0),
  );
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

  Future<void> submitJustification(List<String> recordIds, String reason, {DateTime? date}) async {
    state = const AsyncValue.loading();
    final repo = ref.read(schoolRepositoryProvider);
    await repo.submitJustification(recordIds, reason, date: date);
    state = AsyncValue.data(await repo.getAttendanceRecords());
  }

  Future<void> cancelJustification(List<String> recordIds) async {
    state = const AsyncValue.loading();
    final repo = ref.read(schoolRepositoryProvider);
    await repo.cancelJustification(recordIds);
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

final teachersProvider = FutureProvider<List<TeacherContact>>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getTeachers();
});

final unreadMessagesCountProvider = Provider<int>((ref) {
  final messagesAsync = ref.watch(messagesProvider);
  return messagesAsync.value?.where((m) => m.isUnread).length ?? 0;
});

