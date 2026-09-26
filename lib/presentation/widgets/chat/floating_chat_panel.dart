import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/auth_providers.dart';
import '../../providers/family_chat_provider.dart';
import '../../screens/chat/family_chat_screen.dart';
import 'ai_assistant_chat_view.dart';

/// Segmented mode switcher bar (`👨‍👦 Czat: Oskar / Tata` ↔ `✨ Asystent AI`)
/// shared between [FloatingChatPanel] and [FamilyChatScreen] (`D-02`, `20-UI-SPEC.md`).
class ChatModeSegmentedSwitcher extends ConsumerWidget {
  final bool compact;

  const ChatModeSegmentedSwitcher({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMode = ref.watch(activeChatModeProvider);
    final isStudent = ref.watch(appUserProvider)?.isStudent ?? false;
    final unreadFamilyCount = ref.watch(familyChatUnreadCountProvider);
    final familyLabel = isStudent ? '👨‍👦 Czat: Tata' : '👨‍👦 Czat: Oskar';

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentButton(
            selected: activeMode == ChatWorkspaceMode.family,
            label: familyLabel,
            badgeCount: unreadFamilyCount,
            compact: compact,
            isAi: false,
            onTap: () {
              ref
                  .read(activeChatModeProvider.notifier)
                  .setMode(ChatWorkspaceMode.family);
            },
          ),
          const SizedBox(width: 4),
          _buildSegmentButton(
            selected: activeMode == ChatWorkspaceMode.aiAssistant,
            label: '✨ Asystent AI',
            badgeCount: 0,
            compact: compact,
            isAi: true,
            onTap: () {
              ref
                  .read(activeChatModeProvider.notifier)
                  .setMode(ChatWorkspaceMode.aiAssistant);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required bool selected,
    required String label,
    required int badgeCount,
    required bool compact,
    required bool isAi,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          gradient: (selected && isAi)
              ? const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                )
              : null,
          color: selected
              ? (isAi ? null : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w700,
                color: selected
                    ? (isAi ? Colors.white : const Color(0xFF0F172A))
                    : const Color(0xFF64748B),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Floating dual-mode chat window (`400x580` card on desktop, `88%` modal bottom sheet on mobile)
/// providing instant access to both Family Chat and the Gemini AI Assistant (`D-01`, `D-02`).
class FloatingChatPanel extends ConsumerWidget {
  final bool isInsideBottomSheet;

  const FloatingChatPanel({
    super.key,
    this.isInsideBottomSheet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMode = ref.watch(activeChatModeProvider);

    return Material(
      color: Colors.white,
      elevation: isInsideBottomSheet ? 0 : 16,
      shadowColor: const Color(0x330F172A),
      borderRadius: isInsideBottomSheet
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: isInsideBottomSheet ? double.infinity : 410,
        height: isInsideBottomSheet
            ? MediaQuery.of(context).size.height * 0.86
            : 580,
        decoration: BoxDecoration(
          border: isInsideBottomSheet
              ? null
              : Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: isInsideBottomSheet
              ? const BorderRadius.vertical(top: Radius.circular(24))
              : BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            if (isInsideBottomSheet)
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // Top bar with Segmented Mode Switcher + Expand + Close
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ChatModeSegmentedSwitcher(compact: true),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Otwórz na pełnym ekranie (/czat)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      if (isInsideBottomSheet && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      ref.read(isFloatingChatOpenProvider.notifier).close();
                      context.go('/czat');
                    },
                    icon: const Icon(
                      Icons.open_in_full_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Zamknij okno czatu',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      if (isInsideBottomSheet && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        ref.read(isFloatingChatOpenProvider.notifier).close();
                      }
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),

            // Active view body
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: activeMode == ChatWorkspaceMode.aiAssistant
                    ? AiAssistantChatView(
                        key: const ValueKey('ai_chat_view'),
                        isInsideBottomSheet: isInsideBottomSheet,
                      )
                    : const FamilyChatScreen(
                        key: ValueKey('family_chat_view'),
                        embeddedInPanel: true,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
