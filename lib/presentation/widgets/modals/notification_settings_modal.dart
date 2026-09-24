import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/calendar_browser_helper_stub.dart'
    if (dart.library.js_interop) '../../../core/utils/calendar_browser_helper_web.dart';
import '../../../domain/models/notification_settings.dart';
import '../../providers/notification_settings_provider.dart';
import '../../providers/school_providers.dart';

class NotificationSettingsModal extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const NotificationSettingsModal({
    super.key,
    this.initialTabIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    int initialTabIndex = 0,
  }) {
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
  late TabController _tabController;
  final TextEditingController _botTokenController = TextEditingController();
  final TextEditingController _botUsernameController = TextEditingController();
  final TextEditingController _manualChatIdController = TextEditingController();

  bool _isGeneratingCode = false;
  bool _isVerifyingCode = false;
  bool _isSendingTelegramTest = false;
  bool _showAdvancedBotConfig = false;
  bool _controllersInitialized = false;
  String? _statusMessage;
  bool _statusIsError = false;

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
    _botTokenController.dispose();
    _botUsernameController.dispose();
    _manualChatIdController.dispose();
    super.dispose();
  }

  void _syncControllers(NotificationChannelSettings settings) {
    if (_controllersInitialized) return;
    _botTokenController.text = settings.telegramBotToken ?? '';
    _botUsernameController.text = settings.telegramBotUsername;
    _manualChatIdController.text = settings.telegramChatId ?? '';
    _controllersInitialized = true;
  }

  void _setFeedback(String msg, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _statusMessage = msg;
      _statusIsError = isError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationChannelSettingsProvider);
    final notificationsAsync = ref.watch(schoolNotificationsStreamProvider);
    final student = ref.watch(studentProfileProvider).value;
    final studentName = student?.name.split(' ').first ?? 'Oskar';
    final roleKey = ref.watch(notificationRoleKeyProvider);
    final isStudent = roleKey == 'student';

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
                      onPressed: () => Navigator.of(context).pop(),
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
                      text:
                          'Ostatnie alerty (${notificationsAsync.value?.length ?? 0})',
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
            child: settingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Błąd wczytywania ustawień: $err'),
              ),
              data: (settings) {
                _syncControllers(settings);
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChannelsTab(context, settings, studentName),
                    _buildAlertsHistoryTab(
                      context,
                      settings,
                      notificationsAsync.value ?? const [],
                      studentName,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsTab(
    BuildContext context,
    NotificationChannelSettings settings,
    String studentName,
  ) {
    final service = ref.read(notificationChannelsServiceProvider);
    final browserPerm = service.getWebPushPermission();
    final swActive = service.isSwActive();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. TELEGRAM BOT CARD
        _buildSectionCard(
          icon: Icons.send_rounded,
          iconBg: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF0284C7),
          title: 'Telegram Bot (Powiadomienia natychmiastowe)',
          subtitle:
              'Otrzymuj nowe oceny, wiadomości i sprawdziany bezpośrednio na czacie Telegram',
          badgeText: settings.isTelegramPaired
              ? 'Połączono (${settings.telegramUsername ?? settings.telegramChatId})'
              : 'Niepołączono',
          badgeColor: settings.isTelegramPaired
              ? const Color(0xFF15803D)
              : const Color(0xFFB45309),
          badgeBg: settings.isTelegramPaired
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFFEF3C7),
          trailing: settings.isTelegramPaired
              ? Switch(
                  value: settings.telegramEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) async {
                    await service.updateSettings(
                      familyId: settings.familyId,
                      roleKey: settings.roleKey,
                      patch: {'telegramEnabled': val},
                    );
                    _setFeedback(
                      val
                          ? 'Włączono powiadomienia Telegram.'
                          : 'Wstrzymano powiadomienia Telegram.',
                    );
                  },
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (settings.isTelegramPaired) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Konto powiązane z czatem Telegram ID: ${settings.telegramChatId}'
                          '${settings.telegramUsername != null ? " (@${settings.telegramUsername})" : ""}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await service.disconnectTelegram(
                            familyId: settings.familyId,
                            roleKey: settings.roleKey,
                          );
                          _setFeedback('Rozłączono czat Telegram.');
                        },
                        icon: const Icon(
                          Icons.link_off,
                          size: 16,
                          color: AppColors.error,
                        ),
                        label: const Text(
                          'Rozłącz',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 6-digit Pairing Code Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Parowanie 6-cyfrowym kodem jednorazowym',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _isGeneratingCode
                              ? null
                              : () async {
                                  setState(() => _isGeneratingCode = true);
                                  try {
                                    final code =
                                        await service.generatePairingCode(
                                      familyId: settings.familyId,
                                      roleKey: settings.roleKey,
                                      botToken: _botTokenController.text,
                                      botUsername: _botUsernameController.text,
                                    );
                                    _setFeedback(
                                      'Wygenerowano 6-cyfrowy kod parowania: $code (ważny 15 minut).',
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isGeneratingCode = false);
                                    }
                                  }
                                },
                          icon: _isGeneratingCode
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(
                            settings.hasActivePairingCode
                                ? 'Nowy kod'
                                : 'Generuj 6-cyfrowy kod',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (settings.hasActivePairingCode) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TWÓJ KOD PAROWANIA (15 MIN):',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  '${settings.pairingCode!.substring(0, 3)} ${settings.pairingCode!.substring(3)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3,
                                    color: AppColors.primary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: '/start ${settings.pairingCode}',
                                      ),
                                    );
                                    _setFeedback(
                                      'Skopiowano komendę "/start ${settings.pairingCode}" do schowka.',
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 15),
                                  label: Text(
                                    'Kopiuj /start ${settings.pairingCode}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: () {
                                    final botUser = _botUsernameController.text
                                            .trim()
                                            .isNotEmpty
                                        ? _botUsernameController.text
                                            .trim()
                                            .replaceAll('@', '')
                                        : settings.telegramBotUsername;
                                    openUrlInBrowser(
                                      'https://t.me/$botUser?start=${settings.pairingCode}',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 15,
                                  ),
                                  label: const Text(
                                    'Otwórz Telegram',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Krok 2: Po wysłaniu komendy /start do bota w Telegramie kliknij przycisk obok, aby powiązać czat:',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                            ),
                            onPressed: _isVerifyingCode
                                ? null
                                : () async {
                                    setState(() => _isVerifyingCode = true);
                                    try {
                                      final res =
                                          await service.verifyPairingCode(
                                        familyId: settings.familyId,
                                        roleKey: settings.roleKey,
                                        pairingCode: settings.pairingCode!,
                                        botToken:
                                            _botTokenController.text.isNotEmpty
                                                ? _botTokenController.text
                                                : settings.telegramBotToken,
                                      );
                                      if (res.paired) {
                                        _manualChatIdController.text =
                                            res.chatId ?? '';
                                        _setFeedback(
                                          'Pomyślnie sparowano czat Telegram (${res.username ?? res.chatId}) i wysłano powitanie!',
                                        );
                                      } else {
                                        _setFeedback(
                                          res.error ??
                                              'Nie znaleziono wiadomości z kodem.',
                                          isError: true,
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(
                                          () => _isVerifyingCode = false,
                                        );
                                      }
                                    }
                                  },
                            icon: _isVerifyingCode
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_outline,
                                    size: 16,
                                  ),
                            label: const Text(
                              'Weryfikuj parowanie',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Kliknij „Generuj 6-cyfrowy kod”, a następnie wyślij go botowi na Telegramie komendą /start KOD.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Advanced configuration (Bot Token / Manual Chat ID) & Test Button
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(
                        () => _showAdvancedBotConfig = !_showAdvancedBotConfig,
                      );
                    },
                    icon: Icon(
                      _showAdvancedBotConfig
                          ? Icons.expand_less
                          : Icons.settings_ethernet_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _showAdvancedBotConfig
                          ? 'Ukryj konfigurację Tokenu / Chat ID'
                          : 'Konfiguracja własnego bota (@BotFather) / Ręczny Chat ID',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  if (settings.isTelegramPaired)
                    OutlinedButton.icon(
                      onPressed: _isSendingTelegramTest
                          ? null
                          : () async {
                              setState(() => _isSendingTelegramTest = true);
                              try {
                                final ok = await service.sendTestTelegram(
                                  settings: settings,
                                  studentName: studentName,
                                );
                                if (ok) {
                                  _setFeedback(
                                    'Wysłano testowe powiadomienie na Twój czat Telegram!',
                                  );
                                } else {
                                  _setFeedback(
                                    'Nie udało się wysłać wiadomości. Sprawdź Token Bota oraz Chat ID w sekcji konfiguracji.',
                                    isError: true,
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(
                                    () => _isSendingTelegramTest = false,
                                  );
                                }
                              }
                            },
                      icon: _isSendingTelegramTest
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined, size: 15),
                      label: const Text(
                        'Wyślij test na Telegram',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),

              if (_showAdvancedBotConfig) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Własny Bot Telegram (@BotFather) lub bezpośredni Chat ID',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Wklej Token HTTP API bota z @BotFather (np. 123456:ABC-DEF...) oraz opcjonalnie swój Chat ID, aby natychmiast odbierać powiadomienia.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _botTokenController,
                              decoration: InputDecoration(
                                labelText: 'Telegram Bot Token (@BotFather)',
                                hintText: 'np. 7123456789:AAH...',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _manualChatIdController,
                              decoration: InputDecoration(
                                labelText: 'Telegram Chat ID',
                                hintText: 'np. 123456789',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _botUsernameController,
                              decoration: InputDecoration(
                                labelText: 'Nazwa bota (bez @)',
                                hintText: 'EduSyncSzkolnyBot',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () async {
                              final token = _botTokenController.text.trim();
                              final chatId =
                                  _manualChatIdController.text.trim();
                              final botUser =
                                  _botUsernameController.text.trim();
                              await service.updateSettings(
                                familyId: settings.familyId,
                                roleKey: settings.roleKey,
                                patch: {
                                  'telegramBotToken':
                                      token.isNotEmpty ? token : null,
                                  'telegramBotUsername': botUser.isNotEmpty
                                      ? botUser.replaceAll('@', '')
                                      : 'EduSyncSzkolnyBot',
                                  if (chatId.isNotEmpty) ...{
                                    'telegramChatId': chatId,
                                    'telegramEnabled': true,
                                  },
                                },
                              );
                              _setFeedback(
                                'Zapisano konfigurację bota Telegram${chatId.isNotEmpty ? " i aktywowano czat $chatId" : ""}.',
                              );
                            },
                            icon: const Icon(Icons.save_outlined, size: 16),
                            label: const Text(
                              'Zapisz konfigurację',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. WEB PUSH CARD
        _buildSectionCard(
          icon: Icons.web_asset_rounded,
          iconBg: const Color(0xFFEDE9FE),
          iconColor: const Color(0xFF6D28D9),
          title: 'Powiadomienia Web Push w przeglądarce',
          subtitle:
              'Natywne powiadomienia systemowe (macOS / Windows / Android / iOS) przez Service Worker',
          badgeText: browserPerm == 'granted' && settings.webPushEnabled
              ? 'Aktywne (SW Ready)'
              : browserPerm == 'denied'
                  ? 'Zablokowane w przeglądarce'
                  : 'Nieaktywne',
          badgeColor: browserPerm == 'granted' && settings.webPushEnabled
              ? const Color(0xFF15803D)
              : browserPerm == 'denied'
                  ? AppColors.error
                  : const Color(0xFF6D28D9),
          badgeBg: browserPerm == 'granted' && settings.webPushEnabled
              ? const Color(0xFFDCFCE7)
              : browserPerm == 'denied'
                  ? AppColors.errorContainer
                  : const Color(0xFFEDE9FE),
          trailing: Switch(
            value: settings.webPushEnabled && browserPerm == 'granted',
            activeThumbColor: AppColors.primary,
            onChanged: (val) async {
              if (val) {
                final perm = await service.requestAndEnableWebPush(
                  familyId: settings.familyId,
                  roleKey: settings.roleKey,
                );
                if (perm == 'granted') {
                  _setFeedback(
                    'Włączono powiadomienia Web Push w przeglądarce!',
                  );
                } else {
                  _setFeedback(
                    'Przeglądarka nie udzieliła zgody na powiadomienia (status: $perm). Odblokuj powiadomienia obok paska adresu.',
                    isError: true,
                  );
                }
              } else {
                await service.updateSettings(
                  familyId: settings.familyId,
                  roleKey: settings.roleKey,
                  patch: {'webPushEnabled': false},
                );
                _setFeedback('Wyłączono powiadomienia Web Push.');
              }
              setState(() {});
            },
          ),
          child: Row(
            children: [
              Icon(
                swActive ? Icons.check_circle : Icons.info_outline,
                size: 16,
                color:
                    swActive ? const Color(0xFF15803D) : AppColors.onSurfaceVariant,
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
                      familyId: settings.familyId,
                      roleKey: settings.roleKey,
                    );
                    if (perm != 'granted') {
                      _setFeedback(
                        'Najpierw zezwól na powiadomienia w przeglądarce.',
                        isError: true,
                      );
                      return;
                    }
                  }
                  final ok = service.triggerWebPush(
                    title: '🎓 EduSync • Nowa ocena: 5 (Język angielski)',
                    body:
                        'Uczeń: $studentName • Kategoria: Sprawdzian (Waga 3) • Kliknij, aby otworzyć Oceny.',
                    tag: 'edusync-test-webpush',
                    url: '/oceny',
                  );
                  if (ok) {
                    _setFeedback(
                      'Wyświetlono natywne powiadomienie Web Push w przeglądarce!',
                    );
                  } else {
                    _setFeedback(
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
        ),

        const SizedBox(height: 16),

        // 3. EVENT CATEGORIES CARD
        _buildSectionCard(
          icon: Icons.category_outlined,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          title: 'Kategorie powiadomień (Filtry zdarzeń)',
          subtitle:
              'Wybierz, o jakich zdarzeniach szkolnych chcesz otrzymywać alerty na Telegram i Web Push',
          child: Column(
            children: [
              _buildCategoryToggle(
                icon: Icons.verified_outlined,
                title: 'Nowe oceny i średnie',
                subtitle:
                    'Przedmiot, stopień, waga oceny, kategoria oraz nauczyciel',
                value: settings.notifyGrades,
                onChanged: (val) => service.updateSettings(
                  familyId: settings.familyId,
                  roleKey: settings.roleKey,
                  patch: {'notifyGrades': val},
                ),
              ),
              const Divider(height: 1),
              _buildCategoryToggle(
                icon: Icons.mail_outline_rounded,
                title: 'Nowe wiadomości i ogłoszenia z Librusa',
                subtitle:
                    'Powiadomienia o nowych wiadomościach od nauczycieli i wychowawcy',
                value: settings.notifyMessages,
                onChanged: (val) => service.updateSettings(
                  familyId: settings.familyId,
                  roleKey: settings.roleKey,
                  patch: {'notifyMessages': val},
                ),
              ),
              const Divider(height: 1),
              _buildCategoryToggle(
                icon: Icons.event_note_rounded,
                title: 'Nadchodzące sprawdziany i kartkówki',
                subtitle:
                    'Nowe wpisy w terminarzu sprawdzianów wraz z zakresem materiału',
                value: settings.notifyExams,
                onChanged: (val) => service.updateSettings(
                  familyId: settings.familyId,
                  roleKey: settings.roleKey,
                  patch: {'notifyExams': val},
                ),
              ),
              const Divider(height: 1),
              _buildCategoryToggle(
                icon: Icons.forum_outlined,
                title: 'Czat rodzinny i wnioski o e-usprawiedliwienie',
                subtitle:
                    'Nowe wiadomości od rodzica/ucznia oraz prośby o akceptację usprawiedliwienia',
                value: settings.notifyFamilyChat,
                onChanged: (val) => service.updateSettings(
                  familyId: settings.familyId,
                  roleKey: settings.roleKey,
                  patch: {'notifyFamilyChat': val},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsHistoryTab(
    BuildContext context,
    NotificationChannelSettings settings,
    List<SchoolNotificationItem> items,
    String studentName,
  ) {
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

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final (icon, color, route) = switch (item.type) {
          'grade' => (Icons.school_rounded, const Color(0xFF2563EB), '/oceny'),
          'message' ||
          'announcement' =>
            (Icons.mail_rounded, const Color(0xFF0284C7), '/wiadomosci'),
          'exam' => (
              Icons.event_available_rounded,
              const Color(0xFFD97706),
              '/plan-lekcji'
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
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
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
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
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
                      DateFormat('dd.MM.yyyy HH:mm').format(item.timestamp),
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
                  Navigator.of(context).pop();
                  context.go(route);
                },
                child: const Text('Otwórz', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBg,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
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
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      secondary: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
