import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/notification_settings_provider.dart';
import '../../providers/school_providers.dart';
import 'notification_settings/notification_alerts_history_tab.dart';
import 'notification_settings/notification_categories_card.dart';
import 'notification_settings/telegram_channel_card.dart';
import 'notification_settings/web_push_channel_card.dart';

class NotificationSettingsModal extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const NotificationSettingsModal({super.key, this.initialTabIndex = 0});

  static Future<void> show(BuildContext context, {int initialTabIndex = 0}) {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: NotificationSettingsModal(initialTabIndex: initialTabIndex),
      ),
    );
  }

  @override
  ConsumerState<NotificationSettingsModal> createState() =>
      _NotificationSettingsModalState();
}

class _NotificationSettingsModalState
    extends ConsumerState<NotificationSettingsModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<TelegramChannelCardState> _telegramCardKey =
      GlobalKey<TelegramChannelCardState>();

  String? _statusMessage;
  bool _statusIsError = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setFeedback(String msg, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _statusMessage = msg;
      _statusIsError = isError;
    });
  }

  Future<void> _handleSaveAndClose() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _telegramCardKey.currentState?.savePendingConfigIfNeeded();
      if (!mounted) return;
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        _setFeedback('Zapisano ustawienia powiadomień.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsLoadState = ref.watch(
      notificationChannelSettingsProvider.select(
        (a) => (
          isLoading: a.isLoading && !a.hasValue,
          error: a.hasError && !a.hasValue ? a.error : null,
        ),
      ),
    );
    final alertsCount = ref.watch(
      schoolNotificationsStreamProvider.select((a) => a.value?.length ?? 0),
    );
    final studentName = ref.watch(
      studentProfileProvider.select(
        (s) => s.value?.name.split(' ').first ?? 'Oskar',
      ),
    );
    final isStudent = ref.watch(notificationRoleKeyProvider) == 'student';

    return Container(
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Powiadomienia w czasie rzeczywistym',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isStudent
                                ? 'Konto: Uczeń ($studentName) • Telegram Bot & Web Push'
                                : 'Konto: Rodzic ($studentName) • Telegram Bot & Web Push',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final nav = Navigator.of(context);
                        if (nav.canPop()) nav.pop();
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Zamknij',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    const Tab(
                      icon: Icon(Icons.tune_rounded, size: 18),
                      text: 'Kanały (Telegram & Web Push)',
                    ),
                    Tab(
                      icon: const Icon(Icons.history_edu_rounded, size: 18),
                      text: 'Ostatnie alerty ($alertsCount)',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Feedback Banner
          if (_statusMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: _statusIsError
                  ? AppColors.errorContainer.withValues(alpha: 0.6)
                  : const Color(0xFFDCFCE7),
              child: Row(
                children: [
                  Icon(
                    _statusIsError
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: 18,
                    color: _statusIsError
                        ? AppColors.error
                        : const Color(0xFF15803D),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusIsError
                            ? AppColors.error
                            : const Color(0xFF166534),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _statusMessage = null),
                  ),
                ],
              ),
            ),

          // Body
          Expanded(
            child: settingsLoadState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : settingsLoadState.error != null
                    ? Center(
                        child: Text(
                          'Błąd wczytywania ustawień: ${settingsLoadState.error}',
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              TelegramChannelCard(
                                key: _telegramCardKey,
                                studentName: studentName,
                                onFeedback: _setFeedback,
                              ),
                              const SizedBox(height: 16),
                              WebPushChannelCard(
                                studentName: studentName,
                                onFeedback: _setFeedback,
                              ),
                              const SizedBox(height: 16),
                              const NotificationCategoriesCard(),
                            ],
                          ),
                          NotificationAlertsHistoryTab(
                            onFeedback: _setFeedback,
                          ),
                        ],
                      ),
          ),

          // Footer Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    final nav = Navigator.of(context);
                    if (nav.canPop()) nav.pop();
                  },
                  child: const Text('Anuluj', style: TextStyle(fontSize: 12.5)),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const ValueKey('save_notification_settings_button'),
                  onPressed: _isSaving ? null : _handleSaveAndClose,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text(
                    'Zapisz ustawienia',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
