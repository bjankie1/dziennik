import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/sync_provider.dart';
import '../../../providers/school_providers.dart';

class WeekNavigatorBar extends ConsumerWidget {
  final DateTime currentWeekMonday;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onCurrentWeek;
  final int viewMode; // 0 = Siatka, 1 = Agenda
  final ValueChanged<int> onViewModeChanged;
  final String className;
  final String profileName;
  final String teacherName;

  const WeekNavigatorBar({
    super.key,
    required this.currentWeekMonday,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onCurrentWeek,
    required this.viewMode,
    required this.onViewModeChanged,
    this.className = 'Klasa',
    this.profileName = '',
    this.teacherName = 'Wychowawca',
  });

  bool _isThisCurrentWeek() {
    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    return currentWeekMonday.year == thisMonday.year &&
        currentWeekMonday.month == thisMonday.month &&
        currentWeekMonday.day == thisMonday.day;
  }

  String _formatWeekRange() {
    final friday = currentWeekMonday.add(const Duration(days: 4));
    final startDay = currentWeekMonday.day;
    final endDay = friday.day;
    final monthName = DateFormat('LLLL yyyy', 'pl_PL').format(friday);
    final capitalized = monthName.isNotEmpty ? '${monthName[0].toUpperCase()}${monthName.substring(1)}' : monthName;
    return '$startDay – $endDay $capitalized';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = _isThisCurrentWeek();
    final isCompact = MediaQuery.of(context).size.width < 1100;
    final isNarrow = MediaQuery.of(context).size.width < 500;
    final syncState = ref.watch(syncProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Class info & Tools
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Class & Homeroom info
              Flexible(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      className,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Text('•', style: TextStyle(color: AppColors.outlineVariant)),
                    Text(
                      profileName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (!isCompact) ...[
                      const Text('•', style: TextStyle(color: AppColors.outlineVariant)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Wychowawca: $teacherName',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Right: Action buttons (Drukuj, iCal)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Generowanie planu lekcji do pliku PDF...')),
                      );
                    },
                    icon: const Icon(Icons.print_outlined, size: 15),
                    label: Text(isCompact ? '' : 'Drukuj'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurface,
                      side: const BorderSide(color: AppColors.surfaceContainerHigh),
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: 8),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: syncState.isSyncing
                        ? null
                        : () async {
                            await ref.read(syncProvider.notifier).syncNow();
                            ref.invalidate(weekScheduleProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ref.read(syncProvider).statusMessage),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          },
                    icon: syncState.isSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.sync, size: 15),
                    label: Text(isCompact ? '' : (syncState.isSyncing ? 'Synchronizacja...' : 'Synchronizuj')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurface,
                      side: const BorderSide(color: AppColors.surfaceContainerHigh),
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: 8),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom Row: Week Navigator & Segmented View Mode
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              // Center: Week Navigator
              Container(
                width: isNarrow ? double.infinity : 430,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Row(
                  children: [
                    // Left button [<] pinned to left edge
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: onPreviousWeek,
                      tooltip: 'Poprzedni tydzień',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),

                    // Middle section with centered text & badge
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _formatWeekRange(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Aktualny',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Right button [>] pinned to right edge
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: onNextWeek,
                      tooltip: 'Następny tydzień',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: onCurrentWeek,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerLowest,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Dzisiaj',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Segmented View Mode Toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSegmentButton(
                      mode: 0,
                      label: 'Siatka',
                      icon: Icons.grid_view_rounded,
                      isSelected: viewMode == 0,
                    ),
                    _buildSegmentButton(
                      mode: 1,
                      label: 'Agenda',
                      icon: Icons.view_agenda_rounded,
                      isSelected: viewMode == 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required int mode,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onViewModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
