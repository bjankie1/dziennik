import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/lesson_slot.dart';
import '../../../../domain/models/message_thread.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/school_providers.dart';
import '../../../providers/sync_provider.dart';
import '../../../widgets/common/grade_badge_pill.dart';
import '../../attendance/widgets/parent_approval_modal.dart';
import '../../attendance/widgets/parent_rejection_modal.dart';
import '../../attendance/widgets/student_response_modal.dart';
import '../../grades/grade_details_modal.dart';
import 'dashboard_tasks_card.dart';
import 'dashboard_upcoming_exam_card.dart';

/// Ergonomic Mobile Dashboard View (`< 1024px`, `REQ-ARCH-01`, `REQ-ARCH-02`).
class DashboardMobileView extends ConsumerWidget {
  const DashboardMobileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProfileProvider);
    final scheduleAsync = ref.watch(todayScheduleProvider);
    final upcomingExam = ref.watch(upcomingExamProvider).value;
    final recentGradesAsync = ref.watch(recentGradesProvider);
    final messagesAsync = ref.watch(messagesProvider);
    final unreadMessagesCount = ref.watch(unreadMessagesCountProvider);
    final syncState = ref.watch(syncProvider);
    final user = ref.watch(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final isParent = !isStudent;
    final justificationRequestsAsync = ref.watch(justificationRequestsProvider);
    final allMobileJustifications = justificationRequestsAsync.value ?? [];
    final pendingRequests =
        allMobileJustifications.where((r) => r.status.isPending).toList();
    final rejectedRequests =
        allMobileJustifications.where((r) => r.status.isRejected).toList();

    final messages = messagesAsync.value ?? [];

    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final rawDate = DateFormat('EEEE, d MMMM', 'pl_PL').format(now);
    final formattedDate = rawDate.isNotEmpty
        ? '${rawDate[0].toUpperCase()}${rawDate.substring(1)}'
        : rawDate;

    final lessons = scheduleAsync.value ?? [];
    final firstLesson = lessons.isNotEmpty ? lessons.first : null;
    final lastLesson = lessons.isNotEmpty ? lessons.last : null;
    final cancelledLessons =
        lessons.where((l) => l.status == LessonStatus.canceled).toList();
    final effectiveCount = lessons.length - cancelledLessons.length;
    final startTimeStr =
        firstLesson != null ? 'Początek ${firstLesson.startTime}' : 'Brak lekcji';
    final endTimeStr = lastLesson != null
        ? 'Koniec zajęć: ${lastLesson.endTime} • $effectiveCount lekcji efektywnych'
        : 'Dzień wolny';
    final statusNoteStr = lessons.isEmpty
        ? (isWeekend ? 'Weekend' : 'Dzień wolny')
        : (cancelledLessons.isNotEmpty
            ? 'Lekcja ${cancelledLessons.first.lessonNumber} odwołana'
            : (lessons.any((l) => l.status == LessonStatus.substituted)
                ? 'Zastępstwo w planie'
                : 'Zgodnie z planem'));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncProvider.notifier).syncNow();
        },
        color: AppColors.primary,
        child: ListView(
          cacheExtent: 2000.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // Top Academic Status Micro-Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.outlineVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    studentAsync.value?.currentWeek ?? 'Tydzień B',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.eco,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${studentAsync.value?.attendancePercentage ?? 98.6}% Frekw.',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Sync Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: syncState.isDemoMode
                    ? const Color(0xFFFFFBEB)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: syncState.isDemoMode
                      ? const Color(0xFFFDE68A)
                      : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: syncState.isDemoMode
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : const Color(0xFF16A34A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      syncState.isDemoMode
                          ? Icons.science_outlined
                          : Icons.cloud_done_outlined,
                      size: 16,
                      color: syncState.isDemoMode
                          ? const Color(0xFFD97706)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              syncState.isDemoMode
                                  ? 'Tryb demonstracyjny'
                                  : 'Połączono z Librus Synergia',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: syncState.isDemoMode
                                    ? const Color(0xFF92400E)
                                    : const Color(0xFF166534),
                              ),
                            ),
                            if (syncState.connectedLogin != null &&
                                !syncState.isDemoMode) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '(${syncState.connectedLogin})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF15803D),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          'Ostatnia synchronizacja: ${syncState.formattedLastSync}',
                          style: TextStyle(
                            fontSize: 11,
                            color: syncState.isDemoMode
                                ? const Color(0xFFB45309)
                                : const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: syncState.isSyncing
                        ? null
                        : () async {
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: syncState.isDemoMode
                            ? const Color(0xFFD97706).withValues(alpha: 0.1)
                            : const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: syncState.isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Text(
                              'Odśwież',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: syncState.isDemoMode
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (isParent && pendingRequests.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        color: Color(0xFFB45309),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pendingRequests.first.studentName} prosi o usprawiedliwienie',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF78350F),
                            ),
                          ),
                          Text(
                            '${pendingRequests.first.lessonNumbers.isNotEmpty ? pendingRequests.first.lessonNumbers.length : pendingRequests.first.recordIds.length} lekcji • ${pendingRequests.first.reason}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            final req = pendingRequests.first;
                            ParentApprovalModal.show(
                              context,
                              req,
                              onApprove: (pin) async {
                                final ok = await ref
                                    .read(attendanceProvider.notifier)
                                    .approveJustification(req.id, pin);
                                if (ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Usprawiedliwienie dla ${req.studentName} zostało wysłane.',
                                      ),
                                      backgroundColor: const Color(0xFF006C4A),
                                    ),
                                  );
                                }
                                return ok;
                              },
                              onReject: (reason) async {
                                final ok = await ref
                                    .read(attendanceProvider.notifier)
                                    .rejectJustification(req.id, reason: reason);
                                if (ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Wniosek ucznia został odrzucony.'),
                                      backgroundColor: Color(0xFFDC2626),
                                    ),
                                  );
                                }
                                return ok;
                              },
                            );
                          },
                          icon: const Icon(Icons.pin, size: 12),
                          label: const Text(
                            'Zatwierdź',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3525CD),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          onPressed: () {
                            final req = pendingRequests.first;
                            ParentRejectionModal.show(
                              context,
                              req,
                              onReject: (reason) async {
                                final ok = await ref
                                    .read(attendanceProvider.notifier)
                                    .rejectJustification(req.id, reason: reason);
                                if (ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Wniosek ucznia został odrzucony z komentarzem.',
                                      ),
                                      backgroundColor: Color(0xFFDC2626),
                                    ),
                                  );
                                }
                                return ok;
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: Color(0xFFDC2626),
                          ),
                          label: const Text(
                            'Odrzuć',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (isStudent && rejectedRequests.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Odrzucona prośba o usprawiedliwienie',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          Text(
                            '„${rejectedRequests.first.rejectionReason ?? 'Brak podanego powodu'}”',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7F1D1D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final req = rejectedRequests.first;
                        StudentResponseModal.show(
                          context,
                          req,
                          onRespond: (responseText) async {
                            final ok = await ref
                                .read(attendanceProvider.notifier)
                                .respondToJustification(req.id, responseText);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Twoje wyjaśnienie zostało przekazane rodzicowi.',
                                  ),
                                  backgroundColor: Color(0xFF2563EB),
                                ),
                              );
                            }
                            return ok;
                          },
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Odpowiedz',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Daily Schedule Hero Card (Mobile)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DZISIEJSZY PLAN ZAJĘĆ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusNoteStr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (lessons.isEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.weekend_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isWeekend
                                    ? 'Brak zajęć dzisiaj • Weekend 🎉'
                                    : 'Brak lekcji na dzisiaj • Dzień wolny 🎉',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isWeekend
                                    ? 'Odpocznij i zregeneruj siły przed nowym tygodniem.'
                                    : 'Ciesz się wolnym czasem lub powtórz materiał.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Text(
                      startTimeStr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      endTimeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...lessons.take(4).map(
                          (l) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  l.startTime,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l.subjectName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      decoration:
                                          l.status == LessonStatus.canceled
                                              ? TextDecoration.lineThrough
                                              : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  l.room.isNotEmpty ? 'Sala ${l.room}' : '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => context.go('/plan-lekcji'),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Zobacz pełny plan lekcji',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (upcomingExam != null) ...[
              const SizedBox(height: 16),
              DashboardUpcomingExamCard(exam: upcomingExam),
            ],
            const SizedBox(height: 16),
            const DashboardTasksCard(isCompact: true),
            const SizedBox(height: 16),

            // Messages & Communications (Mobile)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: unreadMessagesCount > 0
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : AppColors.outlineVariant.withValues(alpha: 0.3),
                  width: unreadMessagesCount > 0 ? 1.5 : 1.0,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'WIADOMOŚCI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (unreadMessagesCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadMessagesCount ${unreadMessagesCount == 1 ? 'nowa' : 'nowe'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.go('/wiadomosci'),
                        child: const Text('Wszystkie →'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (messages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Brak wiadomości w skrzynce',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                    )
                  else
                    ...messages
                        .take(3)
                        .map((msg) => _buildMobileMessageItem(context, msg)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Recent Grades (Mobile)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'OSTATNIE OCENY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/oceny'),
                        child: const Text('Wszystkie →'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if ((recentGradesAsync.value ?? []).isNotEmpty)
                    ...recentGradesAsync.value!.take(3).map(
                          (g) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: GradeBadgePill(
                              value: g.rawValue,
                              numericValue: g.numericValue,
                              size: 38,
                            ),
                            title: Text(
                              g.subjectName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${g.categoryName} • waga ${g.weight}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Text(
                              DateFormat('d MMM', 'pl_PL').format(g.date),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.outline,
                              ),
                            ),
                            onTap: () => GradeDetailsModal.show(context, g),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMessageItem(BuildContext context, MessageThread msg) {
    final timeStr = DateFormat('d MMM, HH:mm', 'pl_PL').format(msg.timestamp);

    return InkWell(
      onTap: () => context.go('/wiadomosci/${msg.id}', extra: msg),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: msg.isUnread
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: msg.isUnread
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.25))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: msg.isUnread
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surfaceContainerHigh,
              child: Text(
                msg.senderInitials,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: msg.isUnread
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          msg.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                msg.isUnread ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.subject,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          msg.isUnread ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
