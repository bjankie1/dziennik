import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/calendar_browser_helper_stub.dart'
    if (dart.library.js_interop) '../../../../core/utils/calendar_browser_helper_web.dart';

class TelegramStepByStepGuide extends StatelessWidget {
  final String codeHint;
  final VoidCallback onClose;
  final VoidCallback onShowTokenFields;
  final void Function(String message, {bool isError}) onFeedback;

  const TelegramStepByStepGuide({
    super.key,
    required this.codeHint,
    required this.onClose,
    required this.onShowTokenFields,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('telegram_guide_content'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: Color(0xFF0284C7),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Instrukcja krok po kroku: Jak skonfigurować powiadomienia Telegram',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Ukryj instrukcję',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Step 1
          _buildGuideStepItem(
            stepLabel: 'Krok 1',
            title: 'Utwórz własnego bota w @BotFather',
            description:
                'Otwórz rozmowę z oficjalnym botem @BotFather w aplikacji Telegram i wyślij komendę /newbot. '
                'Podaj dowolną nazwę wyświetlaną (np. „Dziennik Szkolny EduSync”), a następnie nazwę użytkownika zakończoną na „bot” (np. EduSyncOskar_bot). '
                'Skopiuj wygenerowany przez @BotFather klucz HTTP API Token (np. 7123456789:AAH...).',
            actions: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('copy_newbot_button'),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: '/newbot'));
                    onFeedback(
                      'Skopiowano komendę "/newbot" do schowka.',
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text(
                    'Kopiuj /newbot',
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
                FilledButton.tonalIcon(
                  key: const ValueKey('open_botfather_button'),
                  onPressed: () {
                    openUrlInBrowser('https://t.me/BotFather');
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text(
                    'Otwórz @BotFather',
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Step 2
          _buildGuideStepItem(
            stepLabel: 'Krok 2',
            title: 'Wklej Token Bota w EduSync',
            description:
                'Rozwiń sekcję „Konfiguracja własnego bota (@BotFather) / Ręczny Chat ID”, wklej skopiowany Telegram Bot Token i kliknij „Zapisz konfigurację” '
                '(EduSync automatycznie pobierze nazwę Twojego bota z Telegram API).',
            actions: OutlinedButton.icon(
              key: const ValueKey('telegram_guide_show_token_field_button'),
              onPressed: onShowTokenFields,
              icon: const Icon(Icons.key_rounded, size: 14),
              label: const Text(
                'Pokaż pole Tokenu poniżej',
                style: TextStyle(fontSize: 11.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Step 3
          _buildGuideStepItem(
            stepLabel: 'Krok 3',
            title: 'Wygeneruj 6-cyfrowy kod i wyślij go SWOJEMU nowemu botowi',
            description:
                'Kliknij „Generuj 6-cyfrowy kod” powyżej, przejdź do okna czatu ze SWOIM nowo utworzonym botem (nie z @BotFather!) i wyślij mu wiadomość /start $codeHint.',
          ),
          const SizedBox(height: 10),

          // Warning Box about "Invalid bot passed"
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uwaga na błąd „Invalid bot passed” — nie wysyłaj kodu do @BotFather!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nie wklejaj komendy „/start KOD” w oknie rozmowy z @BotFather — @BotFather służy wyłącznie do tworzenia botów i odpowie błędem „Invalid bot passed”. '
                        'W wiadomości zwrotnej od @BotFather kliknij link t.me/TwojaNazwaBota_bot, aby przejść do czatu ze SWOIM nowym botem, kliknij „START” na dole ekranu i dopiero tam wyślij „/start KOD”.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Step 4
          _buildGuideStepItem(
            stepLabel: 'Krok 4',
            title: 'Kliknij „Weryfikuj parowanie”',
            description:
                'Wróć do tego okna w EduSync i kliknij przycisk „Weryfikuj parowanie”. '
                'Po pomyślnym połączeniu możesz przetestować powiadomienia przyciskiem „Wyślij test na Telegram”.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStepItem({
    required String stepLabel,
    required String title,
    required String description,
    Widget? actions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              stepLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0369A1),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (actions != null) ...[
                  const SizedBox(height: 8),
                  actions,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
