import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/polish_date_formatter.dart';
import '../../../../domain/models/attendance_record.dart';
import '../../../../domain/models/justification_request.dart';

class AcceptedJustificationsSummaryCard extends StatefulWidget {
  final List<AttendanceRecord> excusedList;

  const AcceptedJustificationsSummaryCard({
    super.key,
    required this.excusedList,
  });

  static String formatLessonsCount(int count) {
    if (count == 1) return '1 lekcja';
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$count lekcje';
    }
    return '$count lekcji';
  }

  @override
  State<AcceptedJustificationsSummaryCard> createState() =>
      _AcceptedJustificationsSummaryCardState();
}

class _AcceptedJustificationsSummaryCardState
    extends State<AcceptedJustificationsSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final excusedList = widget.excusedList;
    if (excusedList.isEmpty) return const SizedBox.shrink();

    final groupedByDay = JustificationRequest.groupRecordsByDay(
      excusedList,
      descendingDays: true,
    );
    final daysCount = groupedByDay.length;
    final lessonsLabel = AcceptedJustificationsSummaryCard.formatLessonsCount(
      excusedList.length,
    );

    return Container(
      key: const ValueKey('accepted_justifications_summary_card'),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('accepted_justifications_banner_toggle'),
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zaakceptowane usprawiedliwienia ($lessonsLabel • $daysCount ${daysCount == 1 ? "dzień" : "dni"})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _isExpanded
                                      ? 'Ukryj wykaz zaakceptowanych wniosków'
                                      : 'Pokaż wykaz zaakceptowanych wniosków (auto-archiwizowane potwierdzenia)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
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
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                      Divider(
                        height: 1,
                        color: AppColors.success.withValues(alpha: 0.25),
                      ),
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
                            final reasons = dayRecords
                                .map((r) => r.justificationReason?.trim() ?? '')
                                .where((r) => r.isNotEmpty)
                                .toSet()
                                .toList();
                            final subjects = dayRecords
                                .map((r) => 'L${r.lessonNumber} ${r.subjectName}')
                                .join(', ');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.25),
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
                                          dayHeader,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.successSurface,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Zaakceptowano przez wychowawcę',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subjects,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  if (reasons.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Powód: ${reasons.join(" / ")}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
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
