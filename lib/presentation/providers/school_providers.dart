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
import '../../domain/models/justification_request.dart';

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

final upcomingExamProvider = FutureProvider<UpcomingEvent?>((ref) async {
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
  final String substitutionsSubtitle;
  final int examsCount;
  final String examsSubtitle;
  final int canceledCount;
  final String canceledSubtitle;

  const WeeklyScheduleStats({
    required this.totalHours,
    required this.substitutionsCount,
    required this.substitutionsSubtitle,
    required this.examsCount,
    required this.examsSubtitle,
    required this.canceledCount,
    required this.canceledSubtitle,
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

      final subList = <String>[];
      final examList = <String>[];
      final cancelList = <String>[];

      final dayShortNames = {1: 'Pn', 2: 'Wt', 3: 'Śr', 4: 'Czw', 5: 'Pt'};

      for (int day = 1; day <= 5; day++) {
        final lessons = weekMap[day] ?? [];
        total += lessons.length;
        final dName = dayShortNames[day] ?? 'Dzień $day';

        for (final slot in lessons) {
          if (slot.status == LessonStatus.substituted) {
            substitutions++;
            final subText = '$dName: ${slot.subjectName}';
            if (!subList.contains(subText)) subList.add(subText);
          }
          if (slot.status == LessonStatus.canceled) {
            canceled++;
            final cText = '$dName: ${slot.startTime} ${slot.subjectName}';
            if (!cancelList.contains(cText)) cancelList.add(cText);
          }
          if (slot.eventType != null || (slot.topic != null && slot.topic!.toLowerCase().contains('sprawdzian'))) {
            exams++;
            final exType = (slot.eventType ?? 'Sprawdzian').toLowerCase();
            final eText = '$dName: ${slot.subjectName} ($exType)';
            if (!examList.contains(eText)) examList.add(eText);
          }
        }
      }

      final subSubtitle = substitutions > 0
          ? subList.take(2).join(', ')
          : 'Brak zmian w planie';
      final exSubtitle = exams > 0
          ? examList.take(2).join(', ')
          : 'Brak sprawdzianów w tym tygodniu';
      final canSubtitle = canceled > 0
          ? cancelList.take(2).join(', ')
          : 'Wszystkie lekcje zgodnie z planem';

      return WeeklyScheduleStats(
        totalHours: total,
        substitutionsCount: substitutions,
        substitutionsSubtitle: subSubtitle,
        examsCount: exams,
        examsSubtitle: exSubtitle,
        canceledCount: canceled,
        canceledSubtitle: canSubtitle,
      );
    },
    loading: () => const WeeklyScheduleStats(
      totalHours: 0,
      substitutionsCount: 0,
      substitutionsSubtitle: 'Ładowanie...',
      examsCount: 0,
      examsSubtitle: 'Ładowanie...',
      canceledCount: 0,
      canceledSubtitle: 'Ładowanie...',
    ),
    error: (err, stack) => const WeeklyScheduleStats(
      totalHours: 0,
      substitutionsCount: 0,
      substitutionsSubtitle: 'Błąd pobierania',
      examsCount: 0,
      examsSubtitle: 'Błąd pobierania',
      canceledCount: 0,
      canceledSubtitle: 'Błąd pobierania',
    ),
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
    ref.invalidate(justificationRequestsProvider);
    state = AsyncValue.data(await repo.getAttendanceRecords());
  }

  Future<void> cancelJustification(List<String> recordIds) async {
    state = const AsyncValue.loading();
    final repo = ref.read(schoolRepositoryProvider);
    await repo.cancelJustification(recordIds);
    ref.invalidate(justificationRequestsProvider);
    state = AsyncValue.data(await repo.getAttendanceRecords());
  }

  Future<void> requestJustification(List<String> recordIds, String reason, {DateTime? date}) async {
    state = const AsyncValue.loading();
    final repo = ref.read(schoolRepositoryProvider);
    await repo.requestJustification(recordIds, reason, date: date);
    ref.invalidate(justificationRequestsProvider);
    state = AsyncValue.data(await repo.getAttendanceRecords());
  }

  Future<bool> approveJustification(String requestId, String pin) async {
    final repo = ref.read(schoolRepositoryProvider);
    final success = await repo.approveJustificationRequest(requestId, pin);
    ref.invalidate(justificationRequestsProvider);
    state = AsyncValue.data(await repo.getAttendanceRecords());
    return success;
  }

  Future<bool> rejectJustification(String requestId, {String? reason}) async {
    final repo = ref.read(schoolRepositoryProvider);
    final success = await repo.rejectJustificationRequest(requestId, reason: reason);
    ref.invalidate(justificationRequestsProvider);
    state = AsyncValue.data(await repo.getAttendanceRecords());
    return success;
  }

  Future<bool> respondToJustification(String requestId, String responseText) async {
    final repo = ref.read(schoolRepositoryProvider);
    final success = await repo.respondJustificationRequest(requestId, responseText: responseText);
    ref.invalidate(justificationRequestsProvider);
    state = AsyncValue.data(await repo.getAttendanceRecords());
    return success;
  }
}

final attendanceProvider =
    AsyncNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>(AttendanceNotifier.new);

final justificationRequestsProvider = FutureProvider<List<JustificationRequest>>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  final attendanceAsync = ref.watch(attendanceProvider);
  final requests = await repo.getJustificationRequests();

  final records = attendanceAsync.value;
  if (records == null) return requests;

  final unexcusedRecords = records
      .where((r) =>
          r.type == AttendanceType.absent &&
          (r.justificationStatus == JustificationStatus.none ||
              r.justificationStatus == JustificationStatus.requested))
      .toList();

  return requests.map((req) {
    if (req.status == JustificationRequestStatus.pendingParentApproval) {
      final stillHasUnexcused = unexcusedRecords.any((r) {
        if (req.recordIds.contains(r.id)) return true;
        if (req.date != null &&
            r.date.year == req.date!.year &&
            r.date.month == req.date!.month &&
            r.date.day == req.date!.day) {
          if (req.lessonNumbers.isEmpty ||
              req.lessonNumbers.contains(r.lessonNumber)) {
            return true;
          }
        }
        return false;
      });
      if (!stillHasUnexcused) {
        return req.copyWith(
          status: JustificationRequestStatus.approved,
          reviewedBy: 'parent',
          reviewedAt: DateTime.now(),
        );
      }
    }
    return req;
  }).toList();
});

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
  final double? lastGradeDelta;
  final double? semesterDelta;
  final Grade? lastGrade;
  final int subjectsWithGradesCount;
  final List<({DateTime date, double average, Grade grade})> trajectory;

  const GradesDistributionStats({
    required this.counts,
    required this.totalGrades,
    required this.hasThreats,
    required this.dangerCount,
    required this.positivePercentage,
    required this.overallAverage,
    this.lastGradeDelta,
    this.semesterDelta,
    this.lastGrade,
    this.subjectsWithGradesCount = 0,
    this.trajectory = const [],
  });

  factory GradesDistributionStats.empty() {
    return const GradesDistributionStats(
      counts: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0},
      totalGrades: 0,
      hasThreats: false,
      dangerCount: 0,
      positivePercentage: 100.0,
      overallAverage: 0.0,
      lastGradeDelta: null,
      semesterDelta: null,
      lastGrade: null,
      subjectsWithGradesCount: 0,
      trajectory: [],
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
      int subjectsWithGrades = 0;
      final List<({Grade grade, int index})> indexedCountedGrades = [];
      final List<({Grade grade, int index})> indexedAllGrades = [];
      int runningIndex = 0;

      for (final subject in subjects) {
        final grades = term == 3
            ? subject.grades
            : subject.grades.where((g) => g.term == term).toList();

        if (grades.isNotEmpty) {
          subjectsWithGrades++;
        }

        for (final g in grades) {
          final bucket = g.numericValue.round().clamp(1, 6);
          counts[bucket] = (counts[bucket] ?? 0) + 1;
          total++;
          runningIndex++;
          indexedAllGrades.add((grade: g, index: runningIndex));

          if (g.isCountedToAverage) {
            weightedSum += g.numericValue * g.weight;
            totalWeight += g.weight;
            indexedCountedGrades.add((grade: g, index: runningIndex));
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

      indexedCountedGrades.sort((a, b) {
        final cmp = a.grade.date.compareTo(b.grade.date);
        return cmp != 0 ? cmp : a.index.compareTo(b.index);
      });
      indexedAllGrades.sort((a, b) {
        final cmp = a.grade.date.compareTo(b.grade.date);
        return cmp != 0 ? cmp : a.index.compareTo(b.index);
      });

      final List<({DateTime date, double average, Grade grade})> fullTrajectory = [];
      double cumWeightedSum = 0;
      int cumWeight = 0;
      for (final item in indexedCountedGrades) {
        cumWeightedSum += item.grade.numericValue * item.grade.weight;
        cumWeight += item.grade.weight;
        if (cumWeight > 0) {
          fullTrajectory.add((
            date: item.grade.date,
            average: cumWeightedSum / cumWeight,
            grade: item.grade,
          ));
        }
      }

      double? delta;
      double? semDelta;
      Grade? latestGrade;
      if (indexedCountedGrades.isNotEmpty) {
        latestGrade = indexedCountedGrades.last.grade;
        final prevWeight = totalWeight - latestGrade.weight;
        if (indexedCountedGrades.length >= 2 && prevWeight > 0) {
          final prevWeightedSum =
              weightedSum - (latestGrade.numericValue * latestGrade.weight);
          final prevAvg = prevWeightedSum / prevWeight;
          delta = avg - prevAvg;
        }
        if (fullTrajectory.length >= 2) {
          semDelta = fullTrajectory.last.average - fullTrajectory.first.average;
        }
      } else if (indexedAllGrades.isNotEmpty) {
        latestGrade = indexedAllGrades.last.grade;
      }

      return GradesDistributionStats(
        counts: counts,
        totalGrades: total,
        hasThreats: threatCount > 0,
        dangerCount: threatCount + (counts[2] ?? 0),
        positivePercentage: positivePct,
        overallAverage: avg,
        lastGradeDelta: delta,
        semesterDelta: semDelta,
        lastGrade: latestGrade,
        subjectsWithGradesCount: subjectsWithGrades,
        trajectory: fullTrajectory,
      );
    },
    loading: () => GradesDistributionStats.empty(),
    error: (_, stack) => GradesDistributionStats.empty(),
  );
});

