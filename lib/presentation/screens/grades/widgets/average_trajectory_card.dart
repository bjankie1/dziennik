import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/school_providers.dart';
import 'trajectory_chart_painter.dart';

class AverageTrajectoryCard extends ConsumerWidget {
  const AverageTrajectoryCard({super.key});

  static const _shortMonths = [
    'Sty',
    'Lut',
    'Mar',
    'Kwi',
    'Maj',
    'Cze',
    'Lip',
    'Sie',
    'Wrz',
    'Paź',
    'Lis',
    'Gru',
  ];

  String _formatShortDate(DateTime dt) {
    final m = (dt.month >= 1 && dt.month <= 12) ? _shortMonths[dt.month - 1] : '';
    return '${dt.day.toString().padLeft(2, '0')} $m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProfileProvider);
    final stats = ref.watch(gradesDistributionStatsProvider);

    final studentName = studentAsync.value?.name.split(' ').first ?? 'Uczeń';
    final currentAvg = stats.overallAverage;
    final currentAvgStr = currentAvg > 0 ? currentAvg.toStringAsFixed(2) : '—';

    final rawTrajectory = stats.trajectory;
    final List<TrajectoryPoint> points = [];
    if (rawTrajectory.isEmpty) {
      points.add(TrajectoryPoint(
        label: 'Brak ocen',
        value: currentAvg > 0 ? currentAvg : 3.0,
        isLatest: true,
      ));
    } else if (rawTrajectory.length <= 5) {
      for (int i = 0; i < rawTrajectory.length; i++) {
        final item = rawTrajectory[i];
        final isLast = i == rawTrajectory.length - 1;
        points.add(TrajectoryPoint(
          label: '${_formatShortDate(item.date)} (${item.average.toStringAsFixed(2)})',
          value: item.average,
          isLatest: isLast,
        ));
      }
    } else {
      final int n = rawTrajectory.length;
      final indices = <int>{
        0,
        (n * 0.25).floor(),
        (n * 0.50).floor(),
        (n * 0.75).floor(),
        n - 1,
      }.toList()
        ..sort();
      for (int i = 0; i < indices.length; i++) {
        final idx = indices[i];
        final item = rawTrajectory[idx];
        final isLast = idx == n - 1;
        points.add(TrajectoryPoint(
          label: '${_formatShortDate(item.date)} (${item.average.toStringAsFixed(2)})',
          value: item.average,
          isLatest: isLast,
        ));
      }
    }

    double minVal = 6.0;
    double maxVal = 1.0;
    for (final p in points) {
      minVal = min(minVal, p.value);
      maxVal = max(maxVal, p.value);
    }
    final minY = (minVal - 0.4).clamp(1.0, 5.5);
    final maxY = (maxVal + 0.4).clamp(minY + 0.6, 6.0);
    const referenceThreshold = 4.75;

    final semDelta = stats.semesterDelta;
    final isPositiveSem = (semDelta ?? 0) >= 0;

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
                  // Scholarship threshold dashed legend
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 2,
                        color: AppColors.outlineVariant,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Próg wyróżnienia (4.75)',
                        style: TextStyle(
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
                classAverage: referenceThreshold,
                minY: minY,
                maxY: maxY,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  semDelta == null
                      ? Icons.timeline_rounded
                      : (isPositiveSem
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded),
                  size: 14,
                  color: semDelta == null
                      ? AppColors.onSurfaceVariant
                      : (isPositiveSem
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C)),
                ),
                const SizedBox(width: 6),
                Text(
                  semDelta != null
                      ? '${isPositiveSem ? '+' : ''}${semDelta.toStringAsFixed(2)} pkt od pierwszej oceny w semestrze (${rawTrajectory.first.average.toStringAsFixed(2)} → $currentAvgStr)'
                      : 'Zbyt mało ocen w semestrze, aby wyznaczyć trend',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: semDelta == null
                        ? AppColors.onSurfaceVariant
                        : (isPositiveSem
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB91C1C)),
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
