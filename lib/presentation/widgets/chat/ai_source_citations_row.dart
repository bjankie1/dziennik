import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/calendar_export_service.dart';
import '../../../domain/models/ai_chat_message.dart';
import '../../../domain/models/school_task.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/auth_providers.dart';
import '../../providers/tasks_provider.dart';

/// Renders clickable source citation pills (`📩 Wiadomość`, `📅 Plan lekcji`, `🎓 Oceny`, `📋 Frekwencja`)
/// and contextual quick actions (`+ Kalendarz Google`, `+ Dodaj zadanie`) below an AI reply bubble (`D-06`).
class AiSourceCitationsRow extends ConsumerWidget {
  final AiChatMessage message;
  final bool closeBottomSheetOnNavigate;

  const AiSourceCitationsRow({
    super.key,
    required this.message,
    this.closeBottomSheetOnNavigate = false,
  });

  IconData _iconForSourceType(String type) {
    switch (type) {
      case 'message':
      case 'announcement':
        return Icons.mail_outline_rounded;
      case 'timetable':
      case 'exam':
        return Icons.calendar_today_rounded;
      case 'grade':
        return Icons.school_outlined;
      case 'attendance':
        return Icons.rule_rounded;
      case 'task':
        return Icons.task_alt_rounded;
      default:
        return Icons.open_in_new_rounded;
    }
  }

  void _navigateToSource(
    BuildContext context,
    WidgetRef ref,
    AiSourceCitation citation,
  ) {
    if (closeBottomSheetOnNavigate && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    ref.read(isFloatingChatOpenProvider.notifier).close();
    context.go(citation.normalizedRoute);
  }

  Future<void> _handleAddSuggestedTask(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    DateTime? dueDate,
    String? category,
  }) async {
    final user = ref.read(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final familyId = user?.familyId ?? 'jankiewicz_family';
    final tasksRepo = ref.read(tasksRepositoryProvider);

    await tasksRepo.addTask(
      familyId: familyId,
      title: title,
      dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
      priority: TaskPriority.high,
      assignedTo: isStudent ? TaskAssignee.student : TaskAssignee.shared,
      subject: switch (category) {
        'exam' => 'Sprawdzian',
        'trip' => 'Wycieczka',
        'homework' => 'Praca domowa',
        _ => 'Asystent AI',
      },
      createdByRole: isStudent ? 'student' : 'parent',
      createdByName: isStudent ? 'Oskar (AI)' : 'Tata (AI)',
      source: TaskSource.manual,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dodano zadanie do listy To-Do: „$title”'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSources = message.sources.isNotEmpty;
    final hasEvent = message.suggestedEvent != null;
    final hasTask = message.suggestedTask != null;

    if (!hasSources && !hasEvent && !hasTask) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSources)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: message.sources.map((citation) {
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _navigateToSource(context, ref, citation),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC7D7FE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconForSourceType(citation.type),
                          size: 13,
                          color: const Color(0xFF0052CC),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            citation.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0052CC),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_outward_rounded,
                          size: 11,
                          color: Color(0xFF0052CC),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          if (hasEvent || hasTask) ...[
            if (hasSources) const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (hasEvent)
                  OutlinedButton.icon(
                    onPressed: () {
                      CalendarExportService.openGoogleCalendar(
                        context,
                        message.suggestedEvent!.toCalendarExamEvent(),
                      );
                    },
                    icon: const Icon(Icons.event_available_rounded, size: 15),
                    label: const Text('+ Kalendarz Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      backgroundColor: const Color(0xFFF5F3FF),
                      side: const BorderSide(color: Color(0xFFDDD6FE)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                if (hasTask)
                  OutlinedButton.icon(
                    onPressed: () => _handleAddSuggestedTask(
                      context,
                      ref,
                      title: message.suggestedTask!.title,
                      dueDate: message.suggestedTask!.parsedDueDate,
                      category: message.suggestedTask!.category,
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 15),
                    label: const Text('+ Dodaj zadanie'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      backgroundColor: const Color(0xFFF0FDFA),
                      side: const BorderSide(color: Color(0xFF99F6E4)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                else if (hasEvent)
                  OutlinedButton.icon(
                    onPressed: () => _handleAddSuggestedTask(
                      context,
                      ref,
                      title: message.suggestedEvent!.title,
                      dueDate: message.suggestedEvent!.parsedDate,
                      category: 'other',
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 15),
                    label: const Text('+ Dodaj zadanie'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      backgroundColor: const Color(0xFFF0FDFA),
                      side: const BorderSide(color: Color(0xFF99F6E4)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
