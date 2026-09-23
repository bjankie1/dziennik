import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/message_thread.dart';
import '../../../domain/models/school_task.dart';
import '../../providers/auth_providers.dart';
import '../../providers/school_providers.dart';
import '../../providers/tasks_provider.dart';
import '../tasks/widgets/task_form_modal.dart';
import 'package:go_router/go_router.dart';

class MessageThreadScreen extends ConsumerStatefulWidget {
  final MessageThread thread;

  const MessageThreadScreen({
    super.key,
    required this.thread,
  });

  @override
  ConsumerState<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends ConsumerState<MessageThreadScreen> {
  late MessageThread _currentThread;
  final Set<String> _expandedMessageIds = {};
  bool _isReplying = false;
  bool _isSending = false;
  bool _isLoadingBody = false;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentThread = widget.thread;
    // By default, the latest message is expanded
    if (_currentThread.messages.isNotEmpty) {
      _expandedMessageIds.add(_currentThread.messages.last.id);
    }
    if (_currentThread.isUnread) {
      _markAsReadOnOpen();
    }
    _fetchBodyIfNeeded();
  }

  Future<void> _markAsReadOnOpen() async {
    try {
      await ref.read(schoolRepositoryProvider).markMessageAsRead(_currentThread.id, isRead: true);
      if (mounted) {
        setState(() {
          _currentThread = _currentThread.copyWith(isUnread: false);
        });
        ref.invalidate(messagesProvider);
      }
    } catch (_) {}
  }

