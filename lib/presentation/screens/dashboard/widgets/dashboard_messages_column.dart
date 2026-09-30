import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/message_thread.dart';
import '../../messages/message_thread_screen.dart';
import 'dashboard_tasks_card.dart';

/// Middle column of Desktop Dashboard combining Tasks + Messages & Communications (`REQ-ARCH-01`, `REQ-ARCH-02`).
class DashboardMessagesColumn extends StatefulWidget {
  final List<MessageThread> allMessages;
  final List<MessageThread> unreadMessages;
  final List<MessageThread> announcementMessages;

  const DashboardMessagesColumn({
    super.key,
    required this.allMessages,
    required this.unreadMessages,
    required this.announcementMessages,
  });

  @override
  State<DashboardMessagesColumn> createState() => _DashboardMessagesColumnState();
}

class _DashboardMessagesColumnState extends State<DashboardMessagesColumn> {
  int _selectedMessageTab = 0; // 0: Wszystkie, 1: Nieprzeczytane, 2: Ogłoszenia

  @override
  Widget build(BuildContext context) {
    final displayedMessages = _selectedMessageTab == 0
        ? widget.allMessages
        : (_selectedMessageTab == 1
            ? widget.unreadMessages
            : widget.announcementMessages);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardTasksCard(isCompact: false),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.mark_email_unread_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wiadomości i Komunikaty',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            'Skrzynka odbiorcza EduSync',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.go('/wiadomosci'),
                    child: const Row(
                      children: [
                        Text(
                          'Otwórz skrzynkę',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      index: 0,
                      label: 'Wszystkie',
                      isSelected: _selectedMessageTab == 0,
                    ),
                    _buildTabButton(
                      index: 1,
                      label: 'Nieprzeczytane (${widget.unreadMessages.length})',
                      isSelected: _selectedMessageTab == 1,
                    ),
                    _buildTabButton(
                      index: 2,
                      label: 'Ogłoszenia (${widget.announcementMessages.length})',
                      isSelected: _selectedMessageTab == 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (displayedMessages.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Text(
                    _selectedMessageTab == 1
                        ? 'Wszystkie wiadomości zostały przeczytane'
                        : (_selectedMessageTab == 2
                            ? 'Brak ogłoszeń szkolnych'
                            : 'Brak wiadomości w skrzynce'),
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                )
              else
                ...displayedMessages
                    .take(3)
                    .map((msg) => _buildDesktopMessageArticle(context, msg)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.campaign,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '14 Listopada: Dzień Wolny',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            'Konferencja metodyczna rady pedagogicznej',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/plan-lekcji'),
                      icon: const Icon(Icons.event, size: 14),
                      label: const Text('Szczegóły'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMessageTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopMessageArticle(BuildContext context, MessageThread msg) {
    final isUrgent =
        msg.subject.toLowerCase().contains('pilne') || msg.isUnread;
    final isDirector = msg.senderRole.toLowerCase().contains('dyrekcj');
    final timeStr = msg.formattedTimestamp;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (msg.isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    msg.senderName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (msg.senderRole.isNotEmpty)
                    Text(
                      ' • ${msg.senderRole}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PILNE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onErrorContainer,
                        ),
                      ),
                    )
                  else if (isDirector)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DYREKCJA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onPrimaryFixed,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            msg.subject,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            msg.preview,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (msg.attachments.isNotEmpty || msg.hasAttachments)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.attach_file_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        msg.attachments.isEmpty
                            ? 'Załącznik'
                            : (msg.attachments.length == 1
                                ? msg.attachments.first
                                : '${msg.attachments.first} (+${msg.attachments.length - 1})'),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        context.go('/wiadomosci/${msg.id}', extra: msg),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Odpowiedz'),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Szczegóły wątku',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessageThreadScreen(thread: msg),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chevron_right, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
