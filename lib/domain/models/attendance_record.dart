enum AttendanceType {
  present,
  absent,
  excused,
  late,
  excusedLate,
  exempted,
}

enum JustificationStatus {
  none,
  requested,
  approved,
  rejected,
}

class AttendanceRecord {
  final String id;
  final DateTime date;
  final int lessonNumber;
  final String subjectName;
  final AttendanceType type;
  final String timeSlot;
  final JustificationStatus justificationStatus;
  final String? justificationReason;

  const AttendanceRecord({
    required this.id,
    required this.date,
    required this.lessonNumber,
    required this.subjectName,
    required this.type,
    required this.timeSlot,
    this.justificationStatus = JustificationStatus.none,
    this.justificationReason,
  });

  bool get needsJustification =>
      type == AttendanceType.absent && justificationStatus == JustificationStatus.none;
}