  Future<void> _toggleReadStatus() async {
    final newIsUnread = !_currentThread.isUnread;
    setState(() {
      _currentThread = _currentThread.copyWith(isUnread: newIsUnread);
    });
    try {
      await ref.read(schoolRepositoryProvider).markMessageAsRead(_currentThread.id, isRead: !newIsUnread);
      ref.invalidate(messagesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newIsUnread ? 'Oznaczono jako nieprzeczytana' : 'Oznaczono jako przeczytana'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _fetchBodyIfNeeded({bool force = false}) async {
    final firstMsg = _currentThread.messages.isNotEmpty ? _currentThread.messages.first : null;
    final isBodyMissingOrSameAsSubject = firstMsg == null ||
        firstMsg.body.trim().isEmpty ||
        firstMsg.body.trim() == _currentThread.subject.trim();

    if (force || isBodyMissingOrSameAsSubject) {
      if (mounted) setState(() => _isLoadingBody = true);
      try {
        final fullBody = await ref.read(schoolRepositoryProvider).getMessageBody(_currentThread.id);
        if (fullBody != null && fullBody.trim().isNotEmpty && mounted) {
          setState(() {
            final updatedMessages = _currentThread.messages.map((m) {
              if (m == _currentThread.messages.first) {
                return MessageItem(
                  id: m.id,
                  senderName: m.senderName,
                  senderRole: m.senderRole,
                  senderInitials: m.senderInitials,
                  timestamp: m.timestamp,
                  body: fullBody,
                  attachments: m.attachments,
                  isFromMe: m.isFromMe,
                );
              }
              return m;
            }).toList();

            _currentThread = _currentThread.copyWith(
              body: fullBody,
              preview: fullBody.length > 90 ? '${fullBody.substring(0, 90)}...' : fullBody,
              messages: updatedMessages,
            );
            _isLoadingBody = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('Error loading full message body: $e');
      }
      if (mounted) {
        setState(() => _isLoadingBody = false);
      }
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _toggleMessageExpansion(String messageId) {
    setState(() {
      if (_expandedMessageIds.contains(messageId)) {
        _expandedMessageIds.remove(messageId);
      } else {
        _expandedMessageIds.add(messageId);
      }
    });
  }

  Future<void> _handleSendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final repo = ref.read(schoolRepositoryProvider);
      final profile = await repo.getStudentProfile();

      await repo.sendMessage(
        recipientNames: [_currentThread.senderName],
        subject: _currentThread.subject.startsWith('Re:')
            ? _currentThread.subject
            : 'Re: ${_currentThread.subject}',
        body: text,
        replyToId: _currentThread.id,
      );

      final now = DateTime.now();
      final newMsg = MessageItem(
        id: 'reply_${now.millisecondsSinceEpoch}',
        senderName: profile.name,
        senderRole: 'Uczeń',
        senderInitials: profile.name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join(),
        timestamp: now,
        body: text,
        isFromMe: true,
      );

      setState(() {
        _currentThread = _currentThread.copyWith(
          messages: List<MessageItem>.from(_currentThread.messages)..add(newMsg),
        );
        _expandedMessageIds.add(newMsg.id);
        _isReplying = false;
        _isSending = false;
        _replyController.clear();
      });

      ref.invalidate(messagesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Odpowiedź została wysłana'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd wysyłania: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  MessageTaskSuggestion _buildCurrentSuggestion() {
    final fullText = _currentThread.body.trim().isNotEmpty
        ? _currentThread.body
        : (_currentThread.messages.isNotEmpty
            ? _currentThread.messages.first.body
            : _currentThread.preview);
    return SchoolTask.suggestFromMessage(
      messageId: _currentThread.id,
      subject: _currentThread.subject,
      body: fullText,
      senderName: _currentThread.senderName,
    );
  }

  void _openTaskModalFromMessage(MessageTaskSuggestion suggestion, {SchoolTask? existingTask}) {
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

  Future<void> _quickAddTaskFromMessage(MessageTaskSuggestion suggestion) async {
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

      if (mounted) {
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
      if (mounted) {
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
  Widget build(BuildContext context) {
    final messages = _currentThread.messages;
    final tasksAsync = ref.watch(tasksStreamProvider);
    final existingTask = tasksAsync.value
        ?.where((t) => t.matchesMessage(_currentThread.id))
        .firstOrNull;
    final suggestion = _buildCurrentSuggestion();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/wiadomosci');
            }
          },
          tooltip: 'Wróć',
        ),
        title: Text(
          _currentThread.subject,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              existingTask != null ? Icons.task_alt_rounded : Icons.add_task_rounded,
              color: existingTask != null ? AppColors.secondary : AppColors.primary,
              size: 22,
            ),
            tooltip: existingTask != null
                ? 'Pokaż powiązane zadanie'
                : 'Utwórz zadanie z tej wiadomości',
            onPressed: () => _openTaskModalFromMessage(
              suggestion,
              existingTask: existingTask,
            ),
          ),
          IconButton(
            icon: Icon(
              _currentThread.isUnread ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
              color: AppColors.onSurfaceVariant,
              size: 22,
            ),
            tooltip: _currentThread.isUnread ? 'Oznacz jako przeczytana' : 'Oznacz jako nieprzeczytana',
            onPressed: _toggleReadStatus,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant, size: 22),
            tooltip: 'Odśwież wątek',
            onPressed: () {
              ref.invalidate(messagesProvider);
              _fetchBodyIfNeeded(force: true);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. Thread Header Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _currentThread.subject,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (_currentThread.isUnread)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mark_email_unread, size: 12, color: AppColors.onPrimaryContainer),
                            SizedBox(width: 4),
                            Text(
                              'NOWA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_currentThread.isImportant)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.priority_high, size: 12, color: AppColors.onErrorContainer),
                            SizedBox(width: 2),
                            Text(
                              'Ważne',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _currentThread.senderRole,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Wątek: ${messages.length} ${messages.length == 1 ? "wiadomość" : (messages.length < 5 ? "wiadomości" : "wiadomości")}',
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 1b. Smart Task Link / Heuristic Suggestion Card (REQ-TASK-04)
          _buildMessageTaskBanner(context, existingTask, suggestion),
          const SizedBox(height: 16),

          // 2. Messages List (Gmail Style)
          for (int i = 0; i < messages.length; i++) ...[
            _buildMessageItem(messages[i], isLatest: i == messages.length - 1),
            const SizedBox(height: 10),
          ],

          // 3. Bottom Reply Section
          _buildReplySection(),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildMessageTaskBanner(
    BuildContext context,
    SchoolTask? existingTask,
    MessageTaskSuggestion suggestion,
  ) {
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
                            isDone
                                ? Icons.check_circle_rounded
                                : Icons.link_rounded,
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
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${existingTask.assignedTo.label} • Priorytet: ${existingTask.priority.label}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSecondaryContainer
                              .withValues(alpha: 0.8),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      color: AppColors.onSecondaryContainer
                          .withValues(alpha: 0.35),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  isSmart
                      ? Icons.auto_awesome_rounded
                      : Icons.add_task_rounded,
                  size: 18,
                  color: isSmart
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
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
                        color: isSmart
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
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
                onPressed: () => _quickAddTaskFromMessage(suggestion),
                icon: const Icon(Icons.add_task_rounded, size: 16),
                label: const Text(
                  '+ Dodaj zadanie (1-klik)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openTaskModalFromMessage(suggestion),
                icon: const Icon(Icons.tune_rounded, size: 15),
                label: const Text(
                  'Dostosuj przed dodaniem...',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(MessageItem message, {required bool isLatest}) {
    final isExpanded = _expandedMessageIds.contains(message.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: message.isFromMe
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.surfaceContainerHigh,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isExpanded
          ? _buildExpandedMessage(message)
          : _buildCollapsedMessage(message),
    );
  }

  Widget _buildCollapsedMessage(MessageItem message) {
    return InkWell(
      onTap: () => _toggleMessageExpansion(message.id),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isFromMe ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
              child: Text(
                message.senderInitials,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: message.isFromMe ? AppColors.onPrimaryContainer : AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        message.isFromMe ? 'Ja (${message.senderName})' : message.senderName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM, HH:mm', 'pl').format(message.timestamp),
                        style: const TextStyle(fontSize: 11, color: AppColors.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.body.replaceAll('\n', ' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 18, color: AppColors.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedMessage(MessageItem message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with toggle to collapse
          InkWell(
            onTap: () => _toggleMessageExpansion(message.id),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: message.isFromMe ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
                  child: Text(
                    message.senderInitials,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: message.isFromMe ? AppColors.onPrimaryContainer : AppColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.isFromMe ? 'Ja (${message.senderName})' : message.senderName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '${message.senderRole} • ${DateFormat("d MMMM yyyy, HH:mm", "pl").format(message.timestamp)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.expand_less, size: 20, color: AppColors.outline),
                  onPressed: () => _toggleMessageExpansion(message.id),
                  tooltip: 'Zwiń wiadomość',
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 0.8),

          // Message Body
          if (_isLoadingBody && !message.isFromMe && message == _currentThread.messages.first) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pobieranie pełnej treści wiadomości z Librusa...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SelectableText(
              message.body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.onSurface,
              ),
            ),
          ],

          // Attachments
          if (message.attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Załączniki:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.attachments.map((file) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surfaceContainerHigh),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 16, color: AppColors.error),
                      const SizedBox(width: 6),
                      Text(
                        file,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplySection() {
    if (!_isReplying) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() => _isReplying = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _replyFocusNode.requestFocus();
            });
          },
          icon: const Icon(Icons.reply, size: 18, color: AppColors.primary),
          label: Text('Odpowiedz do ${_currentThread.senderName}'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: AppColors.surfaceContainerLowest,
            alignment: Alignment.centerLeft,
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.reply, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Odpowiedź do: ${_currentThread.senderName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.outline),
                onPressed: () {
                  setState(() {
                    _isReplying = false;
                    _replyController.clear();
                  });
                },
                tooltip: 'Anuluj',
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _replyController,
            focusNode: _replyFocusNode,
            maxLines: 6,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'Napisz odpowiedź do nauczyciela...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.outline),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceContainerHigh),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSending
                    ? null
                    : () {
                        setState(() {
                          _isReplying = false;
                          _replyController.clear();
                        });
                      },
                child: const Text('Anuluj'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isSending ? null : _handleSendReply,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, size: 16),
                label: Text(_isSending ? 'Wysyłanie...' : 'Wyślij odpowiedź'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
