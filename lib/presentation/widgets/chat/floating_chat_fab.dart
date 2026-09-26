import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/family_chat_provider.dart';
import 'floating_chat_panel.dart';

/// Floating Chat & AI Assistant button anchored in the bottom-right corner
/// (`D-01`, `20-UI-SPEC.md`). Does not add an 8th navigation tab.
class FloatingChatFab extends ConsumerWidget {
  final bool isDesktop;

  const FloatingChatFab({
    super.key,
    required this.isDesktop,
  });

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (isDesktop) {
      ref.read(isFloatingChatOpenProvider.notifier).toggle();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: const FloatingChatPanel(isInsideBottomSheet: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(isFloatingChatOpenProvider);
    final unreadCount = ref.watch(familyChatUnreadCountProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _handleTap(context, ref),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0052CC), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3D1E293B),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOpen && isDesktop
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isOpen && isDesktop ? 'Ukryj czat' : 'Czat & AI ✨',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
