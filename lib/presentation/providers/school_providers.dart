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

class SelectedWeekMondayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  }

  void previousWeek() {
    state = state.subtract(const Duration(days: 7));
  }

  void nextWeek() {
    state = state.add(const Duration(days: 7));
  }

  void resetToCurrentWeek() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  }

  void setMonday(DateTime monday) {
    state = DateTime(monday.year, monday.month, monday.day);
  }
}

final selectedWeekMondayProvider =
    NotifierProvider<SelectedWeekMondayNotifier, DateTime>(SelectedWeekMondayNotifier.new);

final weekScheduleProvider = FutureProvider<Map<int, List<LessonSlot>>>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  final monday = ref.watch(selectedWeekMondayProvider);
  return repo.getWeekSchedule(weekStart: monday);
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
    loading: () => const WeeklyScheduleStats(totalHours: 0, substitutionsCount: 0, examsCount: 0, canceledCount: 0),
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

// ==========================================
// Phase 10: Academic Grades Portal Providers
// ==========================================

class SelectedGradesSubjectNotifier extends Notifier<Subject?> {
  @override
  Subject? build() => null; // D-03: default null / empty

  void select(Subject? subject) {
    if (state?.id == subject?.id) {
      state = null; // toggle off
    } else {
      state = subject;
    }
  }

  void clear() => state = null;
}

final selectedGradesSubjectProvider =
    NotifierProvider<SelectedGradesSubjectNotifier, Subject?>(SelectedGradesSubjectNotifier.new);

class GradesSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final gradesSearchQueryProvider =
    NotifierProvider<GradesSearchQueryNotifier, String>(GradesSearchQueryNotifier.new);

class GradesTermNotifier extends Notifier<int> {
  @override
  int build() => 1; // 1 = Semestr 1, 2 = Semestr 2, 3 = Roczna

  void setTerm(int term) => state = term;
}

final gradesTermProvider =
    NotifierProvider<GradesTermNotifier, int>(GradesTermNotifier.new);

class GradesDistributionStats {
  final Map<int, int> counts; // 1..6
  final int totalGrades;
  final bool hasThreats;
  final int dangerCount;
  final double positivePercentage;
  final double overallAverage;

  const GradesDistributionStats({
    required this.counts,
    required this.totalGrades,
    required this.hasThreats,
    required this.dangerCount,
    required this.positivePercentage,
    required this.overallAverage,
  });

  factory GradesDistributionStats.empty() {
    return const GradesDistributionStats(
      counts: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0},
      totalGrades: 0,
      hasThreats: false,
      dangerCount: 0,
      positivePercentage: 100.0,
      overallAverage: 0.0,
    );
  }
}

final gradesDistributionStatsProvider = Provider<GradesDistributionStats>((ref) {
  final subjectsAsync = ref.watch(subjectsProvider);
  final term = ref.watch(gradesTermProvider);

  return subjectsAsync.when(
    data: (subjects) {
      final Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
      int total = 0;
      double weightedSum = 0;
      int totalWeight = 0;

      for (final subject in subjects) {
        final grades = term == 3
            ? subject.grades
            : subject.grades.where((g) => g.term == term).toList();

        for (final g in grades) {
          final bucket = g.numericValue.round().clamp(1, 6);
          counts[bucket] = (counts[bucket] ?? 0) + 1;
          total++;

          if (g.isCountedToAverage) {
            weightedSum += g.numericValue * g.weight;
            totalWeight += g.weight;
          }
        }
      }

      final int threatCount = counts[1] ?? 0;
      final int positiveCount = (counts[2] ?? 0) +
          (counts[3] ?? 0) +
          (counts[4] ?? 0) +
          (counts[5] ?? 0) +
          (counts[6] ?? 0);
      final double positivePct = total > 0 ? (positiveCount / total) * 100 : 100.0;
      final double avg = totalWeight > 0 ? (weightedSum / totalWeight) : 0.0;

      return GradesDistributionStats(
        counts: counts,
        totalGrades: total,
        hasThreats: threatCount > 0,
        dangerCount: threatCount + (counts[2] ?? 0),
        positivePercentage: positivePct,
        overallAverage: avg,
      );
    },
    loading: () => const GradesDistributionStats(
      counts: {1: 0, 2: 0, 3: 3, 4: 9, 5: 18, 6: 8},
      totalGrades: 38,
      hasThreats: false,
      dangerCount: 0,
      positivePercentage: 100.0,
      overallAverage: 4.82,
    ),
    error: (_, stack) => GradesDistributionStats.empty(),
  );
});

