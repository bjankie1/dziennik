import 'attendance_record.dart';

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
  final AttendanceType? attendanceType;
  final JustificationStatus? attendanceJustificationStatus;
  final String? attendanceNote;

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
    this.attendanceType,
    this.attendanceJustificationStatus,
    this.attendanceNote,
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
    AttendanceType? attendanceType,
    JustificationStatus? attendanceJustificationStatus,
    String? attendanceNote,
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
      attendanceType: attendanceType ?? this.attendanceType,
      attendanceJustificationStatus: attendanceJustificationStatus ?? this.attendanceJustificationStatus,
      attendanceNote: attendanceNote ?? this.attendanceNote,
    );
  }

  DateTime? startDateTimeOn(DateTime day) => _parseTimeOn(startTime, day);

  DateTime? endDateTimeOn(DateTime day) => _parseTimeOn(endTime, day);

  static DateTime? _parseTimeOn(String timeStr, DateTime day) {
    final parts = timeStr.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  static bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isHappeningAt(DateTime now, {DateTime? lessonDate}) {
    if (status == LessonStatus.canceled) return false;
    final day = lessonDate ?? now;
    if (!_isSameCalendarDay(day, now)) return false;

    final start = startDateTimeOn(day);
    final end = endDateTimeOn(day);
    if (start != null && end != null && end.isAfter(start)) {
      return !now.isBefore(start) && now.isBefore(end);
    }
    return status == LessonStatus.inProgress;
  }

  bool isCompletedAt(DateTime now, {DateTime? lessonDate}) {
    if (status == LessonStatus.canceled) return false;
    final day = lessonDate ?? now;
    final dayStart = DateTime(day.year, day.month, day.day);
    final nowDayStart = DateTime(now.year, now.month, now.day);

    if (dayStart.isBefore(nowDayStart)) return true;
    if (dayStart.isAfter(nowDayStart)) return false;

    final end = endDateTimeOn(day);
    if (end != null) {
      return !now.isBefore(end);
    }
    return status == LessonStatus.completed;
  }

  double progressAt(DateTime now, {DateTime? lessonDate}) {
    if (status == LessonStatus.canceled) return 0.0;
    if (isCompletedAt(now, lessonDate: lessonDate)) return 1.0;
    if (!isHappeningAt(now, lessonDate: lessonDate)) return 0.0;

    final day = lessonDate ?? now;
    final start = startDateTimeOn(day);
    final end = endDateTimeOn(day);
    if (start != null && end != null) {
      final totalSec = end.difference(start).inSeconds;
      if (totalSec > 0) {
        final elapsedSec = now.difference(start).inSeconds;
        return (elapsedSec / totalSec).clamp(0.0, 1.0);
      }
    }
    return (progressFraction ?? 0.0).clamp(0.0, 1.0);
  }

  int remainingMinutesAt(DateTime now, {DateTime? lessonDate}) {
    if (!isHappeningAt(now, lessonDate: lessonDate)) return 0;
    final day = lessonDate ?? now;
    final end = endDateTimeOn(day);
    if (end != null) {
      final remSec = end.difference(now).inSeconds;
      if (remSec > 0) {
        return (remSec / 60).ceil().clamp(1, 180);
      }
    }
    return 0;
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
