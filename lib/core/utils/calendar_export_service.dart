import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/lesson_slot.dart';
import '../../domain/models/school_task.dart';
import '../theme/app_colors.dart';
import 'calendar_browser_helper_stub.dart'
    if (dart.library.js_interop) 'calendar_browser_helper_web.dart';

/// Unified representation of an exam, test, or school event for Google Calendar & RFC 5545 `.ics` export (`REQ-CAL-01`, `REQ-CAL-02`).
class CalendarExamEvent {
  final String subject;
  final String eventType;
  final String scope;
  final DateTime date;
  final String? startTime; // e.g. '12:40'
  final String? endTime; // e.g. '13:25'
  final String? room;
  final String? teacher;

  const CalendarExamEvent({
    required this.subject,
    required this.eventType,
    required this.scope,
    required this.date,
    this.startTime,
    this.endTime,
    this.room,
    this.teacher,
  });

  factory CalendarExamEvent.fromUpcomingEvent(UpcomingEvent exam) {
    // Extract optional HH:mm - HH:mm from exam.room or default to 08:00 - 08:45
    String? start;
    String? end;
    final timeMatch =
        RegExp(r'(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})').firstMatch(exam.room);
    if (timeMatch != null) {
      start = timeMatch.group(1);
      end = timeMatch.group(2);
    }
    return CalendarExamEvent(
      subject: exam.subject.trim(),
      eventType: exam.type.trim().isNotEmpty ? exam.type.trim() : 'Sprawdzian',
      scope: exam.title.trim(),
      date: DateTime(exam.date.year, exam.date.month, exam.date.day),
      startTime: start,
      endTime: end,
      room: exam.room.trim().isNotEmpty ? exam.room.trim() : null,
    );
  }

  factory CalendarExamEvent.fromLessonSlot(LessonSlot slot, DateTime date) {
    final examType = slot.eventType?.trim().isNotEmpty == true
        ? slot.eventType!.trim()
        : 'Sprawdzian';
    final rawScope = (slot.eventTitle ?? slot.topic ?? '').trim();
    final scope = (rawScope.isNotEmpty &&
            rawScope.toLowerCase() != examType.toLowerCase())
        ? rawScope
        : 'Sprawdzian z przedmiotu ${slot.subjectName}';
    final teacher = (slot.substituteTeacher ?? slot.teacher).trim();

    return CalendarExamEvent(
      subject: slot.subjectName.trim(),
      eventType: examType,
      scope: scope,
      date: DateTime(date.year, date.month, date.day),
      startTime: slot.startTime.trim().isNotEmpty ? slot.startTime.trim() : null,
      endTime: slot.endTime.trim().isNotEmpty ? slot.endTime.trim() : null,
      room: slot.room.trim().isNotEmpty ? slot.room.trim() : null,
      teacher: teacher.isNotEmpty ? teacher : null,
    );
  }

  String get summaryTitle => '$eventType: $subject (Oskar)';

  String get descriptionBody {
    final lines = <String>[
      'Przedmiot: $subject',
      'Rodzaj: $eventType',
      if (scope.isNotEmpty) 'Zakres materiału: $scope',
      if (teacher != null && teacher!.isNotEmpty) 'Nauczyciel: $teacher',
      if (room != null && room!.isNotEmpty) 'Sala / informacje: $room',
      '',
      'Wyeksportowano z aplikacji EduSync (Dziennik Szkolny)',
    ];
    return lines.join('\n');
  }

  (DateTime, DateTime) get resolvedStartAndEnd {
    int startHour = 8;
    int startMin = 0;
    int endHour = 8;
    int endMin = 45;

    if (startTime != null && startTime!.contains(':')) {
      final parts = startTime!.split(':');
      startHour = int.tryParse(parts[0].trim()) ?? 8;
      startMin = int.tryParse(parts[1].trim()) ?? 0;
    }
    if (endTime != null && endTime!.contains(':')) {
      final parts = endTime!.split(':');
      endHour = int.tryParse(parts[0].trim()) ?? startHour;
      endMin = int.tryParse(parts[1].trim()) ?? (startMin + 45);
    } else {
      final computedEnd = DateTime(
        date.year,
        date.month,
        date.day,
        startHour,
        startMin,
      ).add(const Duration(minutes: 45));
      endHour = computedEnd.hour;
      endMin = computedEnd.minute;
    }

    final startDt = DateTime(date.year, date.month, date.day, startHour, startMin);
    final endDt = DateTime(date.year, date.month, date.day, endHour, endMin);
    return (startDt, endDt);
  }
}

