import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../core/theme/app_colors.dart";
import "../../domain/models/student_profile.dart";
import "../providers/sync_provider.dart";

class AppSidebar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;
  final int unexcusedCount;
  final int unreadCount;
  final StudentProfile? student;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onIndexSelected,
    this.unexcusedCount = 0,
    this.unreadCount = 0,
    this.student,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          right: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Brand & School Name
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "EduSync",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: -0.3,
                            ),
                      ),
                      Text(
                        student?.schoolName ?? "LO nr X im. S. Sempołowskiej",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 11,
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

          // Semester Selector Pill
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Semestr 1 / 2024-2025",
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                            fontSize: 12,
                          ),
                    ),
                  ),
                  const Icon(
                    Icons.expand_more,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  label: "Pulpit",
                  icon: Icons.grid_view_rounded,
                  isSelected: currentIndex == 0,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context: context,
                  index: 1,
                  label: "Plan Lekcji",
                  icon: Icons.schedule_rounded,
                  isSelected: currentIndex == 1,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context: context,
                  index: 2,
                  label: "Oceny i Średnie",
                  icon: Icons.verified_outlined,
                  isSelected: currentIndex == 2,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context: context,
                  index: 3,
                  label: "Frekwencja",
                  icon: Icons.fact_check_outlined,
                  isSelected: currentIndex == 3,
                  badgeCount: unexcusedCount,
                  badgeColor: AppColors.error,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context: context,
                  index: 4,
                  label: "Wiadomości i Ogłoszenia",
                  icon: Icons.chat_bubble_outline_rounded,
                  isSelected: currentIndex == 4,
                  badgeCount: unreadCount,
                  badgeColor: AppColors.primary,
                ),
              ],
            ),
          ),

          // Bottom Widget: Rada Rodziców & Sync Status
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.school,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Dziennik & Rada Rodziców",
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Aktualizacja: Dzisiaj, ${syncState.formattedLastSync}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
    int badgeCount = 0,
    Color badgeColor = AppColors.primary,
  }) {
    return InkWell(
      onTap: () => onIndexSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$badgeCount",
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryContainer : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
