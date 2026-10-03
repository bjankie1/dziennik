import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/calendar_browser_helper_stub.dart'
    if (dart.library.js_interop) '../../../../core/utils/calendar_browser_helper_web.dart';
import '../../../../domain/models/notification_settings.dart';
import '../../../providers/notification_settings_provider.dart';
import 'notification_section_card.dart';
import 'telegram_step_by_step_guide.dart';

class TelegramChannelCard extends ConsumerStatefulWidget {
  final String studentName;
  final void Function(String message, {bool isError}) onFeedback;

  const TelegramChannelCard({
    super.key,
    required this.studentName,
    required this.onFeedback,
  });

  @override
  ConsumerState<TelegramChannelCard> createState() =>
      TelegramChannelCardState();
}

class TelegramChannelCardState extends ConsumerState<TelegramChannelCard> {
  final TextEditingController _botTokenController = TextEditingController();
  final TextEditingController _botUsernameController = TextEditingController();
  final TextEditingController _manualChatIdController = TextEditingController();

  bool _isGeneratingCode = false;
  bool _isVerifyingCode = false;
  bool _isSendingTelegramTest = false;
  bool _showTelegramGuide = false;
  bool _showAdvancedBotConfig = false;
  bool _controllersInitialized = false;

  @override
  void dispose() {
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

  String _formatPairingCode(String? code) {
    final trimmed = (code ?? '').trim();
    if (trimmed.length == 6) {
      return '${trimmed.substring(0, 3)} ${trimmed.substring(3)}';
    }
    return trimmed;
  }

  Future<void> savePendingConfigIfNeeded() async {
    final settings = ref.read(notificationChannelSettingsProvider).value;
    if (settings == null || !_controllersInitialized) return;

    final token = _botTokenController.text.trim();
    final chatId = _manualChatIdController.text.trim();
    var botUser = _botUsernameController.text.trim().replaceAll('@', '');

    final currentToken = (settings.telegramBotToken ?? '').trim();
    final currentChatId = (settings.telegramChatId ?? '').trim();
    final currentBotUser =
        settings.telegramBotUsername.trim().replaceAll('@', '');

    if (token == currentToken &&
        chatId == currentChatId &&
        (botUser.isEmpty ? 'EduSyncSzkolnyBot' : botUser) == currentBotUser) {
      return;
    }

    final service = ref.read(notificationChannelsServiceProvider);
    if (token.isNotEmpty &&
        (botUser.isEmpty || botUser == 'EduSyncSzkolnyBot')) {
      final resolved = await service.fetchBotUsername(token);
      if (resolved != null && resolved.isNotEmpty) {
        botUser = resolved.trim().replaceAll('@', '');
        if (mounted) {
          _botUsernameController.text = botUser;
        }
      }
    }

    await service.updateSettings(
      familyId: settings.familyId,
      roleKey: settings.roleKey,
      patch: {
        'telegramBotToken': token.isNotEmpty ? token : null,
        'telegramBotUsername':
            botUser.isNotEmpty ? botUser : 'EduSyncSzkolnyBot',
        if (chatId.isNotEmpty) ...{
          'telegramChatId': chatId,
          'telegramEnabled': true,
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final telegramSlice = ref.watch(
      notificationChannelSettingsProvider.select((asyncVal) {
        final s = asyncVal.value;
        if (s == null) return null;
        return (
          familyId: s.familyId,
          roleKey: s.roleKey,
          telegramEnabled: s.telegramEnabled,
          telegramChatId: s.telegramChatId,
          telegramUsername: s.telegramUsername,
          telegramBotToken: s.telegramBotToken,
          telegramBotUsername: s.telegramBotUsername,
          pairingCode: s.pairingCode,
          pairingCodeExpiresAt: s.pairingCodeExpiresAt,
        );
      }),
    );

    if (telegramSlice == null) {
      return const SizedBox.shrink();
    }

    final settings = NotificationChannelSettings(
      familyId: telegramSlice.familyId,
      roleKey: telegramSlice.roleKey,
      telegramEnabled: telegramSlice.telegramEnabled,
      telegramChatId: telegramSlice.telegramChatId,
      telegramUsername: telegramSlice.telegramUsername,
      telegramBotToken: telegramSlice.telegramBotToken,
      telegramBotUsername: telegramSlice.telegramBotUsername,
      pairingCode: telegramSlice.pairingCode,
      pairingCodeExpiresAt: telegramSlice.pairingCodeExpiresAt,
    );
    _syncControllers(settings);

    final service = ref.read(notificationChannelsServiceProvider);

    return NotificationSectionCard(
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
                widget.onFeedback(
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
                      widget.onFeedback('Rozłączono czat Telegram.');
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
                                final token = _botTokenController.text.trim();
                                var currentBotUser = _botUsernameController.text
                                    .trim()
                                    .replaceAll('@', '');
                                if (token.isNotEmpty &&
                                    (currentBotUser.isEmpty ||
                                        currentBotUser ==
                                            'EduSyncSzkolnyBot')) {
                                  final resolved =
                                      await service.fetchBotUsername(token);
                                  if (resolved != null &&
                                      resolved.isNotEmpty) {
                                    currentBotUser =
                                        resolved.trim().replaceAll('@', '');
                                    _botUsernameController.text =
                                        currentBotUser;
                                  }
                                }
                                final code = await service.generatePairingCode(
                                  familyId: settings.familyId,
                                  roleKey: settings.roleKey,
                                  botToken: token,
                                  botUsername: currentBotUser,
                                );
                                widget.onFeedback(
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                              _formatPairingCode(settings.pairingCode),
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
                                widget.onFeedback(
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
                                final rawUser = _botUsernameController.text
                                    .trim()
                                    .replaceAll('@', '');
                                final botUser = rawUser.isNotEmpty
                                    ? rawUser
                                    : settings.telegramBotUsername
                                        .trim()
                                        .replaceAll('@', '');
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
                                  final res = await service.verifyPairingCode(
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
                                    widget.onFeedback(
                                      'Pomyślnie sparowano czat Telegram (${res.username ?? res.chatId}) i wysłano powitanie!',
                                    );
                                  } else {
                                    widget.onFeedback(
                                      res.error ??
                                          'Nie znaleziono wiadomości z kodem.',
                                      isError: true,
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isVerifyingCode = false);
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

          // Step-by-step guide, Advanced configuration (Bot Token / Manual Chat ID) & Test Button
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                key: const ValueKey('telegram_step_by_step_guide_button'),
                onPressed: () {
                  setState(() => _showTelegramGuide = !_showTelegramGuide);
                },
                icon: Icon(
                  _showTelegramGuide
                      ? Icons.expand_less_rounded
                      : Icons.help_outline_rounded,
                  size: 16,
                ),
                label: Text(
                  _showTelegramGuide
                      ? 'Ukryj instrukcję krok po kroku'
                      : 'Instrukcja krok po kroku (Jak połączyć?)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
              if (settings.isTelegramPaired)
                OutlinedButton.icon(
                  onPressed: _isSendingTelegramTest
                      ? null
                      : () async {
                          setState(() => _isSendingTelegramTest = true);
                          try {
                            final ok = await service.sendTestTelegram(
                              settings: settings,
                              studentName: widget.studentName,
                            );
                            if (ok) {
                              widget.onFeedback(
                                'Wysłano testowe powiadomienie na Twój czat Telegram!',
                              );
                            } else {
                              widget.onFeedback(
                                'Nie udało się wysłać wiadomości. Sprawdź Token Bota oraz Chat ID w sekcji konfiguracji.',
                                isError: true,
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isSendingTelegramTest = false);
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

          if (_showTelegramGuide) ...[
            const SizedBox(height: 10),
            TelegramStepByStepGuide(
              codeHint: settings.hasActivePairingCode
                  ? settings.pairingCode!
                  : '123456',
              onClose: () => setState(() => _showTelegramGuide = false),
              onShowTokenFields: () =>
                  setState(() => _showAdvancedBotConfig = true),
              onFeedback: widget.onFeedback,
            ),
          ],

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
                          final chatId = _manualChatIdController.text.trim();
                          var botUser = _botUsernameController.text
                              .trim()
                              .replaceAll('@', '');
                          if (token.isNotEmpty &&
                              (botUser.isEmpty ||
                                  botUser == 'EduSyncSzkolnyBot')) {
                            final resolved =
                                await service.fetchBotUsername(token);
                            if (resolved != null && resolved.isNotEmpty) {
                              botUser = resolved.trim().replaceAll('@', '');
                              _botUsernameController.text = botUser;
                            }
                          }
                          await service.updateSettings(
                            familyId: settings.familyId,
                            roleKey: settings.roleKey,
                            patch: {
                              'telegramBotToken':
                                  token.isNotEmpty ? token : null,
                              'telegramBotUsername': botUser.isNotEmpty
                                  ? botUser
                                  : 'EduSyncSzkolnyBot',
                              if (chatId.isNotEmpty) ...{
                                'telegramChatId': chatId,
                                'telegramEnabled': true,
                              },
                            },
                          );
                          widget.onFeedback(
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
    );
  }
}
