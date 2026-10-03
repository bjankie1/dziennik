import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/ai_chat_message.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/auth_providers.dart';
import '../../providers/school_providers.dart';
import 'ai_source_citations_row.dart';

/// Conversational AI Assistant view (`✨ Asystent AI`) supporting:
/// - Gemini 3 model switcher (`⚡ 3.8 Flash` ↔ `🧠 3.1 Pro`)
/// - Starter prompt chips (`Kiedy jest następny sprawdzian?`, `Kiedy jest wycieczka Oskara do Warszawy?`, `Kiedy jest zebranie z rodzicami?`)
/// - Markdown bold formatting, clickable source citations & calendar/task quick actions
/// - Per-role Firestore conversation history & "Wyczyść czat" action (`20-UI-SPEC.md`).
class AiAssistantChatView extends ConsumerStatefulWidget {
  final bool isInsideBottomSheet;

  const AiAssistantChatView({
    super.key,
    this.isInsideBottomSheet = false,
  });

  @override
  ConsumerState<AiAssistantChatView> createState() =>
      _AiAssistantChatViewState();
}

class _AiAssistantChatViewState extends ConsumerState<AiAssistantChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<String> _starterPrompts = [
    '📅 Kiedy jest następny sprawdzian?',
    '🚌 Kiedy jest wycieczka Oskara do Warszawy?',
    '👨‍🏫 Kiedy jest zebranie z rodzicami?',
    '🎓 Jakie oceny Oskar dostał ostatnio?',
    '📋 Czy są nieusprawiedliwione nieobecności?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _submitQuestion([String? presetQuestion]) async {
    final raw = presetQuestion ?? _controller.text;
    final clean = raw
        .replaceFirst(RegExp(r'^[📅🚌👨‍🏫🎓📋]\s*'), '')
        .trim();
    if (clean.isEmpty) return;

    if (presetQuestion == null) {
      _controller.clear();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    await ref.read(aiChatActionsProvider).askQuestion(clean);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wyczyścić historię rozmowy?'),
        content: const Text(
          'Wszystkie dotychczasowe pytania i odpowiedzi Asystenta AI dla Twojej roli zostaną usunięte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Wyczyść czat'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(aiChatActionsProvider).clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(aiChatMessagesProvider);
    final isLoading = ref.watch(aiAssistantLoadingProvider);
    final selectedModel = ref.watch(selectedAiModelProvider);
    final isStudent = ref.watch(appUserProvider)?.isStudent ?? false;
    final schoolMsgsCount = ref.watch(messagesProvider).value?.length ?? 0;

    return Column(
      children: [
        // Sub-header: Model selector chip + indexed messages indicator + Clear chat button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          child: Row(
            children: [
              PopupMenuButton<AiModelTier>(
                tooltip: 'Wybierz model językowy Gemini',
                initialValue: selectedModel,
                onSelected: (tier) {
                  ref.read(selectedAiModelProvider.notifier).selectModel(tier);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                itemBuilder: (context) => AiModelTier.values.map((tier) {
                  final isSelected = tier == selectedModel;
                  return PopupMenuItem<AiModelTier>(
                    value: tier,
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 18,
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tier.fullLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                tier.subtitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedModel.shortLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: Color(0xFF4338CA),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  schoolMsgsCount > 0
                      ? 'Indeks: plan, oceny + $schoolMsgsCount wiad.'
                      : 'Indeks: pełny dziennik Librus',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _confirmClearHistory(context),
                tooltip: 'Wyczyść historię rozmowy',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  size: 19,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // Conversation message list or Empty Welcome State
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nie udało się wczytać historii czatu AI: $err',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty && !isLoading) {
                  return _buildWelcomeEmptyState(isStudent);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return _buildTypingIndicatorBubble(selectedModel);
                    }
                    final msg = messages[index];
                    return _buildMessageBubble(context, msg);
                  },
                );
              },
            ),
          ),
        ),

        // Quick prompt chips strip when conversation is active
        if ((messagesAsync.value?.isNotEmpty ?? false) && !isLoading)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _starterPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(prompt),
                      onPressed: () => _submitQuestion(prompt),
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        // Bottom composer bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitQuestion(),
                  decoration: InputDecoration(
                    hintText:
                        'Zapytaj o sprawdziany, wycieczki, oceny, zebrania...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: isLoading ? null : () => _submitQuestion(),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(11),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 19),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeEmptyState(bool isStudent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x334F46E5),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isStudent
                ? 'Cześć Oskar! Zapytaj o swój dziennik ✨'
                : 'Asystent AI dziennika Oskara ✨',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Znam plan lekcji, terminarz sprawdzianów, oceny, frekwencję oraz pełną treść wiadomości od nauczycieli (wycieczki, zebrania, ogłoszenia).',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'PRZYKŁADOWE PYTANIA:',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._starterPrompts.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _submitQuestion(prompt),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          prompt,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTypingIndicatorBubble(AiModelTier selectedModel) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Asystent AI (${selectedModel.shortLabel}) przeszukuje dziennik...',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, AiChatMessage msg) {
    final isUser = msg.isUser;
    final timeStr = DateFormat('HH:mm').format(msg.timestamp);

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                msg.text,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isError ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: msg.isError
                ? const Color(0xFFFECACA)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Asystent AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                if (msg.modelUsed != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '• ${msg.modelUsed!.contains('lokalny') ? 'Lokalny indeks' : (msg.modelUsed!.contains('pro') ? '3.1 Pro' : '3.8 Flash')}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildFormattedMarkdownText(msg.text),
            AiSourceCitationsRow(
              message: msg,
              closeBottomSheetOnNavigate: widget.isInsideBottomSheet,
            ),
          ],
        ),
      ),
    );
  }

  /// Renders inline `**bold**` Markdown spans cleanly inside AI responses.
  Widget _buildFormattedMarkdownText(String rawText) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in pattern.allMatches(rawText)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: rawText.substring(lastEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < rawText.length) {
      spans.add(TextSpan(text: rawText.substring(lastEnd)));
    }

    return SelectableText.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF1E293B),
          height: 1.42,
        ),
        children: spans,
      ),
    );
  }
}
