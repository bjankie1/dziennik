import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/lesson_slot.dart';
import 'dashboard_upcoming_exam_card.dart';

/// Left column of Desktop Dashboard containing Daily Schedule Timeline and Upcoming Exam Card (`REQ-ARCH-01`, `REQ-ARCH-02`).
class DashboardScheduleColumn extends StatelessWidget {
  final List<LessonSlot> lessons;
  final DateTime now;
  final UpcomingEvent? exam;
  final bool isWeekend;

  const DashboardScheduleColumn({
    super.key,
    required this.lessons,
    required this.now,
    this.exam,
    required this.isWeekend,
  });

  @override
  Widget build(BuildContext context) {
    int completedCount = 0;
    for (final l in lessons) {
      if (l.status == LessonStatus.canceled) {
        completedCount++;
        continue;
      }
      try {
        final endParts = l.endTime.split(':').map(int.parse).toList();
        final end = DateTime(
          now.year,
          now.month,
          now.day,
          endParts[0],
          endParts[1],
        );
        if (now.isAfter(end)) completedCount++;
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Harmonogram na dziś',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lessons.isEmpty
                          ? (isWeekend ? 'Weekend' : 'Dzień wolny')
                          : '$completedCount / ${lessons.length} zrealizowane',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (lessons.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 16,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.weekend_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isWeekend
                            ? 'Brak lekcji na dzisiaj • Weekend 🎉'
                            : 'Brak lekcji na dzisiaj • Dzień wolny 🎉',
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isWeekend
                            ? 'Dziś nie masz zajęć lekcyjnych. Odpocznij i nabierz sił na nadchodzący tydzień nauki!'
                            : 'Ciesz się wolnym czasem lub powtórz materiał na nadchodzące lekcje.',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...lessons.map((lesson) => _buildDesktopLessonItem(lesson)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => context.go('/plan-lekcji'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Pełny plan lekcji na cały tydzień'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerLow,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (exam != null) ...[
          const SizedBox(height: 20),
          DashboardUpcomingExamCard(exam: exam!),
        ],
      ],
    );
  }

  Widget _buildDesktopLessonItem(LessonSlot lesson) {
    bool isInProgress = lesson.status == LessonStatus.inProgress;
    double progress = lesson.progressFraction ?? 0.0;
    int remainingMinutes = 0;

    if (lesson.status != LessonStatus.canceled) {
      try {
        final sParts = lesson.startTime.split(':').map(int.parse).toList();
        final eParts = lesson.endTime.split(':').map(int.parse).toList();
        final start = DateTime(
          now.year,
          now.month,
          now.day,
          sParts[0],
          sParts[1],
        );
        final end = DateTime(
          now.year,
          now.month,
          now.day,
          eParts[0],
          eParts[1],
        );

        if (now.isAfter(start) && now.isBefore(end)) {
          isInProgress = true;
          final totalSec = end.difference(start).inSeconds;
          final elapsedSec = now.difference(start).inSeconds;
          progress = (elapsedSec / totalSec).clamp(0.0, 1.0);
          remainingMinutes = end.difference(now).inMinutes;
        }
      } catch (_) {}
    }

    Color stripeColor = AppColors.outlineVariant;
    if (lesson.status == LessonStatus.canceled) {
      stripeColor = AppColors.error;
    } else if (isInProgress) {
      stripeColor = AppColors.primary;
    } else if (lesson.status == LessonStatus.substituted) {
      stripeColor = AppColors.tertiary;
    } else {
      stripeColor = AppColors.secondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isInProgress
            ? AppColors.primaryFixed.withValues(alpha: 0.25)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: isInProgress ? 65 : 44,
            decoration: BoxDecoration(
              color: stripeColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${lesson.startTime} - ${lesson.endTime}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isInProgress ? FontWeight.bold : FontWeight.w500,
                        color: isInProgress
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        decoration: lesson.status == LessonStatus.canceled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (lesson.status == LessonStatus.canceled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ODWOŁANE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      )
                    else if (isInProgress)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'W TRAKCIE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (lesson.status == LessonStatus.substituted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryFixed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ZASTĘPSTWO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onTertiaryFixed,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PLANOWO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${lesson.lessonNumber}. ${lesson.subjectName}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isInProgress
                            ? AppColors.primary
                            : AppColors.onSurface,
                        decoration: lesson.status == LessonStatus.canceled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      lesson.room.isNotEmpty ? 'Sala ${lesson.room}' : '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (lesson.status == LessonStatus.canceled) ...[
                  const SizedBox(height: 2),
                  Text(
                    lesson.statusNote ?? 'Lekcja odwołana',
                    style: const TextStyle(fontSize: 11, color: AppColors.error),
                  ),
                ],
                if (lesson.status == LessonStatus.substituted &&
                    lesson.substituteTeacher != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Zamiast ${lesson.teacher} prowadzi ${lesson.substituteTeacher}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
                if (isInProgress) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lesson.teacher,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Zostało $remainingMinutes min',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
