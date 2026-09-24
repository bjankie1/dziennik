import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/attendance_record.dart';
import '../../../domain/models/lesson_slot.dart';
import '../../../domain/models/student_profile.dart';
import '../../providers/auth_providers.dart';
import '../../providers/school_providers.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/modals/librus_query_log_modal.dart';
import 'widgets/dashboard_messages_column.dart';
import 'widgets/dashboard_metrics_column.dart';
import 'widgets/dashboard_mobile_view.dart';
import 'widgets/dashboard_schedule_column.dart';

/// Modular Desktop & Mobile Dashboard Orchestrator (`REQ-ARCH-01`, `REQ-ARCH-02`).
/// Each Bento column and sub-card is isolated in `lib/presentation/screens/dashboard/widgets/`
/// and consumes canonical widgets from `lib/presentation/widgets/common/`.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return _buildDesktopDashboard(context, ref);
        }
        return const DashboardMobileView();
      },
    );
  }

  Widget _buildDesktopDashboard(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProfileProvider);
    final scheduleAsync = ref.watch(todayScheduleProvider);
    final recentGradesAsync = ref.watch(recentGradesProvider);
    final messagesAsync = ref.watch(messagesProvider);
    final attendanceAsync = ref.watch(attendanceProvider);
    final teachersAsync = ref.watch(teachersProvider);
    final examAsync = ref.watch(upcomingExamProvider);
    final user = ref.watch(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final justificationRequestsAsync = ref.watch(justificationRequestsProvider);
    final allJustificationRequests = justificationRequestsAsync.value ?? [];
    final pendingRequests =
        allJustificationRequests.where((r) => r.status.isPending).toList();
    final rejectedRequests =
        allJustificationRequests.where((r) => r.status.isRejected).toList();

    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final rawDate = DateFormat('EEEE, d MMMM y', 'pl_PL').format(now);
    final formattedDate = rawDate.isNotEmpty
        ? '${rawDate[0].toUpperCase()}${rawDate.substring(1)}'
        : rawDate;

    final lessons = scheduleAsync.value ?? [];
    final firstLesson = lessons.isNotEmpty ? lessons.first : null;
    final lastLesson = lessons.isNotEmpty ? lessons.last : null;
    final cancelledLessons =
        lessons.where((l) => l.status == LessonStatus.canceled).toList();
    final effectiveCount = lessons.length - cancelledLessons.length;
    final startTimeStr = firstLesson != null ? firstLesson.startTime : '08:00';
    final endTimeStr = lastLesson != null ? lastLesson.endTime : '14:25';

    final student = studentAsync.value;
    final grades = recentGradesAsync.value ?? [];
    final allMessages = messagesAsync.value ?? [];
    final unreadMessages = allMessages.where((m) => m.isUnread).toList();
    final announcementMessages = allMessages.where((m) {
      final s = m.subject.toLowerCase();
      final r = m.senderRole.toLowerCase();
      return s.contains('ogłoszen') ||
          s.contains('komunikat') ||
          r.contains('dyrekcj');
    }).toList();

    final unexcusedRecords = (attendanceAsync.value ?? [])
        .where((r) =>
            r.type == AttendanceType.absent &&
            r.justificationStatus == JustificationStatus.none)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncProvider.notifier).syncNow();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDesktopWelcomeBanner(
                    context,
                    student: student,
                    formattedDate: formattedDate,
                    startTimeStr: startTimeStr,
                    endTimeStr: endTimeStr,
                    effectiveCount: effectiveCount,
                    cancelledLessons: cancelledLessons,
                    isWeekend: isWeekend,
                    hasLessons: lessons.isNotEmpty,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Column 1: Harmonogram na dziś & Nadchodzący sprawdzian (~35% flex: 4)
                      Expanded(
                        flex: 4,
                        child: DashboardScheduleColumn(
                          lessons: lessons,
                          now: now,
                          exam: examAsync.value,
                          isWeekend: isWeekend,
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Column 2: Zadania na dziś & Wiadomości i Komunikaty (~40% flex: 5)
                      Expanded(
                        flex: 5,
                        child: DashboardMessagesColumn(
                          allMessages: allMessages,
                          unreadMessages: unreadMessages,
                          announcementMessages: announcementMessages,
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Column 3: Ostatnie oceny, Frekwencja & Skróty (~25% flex: 3)
                      Expanded(
                        flex: 3,
                        child: DashboardMetricsColumn(
                          student: student,
                          grades: grades,
                          unexcusedRecords: unexcusedRecords,
                          teachers: teachersAsync.value ?? [],
                          pendingRequests: pendingRequests,
                          rejectedRequests: rejectedRequests,
                          isStudent: isStudent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopWelcomeBanner(
    BuildContext context, {
    required StudentProfile? student,
    required String formattedDate,
    required String startTimeStr,
    required String endTimeStr,
    required int effectiveCount,
    required List<LessonSlot> cancelledLessons,
    required bool isWeekend,
    required bool hasLessons,
  }) {
    final firstName = (student != null && student.name.isNotEmpty)
        ? student.name.split(' ').first
        : 'Oskar';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Dzień dobry, $firstName! 👋',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                    ),
                    Builder(
                      builder: (context) {
                        final luckyNumber = student?.luckyNumber ?? 0;
                        if (isWeekend || luckyNumber <= 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🍀', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 6),
                                Text(
                                  isWeekend
                                      ? 'Brak losowania w weekend'
                                      : 'Brak losowania dzisiaj',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.65,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🍀', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 6),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Szczęśliwy numerek: ',
                                    ),
                                    TextSpan(
                                      text: '$luckyNumber',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${student?.currentWeek ?? 'Tydzień A'} • Semestr 1',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message:
                          'Status systemu: Stan normalny • Kliknij, aby zobaczyć dziennik zapytań Librus (Access Log)',
                      child: InkWell(
                        onTap: () => LibrusQueryLogModal.show(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withValues(
                              alpha: 0.7,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.onSecondaryContainer,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Stan normalny',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Text(
                      '•',
                      style: TextStyle(color: AppColors.outlineVariant),
                    ),
                    if (isWeekend || !hasLessons)
                      Text(
                        isWeekend
                            ? 'Weekend • Dzień wolny od zajęć lekcyjnych 🎉'
                            : 'Dzień wolny od zajęć lekcyjnych 🎉',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      )
                    else ...[
                      Text(
                        'Początek lekcji: $startTimeStr',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (cancelledLessons.isNotEmpty)
                        Text(
                          '(Lekcja ${cancelledLessons.first.lessonNumber} odwołana - ${cancelledLessons.first.subjectName})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      const Text(
                        '•',
                        style: TextStyle(color: AppColors.outlineVariant),
                      ),
                      Text(
                        'Koniec: $endTimeStr ($effectiveCount lekcje efektywne)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
