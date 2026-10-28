import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/student_profile.dart';
import '../providers/family_chat_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/school_providers.dart';
import 'chat/floating_chat_panel.dart';
import 'modals/librus_query_log_modal.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final StudentProfile student;
  final String currentSectionTitle;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const AppHeader({
    super.key,
    required this.student,
    required this.currentSectionTitle,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final unreadMessagesCount = ref.watch(unreadMessagesCountProvider);
    final chatUnreadCount = ref.watch(familyChatUnreadCountProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Logo
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primaryContainer,
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Student Info & Screen Title
              Expanded(
                child: InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              student.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.expand_more,
                            size: 16,
                            color: AppColors.outline,
                          ),
                        ],
                      ),
                      Text(
                        '${student.className} • $currentSectionTitle',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              // Manual Sync Action
              IconButton(
                tooltip: 'Synchronizuj z Librusem (ostatnia: ${syncState.formattedLastSync})',
                onPressed: syncState.isSyncing
                    ? null
                    : () async {
                        await ref.read(syncProvider.notifier).syncNow();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Zsynchronizowano z Librusem (${ref.read(syncProvider).formattedLastSync})'),
                                ],
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                icon: syncState.isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(
                        Icons.sync,
                        color: AppColors.primary,
                        size: 22,
                      ),
              ),

              // Technical Librus Access Log
              IconButton(
                tooltip: 'Dziennik zapytań Librus (Access Log)',
                onPressed: () => LibrusQueryLogModal.show(context),
                icon: const Icon(
                  Icons.terminal_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 21,
                ),
              ),

              // Family Chat & AI Assistant Action with Badge (D-09)
              IconButton(
                tooltip: 'Czat & AI ✨',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(ctx).viewInsets.bottom,
                      ),
                      child: const FloatingChatPanel(isInsideBottomSheet: true),
                    ),
                  );
                },
                icon: Badge(
                  isLabelVisible: chatUnreadCount > 0,
                  label: Text('$chatUnreadCount'),
                  backgroundColor: AppColors.error,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0052CC), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Notifications Action with Badge
              IconButton(
                onPressed: onNotificationsTap,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_outlined,
                      color: AppColors.onSurface,
                      size: 24,
                    ),
                    if (unreadMessagesCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadMessagesCount',
                            style: const TextStyle(
                              color: AppColors.onError,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Profile Avatar
              InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceContainerHigh, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.primaryFixed,
                    backgroundImage: const AssetImage('assets/images/avatar.png'),
                    child: Text(
                      student.name.isNotEmpty ? student.name[0] : 'U',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
