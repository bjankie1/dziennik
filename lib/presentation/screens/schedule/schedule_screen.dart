import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/school_providers.dart';
import 'widgets/week_navigator_bar.dart';
import 'widgets/weekly_summary_banner.dart';
import 'widgets/weekly_grid_view.dart';
import 'widgets/agenda_view.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  void _previousWeek(WidgetRef ref) {
    ref.read(selectedWeekMondayProvider.notifier).previousWeek();
  }

  void _nextWeek(WidgetRef ref) {
    ref.read(selectedWeekMondayProvider.notifier).nextWeek();
  }

  void _goToCurrentWeek(WidgetRef ref) {
    ref.read(selectedWeekMondayProvider.notifier).resetToCurrentWeek();
    final now = DateTime.now();
    ref
        .read(selectedScheduleDayProvider.notifier)
        .setDay((now.weekday - 1).clamp(0, 4));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWeekMonday = ref.watch(selectedWeekMondayProvider);
    final weekScheduleAsync = ref.watch(weekScheduleProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Automatically switch between full 5-day Grid (wide viewports >= 900px)
        // and daily Agenda (narrow/mobile viewports < 900px)
        final isWideGrid = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: isWideGrid ? AppColors.surface : Colors.white,
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(weekScheduleProvider);
            },
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isWideGrid ? 20 : 12,
                vertical: 10,
              ),
              children: [
                // 1. Compact 1-line Week Navigator Bar
                WeekNavigatorBar(
                  currentWeekMonday: currentWeekMonday,
                  onPreviousWeek: () => _previousWeek(ref),
                  onNextWeek: () => _nextWeek(ref),
                  onCurrentWeek: () => _goToCurrentWeek(ref),
                ),
                const SizedBox(height: 10),

                // 2. Main Schedule Area starts immediately at the top:
                // - Wide viewports (>= 900px): WeeklyGridView at the top + AgendaView below the grid
                // - Narrow viewports (< 900px): AgendaView immediately at the top
                weekScheduleAsync.when(
                  data: (weekMap) {
                    if (isWideGrid) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WeeklyGridView(
                            currentWeekMonday: currentWeekMonday,
                            weekMap: weekMap,
                            onDayHeaderTap: (dayIdx) {
                              ref
                                  .read(selectedScheduleDayProvider.notifier)
                                  .setDay(dayIdx);
                            },
                          ),
                          const SizedBox(height: 16),
                          AgendaView(
                            currentWeekMonday: currentWeekMonday,
                            weekMap: weekMap,
                          ),
                        ],
                      );
                    }
                    return AgendaView(
                      currentWeekMonday: currentWeekMonday,
                      weekMap: weekMap,
                    );
                  },
                  loading: () => Container(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
                  error: (err, _) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 36,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nie udało się pobrać planu lekcji: $err',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(weekScheduleProvider),
                          child: const Text('Spróbuj ponownie'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Weekly Summary Banner placed below the schedule so it doesn't push lessons down
                const WeeklySummaryBanner(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
