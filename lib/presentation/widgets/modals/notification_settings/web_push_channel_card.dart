import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/notification_settings_provider.dart';
import 'notification_section_card.dart';

class WebPushChannelCard extends ConsumerStatefulWidget {
  final String studentName;
  final void Function(String message, {bool isError}) onFeedback;

  const WebPushChannelCard({
    super.key,
    required this.studentName,
    required this.onFeedback,
  });

  @override
  ConsumerState<WebPushChannelCard> createState() => _WebPushChannelCardState();
}

class _WebPushChannelCardState extends ConsumerState<WebPushChannelCard> {
  @override
  Widget build(BuildContext context) {
    final slice = ref.watch(
      notificationChannelSettingsProvider.select(
        (asyncVal) => asyncVal.value == null
            ? null
            : (
                familyId: asyncVal.value!.familyId,
                roleKey: asyncVal.value!.roleKey,
                webPushEnabled: asyncVal.value!.webPushEnabled,
              ),
      ),
    );

    if (slice == null) {
      return const SizedBox.shrink();
    }

    final service = ref.read(notificationChannelsServiceProvider);
    final browserPerm = service.getWebPushPermission();
    final swActive = service.isSwActive();

    return NotificationSectionCard(
      icon: Icons.web_asset_rounded,
      iconBg: const Color(0xFFEDE9FE),
      iconColor: const Color(0xFF6D28D9),
      title: 'Powiadomienia Web Push w przeglądarce',
      subtitle:
          'Natywne powiadomienia systemowe (macOS / Windows / Android / iOS) przez Service Worker',
      badgeText: browserPerm == 'granted' && slice.webPushEnabled
          ? 'Aktywne (SW Ready)'
          : browserPerm == 'denied'
              ? 'Zablokowane w przeglądarce'
              : 'Nieaktywne',
      badgeColor: browserPerm == 'granted' && slice.webPushEnabled
          ? const Color(0xFF15803D)
          : browserPerm == 'denied'
              ? AppColors.error
              : const Color(0xFF6D28D9),
      badgeBg: browserPerm == 'granted' && slice.webPushEnabled
          ? const Color(0xFFDCFCE7)
          : browserPerm == 'denied'
              ? AppColors.errorContainer
              : const Color(0xFFEDE9FE),
      trailing: Switch(
        value: slice.webPushEnabled && browserPerm == 'granted',
        activeThumbColor: AppColors.primary,
        onChanged: (val) async {
          if (val) {
            final perm = await service.requestAndEnableWebPush(
              familyId: slice.familyId,
              roleKey: slice.roleKey,
            );
            if (perm == 'granted') {
              widget.onFeedback(
                'Włączono powiadomienia Web Push w przeglądarce!',
              );
            } else {
              widget.onFeedback(
                'Przeglądarka nie udzieliła zgody na powiadomienia (status: $perm). Odblokuj powiadomienia obok paska adresu.',
                isError: true,
              );
            }
          } else {
            await service.updateSettings(
              familyId: slice.familyId,
              roleKey: slice.roleKey,
              patch: {'webPushEnabled': false},
            );
            widget.onFeedback('Wyłączono powiadomienia Web Push.');
          }
          if (mounted) {
            setState(() {});
          }
        },
      ),
      child: Row(
        children: [
          Icon(
            swActive ? Icons.check_circle : Icons.info_outline,
            size: 16,
            color: swActive
                ? const Color(0xFF15803D)
                : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              swActive
                  ? 'Service Worker (/sw-notifications.js) zarejestrowany • Uprawnienia: ${browserPerm.toUpperCase()}'
                  : 'Uprawnienia przeglądarki: ${browserPerm.toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () async {
              if (browserPerm != 'granted') {
                final perm = await service.requestAndEnableWebPush(
                  familyId: slice.familyId,
                  roleKey: slice.roleKey,
                );
                if (perm != 'granted') {
                  widget.onFeedback(
                    'Najpierw zezwól na powiadomienia w przeglądarce.',
                    isError: true,
                  );
                  return;
                }
              }
              final ok = service.triggerWebPush(
                title: '🎓 EduSync • Nowa ocena: 5 (Język angielski)',
                body:
                    'Uczeń: ${widget.studentName} • Kategoria: Sprawdzian (Waga 3) • Kliknij, aby otworzyć Oceny.',
                tag: 'edusync-test-webpush',
                url: '/oceny',
              );
              if (ok) {
                widget.onFeedback(
                  'Wyświetlono natywne powiadomienie Web Push w przeglądarce!',
                );
              } else {
                widget.onFeedback(
                  'Nie udało się wyświetlić powiadomienia Web Push.',
                  isError: true,
                );
              }
            },
            icon: const Icon(Icons.notifications_active_outlined, size: 16),
            label: const Text(
              'Testuj Web Push',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
