import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/school_task.dart';
import '../../providers/auth_providers.dart';
import '../../providers/tasks_provider.dart';
import '../../screens/tasks/widgets/task_form_modal.dart';

/// Unified source-linked task widget (`REQ-TASK-03`, `REQ-ARCH-02`).
/// Renders either the linked task status card (`✓ Powiązane zadanie (Oskar)` + completion checkbox + `Pokaż zadanie`)
/// or the `+ Zadanie dla Oskara` 1-click / modal creation button.
class LinkedTaskActionBar extends ConsumerWidget {
  final String sourceId;
  final TaskSource source;
  final String initialTitle;
  final String initialDescription;
  final String? initialSubject;
  final TaskAssignee initialAssignedTo;
  final TaskPriority initialPriority;
  final DateTime initialDueDate;
  final Map<String, dynamic>? metadata;
  final String createButtonLabel;
  final String linkedHeaderLabel;
  final Color createButtonBgColor;
  final Color createButtonFgColor;
  final bool Function(SchoolTask task)? customMatcher;
  final VoidCallback? onBeforeNavigateToTasks;
  final bool instantOneClickCreate;

  const LinkedTaskActionBar({
    super.key,
    required this.sourceId,
    required this.initialTitle,
    required this.initialDescription,
    required this.initialDueDate,
    this.source = TaskSource.exam,
    this.initialSubject,
    this.initialAssignedTo = TaskAssignee.student,
    this.initialPriority = TaskPriority.high,
    this.metadata,
    this.createButtonLabel = '+ Zadanie dla Oskara: Naucz się',
    this.linkedHeaderLabel = '✓ Powiązane zadanie (Oskar)',
    this.createButtonBgColor = const Color(0xFF92400E),
    this.createButtonFgColor = Colors.white,
    this.customMatcher,
    this.onBeforeNavigateToTasks,
    this.instantOneClickCreate = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksStreamProvider).value ?? const <SchoolTask>[];
    final user = ref.watch(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final familyId = user?.familyId ?? 'jankiewicz_family';
    final actorRole = isStudent ? 'student' : 'parent';
    final actorName = isStudent
        ? 'Oskar'
        : ((user?.displayName.trim().isNotEmpty ?? false)
            ? user!.displayName.trim()
            : 'Tata');

    final existingTask = tasks.cast<SchoolTask?>().firstWhere(
          (t) =>
              t != null &&
              (t.sourceId == sourceId ||
                  (customMatcher != null && customMatcher!(t))),
          orElse: () => null,
        );

    if (existingTask != null) {
      final isDone = existingTask.isCompleted;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDone
              ? AppColors.secondaryContainer.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone
                ? AppColors.secondary.withValues(alpha: 0.4)
                : createButtonBgColor.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => ref.read(tasksRepositoryProvider).toggleTaskCompletion(
                        familyId,
                        existingTask,
                        isCompleted: !isDone,
                        actorRole: actorRole,
                        actorName: actorName,
                      ),
                  borderRadius: BorderRadius.circular(6),
                  child: Icon(
                    isDone ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                    size: 18,
                    color: isDone ? AppColors.secondary : createButtonBgColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDone ? '✓ Zadanie wykonane' : linkedHeaderLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isDone
                              ? AppColors.onSecondaryContainer
                              : createButtonBgColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        existingTask.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      onBeforeNavigateToTasks?.call();
                      context.go('/zadania');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Pokaż zadanie w module Zadania',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => TaskFormModal.show(context, existingTask: existingTask),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () async {
          if (instantOneClickCreate) {
            final createdTask = await ref.read(tasksRepositoryProvider).addTask(
                  familyId: familyId,
                  title: initialTitle,
                  description: initialDescription,
                  dueDate: initialDueDate,
                  priority: initialPriority,
                  assignedTo: initialAssignedTo,
                  subject: initialSubject,
                  createdByRole: actorRole,
                  createdByName: actorName,
                  source: source,
                  sourceId: sourceId,
                  metadata: metadata,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dodano zadanie: ${createdTask.title}'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Edytuj',
                    onPressed: () {
                      TaskFormModal.show(context, existingTask: createdTask);
                    },
                  ),
                ),
              );
            }
          } else {
            TaskFormModal.show(
              context,
              initialTitle: initialTitle,
              initialDescription: initialDescription,
              initialSubject: initialSubject,
              initialAssignedTo: initialAssignedTo,
              initialPriority: initialPriority,
              initialDueDate: initialDueDate,
              initialSource: source,
              initialSourceId: sourceId,
              initialMetadata: metadata,
            );
          }
        },
        icon: const Icon(Icons.add_task_rounded, size: 16),
        label: Text(
          createButtonLabel,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: createButtonBgColor,
          foregroundColor: createButtonFgColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
