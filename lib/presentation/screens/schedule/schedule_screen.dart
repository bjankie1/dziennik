import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/lesson_slot.dart';
import '../../providers/school_providers.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late int _selectedDayIndex; // 0=Pn, 1=Wt, 2=Śr, 3=Czw, 4=Pt
  int _viewMode = 0; // 0 = Agenda, 1 = Tydzień
  late DateTime _currentWeekMonday;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon, ..., 7=Sun
    _selectedDayIndex = (weekday - 1).clamp(0, 4);
    _currentWeekMonday = now.subtract(Duration(days: weekday - 1));
  }

  List<Map<String, dynamic>> _buildWeekDays() {
    final dayNames = ['Pn', 'Wt', 'Śr', 'Czw', 'Pt'];
    return List.generate(5, (i) {
      final d = _currentWeekMonday.add(Duration(days: i));
      return {
        'day': dayNames[i],
        'date': '${d.day}',
        'dateTime': d,
        'dots': <String>[],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(dayScheduleProvider(_selectedDayIndex + 1));
    final weekDays = _buildWeekDays();
    final monthYearTitle = DateFormat('LLLL yyyy', 'pl_PL').format(_currentWeekMonday);
    final capitalizedMonth = monthYearTitle.isNotEmpty
        ? '${monthYearTitle[0].toUpperCase()}${monthYearTitle.substring(1)}'
        : monthYearTitle;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Segmented View Mode Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildViewModeButton(0, Icons.view_agenda, 'Plan dnia (Agenda)'),
                ),
                Expanded(
                  child: _buildViewModeButton(1, Icons.calendar_view_week, 'Tydzień (Siatka)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Horizontal Week Strip with Anomaly Dots
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          capitalizedMonth,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: Text(
                              'Semestr 1',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimaryFixedVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _currentWeekMonday = _currentWeekMonday.subtract(const Duration(days: 7));
                            });
                          },
                          icon: const Icon(Icons.chevron_left, size: 20),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _currentWeekMonday = _currentWeekMonday.add(const Duration(days: 7));
                            });
                          },
                          icon: const Icon(Icons.chevron_right, size: 20),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Days Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(weekDays.length, (idx) {
                    final item = weekDays[idx];
                    final isSelected = _selectedDayIndex == idx;
                    final dots = item['dots'] as List<String>;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDayIndex = idx),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                item['day'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.onPrimaryContainer
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['date'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: dots.map((dot) {
                                  Color dotColor = AppColors.surfaceContainerHighest;
                                  if (dot == 'canceled') dotColor = AppColors.error;
                                  if (dot == 'substitution') dotColor = AppColors.tertiaryContainer;
                                  if (dot == 'exam') dotColor = AppColors.primaryContainer;
                                  return Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),

                // Legend
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LegendItem(color: AppColors.error, label: 'Odwołane'),
                      _LegendItem(color: AppColors.tertiaryContainer, label: 'Zastępstwo'),
                      _LegendItem(color: AppColors.primaryContainer, label: 'Sprawdzian'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Live Pulse Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Aktualnie: Język Polski w sali 204 (mgr E. Bąk)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Plan został zsynchronizowany z kalendarzem.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync, size: 14),
                      SizedBox(width: 4),
                      Text('iCal', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Lessons Timeline
          scheduleAsync.when(
            data: (lessons) {
              if (lessons.isEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceContainerHigh),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.event_available, size: 44, color: AppColors.outline.withValues(alpha: 0.6)),
                      const SizedBox(height: 10),
                      const Text(
                        'Brak lekcji w tym dniu',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Wybierz inny dzień tygodnia z paska powyżej.',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: lessons.map((slot) => _buildScheduleCard(slot)).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Błąd: $err', style: const TextStyle(color: AppColors.error))),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(int mode, IconData icon, String title) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(LessonSlot slot) {
    Color indicatorColor = AppColors.surfaceContainerHigh;
    if (slot.status == LessonStatus.canceled) indicatorColor = AppColors.error;
    if (slot.status == LessonStatus.substituted) indicatorColor = AppColors.tertiaryContainer;
    if (slot.status == LessonStatus.inProgress) indicatorColor = AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: slot.status == LessonStatus.inProgress
              ? AppColors.primary
              : AppColors.surfaceContainerHigh,
          width: slot.status == LessonStatus.inProgress ? 1.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: indicatorColor),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: SizedBox(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.startTime,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: slot.status == LessonStatus.canceled
                            ? AppColors.outline
                            : (slot.status == LessonStatus.inProgress
                                ? AppColors.primary
                                : AppColors.onSurface),
                        decoration: slot.status == LessonStatus.canceled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      slot.endTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                        decoration: slot.status == LessonStatus.canceled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          slot.subjectName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            decoration: slot.status == LessonStatus.canceled
                                ? TextDecoration.lineThrough
                                : null,
                            color: slot.status == LessonStatus.canceled
                                ? AppColors.outline
                                : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (slot.status == LessonStatus.canceled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ODWOŁANA',
                              style: TextStyle(
                                color: AppColors.onErrorContainer,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (slot.status == LessonStatus.substituted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.tertiaryFixed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ZASTĘPSTWO',
                              style: TextStyle(
                                color: AppColors.onTertiaryFixed,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (slot.status == LessonStatus.inProgress)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TERAZ TRWA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${slot.room} • ${slot.substituteTeacher ?? slot.teacher}',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    if (slot.statusNote != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        slot.statusNote!,
                        style: TextStyle(
                          fontSize: 11,
                          color: slot.status == LessonStatus.canceled
                              ? AppColors.error
                              : AppColors.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
