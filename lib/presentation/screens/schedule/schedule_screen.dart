import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/school_providers.dart';
import 'widgets/week_navigator_bar.dart';
import 'widgets/weekly_summary_banner.dart';
import 'widgets/weekly_grid_view.dart';
import 'widgets/agenda_view.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int? _viewMode; // 0 = Siatka, 1 = Agenda (null until initialized from screen size)

  void _previousWeek() {
    ref.read(selectedWeekMondayProvider.notifier).previousWeek();
  }

  void _nextWeek() {
    ref.read(selectedWeekMondayProvider.notifier).nextWeek();
  }

  void _goToCurrentWeek() {
    ref.read(selectedWeekMondayProvider.notifier).resetToCurrentWeek();
    final now = DateTime.now();
    ref.read(selectedScheduleDayProvider.notifier).setDay((now.weekday - 1).clamp(0, 4));
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentProfileProvider);
    final currentWeekMonday = ref.watch(selectedWeekMondayProvider);
    final weekScheduleAsync = ref.watch(weekScheduleProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        // If view mode was not manually toggled by the user, default to Grid on desktop, Agenda on mobile
        final activeViewMode = _viewMode ?? (isDesktop ? 0 : 1);

        final student = studentAsync.value;
        final className = student?.className ?? 'Klasa 3B';
        final schoolName = student?.schoolName ?? 'LO nr X we Wrocławiu';

        return Scaffold(
          backgroundColor: isDesktop ? AppColors.surface : Colors.white,
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(weekScheduleProvider);
            },
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: 16,
              ),
              children: [
                // 1. Week Navigator Bar with Tools & View Toggle
                WeekNavigatorBar(
                  currentWeekMonday: currentWeekMonday,
                  onPreviousWeek: _previousWeek,
                  onNextWeek: _nextWeek,
                  onCurrentWeek: _goToCurrentWeek,
                  viewMode: activeViewMode,
                  onViewModeChanged: (mode) {
                    setState(() {
                      _viewMode = mode;
                    });
                  },
                  className: className,
                  profileName: schoolName,
                  teacherName: 'mgr K. Wiśniewski',
                ),
                const SizedBox(height: 14),

                // 2. Weekly Summary Banner (4 Alert Cards) - always available or above Grid
                const WeeklySummaryBanner(),
                const SizedBox(height: 14),

                // 3. Main Schedule Area (Grid or Agenda)
                weekScheduleAsync.when(
                  data: (weekMap) {
                    if (activeViewMode == 0) {
                      // Grid View
                      return WeeklyGridView(
                        currentWeekMonday: currentWeekMonday,
                        weekMap: weekMap,
                        onDayHeaderTap: (dayIdx) {
                          ref.read(selectedScheduleDayProvider.notifier).setDay(dayIdx);
                          setState(() {
                            _viewMode = 1; // Switch to Agenda view for this day
                          });
                        },
                      );
                    } else {
                      // Agenda View
                      return AgendaView(
                        currentWeekMonday: currentWeekMonday,
                        weekMap: weekMap,
                      );
                    }
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
                        const Icon(Icons.error_outline, size: 36, color: AppColors.error),
                        const SizedBox(height: 8),
                        Text(
                          'Nie udało się pobrać planu lekcji: $err',
                          style: const TextStyle(fontSize: 13, color: AppColors.error),
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
