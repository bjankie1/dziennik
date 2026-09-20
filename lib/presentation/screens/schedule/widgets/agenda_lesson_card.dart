import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/lesson_slot.dart';
import '../../../../domain/models/attendance_record.dart';
import 'lesson_details_modal.dart';

class AgendaLessonCard extends StatefulWidget {
  final LessonSlot slot;
  final DateTime date;

  const AgendaLessonCard({
    super.key,
    required this.slot,
    required this.date,
  });

  @override
  State<AgendaLessonCard> createState() => _AgendaLessonCardState();
}

class _AgendaLessonCardState extends State<AgendaLessonCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    if (widget.slot.status == LessonStatus.inProgress) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  int _calculateMinutesRemaining() {
    final now = DateTime.now();
    final parts = widget.slot.endTime.split(':');
    if (parts.length < 2) return 15;
    final endHour = int.tryParse(parts[0]) ?? 0;
    final endMin = int.tryParse(parts[1]) ?? 0;
    final endDateTime = DateTime(now.year, now.month, now.day, endHour, endMin);
    final diff = endDateTime.difference(now).inMinutes;
    return diff.clamp(1, 45);
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final isCanceled = slot.status == LessonStatus.canceled;
    final isSubstituted = slot.status == LessonStatus.substituted;
    final isLive = slot.status == LessonStatus.inProgress;
    final isExam = slot.eventType != null || (slot.topic != null && slot.topic!.toLowerCase().contains('sprawdzian'));

    Color stripeColor = AppColors.surfaceContainerHighest;
    if (isCanceled) {
      stripeColor = AppColors.error;
    } else if (isLive) {
      stripeColor = AppColors.secondary;
    } else if (isSubstituted) {
      stripeColor = const Color(0xFFC2410C);
    } else if (isExam) {
      stripeColor = AppColors.primary;
    }

    final minutesLeft = isLive ? _calculateMinutesRemaining() : 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => LessonDetailsModal.show(context, slot, widget.date),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLive ? AppColors.secondary.withValues(alpha: 0.4) : AppColors.surfaceContainerHigh,
              width: isLive ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isLive ? AppColors.secondary.withValues(alpha: 0.08) : const Color(0x06000000),
                blurRadius: isLive ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left status indicator stripe
                Container(
                  width: 5,
                  color: stripeColor,
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top line: Lesson number, time, room, status pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isLive ? AppColors.secondary : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${slot.lessonNumber}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isLive ? Colors.white : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${slot.startTime} – ${slot.endTime}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isCanceled ? AppColors.outline : AppColors.onSurface,
                                    decoration: isCanceled ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('•', style: TextStyle(color: AppColors.outlineVariant)),
                                const SizedBox(width: 6),
                                Text(
                                  slot.room,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isLive || isSubstituted ? FontWeight.w700 : FontWeight.w500,
                                    color: isLive
                                        ? AppColors.secondary
                                        : (isSubstituted ? const Color(0xFFC2410C) : AppColors.onSurfaceVariant),
                                    decoration: isCanceled ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ],
                            ),

