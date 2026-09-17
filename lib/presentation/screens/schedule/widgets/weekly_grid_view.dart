import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/lesson_slot.dart';
import '../../../providers/school_providers.dart';
import 'lesson_details_modal.dart';

class WeeklyGridView extends ConsumerWidget {
  final DateTime currentWeekMonday;
  final Map<int, List<LessonSlot>> weekMap;
  final ValueChanged<int>? onDayHeaderTap;

  const WeeklyGridView({
    super.key,
    required this.currentWeekMonday,
    required this.weekMap,
    this.onDayHeaderTap,
  });

  static const List<Map<String, String>> defaultTimeSlots = [
    {'number': '1', 'start': '08:00', 'end': '08:45'},
    {'number': '2', 'start': '08:50', 'end': '09:35'},
    {'number': '3', 'start': '09:45', 'end': '10:30'},
    {'number': '4', 'start': '10:45', 'end': '11:30'},
    {'number': '5', 'start': '11:45', 'end': '12:30'},
    {'number': '6', 'start': '12:40', 'end': '13:25'},
    {'number': '7', 'start': '13:35', 'end': '14:20'},
    {'number': '8', 'start': '14:25', 'end': '15:10'},
  ];

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(weekScheduleFilterProvider);
    final now = DateTime.now();

    final dayNames = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek'];
    final dayDates = List.generate(5, (i) => currentWeekMonday.add(Duration(days: i)));

