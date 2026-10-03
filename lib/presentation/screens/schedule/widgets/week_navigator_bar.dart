import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/calendar_export_service.dart';
import '../../../../domain/models/lesson_slot.dart';
import '../../../providers/school_providers.dart';

class WeekNavigatorBar extends ConsumerWidget {
  final DateTime currentWeekMonday;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onCurrentWeek;

  const WeekNavigatorBar({
    super.key,
    required this.currentWeekMonday,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onCurrentWeek,
  });

  bool _isThisCurrentWeek() {
    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    return currentWeekMonday.year == thisMonday.year &&
        currentWeekMonday.month == thisMonday.month &&
        currentWeekMonday.day == thisMonday.day;
  }

  String _formatWeekRange() {
    final friday = currentWeekMonday.add(const Duration(days: 4));
    final startDay = currentWeekMonday.day;
    final endDay = friday.day;
    final monthName = DateFormat('LLLL yyyy', 'pl_PL').format(friday);
    final capitalized = monthName.isNotEmpty
        ? '${monthName[0].toUpperCase()}${monthName.substring(1)}'
        : monthName;
    return '$startDay – $endDay $capitalized';
  }

  List<CalendarExamEvent> _collectExamEvents(WidgetRef ref) {
    final byKey = <String, CalendarExamEvent>{};

    // 1. From current week's timetable slots (has exact startTime, endTime, room, teacher)
    final weekMap =
        ref.read(weekScheduleProvider).value ?? const <int, List<LessonSlot>>{};
    for (final entry in weekMap.entries) {
      final dayIndex = entry.key; // 1 = Monday .. 5 = Friday
      final lessonDate = currentWeekMonday.add(Duration(days: dayIndex - 1));
      final dateStr =
          '${lessonDate.year}-${lessonDate.month.toString().padLeft(2, '0')}-${lessonDate.day.toString().padLeft(2, '0')}';

      for (final slot in entry.value) {
        final hasExam = slot.eventType != null ||
            (slot.topic != null &&
                slot.topic!.toLowerCase().contains('sprawdzian')) ||
            (slot.topic != null &&
                slot.topic!.toLowerCase().contains('kartków'));
        if (hasExam) {
          final event = CalendarExamEvent.fromLessonSlot(slot, lessonDate);
          final key = '${dateStr}_${event.subject.toLowerCase()}';
          byKey[key] = event;
        }
      }
    }

    // 2. From upcomingExamProvider (next upcoming exam across weeks)
    final upcomingExam = ref.read(upcomingExamProvider).value;
    if (upcomingExam != null) {
      final event = CalendarExamEvent.fromUpcomingEvent(upcomingExam);
      final dateStr =
          '${event.date.year}-${event.date.month.toString().padLeft(2, '0')}-${event.date.day.toString().padLeft(2, '0')}';
      final key = '${dateStr}_${event.subject.toLowerCase()}';
      byKey.putIfAbsent(key, () => event);
    }

    final list = byKey.values.toList()
      ..sort((a, b) {
        final (aStart, _) = a.resolvedStartAndEnd;
        final (bStart, _) = b.resolvedStartAndEnd;
        return aStart.compareTo(bStart);
      });
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = _isThisCurrentWeek();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;
    // Watch providers so data is fresh when user clicks iCal export
    ref.watch(upcomingExamProvider);
    ref.watch(weekScheduleProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left / Expanded: Compact Week Selector
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 18),
                    onPressed: onPreviousWeek,
                    tooltip: 'Poprzedni tydzień',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _formatWeekRange(),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Aktualny',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 18),
                    onPressed: onNextWeek,
                    tooltip: 'Następny tydzień',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const SizedBox(width: 2),
                  TextButton(
                    onPressed: onCurrentWeek,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerLowest,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 26),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: const Text(
                      'Dzisiaj',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Right: Compact Export & Print tools
          OutlinedButton.icon(
            onPressed: () {
              final events = _collectExamEvents(ref);
              CalendarExportService.showBulkExportDialog(context, events);
            },
            icon: const Icon(
              Icons.event_available_rounded,
              size: 15,
              color: AppColors.primary,
            ),
            label: Text(
              isCompact ? 'iCal' : 'Eksport iCal / Google',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primaryFixed.withValues(alpha: 0.35),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 12,
                vertical: 6,
              ),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generowanie planu lekcji do pliku PDF...'),
                ),
              );
            },
            tooltip: 'Drukuj plan lekcji',
            icon: const Icon(Icons.print_outlined, size: 17),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.onSurface,
              side: const BorderSide(color: AppColors.surfaceContainerHigh),
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
