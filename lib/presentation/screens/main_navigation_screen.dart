import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/attendance_record.dart';
import '../providers/school_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/sync_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_desktop_header.dart';
import 'dashboard/dashboard_screen.dart';
import 'grades/grades_screen.dart';
import 'schedule/schedule_screen.dart';
import 'attendance/attendance_screen.dart';
import 'messages/messages_screen.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  static const _screenTitles = [
    'Dashboard',
    'Plan Lekcji',
    'Oceny',
    'Frekwencja',
    'Wiadomości',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentNavIndexProvider);
    final studentAsync = ref.watch(studentProfileProvider);
    final attendanceAsync = ref.watch(attendanceProvider);
    final messagesAsync = ref.watch(messagesProvider);

    // Unexcused absences count for Frekwencja badge
    final unexcusedCount = (attendanceAsync.value ?? [])
        .where((r) => r.type == AttendanceType.absent && r.justificationStatus == JustificationStatus.none)
        .length;

    // Unread messages count for Wiadomości badge
    final messageBadgeCount = messagesAsync.hasValue
        ? (messagesAsync.value ?? []).where((m) => m.isUnread).length
        : (studentAsync.value?.unreadMessagesCount ?? 0);

    final screens = const [
      DashboardScreen(),
      ScheduleScreen(),
      GradesScreen(),
      AttendanceScreen(),
      MessagesScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: Row(
              children: [
                AppSidebar(
                  currentIndex: currentIndex,
                  onIndexSelected: (index) {
                    ref.read(currentNavIndexProvider.notifier).setIndex(index);
                  },
                  unexcusedCount: unexcusedCount,
                  unreadCount: messageBadgeCount,
                  student: studentAsync.value,
                ),
                Expanded(
                  child: Column(
                    children: [
                      AppDesktopHeader(
                        student: studentAsync.value,
                        unreadCount: messageBadgeCount,
                        onNotificationsTap: () {
                          ref.read(currentNavIndexProvider.notifier).setIndex(4); // Messages
                        },
                        onProfileTap: () {
                          _showProfileSheet(context, ref);
                        },
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: currentIndex,
                          children: screens,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: studentAsync.when(
            data: (student) => AppHeader(
              student: student,
              currentSectionTitle: _screenTitles[currentIndex],
              onNotificationsTap: () {
                ref.read(currentNavIndexProvider.notifier).setIndex(4); // Messages
              },
              onProfileTap: () {
                _showProfileSheet(context, ref);
              },
            ),
            loading: () => null,
            error: (err, stack) => null,
          ),
          body: IndexedStack(
            index: currentIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              ref.read(currentNavIndexProvider.notifier).setIndex(index);
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Pulpit',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Plan',
              ),
              const NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Oceny',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unexcusedCount > 0,
                  label: Text('$unexcusedCount'),
                  backgroundColor: AppColors.error,
                  child: const Icon(Icons.rule_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unexcusedCount > 0,
                  label: Text('$unexcusedCount'),
                  backgroundColor: AppColors.error,
                  child: const Icon(Icons.rule),
                ),
                label: 'Frekwencja',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: messageBadgeCount > 0,
                  label: Text('$messageBadgeCount'),
                  backgroundColor: AppColors.error,
                  child: const Icon(Icons.mail_outline),
                ),
                selectedIcon: Badge(
                  isLabelVisible: messageBadgeCount > 0,
                  label: Text('$messageBadgeCount'),
                  backgroundColor: AppColors.error,
                  child: const Icon(Icons.mail),
                ),
                label: 'Wiadomości',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref) {
    final student = ref.read(studentProfileProvider).value;
    if (student == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryFixed,
                backgroundImage: const AssetImage('assets/images/avatar.png'),
                child: Text(
                  student.name[0],
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                student.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${student.className} • ${student.schoolName}',
                style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.sync, color: AppColors.primary),
                title: const Text('Status synchronizacji z Librusem'),
                subtitle: Text('Aktywne połączenie • Ostatnia: ${ref.watch(syncProvider).formattedLastSync}'),
                trailing: const Icon(Icons.check_circle, color: AppColors.secondary),
                onTap: () async {
                  await ref.read(syncProvider.notifier).syncNow();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Zsynchronizowano dane z Librusem'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off, color: AppColors.outline),
                title: const Text('Rozłącz konto Librus'),
                subtitle: const Text('Wyczyść zapisane poświadczenia'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(librusConnectionStateProvider.notifier).disconnect();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rozłączono konto Librus.')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Wyloguj się z aplikacji', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  ref.read(appUserProvider.notifier).setUser(null);
                  await ref.read(librusConnectionServiceProvider).clearLocalSession();
                  await ref.read(firebaseAuthServiceProvider).signOut();
                },
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'EduSync v1.0.0 • Open Source • Lepsza Szkoła',
                  style: TextStyle(fontSize: 10, color: AppColors.outline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
