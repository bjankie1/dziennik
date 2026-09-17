import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/school_providers.dart';

class WeeklySummaryBanner extends ConsumerWidget {
  const WeeklySummaryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(weeklyScheduleStatsProvider);
    final activeFilter = ref.watch(weekScheduleFilterProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      icon: Icons.timelapse_rounded,
                      iconBg: AppColors.primary.withValues(alpha: 0.1),
                      iconColor: AppColors.primary,
                      title: '${stats.totalHours} godz.',
                      subtitle: 'Planowy tydzień',
                      isSelected: false,
                      onTap: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCard(
                      icon: Icons.swap_horiz_rounded,
                      iconBg: const Color(0xFFFFEDD5),
                      iconColor: const Color(0xFFC2410C),
                      title: '${stats.substitutionsCount} Zastępstwa',
                      subtitle: 'Zmiany sal / n-li',
                      isSelected: activeFilter == WeekScheduleFilter.substitutions,
                      onTap: () {
                        ref.read(weekScheduleFilterProvider.notifier).toggleFilter(WeekScheduleFilter.substitutions);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      icon: Icons.fact_check_rounded,
                      iconBg: AppColors.primaryFixed,
                      iconColor: AppColors.primary,
                      title: '${stats.examsCount} Sprawdziany',
                      subtitle: 'Terminarz tygodnia',
                      isSelected: activeFilter == WeekScheduleFilter.exams,
                      onTap: () {
                        ref.read(weekScheduleFilterProvider.notifier).toggleFilter(WeekScheduleFilter.exams);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCard(
                      icon: Icons.event_busy_rounded,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      title: '${stats.canceledCount} Odwołana',
                      subtitle: 'Późniejszy start',
                      isSelected: activeFilter == WeekScheduleFilter.canceled,
                      onTap: () {
                        ref.read(weekScheduleFilterProvider.notifier).toggleFilter(WeekScheduleFilter.canceled);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceContainerHigh),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildCard(
                  icon: Icons.timelapse_rounded,
                  iconBg: AppColors.primary.withValues(alpha: 0.1),
                  iconColor: AppColors.primary,
                  title: '${stats.totalHours} godz.',
                  subtitle: 'Planowy tydzień lekcyjny',
                  isSelected: false,
                  onTap: null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCard(
                  icon: Icons.swap_horiz_rounded,
                  iconBg: const Color(0xFFFFEDD5),
                  iconColor: const Color(0xFFC2410C),
                  title: '${stats.substitutionsCount} Zastępstwa',
                  subtitle: 'Wt: Geografia, Czw: Matematyka',
                  isSelected: activeFilter == WeekScheduleFilter.substitutions,
                  onTap: () {
                    ref.read(weekScheduleFilterProvider.notifier).toggleFilter(WeekScheduleFilter.substitutions);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCard(
                  icon: Icons.fact_check_rounded,
                  iconBg: AppColors.primaryFixed,
                  iconColor: AppColors.primary,
                  title: '${stats.examsCount} Sprawdziany',
                  subtitle: 'Czw: Chemia, Pt: J. Polski',
                  isSelected: activeFilter == WeekScheduleFilter.exams,
                  onTap: () {
                    ref.read(weekScheduleFilterProvider.notifier).toggleFilter(WeekScheduleFilter.exams);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCard(
                  icon: Icons.event_busy_rounded,
                  iconBg: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFDC2626),
                  title: '${stats.canceledCount} Lekcja odwołana',
                  subtitle: 'Czw: 08:00 Fizyka (start 08:50)',
                  isSelected: activeFilter == WeekScheduleFilter.canceled,
                  onTap: () {
                    ref.read(weekScheduleFilterProvider.notifier).toggleFilter(WeekScheduleFilter.canceled);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryFixed.withValues(alpha: 0.35)
                : AppColors.surfaceContainerLow.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
