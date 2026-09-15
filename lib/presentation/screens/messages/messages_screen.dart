import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/message_thread.dart';
import '../../providers/school_providers.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  int _activeTab = 0; // 0 = Wiadomości, 1 = Ogłoszenia
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    final messages = messagesAsync.value ?? [];
    final unreadMessages = messages.where((m) => m.isUnread).length;
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
                    badgeCount: unreadMessages > 0 ? unreadMessages : (messages.isNotEmpty ? messages.length : null),
                    badgeColor: unreadMessages > 0 ? AppColors.error : AppColors.primary,
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

          // 2. Search & Write Button Bar
          Row(
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
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Formularz nowej wiadomości do nauczyciela')),
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
          ),
          const SizedBox(height: 16),

          // 3. Tab Content
          if (_activeTab == 0) ...[
            messagesAsync.when(
              data: (threads) {
                if (threads.isEmpty) {
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
                        Icon(Icons.mark_email_read_outlined, size: 44, color: AppColors.outline.withValues(alpha: 0.6)),
                        const SizedBox(height: 10),
                        const Text(
                          'Brak nowych wiadomości',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Wszystkie wiadomości od nauczycieli zostały przeczytane.',
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: threads.map((thread) => _buildMessageCard(thread)).toList(),
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
          color: thread.isUnread ? AppColors.primaryFixed : AppColors.surfaceContainerHigh,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () => _showMessageDialog(thread),
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
                      color: AppColors.primary.withValues(alpha: 0.1),
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
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
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
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Dzisiaj, 09:15',
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
                      children: [
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
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      thread.subject,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thread.preview,
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (thread.attachments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${thread.attachments.length} załączniki',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
          Text(
            ann.content,
            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.onSurface),
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

  void _showMessageDialog(MessageThread thread) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.all(16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        actionsPadding: const EdgeInsets.all(12),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(thread.subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Od: ${thread.senderName} (${thread.senderRole})',
              style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              Text(thread.body, style: const TextStyle(fontSize: 13, height: 1.5)),
              if (thread.attachments.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Załączniki:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...thread.attachments.map(
                  (file) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 16, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(file, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Otwieranie formularza odpowiedzi...')),
              );
            },
            icon: const Icon(Icons.reply, size: 16),
            label: const Text('Odpowiedz'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
