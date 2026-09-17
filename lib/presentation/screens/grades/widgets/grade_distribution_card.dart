import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/school_providers.dart';

class GradeDistributionCard extends ConsumerWidget {
  const GradeDistributionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(gradesDistributionStatsProvider);
    final counts = stats.counts;
    final total = stats.totalGrades > 0 ? stats.totalGrades : 38;

    // Determine max count for scaling (ensure at least 1)
    int maxCount = 1;
    for (int i = 1; i <= 6; i++) {
      maxCount = max(maxCount, counts[i] ?? 0);
    }

    final double pct5 = total > 0 ? ((counts[5] ?? 0) / total * 100) : 47.4;
    final double pct6 = total > 0 ? ((counts[6] ?? 0) / total * 100) : 21.1;

    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 4px Top Accent Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 4,
            child: Container(color: AppColors.primaryContainer),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Title + Safety Badge (D-08) + Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'ROZKŁAD OCEN CZĄSTKOWYCH',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Safety Badge (D-08)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: stats.hasThreats
                                      ? const Color(0xFFFFDAD6)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      stats.hasThreats ? Icons.warning_amber_rounded : Icons.verified_rounded,
                                      size: 13,
                                      color: stats.hasThreats
                                          ? AppColors.error
                                          : const Color(0xFF15803D),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      stats.hasThreats
                                          ? '${stats.counts[1]} zagrożeń'
                                          : '0 zagrożeń • 100% pozytywnych',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: stats.hasThreats
                                            ? AppColors.error
                                            : const Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '$total',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'ocen wpisanych w semestrze',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bar Histogram (Scale 1..6)
                Container(
                  height: 80,
                  padding: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(6, (index) {
                      final gradeNum = index + 1;
                      final count = counts[gradeNum] ?? 0;
                      final ratio = maxCount > 0 ? (count / maxCount) : 0.0;
                      final barHeight = (ratio * 46).clamp(4.0, 46.0);

                      Color barColor;
                      Color countColor;
                      if (gradeNum == 1 || gradeNum == 2) {
                        barColor = count > 0 ? AppColors.error : AppColors.surfaceContainerHigh;
                        countColor = count > 0 ? AppColors.error : AppColors.outline;
                      } else if (gradeNum == 3) {
                        barColor = AppColors.tertiaryFixedDim;
                        countColor = AppColors.tertiary;
                      } else if (gradeNum == 4) {
                        barColor = AppColors.primaryFixedDim;
                        countColor = AppColors.primary;
                      } else if (gradeNum == 5) {
                        barColor = AppColors.primaryContainer;
                        countColor = AppColors.primary;
                      } else {
                        barColor = AppColors.secondary;
                        countColor = AppColors.secondary;
                      }

                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: countColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 32,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$gradeNum',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: gradeNum >= 5 ? FontWeight.w800 : FontWeight.w600,
                                color: gradeNum >= 5 ? AppColors.primary : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),

                // Legend Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Skala ocen MEN (1-6)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: [
                        _buildLegendItem(AppColors.primaryContainer, 'B. dobre (${pct5.toStringAsFixed(1)}%)'),
                        const SizedBox(width: 10),
                        _buildLegendItem(AppColors.secondary, 'Celujące (${pct6.toStringAsFixed(1)}%)'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
