import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/polish_date_formatter.dart';
import '../../../../domain/models/attendance_record.dart';
import 'requested_attendance_details_sheet.dart';

class AttendanceDayGroupCard extends StatelessWidget {
  final List<AttendanceRecord> dayRecords;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelection;

  const AttendanceDayGroupCard({
    super.key,
    required this.dayRecords,
    required this.selectedIds,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final firstDate = dayRecords.first.date;
    final dateTitle = PolishDateFormatter.formatDayHeader(firstDate);
    final unexcusedInDay = dayRecords
        .where(
          (r) =>
              r.type == AttendanceType.absent &&
              r.justificationStatus == JustificationStatus.none,
        )
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Nagłówek dnia
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.slate50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.slate500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                  ],
                ),
                if (unexcusedInDay > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSurfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$unexcusedInDay DO DECYZJI',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                        letterSpacing: 0.4,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ROZLICZONE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.slate100),

          // Wiersze lekcji w danym dniu
          Column(
            children: dayRecords
                .map(
                  (rec) => AttendanceLessonRow(
                    record: rec,
                    isSelected: selectedIds.contains(rec.id),
                    onToggleSelection: () => onToggleSelection(rec.id),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class AttendanceLessonRow extends StatelessWidget {
  final AttendanceRecord record;
  final bool isSelected;
  final VoidCallback onToggleSelection;

  const AttendanceLessonRow({
    super.key,
    required this.record,
    required this.isSelected,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final isRequested =
        record.justificationStatus == JustificationStatus.requested;
    final isExempted = record.type == AttendanceType.exempted;
    final isUnexcused = record.type == AttendanceType.absent &&
        record.justificationStatus == JustificationStatus.none;

    final accentColor = isUnexcused
        ? AppColors.danger
        : (isRequested
            ? AppColors.warningIcon
            : (isExempted ? const Color(0xFF2563EB) : AppColors.success));

    return InkWell(
      onTap: isUnexcused
          ? onToggleSelection
          : (isRequested
              ? () => RequestedAttendanceDetailsSheet.show(context, record)
              : null),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.slate100)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kolorowy pasek po lewej krawędzi (wg makiety)
              Container(
                width: 4,
                color: accentColor,
              ),
              const SizedBox(width: 10),

              // Checkbox / Ikona stanu
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: isUnexcused
                    ? Checkbox(
                        value: isSelected,
                        onChanged: (_) => onToggleSelection(),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : (isRequested
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Icon(
                              Icons.hourglass_empty_rounded,
                              size: 20,
                              color: AppColors.warningIcon,
                            ),
                          )
                        : (isExempted
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: Color(0xFF2563EB),
                                ),
                              )
                            : const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 20,
                                  color: AppColors.success,
                                ),
                              ))),
              ),
              const SizedBox(width: 4),

              // Szczegóły lekcji
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 4.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lekcja ${record.lessonNumber}: ${record.subjectName}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          Text(
                            record.timeSlot,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${record.classroom ?? "Sala lekcyjna"} • ${record.teacherName ?? "Nauczyciel"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isUnexcused
                                  ? 'Nieobecność nieusprawiedliwiona'
                                  : (isRequested
                                      ? 'Oczekuje na wychowawcę${record.justificationReason != null && record.justificationReason!.isNotEmpty ? " (${record.justificationReason})" : ""}'
                                      : (isExempted
                                          ? 'Zwolnienie z zajęć'
                                          : 'Usprawiedliwiona • Zaakceptowano przez wychowawcę${record.justificationReason != null && record.justificationReason!.trim().isNotEmpty ? " (${record.justificationReason!.trim()})" : ""}')),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
