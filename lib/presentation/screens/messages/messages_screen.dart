import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/message_thread.dart';
import '../../../domain/models/school_task.dart';
import '../../providers/school_providers.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/linkified_text.dart';
import '../tasks/widgets/task_form_modal.dart';
import 'new_message_screen.dart';
import 'widgets/archive_box_icon.dart';
import 'package:go_router/go_router.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  int _activeTab = 0; // 0 = Wiadomości, 1 = Ogłoszenia
  bool _showArchived = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleArchiveMessage(MessageThread thread) async {
    final nextArchived = !thread.isArchived;
    await ref
        .read(schoolRepositoryProvider)
        .archiveMessage(thread.id, isArchived: nextArchived);
    ref.invalidate(messagesProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nextArchived
              ? 'Wiadomość przeniesiona do archiwum'
              : 'Przywrócono wiadomość do skrzynki odbiorczej',
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Cofnij',
          onPressed: () async {
            await ref
                .read(schoolRepositoryProvider)
                .archiveMessage(thread.id, isArchived: !nextArchived);
            ref.invalidate(messagesProvider);
          },
        ),
      ),
    );
  }

  Widget _buildArchiveFilterToggle(int archivedCount, {required bool isCompact}) {
    final bgColor = _showArchived
        ? const Color(0xFFFEF3C7)
        : AppColors.surfaceContainerLowest;
    final borderColor = _showArchived
        ? const Color(0xFFF59E0B)
        : AppColors.surfaceContainerHigh;
    final fgColor = _showArchived
        ? const Color(0xFF92400E)
        : const Color(0xFFB45309);
    final labelText = 'Pokaż zarchiwizowane ($archivedCount)';

    final button = Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const ValueKey('messages_archive_filter_chip'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _showArchived = !_showArchived),
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: _showArchived ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArchiveBoxIcon(
                size: 16,
                color: fgColor,
                isUnarchive: false,
              ),
              if (isCompact) ...[
                if (archivedCount > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _showArchived
                          ? const Color(0xFFD97706)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$archivedCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _showArchived
                            ? Colors.white
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                const SizedBox(width: 7),
                Text(
                  labelText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _showArchived ? FontWeight.w800 : FontWeight.w700,
                    color: fgColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isCompact) {
      return Tooltip(
        message: labelText,
        child: button,
      );
    }
    return button;
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    final messages = messagesAsync.value ?? [];
    final activeMessages = messages.where((m) => !m.isArchived).toList();
    final archivedMessages = messages.where((m) => m.isArchived).toList();
    final unreadMessages = activeMessages.where((m) => m.isUnread).length;
    final announcements = announcementsAsync.value ?? [];

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Segmented Control Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    0,
                    icon: Icons.inbox,
                    title: 'Wiadomości',
                    badgeCount: unreadMessages > 0 ? unreadMessages : null,
                    badgeColor: AppColors.error,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    1,
                    icon: Icons.campaign,
                    title: 'Ogłoszenia',
                    badgeCount: announcements.isNotEmpty ? announcements.length : null,
                    badgeColor: AppColors.tertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Search, Archive Filter Toggle & Write Button Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        decoration: const InputDecoration(
                          hintText: 'Szukaj wiadomości, nauczyciela...',
                          hintStyle: TextStyle(fontSize: 13, color: AppColors.outline),
                          prefixIcon: Icon(Icons.search, size: 20, color: AppColors.outline),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  if (_activeTab == 0) ...[
                    const SizedBox(width: 8),
                    _buildArchiveFilterToggle(
                      archivedMessages.length,
                      isCompact: isCompact,
                    ),
                  ],
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NewMessageScreen()),
                        );
                      },
                      icon: const Icon(Icons.edit_square, size: 18),
                      label: const Text('Napisz', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // 3. Tab Content
          if (_activeTab == 0) ...[
            if (!_showArchived && unreadMessages > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Nowe: $unreadMessages',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(schoolRepositoryProvider).markAllMessagesAsRead();
                        ref.invalidate(messagesProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Wszystkie wiadomości oznaczono jako przeczytane'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.done_all, size: 15, color: AppColors.primary),
                      label: const Text(
                        'Oznacz jako przeczytane',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
            messagesAsync.when(
              data: (threads) {
                final baseList = _showArchived
                    ? threads.where((m) => m.isArchived).toList()
                    : threads.where((m) => !m.isArchived).toList();
                final filteredThreads = _searchQuery.isEmpty
                    ? baseList
                    : baseList.where((m) {
                        final hay =
                            '${m.subject} ${m.senderName} ${m.senderRole} ${m.preview}'
                                .toLowerCase();
                        return hay.contains(_searchQuery);
                      }).toList();

                if (filteredThreads.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceContainerHigh),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          _showArchived
                              ? Icons.archive_outlined
                              : Icons.mark_email_read_outlined,
                          size: 44,
                          color: AppColors.outline.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _showArchived
                              ? 'Brak zarchiwizowanych wiadomości'
                              : 'Brak wiadomości w skrzynce',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _showArchived
                              ? 'Zarchiwizowane wiadomości oraz potwierdzenia usprawiedliwień pojawią się tutaj.'
                              : 'Wszystkie wiadomości od nauczycieli zostały przeczytane lub zarchiwizowane.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: filteredThreads
                      .map((thread) => _buildMessageCard(thread))
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Błąd: $err', style: const TextStyle(color: AppColors.error))),
              ),
            ),
          ] else ...[
            announcementsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceContainerHigh),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.campaign_outlined, size: 44, color: AppColors.outline.withValues(alpha: 0.6)),
                        const SizedBox(height: 10),
                        const Text(
                          'Brak ogłoszeń szkolnych',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: items.map((ann) => _buildAnnouncementCard(ann)).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Błąd: $err', style: const TextStyle(color: AppColors.error))),
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    int index, {
    required IconData icon,
    required String title,
    int? badgeCount,
    required Color badgeColor,
  }) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(MessageThread thread) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: thread.isUnread ? AppColors.primary : AppColors.surfaceContainerHigh,
          width: thread.isUnread ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.go('/wiadomosci/${thread.id}', extra: thread);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: thread.isUnread
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      thread.senderInitials,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (thread.isUnread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            thread.senderName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: thread.isUnread ? FontWeight.w800 : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          thread.formattedTimestamp,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: thread.isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: thread.isUnread ? AppColors.primary : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (thread.isUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NOWA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            thread.senderRole,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (thread.messages.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.reply, size: 10, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  'Odpowiedzi: ${thread.messages.length - 1}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (thread.isImportant)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.priority_high, size: 10, color: AppColors.onErrorContainer),
                                SizedBox(width: 2),
                                Text(
                                  'Ważne',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (thread.isArchived)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const ArchiveBoxIcon(
                                  size: 12,
                                  color: Color(0xFFB45309),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  thread.isAutoArchived
                                      ? 'Auto-archiwum'
                                      : 'Zarchiwizowana',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      thread.subject,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: thread.isUnread ? FontWeight.w800 : FontWeight.w600,
                        color: thread.isUnread ? AppColors.onSurface : AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thread.messages.length > 1 && thread.messages.last.isFromMe
                          ? 'Ty: ${thread.messages.last.body.replaceAll('\n', ' ')}'
                          : thread.preview,
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (thread.attachments.isNotEmpty || thread.hasAttachments) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              thread.attachments.isEmpty
                                  ? 'Zawiera załącznik'
                                  : (thread.attachments.length == 1
                                      ? '1 załącznik: ${thread.attachments.first}'
                                      : '${thread.attachments.length} ${thread.attachments.length < 5 ? "załączniki" : "załączników"}: ${thread.attachments.join(", ")}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildMessageTaskActionRow(thread),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveActionButton(MessageThread thread) {
    final isArchived = thread.isArchived;
    final bgColor = isArchived
        ? AppColors.successSurface
        : const Color(0xFFFFFBEB);
    final borderColor = isArchived
        ? AppColors.success.withValues(alpha: 0.40)
        : const Color(0xFFF59E0B).withValues(alpha: 0.45);
    final fgColor = isArchived
        ? AppColors.success
        : const Color(0xFFB45309);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: ValueKey('archive_message_${thread.id}'),
        onTap: () => _toggleArchiveMessage(thread),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArchiveBoxIcon(
                size: 14,
                color: fgColor,
                isUnarchive: isArchived,
              ),
              const SizedBox(width: 5),
              Text(
                isArchived ? 'Przywróć' : 'Archiwizuj',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageTaskActionRow(MessageThread thread) {
    final tasks = ref.watch(tasksStreamProvider).value ?? const [];
    final existingTask =
        tasks.where((t) => t.matchesMessage(thread.id)).firstOrNull;
    final suggestion = SchoolTask.suggestFromMessage(
      messageId: thread.id,
      subject: thread.subject,
      body: thread.body.isNotEmpty ? thread.body : thread.preview,
      senderName: thread.senderName,
    );

    if (existingTask != null) {
      final isDone = existingTask.isCompleted;
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Material(
            color: AppColors.secondaryContainer.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              key: ValueKey('task_action_${thread.id}'),
              onTap: () =>
                  TaskFormModal.show(context, existingTask: existingTask),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.link_rounded,
                      size: 14,
                      color: AppColors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        isDone
                            ? '✓ Wykonane: ${existingTask.title}'
                            : '✓ Powiązane zadanie: ${existingTask.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => context.go('/zadania'),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Pokaż w zadaniach →',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          _buildArchiveActionButton(thread),
        ],
      );
    }

    final isSmart = suggestion.isHeuristicMatch;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Material(
          color: isSmart
              ? AppColors.primaryFixed.withValues(alpha: 0.75)
              : AppColors.primaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            key: ValueKey('task_action_${thread.id}'),
            onTap: () {
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
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(
                    alpha: isSmart ? 0.40 : 0.28,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSmart
                        ? Icons.auto_awesome_rounded
                        : Icons.add_task_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      isSmart
                          ? '+ Utwórz zadanie: ${suggestion.detectedAmount != null ? "Opłata (${suggestion.detectedAmount})" : suggestion.suggestedSubject}'
                          : '+ Utwórz zadanie z wiadomości',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildArchiveActionButton(thread),
      ],
    );
  }

  Widget _buildAnnouncementCard(Announcement ann) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
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
                  const Icon(Icons.campaign, size: 18, color: AppColors.tertiaryContainer),
                  const SizedBox(width: 6),
                  Text(
                    '${ann.author} • ${ann.authorRole}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              Text(
                DateFormat('d MMM yyyy', 'pl').format(ann.publishedDate),
                style: const TextStyle(fontSize: 11, color: AppColors.outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ann.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          LinkifiedSelectableText(
            Announcement.formatContent(ann.content),
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: ann.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

}
