import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/school_task.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/tasks_provider.dart';
import '../../tasks/widgets/task_form_modal.dart';

/// Unified responsive Tasks Bento Card used on both Desktop and Mobile Dashboard (`REQ-TASK-02`, `REQ-ARCH-01`).
/// Subscribes directly to `urgentTasksProvider` and `totalActiveTasksCountProvider` so task toggles only rebuild this card.
class DashboardTasksCard extends ConsumerWidget {
  final bool isCompact;

  const DashboardTasksCard({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgentTasks = ref.watch(urgentTasksProvider);
    final totalActiveCount = ref.watch(totalActiveTasksCountProvider);
    final overdueCount = urgentTasks.where((t) => t.isOverdue).length;
    final user = ref.watch(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final familyId = user?.familyId ?? 'jankiewicz_family';
    final iconBoxSize = isCompact ? 32.0 : 36.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: overdueCount > 0
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.checklist_rtl_rounded,
                        size: isCompact ? 18 : 20,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: isCompact ? 8 : 10),
                    const Flexible(
                      child: Text(
                        'Zadania na dziś',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 7 : 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: overdueCount > 0
                            ? AppColors.error
                            : AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${urgentTasks.length}',
                        style: TextStyle(
                          fontSize: isCompact ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: overdueCount > 0
                              ? AppColors.onError
                              : AppColors.onPrimaryFixedVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton.filledTonal(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      tooltip: 'Nowe zadanie',
                      onPressed: () => TaskFormModal.show(context),
                      icon: const Icon(Icons.add),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => context.go('/zadania'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Zobacz wszystkie ($totalActiveCount) →',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 14),
          if (urgentTasks.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(
                vertical: isCompact ? 14 : 16,
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Wszystkie zadania na dziś wykonane! 🎉 Chwila oddechu albo zaplanuj kolejne kroki.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            )
          else
            Column(
              children: urgentTasks
                  .map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _UrgentTaskRow(
                        task: task,
                        familyId: familyId,
                        isStudent: isStudent,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _UrgentTaskRow extends ConsumerWidget {
  final SchoolTask task;
  final String familyId;
  final bool isStudent;

  const _UrgentTaskRow({
    required this.task,
    required this.familyId,
    required this.isStudent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverdue = task.isOverdue;
    final dueLabel = isOverdue
        ? 'Zaległe'
        : task.isDueToday
            ? 'Dzisiaj'
            : task.dueDate != null
                ? '${task.dueDate!.day.toString().padLeft(2, '0')}.${task.dueDate!.month.toString().padLeft(2, '0')}'
                : 'Bez terminu';

    final (roleBg, roleFg) = switch (task.assignedTo) {
      TaskAssignee.student => (AppColors.primaryFixed, AppColors.onPrimaryFixed),
      TaskAssignee.parent => (AppColors.tertiaryFixed, AppColors.onTertiaryFixed),
      TaskAssignee.shared => (
          AppColors.secondaryContainer,
          AppColors.onSecondaryFixedVariant
        ),
    };

    return Material(
      color: AppColors.surfaceContainerLow.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => TaskFormModal.show(context, existingTask: task),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: task.isCompleted,
                  activeColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (checked) {
                    ref.read(tasksRepositoryProvider).toggleTaskCompletion(
                          familyId,
                          task,
                          isCompleted: checked ?? true,
                          actorRole: isStudent ? 'student' : 'parent',
                          actorName: isStudent ? 'Oskar' : 'Tata',
                        );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: task.isCompleted
                            ? AppColors.outline
                            : AppColors.onSurface,
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.assignedTo.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: roleFg,
                            ),
                          ),
                        ),
                        if (task.subject != null && task.subject!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.subject!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? AppColors.errorContainer
                      : AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dueLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOverdue
                        ? AppColors.onErrorContainer
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
