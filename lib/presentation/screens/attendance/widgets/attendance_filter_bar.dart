import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AttendanceFilterBar extends StatelessWidget {
  final int activeFilter;
  final int unexcusedCount;
  final int pendingCount;
  final bool allSelected;
  final ValueChanged<int> onFilterChanged;
  final VoidCallback onToggleSelectAll;
  final Widget? bannerSlot;

  const AttendanceFilterBar({
    super.key,
    required this.activeFilter,
    required this.unexcusedCount,
    required this.pendingCount,
    required this.allSelected,
    required this.onFilterChanged,
    required this.onToggleSelectAll,
    this.bannerSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pasek filtrów
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(0, 'Wszystkie'),
              _buildFilterChip(
                1,
                'Do usprawiedliwienia ($unexcusedCount)',
                isAlert: unexcusedCount > 0,
              ),
              _buildFilterChip(2, 'Usprawiedliwione'),
              _buildFilterChip(3, 'Oczekujące ($pendingCount)'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ?bannerSlot,

        // Nagłówek sekcji zgłoszeń
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, size: 18, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Zgłoszenia nieobecności',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
            if (unexcusedCount > 0)
              TextButton(
                onPressed: onToggleSelectAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  allSelected ? 'Odznacz wszystkie' : 'Zaznacz wszystkie',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildFilterChip(int index, String label, {bool isAlert = false}) {
    final isSelected = activeFilter == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => onFilterChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isAlert ? AppColors.dangerSurfaceAlt : AppColors.primary)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (isAlert ? AppColors.dangerBorder : Colors.transparent)
                  : AppColors.slate200,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAlert) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? (isAlert ? AppColors.danger : Colors.white)
                      : (isAlert ? AppColors.danger : AppColors.slate600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
