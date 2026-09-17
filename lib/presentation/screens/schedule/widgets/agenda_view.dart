import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/lesson_slot.dart';
import '../../../providers/school_providers.dart';
import 'agenda_lesson_card.dart';

class AgendaView extends ConsumerWidget {
  final DateTime currentWeekMonday;
  final Map<int, List<LessonSlot>> weekMap;

  const AgendaView({
    super.key,
    required this.currentWeekMonday,
    required this.weekMap,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDayIndex = ref.watch(selectedScheduleDayProvider);
    final now = DateTime.now();

    final dayNames = ['Pn', 'Wt', 'Śr', 'Czw', 'Pt'];
    final fullDayNames = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek'];
    final dayDates = List.generate(5, (i) => currentWeekMonday.add(Duration(days: i)));

    final selectedDate = dayDates[selectedDayIndex.clamp(0, 4)];
    final selectedLessons = weekMap[selectedDayIndex + 1] ?? [];
    final isSelectedToday = _isSameDay(selectedDate, now);

    final selectedDateStr = DateFormat('d MMMM yyyy', 'pl_PL').format(selectedDate);
    final selectedFullDayName = fullDayNames[selectedDayIndex.clamp(0, 4)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Day Selector Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            children: List.generate(5, (i) {
              final date = dayDates[i];
              final isSelected = selectedDayIndex == i;
              final isToday = _isSameDay(date, now);
              final lessons = weekMap[i + 1] ?? [];

              final hasSubstitution = lessons.any((s) => s.status == LessonStatus.substituted);
              final hasCanceled = lessons.any((s) => s.status == LessonStatus.canceled);
              final hasExam = lessons.any(
                (s) => s.eventType != null || (s.topic != null && s.topic!.toLowerCase().contains('sprawdzian')),
              );

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedScheduleDayProvider.notifier).setDay(i);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isToday ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        border: isToday && !isSelected
                            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayNames[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white70 : AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Status dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasCanceled)
                                _buildDot(AppColors.error, isSelected),
                              if (hasSubstitution)
                                _buildDot(const Color(0xFFC2410C), isSelected),
                              if (hasExam)
                                _buildDot(isSelected ? Colors.white : AppColors.primary, isSelected),
                              if (!hasCanceled && !hasSubstitution && !hasExam)
                                _buildDot(isSelected ? Colors.white54 : const Color(0xFFCBD5E1), isSelected),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Day Summary Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  selectedFullDayName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  selectedDateStr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (isSelectedToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Dziś',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              '${selectedLessons.length} lekcji',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lessons List
        if (selectedLessons.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.event_available_outlined, size: 48, color: AppColors.outline.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text(
                  'Brak zaplanowanych zajęć',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                const Text(
                  'W tym dniu nie ma żadnych lekcji w planie.',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          Column(
            children: selectedLessons.map((slot) {
              return AgendaLessonCard(
                key: ValueKey('${selectedDate.weekday}_${slot.lessonNumber}'),
                slot: slot,
                date: selectedDate,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDot(Color color, bool isSelectedOnPrimary) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: isSelectedOnPrimary && color == AppColors.primary ? Colors.white : color,
        shape: BoxShape.circle,
      ),
    );
  }
}
