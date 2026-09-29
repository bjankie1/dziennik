import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/calendar_browser_helper_stub.dart'
    if (dart.library.js_interop) '../../../core/utils/calendar_browser_helper_web.dart';
import '../../../domain/models/message_thread.dart';
import '../../../domain/models/school_task.dart';
import '../../providers/auth_providers.dart';
import '../../providers/school_providers.dart';
import '../../providers/tasks_provider.dart';
import '../tasks/widgets/task_form_modal.dart';
import 'widgets/drive_folder_picker_modal.dart';
import '../../widgets/linkified_text.dart';
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
  final Set<String> _savingDriveAttachments = {};
  bool _isSavingAllDrive = false;
  bool _isReplying = false;
  bool _isSending = false;
  bool _isLoadingBody = false;
  late List<String> _replyRecipients;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  String _resolveSenderName(MessageThread thread, {String? overrideBody}) {
    final existing = thread.senderName.trim();
    if (existing.isNotEmpty) return existing;

    final bodyText = overrideBody ??
        (thread.body.trim().isNotEmpty
            ? thread.body
            : (thread.messages.isNotEmpty ? thread.messages.first.body : thread.preview));
    final sigMatch = RegExp(
      r'(?:Pozdrawiam|Z\s+poważaniem)[,:\s]*\r?\n+\s*([^\r\n\-]{3,70}(?:-[^\r\n]{2,50})?)',
      caseSensitive: false,
    ).firstMatch(bodyText);
    final signedBy = sigMatch?.group(1)?.trim() ?? '';
    final baseRole =
        thread.senderRole.trim().isNotEmpty ? thread.senderRole.trim() : 'Administrator szkoły';
    if (signedBy.isNotEmpty && !signedBy.toLowerCase().contains('kopia powyższej')) {
      return '$signedBy ($baseRole)';
    }
    return baseRole;
  }

  String? _extractCcTeacherFromBody() {
    final bodyText = _currentThread.body.trim().isNotEmpty
        ? _currentThread.body
        : (_currentThread.messages.isNotEmpty
            ? _currentThread.messages.first.body
            : _currentThread.preview);
    final ccMatch = RegExp(
      r'Kopia powyższej wiadomości została wysłana do nauczyciela:\s*([^\r\n]+)',
      caseSensitive: false,
    ).firstMatch(bodyText);
    final ccName = ccMatch?.group(1)?.trim();
    if (ccName != null && ccName.isNotEmpty) return ccName;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _currentThread = widget.thread;
    final resolvedSender = _resolveSenderName(_currentThread);
    if (_currentThread.senderName.trim().isEmpty) {
      final fixedMessages = _currentThread.messages.map((m) {
        if (!m.isFromMe && m.senderName.trim().isEmpty) {
          return MessageItem(
            id: m.id,
            senderName: resolvedSender,
            senderRole: m.senderRole,
            senderInitials: m.senderInitials,
            timestamp: m.timestamp,
            body: m.body,
            attachments: m.attachments,
            attachmentUrls: m.attachmentUrls,
            hasAttachments: m.hasAttachments,
            driveAttachments: m.driveAttachments,
            isFromMe: m.isFromMe,
          );
        }
        return m;
      }).toList();
      _currentThread = _currentThread.copyWith(
        senderName: resolvedSender,
        messages: fixedMessages,
      );
    }
    _replyRecipients = [resolvedSender];
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

  bool _looksLikeMessageWithAttachment(String text) {
    final lower = text.toLowerCase();
    return lower.contains('załącz') ||
        lower.contains('prezentacj') ||
        lower.contains('przesyłam') ||
        lower.contains('plik') ||
        lower.contains('formularz') ||
        lower.contains('regulamin') ||
        lower.contains('dokument');
  }

  Future<void> _fetchBodyIfNeeded({bool force = false}) async {
    final firstMsg = _currentThread.messages.isNotEmpty ? _currentThread.messages.first : null;
    final isBodyMissingOrSameAsSubject = firstMsg == null ||
        firstMsg.body.trim().isEmpty ||
        firstMsg.body.trim() == _currentThread.subject.trim();
    final needsAttachmentDetails = (_currentThread.hasAttachments &&
            (_currentThread.attachments.isEmpty || _currentThread.attachmentUrls.isEmpty)) ||
        (_currentThread.attachments.isEmpty &&
            _looksLikeMessageWithAttachment(firstMsg?.body ?? _currentThread.body));

    if (force || isBodyMissingOrSameAsSubject || needsAttachmentDetails) {
      if (mounted) setState(() => _isLoadingBody = true);
      try {
        final details = await ref.read(schoolRepositoryProvider).getMessageDetails(_currentThread.id);
        if (details != null && mounted) {
          final fullBody = details.body.trim().isNotEmpty
              ? details.body
              : (firstMsg?.body ?? _currentThread.body);
          final mergedAttachments = details.attachments.isNotEmpty
              ? details.attachments
              : _currentThread.attachments;
          final mergedUrls = details.attachmentUrls.isNotEmpty
              ? details.attachmentUrls
              : _currentThread.attachmentUrls;
          final mergedHasAttachments =
              details.hasAttachments || mergedAttachments.isNotEmpty || _currentThread.hasAttachments;
          final mergedDriveAttachments = {
            ..._currentThread.driveAttachments,
            ...details.driveAttachments,
          };

          setState(() {
            final resolvedSender = _resolveSenderName(_currentThread, overrideBody: fullBody);
            final updatedMessages = _currentThread.messages.map((m) {
              if (m == _currentThread.messages.first) {
                return MessageItem(
                  id: m.id,
                  senderName: m.senderName.trim().isNotEmpty ? m.senderName : resolvedSender,
                  senderRole: m.senderRole,
                  senderInitials: m.senderInitials,
                  timestamp: m.timestamp,
                  body: fullBody,
                  attachments: mergedAttachments,
                  attachmentUrls: mergedUrls,
                  hasAttachments: mergedHasAttachments,
                  driveAttachments: {
                    ...m.driveAttachments,
                    ...mergedDriveAttachments,
                  },
                  isFromMe: m.isFromMe,
                );
              }
              return m;
            }).toList();

            _currentThread = _currentThread.copyWith(
              senderName: resolvedSender,
              body: fullBody,
              preview: fullBody.length > 90 ? '${fullBody.substring(0, 90)}...' : fullBody,
              attachments: mergedAttachments,
              attachmentUrls: mergedUrls,
              hasAttachments: mergedHasAttachments,
              driveAttachments: mergedDriveAttachments,
              messages: updatedMessages,
            );
            if (_replyRecipients.isEmpty || _replyRecipients.every((r) => r.trim().isEmpty)) {
              _replyRecipients = [resolvedSender];
            }
            _isLoadingBody = false;
          });
          if (details.attachments.isNotEmpty) {
            ref.invalidate(messagesProvider);
          }
          return;
        }
      } catch (e) {
        debugPrint('Error loading full message details: $e');
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

    final recipients = _replyRecipients.where((r) => r.trim().isNotEmpty).toList();
    if (recipients.isEmpty) {
      recipients.add(_resolveSenderName(_currentThread));
    }

    setState(() => _isSending = true);

    try {
      final repo = ref.read(schoolRepositoryProvider);
      final profile = await repo.getStudentProfile();

      await repo.sendMessage(
        recipientNames: recipients,
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
          SnackBar(
            content: Text('Odpowiedź została wysłana do: ${recipients.join(", ")}'),
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
          if (_isLoadingBody &&
              !message.isFromMe &&
              message == _currentThread.messages.first &&
              (message.body.trim().isEmpty || message.body.trim() == _currentThread.subject.trim())) ...[
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
            LinkifiedSelectableText(
              message.body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.onSurface,
              ),
            ),
            if (_isLoadingBody &&
                !message.isFromMe &&
                message == _currentThread.messages.first &&
                message.attachments.isEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sprawdzanie załączników w Librusie...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],

          // Attachments
          if (message.attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAttachmentsSection(message),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(MessageItem message) {
    final effectiveDriveAttachments = <String, DriveAttachmentInfo>{
      ..._currentThread.driveAttachments,
      ...message.driveAttachments,
    };
    final hasUnsaved = message.attachments.any(
      (f) => !effectiveDriveAttachments.containsKey(f),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Załączniki (${message.attachments.length}):',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (message.attachments.length >= 2)
              if (hasUnsaved)
                TextButton.icon(
                  key: const ValueKey('save_all_drive_button'),
                  onPressed: _isSavingAllDrive
                      ? null
                      : () => _saveAllAttachmentsToDrive(message),
                  icon: _isSavingAllDrive
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.add_to_drive_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                  label: const Text(
                    'Zapisz wszystkie na Dysku',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Zapisano wszystkie na Dysku',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
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
          runSpacing: 8,
          children: message.attachments.map((file) {
            final (iconData, iconColor) = _attachmentIconAndColor(file);
            final driveInfo = effectiveDriveAttachments[file];
            final isSavingToDrive = _savingDriveAttachments.contains(
              '${message.id}::$file',
            );

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: driveInfo != null
                      ? AppColors.secondary.withValues(alpha: 0.45)
                      : AppColors.surfaceContainerHigh,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: InkWell(
                      key: ValueKey('download_attachment_$file'),
                      onTap: () => _downloadAttachment(file, message),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconData, size: 18, color: iconColor),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                file,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Tooltip(
                              message: 'Pobierz na urządzenie',
                              child: Icon(
                                Icons.download_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppColors.surfaceContainerHigh,
                  ),
                  if (isSavingToDrive)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        key: ValueKey('drive_spinner_$file'),
                        width: 16,
                        height: 16,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (driveInfo != null)
                    Tooltip(
                      message: 'Otwórz w Google Drive (${driveInfo.folderName})',
                      child: InkWell(
                        key: ValueKey('open_drive_$file'),
                        onTap: () => _openSavedDriveAttachment(driveInfo),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(10),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 15,
                                color: AppColors.secondary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Otwórz w Google Drive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Tooltip(
                      message: 'Zapisz na Dysku Google',
                      child: InkWell(
                        key: ValueKey('save_drive_$file'),
                        onTap: () => _saveAttachmentToDrive(file, message),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(10),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Icon(
                            Icons.add_to_drive_rounded,
                            size: 17,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  (IconData, Color) _attachmentIconAndColor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return (Icons.picture_as_pdf_rounded, AppColors.error);
    }
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
      return (Icons.slideshow_rounded, const Color(0xFFD84315));
    }
    if (lower.endsWith('.doc') || lower.endsWith('.docx') || lower.endsWith('.odt')) {
      return (Icons.description_rounded, const Color(0xFF1565C0));
    }
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx') || lower.endsWith('.csv')) {
      return (Icons.table_chart_rounded, const Color(0xFF2E7D32));
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp')) {
      return (Icons.image_rounded, const Color(0xFF6A1B9A));
    }
    if (lower.endsWith('.zip') || lower.endsWith('.rar') || lower.endsWith('.7z')) {
      return (Icons.folder_zip_rounded, const Color(0xFFF57F17));
    }
    return (Icons.attach_file_rounded, AppColors.primary);
  }

  Future<String?> _resolveAttachmentDownloadPath(
    String fileName,
    MessageItem message,
  ) async {
    String? downloadPath =
        message.attachmentUrls[fileName] ?? _currentThread.attachmentUrls[fileName];

    if (downloadPath == null || downloadPath.isEmpty) {
      try {
        final details =
            await ref.read(schoolRepositoryProvider).getMessageDetails(_currentThread.id);
        if (details != null) {
          downloadPath = details.attachmentUrls[fileName];
          if (mounted && details.attachmentUrls.isNotEmpty) {
            setState(() {
              _currentThread = _currentThread.copyWith(
                attachmentUrls: details.attachmentUrls,
              );
            });
          }
        }
      } catch (_) {}
    }
    return downloadPath;
  }

  Future<void> _downloadAttachment(String fileName, MessageItem message) async {
    final downloadPath = await _resolveAttachmentDownloadPath(fileName, message);

    if (downloadPath != null && downloadPath.isNotEmpty) {
      final url = '/api/downloadAttachment?path=${Uri.encodeComponent(downloadPath)}';
      final opened = openUrlInBrowser(url);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pobieranie załącznika: $fileName'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Załącznik „$fileName” (tryb demonstracyjny)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _acquireDriveTokenOrDemo({bool forceRefresh = false}) async {
    final authService = ref.read(firebaseAuthServiceProvider);
    if (!forceRefresh && authService.hasValidDriveAccessToken) {
      return authService.requestGoogleDriveAccessToken();
    }
    if (!authService.isSignedIn) {
      return 'demo_access_token';
    }
    try {
      return await authService.requestGoogleDriveAccessToken(
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('OAuth token acquisition error: $e');
      return null;
    }
  }

  void _applySavedDriveAttachmentsToState(
    String messageId,
    Map<String, DriveAttachmentInfo> newEntries,
  ) {
    final mergedThreadDrive = <String, DriveAttachmentInfo>{
      ..._currentThread.driveAttachments,
      ...newEntries,
    };
    final updatedMessages = _currentThread.messages.map((m) {
      if (m.id == messageId || m == _currentThread.messages.first) {
        return m.copyWith(
          driveAttachments: {
            ...m.driveAttachments,
            ...newEntries,
          },
        );
      }
      return m;
    }).toList();

    _currentThread = _currentThread.copyWith(
      driveAttachments: mergedThreadDrive,
      messages: updatedMessages,
    );
  }

  Future<DriveAttachmentInfo> _uploadSingleAttachmentWithRetry({
    required String fileName,
    required MessageItem message,
    required String initialAccessToken,
  }) async {
    final repo = ref.read(schoolRepositoryProvider);
    final isStudent = ref.read(appUserProvider)?.isStudent ?? false;
    final savedBy = isStudent ? 'Uczeń (Oskar)' : 'Rodzic';
    final resolvedPath = await _resolveAttachmentDownloadPath(fileName, message);
    final downloadPath = (resolvedPath != null && resolvedPath.isNotEmpty)
        ? resolvedPath
        : '/wiadomosci/pobierz_zalacznik/${_currentThread.id}/0';

    try {
      return await repo.saveAttachmentToDrive(
        msgId: _currentThread.id,
        attachmentName: fileName,
        downloadPath: downloadPath,
        accessToken: initialAccessToken,
        savedBy: savedBy,
      );
    } catch (e) {
      if (e.toString().contains('UNAUTHENTICATED_DRIVE')) {
        ref.read(firebaseAuthServiceProvider).clearDriveAccessToken();
        final freshToken = await _acquireDriveTokenOrDemo(forceRefresh: true);
        if (freshToken != null && freshToken.isNotEmpty) {
          return await repo.saveAttachmentToDrive(
            msgId: _currentThread.id,
            attachmentName: fileName,
            downloadPath: downloadPath,
            accessToken: freshToken,
            savedBy: savedBy,
          );
        }
      }
      rethrow;
    }
  }

  Future<void> _saveAttachmentToDrive(
    String fileName,
    MessageItem message,
  ) async {
    final key = '${message.id}::$fileName';
    if (_savingDriveAttachments.contains(key)) return;

    // Acquire OAuth token directly on user gesture before other async work
    final accessToken = await _acquireDriveTokenOrDemo();
    if (accessToken == null || accessToken.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nie udało się uzyskać autoryzacji Google Drive. Spróbuj ponownie.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _savingDriveAttachments.add(key);
      });
    }

    try {
      final savedInfo = await _uploadSingleAttachmentWithRetry(
        fileName: fileName,
        message: message,
        initialAccessToken: accessToken,
      );

      if (!mounted) return;
      setState(() {
        _savingDriveAttachments.remove(key);
        _applySavedDriveAttachmentsToState(
          message.id,
          {fileName: savedInfo},
        );
      });
      ref.invalidate(messagesProvider);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zapisano „$fileName” w: ${savedInfo.folderName}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Zmień folder / Przenieś',
            onPressed: () => _openDriveMoveModal(
              message,
              [fileName],
              savedInfo,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingDriveAttachments.remove(key);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd zapisu na Google Drive: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveAllAttachmentsToDrive(MessageItem message) async {
    if (_isSavingAllDrive) return;

    final effectiveDrive = <String, DriveAttachmentInfo>{
      ..._currentThread.driveAttachments,
      ...message.driveAttachments,
    };
    final unsavedFiles = message.attachments
        .where((f) => !effectiveDrive.containsKey(f))
        .toList();
    if (unsavedFiles.isEmpty) return;

    // Acquire OAuth token directly on user gesture before other async work
    final accessToken = await _acquireDriveTokenOrDemo();
    if (accessToken == null || accessToken.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nie udało się uzyskać autoryzacji Google Drive. Spróbuj ponownie.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSavingAllDrive = true;
        for (final f in unsavedFiles) {
          _savingDriveAttachments.add('${message.id}::$f');
        }
      });
    }

    final savedNames = <String>[];
    DriveAttachmentInfo? lastSavedInfo;

    try {
      for (final fileName in unsavedFiles) {
        final key = '${message.id}::$fileName';
        final info = await _uploadSingleAttachmentWithRetry(
          fileName: fileName,
          message: message,
          initialAccessToken: accessToken,
        );
        savedNames.add(fileName);
        lastSavedInfo = info;
        if (mounted) {
          setState(() {
            _savingDriveAttachments.remove(key);
            _applySavedDriveAttachmentsToState(
              message.id,
              {fileName: info},
            );
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _isSavingAllDrive = false;
      });
      ref.invalidate(messagesProvider);

      if (lastSavedInfo != null && savedNames.isNotEmpty) {
        final info = lastSavedInfo;
        final text = savedNames.length == 1
            ? 'Zapisano „${savedNames.first}” w: ${info.folderName}'
            : 'Zapisano ${savedNames.length} załączniki w: ${info.folderName}';
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Zmień folder / Przenieś',
              onPressed: () => _openDriveMoveModal(
                message,
                savedNames,
                info,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingAllDrive = false;
        for (final f in unsavedFiles) {
          _savingDriveAttachments.remove('${message.id}::$f');
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd zapisu załączników na Google Drive: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openSavedDriveAttachment(DriveAttachmentInfo info) {
    final link = info.webViewLink.trim();
    final isSafeGoogleUrl = link.startsWith('https://drive.google.com/') ||
        link.startsWith('https://docs.google.com/');
    if (!isSafeGoogleUrl) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nieprawidłowy link Google Drive.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final opened = openUrlInBrowser(link);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Otwieranie w Google Drive (${info.folderName})'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openDriveMoveModal(
    MessageItem message,
    List<String> attachmentNames,
    DriveAttachmentInfo currentInfo,
  ) async {
    final currentDriveMap = <String, DriveAttachmentInfo>{
      ..._currentThread.driveAttachments,
      ...message.driveAttachments,
    };

    final newFolder = await DriveFolderPickerModal.showMoveDialog(
      context,
      msgId: _currentThread.id,
      attachmentNames: attachmentNames,
      currentDriveAttachments: currentDriveMap,
      initialFolder: DriveFolderOption(
        id: currentInfo.folderId,
        name: currentInfo.folderName,
      ),
    );

    if (newFolder != null && mounted) {
      final updatedEntries = <String, DriveAttachmentInfo>{};
      for (final name in attachmentNames) {
        final existing = currentDriveMap[name] ?? currentInfo;
        updatedEntries[name] = existing.copyWith(
          folderId: newFolder.id,
          folderName: newFolder.name,
        );
      }
      setState(() {
        _applySavedDriveAttachmentsToState(message.id, updatedEntries);
      });
      ref.invalidate(messagesProvider);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Przeniesiono do folderu: ${newFolder.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildReplySection() {
    final defaultSender = _resolveSenderName(_currentThread);
    final ccTeacher = _extractCcTeacherFromBody();
    final teachers = ref.watch(teachersProvider).value ?? const [];

    if (!_isReplying) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _isReplying = true;
              if (_replyRecipients.isEmpty ||
                  _replyRecipients.every((r) => r.trim().isEmpty)) {
                _replyRecipients = [defaultSender];
              }
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _replyFocusNode.requestFocus();
            });
          },
          icon: const Icon(Icons.reply, size: 18, color: AppColors.primary),
          label: Text('Odpowiedz do $defaultSender'),
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

    final activeRecipients = _replyRecipients.where((r) => r.trim().isNotEmpty).toList();
    if (activeRecipients.isEmpty) {
      activeRecipients.add(defaultSender);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.reply, size: 18, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Odpowiedź do:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    ...activeRecipients.map((recipient) {
                      final canRemove = activeRecipients.length > 1;
                      return Container(
                        padding: EdgeInsets.only(
                          left: 10,
                          right: canRemove ? 4 : 10,
                          top: 4,
                          bottom: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recipient,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            if (canRemove) ...[
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _replyRecipients.remove(recipient);
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    if (ccTeacher != null &&
                        !activeRecipients.any(
                          (r) => r.toLowerCase().contains(ccTeacher.toLowerCase()),
                        ))
                      ActionChip(
                        avatar: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        label: Text(
                          '+ DW: $ccTeacher',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        backgroundColor:
                            AppColors.secondaryContainer.withValues(alpha: 0.5),
                        side: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.35),
                        ),
                        onPressed: () {
                          setState(() {
                            _replyRecipients.add(ccTeacher);
                          });
                        },
                      ),
                    if (teachers.isNotEmpty)
                      PopupMenuButton<String>(
                        tooltip: 'Dodaj adresata z listy nauczycieli',
                        onSelected: (selectedName) {
                          if (!_replyRecipients.contains(selectedName)) {
                            setState(() {
                              _replyRecipients.add(selectedName);
                            });
                          }
                        },
                        itemBuilder: (context) {
                          return teachers.map((t) {
                            final label = t.subjectName.isNotEmpty
                                ? '${t.name} (${t.subjectName})'
                                : t.name;
                            return PopupMenuItem<String>(
                              value: t.name,
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Dodaj adresata',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
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
              hintText: 'Napisz odpowiedź do: ${activeRecipients.join(", ")}...',
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
