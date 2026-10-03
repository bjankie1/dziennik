import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/polish_date_formatter.dart';
import '../../../../domain/models/attendance_record.dart';
import '../../../../domain/models/justification_request.dart';
import '../../../providers/school_providers.dart';

class PendingTeacherAccordionBanner extends ConsumerStatefulWidget {
  final List<AttendanceRecord> pendingList;

  const PendingTeacherAccordionBanner({
    super.key,
    required this.pendingList,
  });

  @override
  ConsumerState<PendingTeacherAccordionBanner> createState() =>
      _PendingTeacherAccordionBannerState();
}

class _PendingTeacherAccordionBannerState
    extends ConsumerState<PendingTeacherAccordionBanner> {
  bool _isExpanded = false;
  bool _isCancellingPending = false;

  @override
  Widget build(BuildContext context) {
    final pendingList = widget.pendingList;
    final groupedByDay = JustificationRequest.groupRecordsByDay(
      pendingList,
      descendingDays: true,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('pending_teacher_banner_toggle'),
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_empty_rounded,
                      color: AppColors.warningIcon,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pendingList.length} ${pendingList.length == 1 ? "wniosek czeka" : "wnioski czekają"} na wychowawcę',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warningTitle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _isExpanded
                                      ? 'Ukryj szczegóły'
                                      : 'Pokaż szczegóły',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warningText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: AppColors.warningText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('cancel_all_pending_button'),
                      onPressed: _isCancellingPending
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                useRootNavigator: true,
                                builder: (dialogCtx) => AlertDialog(
                                  title: const Text(
                                    'Cofnąć wszystkie oczekujące wnioski?',
                                  ),
                                  content: Text(
                                    'Czy na pewno chcesz cofnąć wszystkie oczekujące wnioski (${pendingList.length})? Nieobecności wrócą do puli do ponownego usprawiedliwienia.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogCtx).pop(false),
                                      child: const Text('Anuluj'),
                                    ),
                                    FilledButton(
                                      key: const ValueKey(
                                        'confirm_cancel_all_pending_button',
                                      ),
                                      onPressed: () =>
                                          Navigator.of(dialogCtx).pop(true),
                                      child: const Text('Cofnij wszystkie'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true || !mounted) return;
                              setState(() => _isCancellingPending = true);
                              try {
                                final ids =
                                    pendingList.map((r) => r.id).toList();
                                await ref
                                    .read(attendanceProvider.notifier)
                                    .cancelJustification(ids);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Przywrócono nieobecności do ponownego usprawiedliwienia.',
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isCancellingPending = false);
                                }
                              }
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Cofnij wszystkie',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warningText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(height: 1, color: AppColors.warningBorder),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: groupedByDay.entries.map((entry) {
                            final dayRecords = entry.value;
                            final dayHeader =
                                PolishDateFormatter.formatDayHeader(
                                  dayRecords.first.date,
                                );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 13,
                                        color: AppColors.warningTitle,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          dayHeader,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.warningDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ...dayRecords.map((rec) {
                                    final hasTeacherOrRoom =
                                        (rec.teacherName != null &&
                                            rec.teacherName!.isNotEmpty) ||
                                        (rec.classroom != null &&
                                            rec.classroom!.isNotEmpty);
                                    final teacherRoomSubtitle = hasTeacherOrRoom
                                        ? '${rec.teacherName ?? "Nauczyciel"}${rec.classroom != null && rec.classroom!.isNotEmpty ? " • Sala ${rec.classroom}" : ""}'
                                        : null;
                                    final sentReason =
                                        (rec.justificationReason != null &&
                                            rec.justificationReason!.isNotEmpty)
                                        ? rec.justificationReason!
                                        : 'Usprawiedliwienie wysłane do wychowawcy';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.warningBorder,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Lekcja ${rec.lessonNumber} • ${rec.timeSlot}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.warningText,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  rec.subjectName,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.slate900,
                                                  ),
                                                ),
                                                if (teacherRoomSubtitle !=
                                                    null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    teacherRoomSubtitle,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.slate500,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Powód: $sentReason',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.warningTitle,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            key: ValueKey(
                                              'cancel_pending_${rec.id}',
                                            ),
                                            onPressed: _isCancellingPending
                                                ? null
                                                : () async {
                                                    setState(
                                                      () =>
                                                          _isCancellingPending =
                                                              true,
                                                    );
                                                    try {
                                                      await ref
                                                          .read(
                                                            attendanceProvider
                                                                .notifier,
                                                          )
                                                          .cancelJustification([
                                                            rec.id,
                                                          ]);
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Cofnięto wniosek dla przedmiotu ${rec.subjectName}.',
                                                            ),
                                                            backgroundColor:
                                                                AppColors
                                                                    .primary,
                                                          ),
                                                        );
                                                      }
                                                    } finally {
                                                      if (mounted) {
                                                        setState(
                                                          () =>
                                                              _isCancellingPending =
                                                                  false,
                                                        );
                                                      }
                                                    }
                                                  },
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: AppColors.warningAccent,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              minimumSize: const Size(0, 36),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'Cofnij',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.warningText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
