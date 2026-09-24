import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/calendar_export_service.dart';
import '../../../../domain/models/lesson_slot.dart';
import '../../../../domain/models/school_task.dart';
import '../../../widgets/common/exam_calendar_actions_row.dart';
import '../../../widgets/common/linked_task_action_bar.dart';

/// Modular Upcoming Exam Bento Card used on both Desktop and Mobile Dashboard (`REQ-ARCH-01`, `REQ-ARCH-02`).
class DashboardUpcomingExamCard extends ConsumerWidget {
  final UpcomingEvent exam;

  const DashboardUpcomingExamCard({
    super.key,
    required this.exam,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examDateStr = DateFormat('yyyy-MM-dd').format(exam.date);
    final examSourceId =
        SchoolTask.canonicalExamSourceId(examDateStr, exam.subject);
    final examDay = DateTime(exam.date.year, exam.date.month, exam.date.day);
    final dayBefore = examDay.subtract(const Duration(days: 1));
    final today = SchoolTask.todayStart;
    final targetDueDate = dayBefore.isBefore(today) ? today : dayBefore;
    final formattedExamDate = DateFormat('d MMMM yyyy', 'pl_PL').format(exam.date);
    final descLines = <String>[
      'Zakres: ${exam.title}',
      if (exam.room.isNotEmpty) exam.room,
      'Termin sprawdzianu: $formattedExamDate',
    ];

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: AppColors.tertiary),
                  SizedBox(width: 8),
                  Text(
                    'Nadchodzący sprawdzian',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exam.daysRemaining == 0
                      ? 'Dzisiaj'
                      : exam.daysRemaining == 1
                          ? 'Jutro'
                          : 'Za ${exam.daysRemaining} dni',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onTertiaryFixed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${exam.subject} (${exam.type.toLowerCase()})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('d MMMM', 'pl_PL').format(exam.date),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Zakres: ${exam.title}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (exam.room.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    exam.room,
                    style: const TextStyle(fontSize: 11, color: AppColors.outline),
                  ),
                ],
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => context.go('/plan-lekcji?data=$examDateStr'),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month, size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Zobacz w terminarzu →',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                LinkedTaskActionBar(
                  sourceId: examSourceId,
                  source: TaskSource.exam,
                  initialTitle:
                      'Nauczyć się: ${exam.subject} (${exam.type.toLowerCase()})',
                  initialDescription: descLines.join('\n'),
                  initialSubject: exam.subject,
                  initialDueDate: targetDueDate,
                  createButtonBgColor: AppColors.primary,
                  customMatcher: (t) =>
                      t.matchesExam(dateStr: examDateStr, subject: exam.subject),
                  metadata: {
                    'examDate': examDateStr,
                    'examType': exam.type,
                    'examScope': exam.title,
                  },
                ),
                const SizedBox(height: 8),
                ExamCalendarActionsRow(
                  event: CalendarExamEvent.fromUpcomingEvent(exam),
                  icsButtonLabel: '.ics',
                  accentColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceContainerLowest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
