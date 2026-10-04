import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/notification_settings.dart';
import '../../../providers/notification_settings_provider.dart';

class NotificationAlertsHistoryTab extends ConsumerWidget {
  final void Function(String message, {bool isError}) onFeedback;

  const NotificationAlertsHistoryTab({
    super.key,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      schoolNotificationsStreamProvider.select(
        (a) => a.value ?? const <SchoolNotificationItem>[],
      ),
    );
    final familyId = ref.watch(
      notificationChannelSettingsProvider.select(
        (a) => a.value?.familyId ?? '11010033',
      ),
    );
    final service = ref.read(notificationChannelsServiceProvider);

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Brak zapisanych alertów z ostatnich synchronizacji',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Gdy w Librusie pojawi się nowa ocena, wiadomość lub sprawdzian, zobaczysz je tutaj oraz na Telegramie / Web Push.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final unreadCount = items.where((i) => !i.isRead).length;

    return Column(
      children: [
        if (unreadCount > 0)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await service.markAllNotificationsAsRead(familyId);
                onFeedback('Oznaczono wszystkie alerty jako przeczytane.');
              },
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: Text(
                'Oznacz wszystkie jako przeczytane ($unreadCount)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final (icon, color, route) = switch (item.type) {
                'grade' => (
                    Icons.school_rounded,
                    const Color(0xFF2563EB),
                    '/oceny'
                  ),
                'message' || 'announcement' => (
                    Icons.mail_rounded,
                    const Color(0xFF0284C7),
                    '/wiadomosci'
                  ),
                'exam' => (
                    Icons.event_available_rounded,
                    const Color(0xFFD97706),
                    '/plan-lekcji'
                  ),
                'justification' => (
                    Icons.fact_check_rounded,
                    AppColors.success,
                    '/frekwencja'
                  ),
                'family_chat' => (
                    Icons.forum_rounded,
                    const Color(0xFF7C3AED),
                    '/czat'
                  ),
                _ => (
                    Icons.notifications_rounded,
                    AppColors.primary,
                    '/pulpit'
                  ),
              };

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item.isRead
                      ? AppColors.surfaceContainerLow
                      : AppColors.primaryFixed.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.isRead
                        ? AppColors.outlineVariant.withValues(alpha: 0.35)
                        : AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          if (item.body.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.body,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm')
                                .format(item.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Wyślij jako Web Push',
                      onPressed: () {
                        service.triggerWebPush(
                          title: item.title,
                          body: item.body,
                          tag: item.id,
                          url: route,
                        );
                      },
                      icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                    ),
                    TextButton(
                      onPressed: () {
                        service.markNotificationAsRead(familyId, item.id);
                        Navigator.of(context).pop();
                        context.go(route);
                      },
                      child: const Text(
                        'Otwórz',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
