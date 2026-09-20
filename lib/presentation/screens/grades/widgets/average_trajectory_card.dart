import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/school_providers.dart';
import 'trajectory_chart_painter.dart';

class AverageTrajectoryCard extends ConsumerWidget {
  const AverageTrajectoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProfileProvider);
    final stats = ref.watch(gradesDistributionStatsProvider);

    final studentName = studentAsync.value?.name.split(' ').first ?? 'Maja';
    final className = studentAsync.value?.className ?? '3B';
    final currentAvg = stats.overallAverage > 0 ? stats.overallAverage : 4.82;
    final currentAvgStr = currentAvg.toStringAsFixed(2);

    final points = [
      const TrajectoryPoint(label: '01 Wrz (4.60)', value: 4.60),
      const TrajectoryPoint(label: '15 Wrz (4.68)', value: 4.68),
      const TrajectoryPoint(label: '01 Paź (4.74)', value: 4.74),
      const TrajectoryPoint(label: '15 Paź (4.78)', value: 4.78),
      TrajectoryPoint(
        label: 'Dzisiaj ($currentAvgStr)',
        value: currentAvg,
        isLatest: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Legend Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Trajektoria średniej ocen w semestrze',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Student curve legend
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$studentName ($currentAvgStr)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Class average dashed legend
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 2,
                        color: AppColors.outlineVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Średnia klasy $className (4.18)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Spline Chart Canvas (CustomPainter)
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: TrajectoryChartPainter(
                points: points,
                classAverage: 4.18,
                minY: 3.8,
                maxY: 5.1,
                primaryColor: AppColors.primaryContainer,
                classAvgColor: AppColors.outlineVariant,
                gridColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // X-Axis checkpoint labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: points.map((pt) {
              return Text(
                pt.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: pt.isLatest ? FontWeight.w700 : FontWeight.w500,
                  color: pt.isLatest ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Footer summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 14,
                  color: Color(0xFF15803D),
                ),
                SizedBox(width: 6),
                Text(
                  '+0.22 pkt od początku semestru • Stały trend wzrostowy',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
