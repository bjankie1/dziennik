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
  final String? topic;
  final String? homework;
  final String? materials;
  final String? eventType;
  final String? eventTitle;

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
    this.topic,
    this.homework,
    this.materials,
    this.eventType,
    this.eventTitle,
  });

  LessonSlot copyWith({
    int? lessonNumber,
    String? subjectName,
    String? originalSubjectName,
    String? startTime,
    String? endTime,
    String? room,
    String? originalRoom,
    String? teacher,
    String? substituteTeacher,
    LessonStatus? status,
    String? statusNote,
    double? progressFraction,
    String? topic,
    String? homework,
    String? materials,
    String? eventType,
    String? eventTitle,
  }) {
    return LessonSlot(
      lessonNumber: lessonNumber ?? this.lessonNumber,
      subjectName: subjectName ?? this.subjectName,
      originalSubjectName: originalSubjectName ?? this.originalSubjectName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      originalRoom: originalRoom ?? this.originalRoom,
      teacher: teacher ?? this.teacher,
      substituteTeacher: substituteTeacher ?? this.substituteTeacher,
      status: status ?? this.status,
      statusNote: statusNote ?? this.statusNote,
      progressFraction: progressFraction ?? this.progressFraction,
      topic: topic ?? this.topic,
      homework: homework ?? this.homework,
      materials: materials ?? this.materials,
      eventType: eventType ?? this.eventType,
      eventTitle: eventTitle ?? this.eventTitle,
    );
  }
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
