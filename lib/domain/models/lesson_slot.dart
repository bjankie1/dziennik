enum LessonStatus {
  normal,
  inProgress,
  canceled,
  substituted,
  completed,
}

class LessonSlot {
  final int lessonNumber;
  final String subjectName;
  final String? originalSubjectName;
  final String startTime;
  final String endTime;
  final String room;
  final String? originalRoom;
  final String teacher;
  final String? substituteTeacher;
  final LessonStatus status;
  final String? statusNote; // e.g. "Zwolnienie lekarskie nauczyciela"
  final double? progressFraction; // 0.0 to 1.0 for currently in progress

  const LessonSlot({
    required this.lessonNumber,
    required this.subjectName,
    this.originalSubjectName,
    required this.startTime,
    required this.endTime,
    required this.room,
    this.originalRoom,
    required this.teacher,
    this.substituteTeacher,
    required this.status,
    this.statusNote,
    this.progressFraction,
  });
}

class UpcomingEvent {
  final String title;
  final String subject;
  final DateTime date;
  final String time;
  final String room;
  final String type; // e.g. "Sprawdzian", "Kartkówka", "Wywiadówka"
  final int daysRemaining;
  final bool hasNotes;

  const UpcomingEvent({
    required this.title,
    required this.subject,
    required this.date,
    required this.time,
    required this.room,
    required this.type,
    required this.daysRemaining,
    this.hasNotes = true,
  });
}
