class StudentProfile {
  final String id;
  final String name;
  final String className;
  final String schoolName;
  final String avatarUrl;
  final double attendancePercentage;
  final double overallAverage;
  final double previousPeriodAverage;
  final int classRank;
  final int totalStudentsInClass;
  final int unreadMessagesCount;
  final String currentWeek; // e.g. "Tydzień B"

  const StudentProfile({
    required this.id,
    required this.name,
    required this.className,
    required this.schoolName,
    required this.avatarUrl,
    required this.attendancePercentage,
    required this.overallAverage,
    required this.previousPeriodAverage,
    required this.classRank,
    required this.totalStudentsInClass,
    required this.unreadMessagesCount,
    required this.currentWeek,
  });
}
