import 'package:flutter/material.dart';
import '../../../core/utils/calendar_export_service.dart';

/// Unified row of buttons for exporting an exam/event to Google Calendar or RFC 5545 `.ics` (`REQ-CAL-01`, `REQ-CAL-02`, `REQ-ARCH-02`).
class ExamCalendarActionsRow extends StatelessWidget {
  final CalendarExamEvent event;
  final String icsButtonLabel;
  final Color accentColor;
  final Color? backgroundColor;

  const ExamCalendarActionsRow({
    super.key,
    required this.event,
    this.icsButtonLabel = '.ics',
    this.accentColor = const Color(0xFF92400E),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Colors.white.withValues(alpha: 0.92);
    final borderSide = BorderSide(color: accentColor.withValues(alpha: 0.25));

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => CalendarExportService.openGoogleCalendar(context, event),
            icon: Icon(
              Icons.event_available_rounded,
              size: 15,
              color: accentColor,
            ),
            label: Text(
              '+ Kalendarz Google',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: bg,
              side: borderSide,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => CalendarExportService.downloadSingleExamIcs(context, event),
          icon: Icon(
            Icons.download_rounded,
            size: 15,
            color: accentColor,
          ),
          label: Text(
            icsButtonLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: bg,
            side: borderSide,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 34),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