                            // Right status badge
                            if (isLive) ...[
                              FadeTransition(
                                opacity: Tween(begin: 0.6, end: 1.0).animate(_pulseController),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.secondary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Trwa teraz • Zostało $minutesLeft min',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.onSecondaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else if (isCanceled) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cancel_outlined, size: 12, color: AppColors.error),
                                    SizedBox(width: 4),
                                    Text(
                                      'Lekcja odwołana',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (isSubstituted) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEDD5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.swap_horiz_rounded, size: 12, color: Color(0xFFC2410C)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Zastępstwo',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFC2410C)),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (isExam) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  slot.eventType ?? 'Sprawdzian',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onPrimaryFixedVariant,
                                  ),
                                ),
                              ),
                            ] else if (slot.attendanceType != null && slot.attendanceType != AttendanceType.present) ...[
                              _buildAttendanceTopBadge(slot),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Title & Teacher
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                slot.subjectName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isCanceled ? AppColors.onSurfaceVariant : AppColors.onSurface,
                                  decoration: isCanceled ? TextDecoration.lineThrough : null,
                                  decorationColor: AppColors.error,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  slot.substituteTeacher ?? slot.teacher,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSubstituted ? FontWeight.w700 : FontWeight.w500,
                                    color: isSubstituted ? const Color(0xFFC2410C) : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Canceled Alert Box
                        if (isCanceled && slot.statusNote != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Powód odwołania:',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.error),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        slot.statusNote!,
                                        style: const TextStyle(fontSize: 11, color: AppColors.onSurface),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Attendance Alert & Status Box (D-03)
                        if (slot.attendanceType != null && slot.attendanceType != AttendanceType.present) ...[
                          _buildAttendanceBanner(slot),
                        ],

                        // Extended details box (topic, materials, homework)
                        if (slot.topic != null || slot.homework != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (slot.topic != null)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        width: 70,
                                        child: Text(
                                          'Temat:',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          slot.topic!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (slot.materials != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        width: 70,
                                        child: Text(
                                          'Materiały:',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          slot.materials!,
                                          style: const TextStyle(fontSize: 11, color: AppColors.onSurface),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (slot.homework != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.only(top: 8),
                                    decoration: const BoxDecoration(
                                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(
                                          width: 70,
                                          child: Row(
                                            children: [
                                              Icon(Icons.assignment_outlined, size: 12, color: AppColors.primary),
                                              SizedBox(width: 3),
                                              Text(
                                                'Zadanie:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            slot.homework!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTopBadge(LessonSlot slot) {
    final isPending = slot.attendanceJustificationStatus == JustificationStatus.requested;
    if (isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFB45309)),
            SizedBox(width: 4),
            Text(
              'Oczekuje na weryfikację',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
            ),
          ],
        ),
      );
    }

    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (slot.attendanceType!) {
      case AttendanceType.absent:
        bgColor = const Color(0xFFFEE2E2);
        textColor = AppColors.error;
        label = 'Nieobecność';
        icon = Icons.cancel_outlined;
        break;
      case AttendanceType.excused:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        label = 'Usprawiedliwiona';
        icon = Icons.check_circle_outline;
        break;
      case AttendanceType.exempted:
        bgColor = const Color(0xFFE0F2FE);
        textColor = const Color(0xFF0369A1);
        label = 'Zwolnienie';
        icon = Icons.beach_access_rounded;
        break;
      case AttendanceType.late:
      case AttendanceType.excusedLate:
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFFA16207);
        label = 'Spóźnienie';
        icon = Icons.access_time_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceBanner(LessonSlot slot) {
    final isPending = slot.attendanceJustificationStatus == JustificationStatus.requested;
    final isApproved = slot.attendanceJustificationStatus == JustificationStatus.approved ||
        slot.attendanceType == AttendanceType.excused;

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String statusTitle;
    String statusSubtitle;

    if (isPending) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      textColor = const Color(0xFFB45309);
      icon = Icons.pending_actions_rounded;
      statusTitle = 'Oczekuje na weryfikację';
      statusSubtitle = 'Wniosek o usprawiedliwienie przesłany do wychowawcy';
    } else if (isApproved) {
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      textColor = const Color(0xFF15803D);
      icon = Icons.check_circle_outline_rounded;
      statusTitle = 'Nieobecność usprawiedliwiona';
      statusSubtitle = 'Zaakceptowano przez wychowawcę';
    } else {
      switch (slot.attendanceType!) {
        case AttendanceType.absent:
          bgColor = const Color(0xFFFEF2F2);
          borderColor = const Color(0xFFFECACA);
          textColor = AppColors.error;
          icon = Icons.cancel_outlined;
          statusTitle = 'Nieobecność nieusprawiedliwiona';
          statusSubtitle = 'Wymaga złożenia e-usprawiedliwienia';
          break;
        case AttendanceType.exempted:
          bgColor = const Color(0xFFF0F9FF);
          borderColor = const Color(0xFFBAE6FD);
          textColor = const Color(0xFF0369A1);
          icon = Icons.beach_access_rounded;
          statusTitle = 'Zwolnienie z lekcji';
          statusSubtitle = 'Uczeń zwolniony z udziału w zajęciach';
          break;
        case AttendanceType.late:
        case AttendanceType.excusedLate:
          bgColor = const Color(0xFFFEFCE8);
          borderColor = const Color(0xFFFEF08A);
          textColor = const Color(0xFFA16207);
          icon = Icons.access_time_rounded;
          statusTitle = slot.attendanceType == AttendanceType.excusedLate
              ? 'Spóźnienie usprawiedliwione'
              : 'Spóźnienie';
          statusSubtitle = 'Odnotowano spóźnienie na zajęcia';
          break;
        default:
          return const SizedBox.shrink();
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: const Text(
                          'WERYFIKACJA',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  statusSubtitle,
                  style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.9)),
                ),
                if (slot.attendanceNote != null && slot.attendanceNote!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Powód rodzica: ${slot.attendanceNote}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
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
