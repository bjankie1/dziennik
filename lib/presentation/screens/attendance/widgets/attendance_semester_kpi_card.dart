import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'dual_ring_attendance_gauge.dart';

class AttendanceSemesterKpiCard extends StatelessWidget {
  final double physicalPercentage;
  final double settledPercentage;
  final int presence;
  final int totalAbsences;
  final int lates;
  final int excused;
  final int unexcusedCount;
  final int totalLessons;

  const AttendanceSemesterKpiCard({
    super.key,
    required this.physicalPercentage,
    required this.settledPercentage,
    required this.presence,
    required this.totalAbsences,
    required this.lates,
    required this.excused,
    required this.unexcusedCount,
    required this.totalLessons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              // Dual Ring Gauge (Zewnętrzny: rozliczona, Wewnętrzny: obecność fizyczna)
              DualRingAttendanceGauge(
                physicalPercentage: physicalPercentage,
                settledPercentage: settledPercentage,
                unexcusedCount: unexcusedCount,
                size: 96,
              ),
              const SizedBox(width: 16),

              // Szczegóły stanu semestru i legenda ringów
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Stan semestru',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: unexcusedCount == 0
                                ? AppColors.successSurface
                                : AppColors.warningSurfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: unexcusedCount == 0
                                  ? AppColors.successBorder
                                  : AppColors.warningBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                unexcusedCount == 0
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded,
                                size: 12,
                                color: unexcusedCount == 0
                                    ? AppColors.successDark
                                    : AppColors.warningText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                unexcusedCount == 0
                                    ? 'Wszystko rozliczone'
                                    : '$unexcusedCount do usprawiedliwienia',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: unexcusedCount == 0
                                      ? AppColors.successDark
                                      : AppColors.warningText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate500,
                        ),
                        children: [
                          const TextSpan(text: 'Ustawowe min.: '),
                          const TextSpan(
                            text: '50%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                            ),
                          ),
                          const TextSpan(text: ' • Fizyczna obecność: '),
                          TextSpan(
                            text: '${physicalPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dwukolorowy pasek postępu (obecne + usprawiedliwione)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: [
                            if (presence > 0)
                              Expanded(
                                flex: presence,
                                child: Container(
                                  color: const Color(0xFF0284C7),
                                ),
                              ),
                            if (excused > 0)
                              Expanded(
                                flex: excused,
                                child: Container(color: AppColors.success),
                              ),
                            if (lates > 0)
                              Expanded(
                                flex: lates,
                                child: Container(color: AppColors.warningIcon),
                              ),
                            if (unexcusedCount > 0)
                              Expanded(
                                flex: unexcusedCount,
                                child: Container(color: AppColors.danger),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Legenda ringów / wskaźników
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _buildLegendItem(
                          AppColors.success,
                          'Ring zewn.: Rozliczona ${settledPercentage.toStringAsFixed(1)}%',
                        ),
                        _buildLegendItem(
                          const Color(0xFF0284C7),
                          'Ring wewn.: Obecność ${physicalPercentage.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Kolumny podsumowania (spójne i czytelne wskaźniki godzin)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  '$presence',
                  'Obecności',
                  const Color(0xFF0284C7),
                ),
                _buildStatColumn(
                  '$unexcusedCount',
                  'Do uspraw.',
                  unexcusedCount > 0 ? AppColors.danger : AppColors.slate500,
                  subtitle: 'z $totalAbsences opuszczonych',
                ),
                _buildStatColumn(
                  '$excused',
                  'Usprawiedliwione',
                  AppColors.success,
                ),
                _buildStatColumn('$lates', 'Spóźnienia', AppColors.warningIcon),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String number,
    String label,
    Color color, {
    String? subtitle,
  }) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.slate900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem(Color dotColor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.slate600,
          ),
        ),
      ],
    );
  }
}