/// Service generating Google Calendar deep-links and RFC 5545 `.ics` files (`REQ-CAL-01`, `REQ-CAL-02`).
class CalendarExportService {
  static String _formatLocalCalTimestamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y$m${d}T$hh$mm$ss';
  }

  static String _escapeIcsText(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\r\n', r'\n')
        .replaceAll('\n', r'\n');
  }

  /// Builds a direct Google Calendar template URL (`https://calendar.google.com/calendar/render?action=TEMPLATE...`).
  static String buildGoogleCalendarUrl(CalendarExamEvent event) {
    final (startDt, endDt) = event.resolvedStartAndEnd;
    final datesParam =
        '${_formatLocalCalTimestamp(startDt)}/${_formatLocalCalTimestamp(endDt)}';

    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': event.summaryTitle,
      'dates': datesParam,
      'details': event.descriptionBody,
      if (event.room != null && event.room!.isNotEmpty) 'location': event.room!,
      'ctz': 'Europe/Warsaw',
    });

    return uri.toString();
  }

  /// Builds an RFC 5545 compliant `.ics` calendar file for one or more exams.
  static String buildIcsContent(List<CalendarExamEvent> events) {
    final nowUtc = DateTime.now().toUtc();
    final dtStamp = '${_formatLocalCalTimestamp(nowUtc)}Z';

    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//EduSync//Dziennik Szkolny//PL')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('METHOD:PUBLISH')
      ..writeln('X-WR-CALNAME:Sprawdziany - Oskar (EduSync)')
      ..writeln('X-WR-TIMEZONE:Europe/Warsaw')
      ..writeln('BEGIN:VTIMEZONE')
      ..writeln('TZID:Europe/Warsaw')
      ..writeln('BEGIN:DAYLIGHT')
      ..writeln('TZOFFSETFROM:+0100')
      ..writeln('TZOFFSETTO:+0200')
      ..writeln('TZNAME:CEST')
      ..writeln('DTSTART:19700329T020000')
      ..writeln('RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU')
      ..writeln('END:DAYLIGHT')
      ..writeln('BEGIN:STANDARD')
      ..writeln('TZOFFSETFROM:+0200')
      ..writeln('TZOFFSETTO:+0100')
      ..writeln('TZNAME:CET')
      ..writeln('DTSTART:19701025T030000')
      ..writeln('RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU')
      ..writeln('END:STANDARD')
      ..writeln('END:VTIMEZONE');

    for (final event in events) {
      final (startDt, endDt) = event.resolvedStartAndEnd;
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
      final slug = SchoolTask.normalizeSlug('${event.subject}_${event.eventType}');
      final uid = 'exam-$dateStr-$slug@lepsza-szkola.web.app';

      buffer
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:$uid')
        ..writeln('DTSTAMP:$dtStamp')
        ..writeln(
            'DTSTART;TZID=Europe/Warsaw:${_formatLocalCalTimestamp(startDt)}')
        ..writeln(
            'DTEND;TZID=Europe/Warsaw:${_formatLocalCalTimestamp(endDt)}')
        ..writeln('SUMMARY:${_escapeIcsText(event.summaryTitle)}')
        ..writeln('DESCRIPTION:${_escapeIcsText(event.descriptionBody)}');

      if (event.room != null && event.room!.isNotEmpty) {
        buffer.writeln('LOCATION:${_escapeIcsText(event.room!)}');
      }

      buffer
        ..writeln('STATUS:CONFIRMED')
        // Reminder 1: 24 hours before the exam
        ..writeln('BEGIN:VALARM')
        ..writeln('TRIGGER:-P1D')
        ..writeln('ACTION:DISPLAY')
        ..writeln(
            'DESCRIPTION:${_escapeIcsText("Przypomnienie: Jutro ${event.eventType} z przedmiotu ${event.subject}")}')
        ..writeln('END:VALARM')
        // Reminder 2: 2 hours before the exam
        ..writeln('BEGIN:VALARM')
        ..writeln('TRIGGER:-PT2H')
        ..writeln('ACTION:DISPLAY')
        ..writeln(
            'DESCRIPTION:${_escapeIcsText("Za 2 godziny: ${event.eventType} - ${event.subject}")}')
        ..writeln('END:VALARM')
        ..writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString().replaceAll('\r\n', '\n').replaceAll('\n', '\r\n');
  }

  /// Opens Google Calendar pre-populated with [event] in a new browser tab.
  static void openGoogleCalendar(BuildContext context, CalendarExamEvent event) {
    final url = buildGoogleCalendarUrl(event);
    final opened = openUrlInBrowser(url);
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Otwarto Kalendarz Google: ${event.subject} (${DateFormat("d.MM.yyyy").format(event.date)})'
                : 'Wygenerowano link do Kalendarza Google: ${event.subject}',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Downloads a single `.ics` calendar file for [event].
  static void downloadSingleExamIcs(
    BuildContext context,
    CalendarExamEvent event,
  ) {
    final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
    final slug = SchoolTask.normalizeSlug(event.subject);
    final filename = 'sprawdzian_${slug}_$dateStr.ics';
    final icsContent = buildIcsContent([event]);
    final downloaded = downloadTextFileInBrowser(
      filename: filename,
      content: icsContent,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            downloaded
                ? 'Pobrano plik kalendarza: $filename (Apple Calendar / Outlook / iCal)'
                : 'Przygotowano plik kalendarza: $filename',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Downloads a bulk `.ics` file containing all [events].
  static void downloadBulkExamsIcs(
    BuildContext context,
    List<CalendarExamEvent> events, {
    String? filename,
  }) {
    if (events.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brak nadchodzących sprawdzianów do wyeksportowania.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final targetFilename = filename ??
        'sprawdziany_oskar_${DateFormat("yyyy_MM").format(DateTime.now())}.ics';
    final icsContent = buildIcsContent(events);
    final downloaded = downloadTextFileInBrowser(
      filename: targetFilename,
      content: icsContent,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            downloaded
                ? 'Pobrano zbiorczy plik .ics (${events.length} sprawdzianów): $targetFilename'
                : 'Przygotowano zbiorczy plik .ics (${events.length} sprawdzianów)',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Shows a modal dialog allowing 1-click bulk `.ics` export OR individual Google Calendar / `.ics` export for each upcoming exam.
  static Future<void> showBulkExportDialog(
    BuildContext context,
    List<CalendarExamEvent> events,
  ) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eksport sprawdzianów do Kalendarza',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Kalendarz Google, Apple Calendar (iOS/macOS), Outlook (.ics)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (events.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Brak zapowiedzianych sprawdzianów w terminarzu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: () {
                      downloadBulkExamsIcs(ctx, events);
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: Text(
                      'Pobierz wszystkie sprawdziany w jednym pliku .ics (${events.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'LUB DODAJ POJEDYNCZY SPRAWDZIAN:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: events.map((ev) {
                          final dateLabel =
                              DateFormat('EEEE, d MMM yyyy', 'pl_PL')
                                  .format(ev.date);
                          final timeLabel = (ev.startTime != null &&
                                  ev.endTime != null)
                              ? ' • ${ev.startTime}–${ev.endTime}'
                              : '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.surfaceContainerHigh,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${ev.subject} (${ev.eventType.toLowerCase()})',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$dateLabel$timeLabel',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (ev.scope.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Zakres: ${ev.scope}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          openGoogleCalendar(ctx, ev),
                                      icon: const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        '+ Kalendarz Google',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          downloadSingleExamIcs(ctx, ev),
                                      icon: const Icon(
                                        Icons.download_rounded,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'Pobierz .ics (iCal)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
