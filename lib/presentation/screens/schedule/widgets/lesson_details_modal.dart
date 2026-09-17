import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/lesson_slot.dart';

class LessonDetailsModal extends StatelessWidget {
  final LessonSlot slot;
  final DateTime date;

  const LessonDetailsModal({
    super.key,
    required this.slot,
    required this.date,
  });

  static void show(BuildContext context, LessonSlot slot, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: LessonDetailsModal(slot: slot, date: date),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'pl_PL').format(date);
    final capitalizedDate = dateStr.isNotEmpty ? '${dateStr[0].toUpperCase()}${dateStr.substring(1)}' : dateStr;

    final isCanceled = slot.status == LessonStatus.canceled;
    final isSubstituted = slot.status == LessonStatus.substituted;
    final isLive = slot.status == LessonStatus.inProgress;
    final isExam = slot.eventType != null || (slot.topic != null && slot.topic!.toLowerCase().contains('sprawdzian'));

    Color statusColor = AppColors.secondary;
    String statusLabel = 'Planowa';
    IconData statusIcon = Icons.check_circle_outline;

    if (isCanceled) {
      statusColor = AppColors.error;
      statusLabel = 'Lekcja odwołana';
      statusIcon = Icons.cancel_outlined;
    } else if (isSubstituted) {
      statusColor = const Color(0xFFC2410C);
      statusLabel = 'Zastępstwo';
      statusIcon = Icons.swap_horiz_rounded;
    } else if (isLive) {
      statusColor = const Color(0xFF006C4A);
      statusLabel = 'Trwa teraz';
      statusIcon = Icons.timelapse_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(color: statusColor.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${slot.lessonNumber}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${slot.startTime} – ${slot.endTime}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        capitalizedDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Zamknij',
                ),
              ],
            ),
          ),

          // Body Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject Name
                  Text(
                    slot.subjectName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isCanceled ? AppColors.onSurfaceVariant : AppColors.onSurface,
                      decoration: isCanceled ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Room & Teacher Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceContainerHigh),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.meeting_room_outlined, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Sala lekcyjna:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                            ),
                            const Spacer(),
                            if (slot.originalRoom != null) ...[
                              Text(
                                slot.originalRoom!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.outline,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, size: 12, color: Color(0xFFC2410C)),
                              const SizedBox(width: 6),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: slot.originalRoom != null ? const Color(0xFFFFEDD5) : AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.surfaceContainerHigh),
                              ),
                              child: Text(
                                slot.room,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: slot.originalRoom != null ? const Color(0xFFC2410C) : AppColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, color: AppColors.surfaceContainerHigh),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Nauczyciel:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                            ),
                            const Spacer(),
                            if (slot.substituteTeacher != null) ...[
                              Text(
                                slot.teacher,
                                style: const TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.outline,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, size: 12, color: Color(0xFFC2410C)),
                              const SizedBox(width: 6),
                              Text(
                                slot.substituteTeacher!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFC2410C),
                                ),
                              ),
                            ] else ...[
                              Text(
                                slot.teacher.isNotEmpty ? slot.teacher : 'Brak danych',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Alert reason box (if canceled or substituted)
                  if (slot.statusNote != null && slot.statusNote!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCanceled ? const Color(0xFFFEE2E2) : const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCanceled ? const Color(0xFFFCA5A5) : const Color(0xFFFDBA74),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCanceled ? Icons.info_outline : Icons.notification_important_outlined,
                            size: 18,
                            color: isCanceled ? AppColors.error : const Color(0xFFC2410C),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCanceled ? 'Powód odwołania lekcji:' : 'Szczegóły zastępstwa:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isCanceled ? AppColors.error : const Color(0xFFC2410C),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  slot.statusNote!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Exam alert box (if applicable)
                  if (isExam) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fact_check_outlined, size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot.eventType ?? 'Sprawdzian wiedzy',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (slot.eventTitle != null)
                                  Text(
                                    slot.eventTitle!,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Topic & Education details
                  if (slot.topic != null && slot.topic!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'TEMAT LEKCJI:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceContainerHigh),
                      ),
                      child: Text(
                        slot.topic!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],

                  // Homework / Materials
                  if (slot.materials != null || slot.homework != null) ...[
                    const SizedBox(height: 14),
                    if (slot.materials != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
                                children: [
                                  const TextSpan(text: 'Materiały: ', style: TextStyle(fontWeight: FontWeight.w700)),
                                  TextSpan(text: slot.materials!),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (slot.homework != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.assignment_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
                                children: [
                                  const TextSpan(text: 'Zadanie domowe: ', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  TextSpan(text: slot.homework!),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Zamknij', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
