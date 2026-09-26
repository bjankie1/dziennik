import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/chat_message.dart';
import '../../../domain/models/justification_request.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/auth_providers.dart';
import '../../providers/family_chat_provider.dart';
import '../../providers/school_providers.dart';
import '../../widgets/chat/ai_assistant_chat_view.dart';
import '../../widgets/chat/floating_chat_panel.dart';
import '../attendance/widgets/student_response_modal.dart';

/// Screen providing real-time family chat between student and parent
/// with embedded interactive justification cards and a dual-mode switcher
/// to the Gemini AI Assistant (`REQ-CHAT-01`, `REQ-AI-01`, `D-01`, `D-02`).
class FamilyChatScreen extends ConsumerStatefulWidget {
  final bool embeddedInPanel;

  const FamilyChatScreen({
    super.key,
    this.embeddedInPanel = false,
  });

  @override
  ConsumerState<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends ConsumerState<FamilyChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markRead();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markRead() {
    final user = ref.read(appUserProvider);
    final familyId = user?.familyId ?? 'jankiewicz_family';
    final isStudent = user?.isStudent ?? false;
    ref.read(familyChatRepositoryProvider).markMessagesAsRead(
          familyId: familyId,
          isStudent: isStudent,
        );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend([String? textToSend]) async {
    final text = (textToSend ?? _textController.text).trim();
    if (text.isEmpty || _isSending) return;

    final user = ref.read(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final familyId = user?.familyId ?? 'jankiewicz_family';
    final senderId = isStudent ? (user?.studentLogin ?? '1234567u') : 'parent_tata';
    final senderName = isStudent ? 'Oskar' : 'Tata';
    final senderRole = isStudent ? 'student' : 'parent';

    setState(() => _isSending = true);
    if (textToSend == null) _textController.clear();

    final repo = ref.read(familyChatRepositoryProvider);
    await repo.sendMessage(
      familyId: familyId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      text: text,
    );

    if (mounted) {
      setState(() => _isSending = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Widget _buildFamilyChatBody(
    BuildContext context,
    AsyncValue<List<ChatMessage>> messagesAsync,
    bool isStudent,
    String otherRoleLabel,
  ) {
    return Column(
      children: [
        // Message stream
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Błąd ładowania wiadomości: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markRead();
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Brak wiadomości w czacie rodzinnym',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Napisz pierwszą wiadomość do ${isStudent ? 'Taty' : 'Oskara'} poniżej.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe =
                        isStudent ? msg.isStudentSender : msg.isParentSender;
                    return _buildMessageRow(context, msg, isMe, isStudent);
                  },
                );
              },
            ),
          ),
        ),

        // Quick suggestions bar
        _buildQuickSuggestions(isStudent),

        // Message input composer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration(
                    hintText: 'Napisz wiadomość do $otherRoleLabel...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                onPressed: _isSending ? null : () => _handleSend(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final otherRoleLabel = isStudent ? 'Tata' : 'Oskar';
    final messagesAsync = ref.watch(familyChatMessagesProvider);

    if (widget.embeddedInPanel) {
      return _buildFamilyChatBody(
        context,
        messagesAsync,
        isStudent,
        otherRoleLabel,
      );
    }

    final activeMode = ref.watch(activeChatModeProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    final content = Column(
      children: [
        // Chat room header with segmented Family Chat ↔ AI Assistant switcher (D-02)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isDesktop)
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/pulpit'),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF475569),
                      ),
                    ),
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: activeMode == ChatWorkspaceMode.aiAssistant
                        ? const Color(0xFFEEF2FF)
                        : (isStudent
                            ? const Color(0xFFDBEAFE)
                            : const Color(0xFFDCFCE7)),
                    child: Icon(
                      activeMode == ChatWorkspaceMode.aiAssistant
                          ? Icons.auto_awesome_rounded
                          : (isStudent
                              ? Icons.person_rounded
                              : Icons.school_rounded),
                      color: activeMode == ChatWorkspaceMode.aiAssistant
                          ? const Color(0xFF4F46E5)
                          : (isStudent
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF15803D)),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeMode == ChatWorkspaceMode.aiAssistant
                            ? 'Asystent AI Dziennika • Oskar'
                            : 'Czat rodzinny • $otherRoleLabel',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: activeMode == ChatWorkspaceMode.aiAssistant
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            activeMode == ChatWorkspaceMode.aiAssistant
                                ? 'Pełny kontekst ocen, planu i wiadomości Librus'
                                : 'Aktywny w aplikacji',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const ChatModeSegmentedSwitcher(),
            ],
          ),
        ),

        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: activeMode == ChatWorkspaceMode.aiAssistant
                ? const AiAssistantChatView(key: ValueKey('full_ai_view'))
                : _buildFamilyChatBody(
                    context,
                    messagesAsync,
                    isStudent,
                    otherRoleLabel,
                  ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: !isDesktop,
        bottom: true,
        child: content,
      ),
    );
  }

  Widget _buildQuickSuggestions(bool isStudent) {
    final suggestions = isStudent
        ? [
            'Wracam ze szkoły do domu 🚌',
            'Będę 15 minut później',
            'Dostałem dobrą ocenę! 🎉',
          ]
        : [
            'O której dzisiaj kończysz?',
            'Pamiętaj o obiedzie 🍲',
            'Wszystko w porządku w szkole?',
          ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((chipText) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(chipText),
                onPressed: () => _handleSend(chipText),
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                backgroundColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageRow(BuildContext context, ChatMessage msg, bool isMe, bool isStudent) {
    final timeStr = DateFormat('HH:mm').format(msg.createdAt);

    if (msg.isJustificationCard) {
      return _buildJustificationCardBubble(context, msg, isStudent);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  msg.senderName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : const Color(0xFF1E293B),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all_rounded, size: 12, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJustificationCardBubble(BuildContext context, ChatMessage msg, bool isStudent) {
    final meta = msg.metadata ?? {};
    final requestId = meta['requestId']?.toString() ?? '';
    final studentReason = meta['studentReason']?.toString() ?? '';
    final rejectionReason = meta['rejectionReason']?.toString() ?? msg.text;
    final dateStr = meta['date']?.toString() ?? '';
    final lessonNumbers = meta['lessonNumbers'] is List ? (meta['lessonNumbers'] as List).join(', ') : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_late_outlined, color: Color(0xFFB45309), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wniosek o usprawiedliwienie odrzucony',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        'Data: $dateStr ${lessonNumbers.isNotEmpty ? "• Lekcje: $lessonNumbers" : ""}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Wymaga wyjaśnienia',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
                ),
              ),
            ],
          ),
          if (studentReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Powód Oskara: „$studentReason”',
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              'Komentarz rodzica: „$rejectionReason”',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF78350F)),
            ),
          ),
          if (isStudent && requestId.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: FilledButton.icon(
                onPressed: () {
                  final dummyReq = JustificationRequest(
                    id: requestId,
                    studentLogin: '1234567u',
                    studentName: 'Oskar Jankiewicz',
                    recordIds: const [],
                    reason: studentReason,
                    rejectionReason: rejectionReason,
                    status: JustificationRequestStatus.rejected,
                    requestedAt: DateTime.now(),
                  );

                  StudentResponseModal.show(
                    context,
                    dummyReq,
                    onRespond: (responseText) async {
                      final ok = await ref
                          .read(attendanceProvider.notifier)
                          .respondToJustification(requestId, responseText);
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Twoje wyjaśnienie zostało wysłane rodzicowi.'),
                            backgroundColor: Color(0xFF2563EB),
                          ),
                        );
                      }
                      return ok;
                    },
                  );
                },
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: const Text(
                  'Odpowiedz i poproś ponownie',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
