import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/school_providers.dart';

class WeightedAverageKpiCard extends ConsumerWidget {
  const WeightedAverageKpiCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(gradesDistributionStatsProvider);
    final term = ref.watch(gradesTermProvider);
    final termLabel = term == 1 ? 'S1' : (term == 2 ? 'S2' : 'ROCZNA');
    final student = ref.watch(studentProfileProvider).value;
    final className = student?.className ?? 'Klasa';

    final avgStr = stats.overallAverage > 0
        ? stats.overallAverage.toStringAsFixed(2)
        : '—';
    final delta = stats.lastGradeDelta;
    final isPositiveDelta = (delta ?? 0) >= 0;
    final lastGrade = stats.lastGrade;

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
            child: Container(color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Label & Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ŚREDNIA WAŻONA ($termLabel)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle: Big Average + Real Trend Pill (from last grade impact)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      avgStr,
                      style: const TextStyle(
                        fontSize: 46,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (delta != null) ...[
                      const SizedBox(width: 10),
                      Tooltip(
                        message: lastGrade != null
                            ? 'Zmiana średniej po ostatniej ocenie: ${lastGrade.rawValue} (waga ${lastGrade.weight}) z przedmiotu ${lastGrade.subjectName}'
                            : 'Zmiana średniej po ostatniej ocenie',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPositiveDelta
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositiveDelta
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                size: 16,
                                color: isPositiveDelta
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB91C1C),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${isPositiveDelta ? '+' : ''}${delta.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isPositiveDelta
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Wyliczona na podstawie ${stats.totalGrades} ocen cząstkowych (${stats.subjectsWithGradesCount} przedm.)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),

                // Footer: Real Latest Grade Context (Librus does not expose class rank)
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        lastGrade != null && lastGrade.numericValue < 2.0
                            ? Icons.warning_amber_rounded
                            : Icons.history_edu_rounded,
                        size: 16,
                        color: lastGrade != null && lastGrade.numericValue < 2.0
                            ? const Color(0xFFB91C1C)
                            : AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          lastGrade != null
                              ? 'Ostatnia ocena: ${lastGrade.rawValue} (waga ${lastGrade.weight}) • ${lastGrade.subjectName}'
                              : 'Klasa $className • Brak ocen w wybranym okresie',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: lastGrade != null && lastGrade.numericValue < 2.0
                                ? const Color(0xFFB91C1C)
                                : AppColors.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