    // Calculate maximum lesson number to display (at least 6, up to 8)
    int maxLessonNumber = 6;
    for (final dayLessons in weekMap.values) {
      for (final slot in dayLessons) {
        if (slot.lessonNumber > maxLessonNumber) {
          maxLessonNumber = slot.lessonNumber;
        }
      }
    }
    final timeSlots = defaultTimeSlots.take(maxLessonNumber.clamp(6, 8)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompactTablet = screenWidth >= 700 && screenWidth < 1024;
        final timeColWidth = isCompactTablet ? 72.0 : 96.0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceContainerHigh),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: screenWidth < 700 ? Axis.horizontal : Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: screenWidth < 700 ? 760 : screenWidth,
                ),
                child: Column(
                  children: [
                    // Header Row: Days
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        border: Border(
                          bottom: BorderSide(color: AppColors.surfaceContainerHigh),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Time header
                          SizedBox(
                            width: timeColWidth,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Text(
                                  'GODZINA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 5 Day Columns
                          ...List.generate(5, (i) {
                            final dayDate = dayDates[i];
                            final isToday = _isSameDay(dayDate, now);
                            final dayLessons = weekMap[i + 1] ?? [];
                            final dayNumber = DateFormat('d MMMM', 'pl_PL').format(dayDate);

                            final hasSubstitution = dayLessons.any((s) => s.status == LessonStatus.substituted);
                            final hasCanceled = dayLessons.any((s) => s.status == LessonStatus.canceled);
                            final hasExam = dayLessons.any(
                              (s) => s.eventType != null || (s.topic != null && s.topic!.toLowerCase().contains('sprawdzian')),
                            );

                            return Expanded(
                              child: Material(
                                color: isToday ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (onDayHeaderTap != null) onDayHeaderTap!(i);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompactTablet ? 6 : 10,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: const BorderSide(color: AppColors.surfaceContainerHigh),
                                        top: isToday ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      isCompactTablet ? dayNames[i].substring(0, 3) : dayNames[i],
                                                      style: TextStyle(
                                                        fontSize: isCompactTablet ? 12 : 13,
                                                        fontWeight: FontWeight.w800,
                                                        color: isToday ? AppColors.primary : AppColors.onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isToday) ...[
                                                    const SizedBox(width: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Text(
                                                        'Dziś',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                dayNumber,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                                  color: isToday ? AppColors.primary : AppColors.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Status indicators
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (hasCanceled)
                                              _buildDot(AppColors.error, 'Lekcja odwołana'),
                                            if (hasSubstitution)
                                              _buildDot(const Color(0xFFC2410C), 'Zastępstwo'),
                                            if (hasExam)
                                              _buildDot(AppColors.primary, 'Sprawdzian'),
                                            if (!hasCanceled && !hasSubstitution && !hasExam)
                                              _buildDot(AppColors.secondary, 'Wszystkie planowo'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Grid Rows for each lesson slot
                    ...timeSlots.map((ts) {
                      final lessonNum = int.parse(ts['number']!);
                      final startTime = ts['start']!;
                      final endTime = ts['end']!;

                      return Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFF1F5F9)),
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Time cell
                              Container(
                                width: timeColWidth,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                color: const Color(0xFFF8FAFC),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$lessonNum. LEKCJA',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      startTime,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      endTime,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 5 Days cells
                              ...List.generate(5, (i) {
                                final dayDate = dayDates[i];
                                final isToday = _isSameDay(dayDate, now);
                                final dayLessons = weekMap[i + 1] ?? [];
                                final slot = dayLessons.where((s) => s.lessonNumber == lessonNum).firstOrNull;

                                return Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isToday ? AppColors.primary.withValues(alpha: 0.02) : Colors.transparent,
                                      border: const Border(
                                        left: BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: slot != null
                                        ? _buildLessonCell(
                                            context,
                                            slot,
                                            dayDate,
                                            activeFilter,
                                            isCompactTablet,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot(Color color, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildLessonCell(
    BuildContext context,
    LessonSlot slot,
    DateTime date,
    WeekScheduleFilter filter,
    bool isCompact,
  ) {
    final isCanceled = slot.status == LessonStatus.canceled;
    final isSubstituted = slot.status == LessonStatus.substituted;
    final isLive = slot.status == LessonStatus.inProgress;
    final isExam = slot.eventType != null || (slot.topic != null && slot.topic!.toLowerCase().contains('sprawdzian'));

    // Check filter match
    bool isDimmed = false;
    if (filter == WeekScheduleFilter.substitutions && !isSubstituted) isDimmed = true;
    if (filter == WeekScheduleFilter.exams && !isExam) isDimmed = true;
    if (filter == WeekScheduleFilter.canceled && !isCanceled) isDimmed = true;

    Color borderColor = const Color(0xFFE2E8F0);
    Color bgColor = const Color(0xFFF8FAFC);
    Color stripeColor = Colors.transparent;

    if (isCanceled) {
      stripeColor = AppColors.error;
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
    } else if (isSubstituted) {
      stripeColor = const Color(0xFFC2410C);
      bgColor = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFFED7AA);
    } else if (isLive) {
      stripeColor = const Color(0xFF006C4A);
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
    } else if (isExam) {
      stripeColor = AppColors.primary;
      bgColor = const Color(0xFFEEF2FF);
      borderColor = const Color(0xFFC7D2FE);
    }

    return Opacity(
      opacity: isDimmed ? 0.25 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            LessonDetailsModal.show(context, slot, date);
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(isCompact ? 5 : 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Subject + Room pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stripeColor != Colors.transparent)
                      Container(
                        width: 3,
                        height: 14,
                        margin: const EdgeInsets.only(right: 5, top: 1),
                        decoration: BoxDecoration(
                          color: stripeColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        slot.subjectName,
                        style: TextStyle(
                          fontSize: isCompact ? 11 : 12,
                          fontWeight: FontWeight.w700,
                          color: isCanceled ? AppColors.onSurfaceVariant : AppColors.onSurface,
                          decoration: isCanceled ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.error,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSubstituted ? const Color(0xFFFFEDD5) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        slot.room.replaceFirst('Sala ', 's. '),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isSubstituted ? const Color(0xFFC2410C) : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Bottom: Teacher or Exam tag or Topic
                if (isExam) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      slot.eventTitle ?? slot.eventType ?? 'Sprawdzian',
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else if (isCanceled) ...[
                  const Text(
                    'Odwołana',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.error),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          slot.substituteTeacher ?? slot.teacher,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSubstituted ? const Color(0xFFC2410C) : AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
