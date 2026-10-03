import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/message_thread.dart';
import '../../../../domain/models/school_task.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/tasks_provider.dart';
import '../../tasks/widgets/task_form_modal.dart';

MessageTaskSuggestion _buildSuggestionForThread(MessageThread thread) {
  final fullText = thread.body.trim().isNotEmpty
      ? thread.body
      : (thread.messages.isNotEmpty ? thread.messages.first.body : thread.preview);
  return SchoolTask.suggestFromMessage(
    messageId: thread.id,
    subject: thread.subject,
    body: fullText,
    senderName: thread.senderName,
  );
}

void _openTaskModalFromMessage(
  BuildContext context,
  MessageTaskSuggestion suggestion, {
  SchoolTask? existingTask,
}) {
  if (existingTask != null) {
    TaskFormModal.show(context, existingTask: existingTask);
    return;
  }
  TaskFormModal.show(
    context,
    initialTitle: suggestion.suggestedTitle,
    initialDescription: suggestion.suggestedDescription,
    initialSubject: suggestion.suggestedSubject,
    initialAssignedTo: suggestion.suggestedAssignee,
    initialPriority: suggestion.suggestedPriority,
    initialDueDate: suggestion.suggestedDueDate,
    initialSource: TaskSource.message,
    initialSourceId: suggestion.sourceId,
    initialMetadata: suggestion.metadata,
  );
}

class MessageAppBarTaskAction extends ConsumerWidget {
  final MessageThread thread;

  const MessageAppBarTaskAction({
    super.key,
    required this.thread,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existingTask = ref.watch(
      tasksStreamProvider.select(
        (asyncVal) => asyncVal.value?.where((t) => t.matchesMessage(thread.id)).firstOrNull,
      ),
    );
    final suggestion = _buildSuggestionForThread(thread);

    return IconButton(
      icon: Icon(
        existingTask != null ? Icons.task_alt_rounded : Icons.add_task_rounded,
        color: existingTask != null ? AppColors.secondary : AppColors.primary,
        size: 22,
      ),
      tooltip: existingTask != null
          ? 'Pokaż powiązane zadanie'
          : 'Utwórz zadanie z tej wiadomości',
      onPressed: () => _openTaskModalFromMessage(
        context,
        suggestion,
        existingTask: existingTask,
      ),
    );
  }
}

class MessageTaskBanner extends ConsumerWidget {
  final MessageThread thread;

  const MessageTaskBanner({
    super.key,
    required this.thread,
  });

  Future<void> _quickAddTaskFromMessage(
    BuildContext context,
    WidgetRef ref,
    MessageTaskSuggestion suggestion,
  ) async {
    final user = ref.read(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final familyId = user?.familyId ?? 'jankiewicz_family';
    final actorRole = isStudent ? 'student' : 'parent';
    final actorName = isStudent
        ? 'Oskar'
        : ((user?.displayName.trim().isNotEmpty ?? false)
            ? user!.displayName.trim()
            : 'Tata');

    try {
      final createdTask = await ref.read(tasksRepositoryProvider).addTask(
            familyId: familyId,
            title: suggestion.suggestedTitle,
            description: suggestion.suggestedDescription,
            dueDate: suggestion.suggestedDueDate,
            priority: suggestion.suggestedPriority,
            assignedTo: suggestion.suggestedAssignee,
            subject: suggestion.suggestedSubject,
            createdByRole: actorRole,
            createdByName: actorName,
            source: TaskSource.message,
            sourceId: suggestion.sourceId,
            metadata: suggestion.metadata,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dodano zadanie z wiadomości: „${createdTask.title}”'),
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się dodać zadania: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existingTask = ref.watch(
      tasksStreamProvider.select(
        (asyncVal) => asyncVal.value?.where((t) => t.matchesMessage(thread.id)).firstOrNull,
      ),
    );
    final suggestion = _buildSuggestionForThread(thread);

    if (existingTask != null) {
      final isDone = existingTask.isCompleted;
      final user = ref.read(appUserProvider);
      final isStudent = user?.isStudent ?? false;
      final familyId = user?.familyId ?? 'jankiewicz_family';

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: isDone,
                    activeColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onChanged: (checked) {
                      ref.read(tasksRepositoryProvider).toggleTaskCompletion(
                            familyId,
                            existingTask,
                            isCompleted: checked ?? !isDone,
                            actorRole: isStudent ? 'student' : 'parent',
                            actorName: isStudent ? 'Oskar' : 'Tata',
                          );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDone ? Icons.check_circle_rounded : Icons.link_rounded,
                            size: 14,
                            color: AppColors.onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDone
                                ? 'POWIĄZANE ZADANIE (WYKONANE)'
                                : 'POWIĄZANE ZADANIE Z WIADOMOŚCI',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSecondaryContainer,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        existingTask.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSecondaryContainer,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${existingTask.assignedTo.label} • Priorytet: ${existingTask.priority.label}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSecondaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () =>
                      TaskFormModal.show(context, existingTask: existingTask),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text(
                    'Szczegóły / Edytuj zadanie',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/zadania'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: const Text(
                    'Pokaż na liście zadań →',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.onSecondaryContainer,
                    side: BorderSide(
                      color: AppColors.onSecondaryContainer.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final isSmart = suggestion.isHeuristicMatch;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSmart
            ? AppColors.primaryFixed.withValues(alpha: 0.45)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSmart
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.surfaceContainerHigh,
          width: isSmart ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isSmart
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSmart ? Icons.auto_awesome_rounded : Icons.add_task_rounded,
                  size: 18,
                  color: isSmart ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.categoryLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSmart ? AppColors.primary : AppColors.onSurfaceVariant,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      suggestion.suggestedTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sugerowane: ${suggestion.suggestedAssignee.label} • Priorytet: ${suggestion.suggestedPriority.label}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilledButton.icon(
                onPressed: () => _quickAddTaskFromMessage(context, ref, suggestion),
                icon: const Icon(Icons.add_task_rounded, size: 16),
                label: const Text(
                  '+ Dodaj zadanie (1-klik)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openTaskModalFromMessage(context, suggestion),
                icon: const Icon(Icons.tune_rounded, size: 15),
                label: const Text(
                  'Dostosuj przed dodaniem...',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
