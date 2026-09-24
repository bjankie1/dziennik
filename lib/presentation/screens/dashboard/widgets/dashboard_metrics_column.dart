import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/attendance_record.dart';
import '../../../../domain/models/grade.dart';
import '../../../../domain/models/justification_request.dart';
import '../../../../domain/models/student_profile.dart';
import '../../../../domain/models/teacher_contact.dart';
import '../../../providers/school_providers.dart';
import '../../../widgets/common/grade_badge_pill.dart';
import '../../attendance/justification_modal.dart';
import '../../attendance/widgets/parent_approval_modal.dart';
import '../../attendance/widgets/parent_rejection_modal.dart';
import '../../attendance/widgets/student_justification_modal.dart';
import '../../attendance/widgets/student_response_modal.dart';
import '../../grades/grade_details_modal.dart';
import '../../messages/new_message_screen.dart';

/// Right column of Desktop Dashboard displaying GPA, Recent Grades, Attendance, and Quick Shortcuts (`REQ-ARCH-01`, `REQ-ARCH-02`).
class DashboardMetricsColumn extends ConsumerWidget {
  final StudentProfile? student;
  final List<Grade> grades;
  final List<AttendanceRecord> unexcusedRecords;
  final List<TeacherContact> teachers;
  final List<JustificationRequest> pendingRequests;
  final List<JustificationRequest> rejectedRequests;
  final bool isStudent;

  const DashboardMetricsColumn({
    super.key,
    required this.student,
    required this.grades,
    required this.unexcusedRecords,
    required this.teachers,
    this.pendingRequests = const [],
    this.rejectedRequests = const [],
    this.isStudent = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendancePct = student?.attendancePercentage ?? 98.6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Ostatnie oceny Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.military_tech_outlined,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Ostatnie oceny',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryContainer.withValues(alpha: 0.6),
                      AppColors.secondaryContainer.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.trending_up,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ŚREDNIA WAŻONA',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  (student?.overallAverage ?? 5.0)
                                      .toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Top 5%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      student != null && student!.overallAverage >= 4.75
                          ? 'Wyróżnienie 🏅'
                          : 'Bardzo dobry wynik',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (grades.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Brak najnowszych ocen',
                    style: TextStyle(color: AppColors.outline),
                  ),
                )
              else
                ...grades.take(3).map((g) => _buildDesktopGradeRow(context, g)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => context.go('/oceny'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Zobacz wszystkie oceny',
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
        const SizedBox(height: 20),

        // 2. Frekwencja Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        size: 20,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Frekwencja',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${attendancePct.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Wymóg min. 50%',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Cel roczny: 90% (Osiągnięty)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (attendancePct * 10).toInt(),
                        child: Container(color: AppColors.secondary),
                      ),
                      Expanded(
                        flex: ((100 - attendancePct) * 10).toInt(),
                        child: Container(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isStudent && pendingRequests.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildParentPendingRequestCard(context, ref, pendingRequests.first),
              ],
              if (isStudent && rejectedRequests.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildStudentRejectedRequestCard(
                  context,
                  ref,
                  rejectedRequests.first,
                ),
              ],
              if (unexcusedRecords.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryFixed.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${unexcusedRecords.length} godz. do usprawiedliwienia',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onTertiaryFixed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _openJustificationFlow(context, ref),
                icon: Icon(
                  isStudent
                      ? Icons.family_restroom_rounded
                      : Icons.security,
                  size: 16,
                ),
                label: Text(
                  isStudent
                      ? 'Poproś o usprawiedliwienie'
                      : 'Szybkie usprawiedliwienie (PIN)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Quick Action Widgets Mosaic
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _buildDesktopShortcutTile(
                icon: Icons.assignment_outlined,
                iconBg: AppColors.primaryFixed,
                iconColor: AppColors.primary,
                title: 'Zadania domowe',
                subtitle: 'Terminarz i sprawdziany',
                onTap: () => context.go('/zadania'),
              ),
              const Divider(height: 12, color: AppColors.surfaceContainerHigh),
              _buildDesktopShortcutTile(
                icon: Icons.forum_outlined,
                iconBg: AppColors.secondaryContainer,
                iconColor: AppColors.secondary,
                title: 'Kontakt z wychowawcą',
                subtitle: 'Napisz nową wiadomość',
                onTap: () {
                  final educatorName = student?.educator ?? 'Wychowawca';
                  final homeroomTeacher = teachers.firstWhere(
                    (t) =>
                        t.role.toLowerCase().contains('wychowawc') ||
                        t.subjectName.toLowerCase().contains('wychowawc') ||
                        t.id == 'educator',
                    orElse: () => teachers.isNotEmpty
                        ? teachers.first
                        : TeacherContact(
                            id: 'educator',
                            name: educatorName,
                            subjectName: 'Wychowawstwo',
                            role: 'Wychowawca',
                            initials: educatorName
                                .split(' ')
                                .map((p) => p.isNotEmpty ? p[0] : '')
                                .take(2)
                                .join()
                                .toUpperCase(),
                          ),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          NewMessageScreen(initialRecipient: homeroomTeacher),
                    ),
                  );
                },
              ),
              const Divider(height: 12, color: AppColors.surfaceContainerHigh),
              _buildDesktopShortcutTile(
                icon: Icons.event_busy_outlined,
                iconBg: AppColors.surfaceContainerHigh,
                iconColor: AppColors.onSurface,
                title: isStudent
                    ? 'Poproś o usprawiedliwienie'
                    : 'Zgłoś nieobecność',
                subtitle:
                    isStudent ? 'Wniosek do rodzica' : 'e-Usprawiedliwienie',
                onTap: () => _openJustificationFlow(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openJustificationFlow(BuildContext context, WidgetRef ref) {
    final recordIds = unexcusedRecords.map((r) => r.id).toList();
    if (isStudent) {
      StudentJustificationModal.show(
        context,
        recordIds,
        onConfirm: (reason, selectedDate) async {
          await ref.read(attendanceProvider.notifier).requestJustification(
                recordIds,
                reason,
                date: selectedDate,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Prośba o usprawiedliwienie została przesłana do rodzica.',
                ),
                backgroundColor: Color(0xFF006C4A),
              ),
            );
          }
        },
      );
    } else {
      JustificationModal.show(
        context,
        recordIds,
        'Wizyta lekarska',
        (reason, pin, selectedDate) async {
          await ref.read(attendanceProvider.notifier).submitJustification(
                recordIds,
                reason,
                date: selectedDate,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Wniosek o usprawiedliwienie został pomyślnie wysłany.',
                ),
                backgroundColor: Color(0xFF006C4A),
              ),
            );
          }
        },
      );
    }
  }

  Widget _buildParentPendingRequestCard(
    BuildContext context,
    WidgetRef ref,
    JustificationRequest req,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                size: 16,
                color: Color(0xFFB45309),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${req.studentName} prosi o usprawiedliwienie',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF78350F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${req.lessonNumbers.isNotEmpty ? req.lessonNumbers.length : req.recordIds.length} godz. • ${req.reason}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: FilledButton.icon(
                    onPressed: () {
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
                                  'Usprawiedliwienie dla ${req.studentName} zostało zatwierdzone.',
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
                    icon: const Icon(Icons.pin, size: 14),
                    label: const Text(
                      'Zatwierdź (PIN)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3525CD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: () {
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
                    size: 14,
                    color: Color(0xFFDC2626),
                  ),
                  label: const Text(
                    'Odrzuć',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRejectedRequestCard(
    BuildContext context,
    WidgetRef ref,
    JustificationRequest req,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFFDC2626),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rodzic odrzucił prośbę o usprawiedliwienie',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Komentarz: „${req.rejectionReason ?? 'Wymagane dodatkowe wyjaśnienie'}”',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF7F1D1D),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: FilledButton.icon(
              onPressed: () {
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
              icon: const Icon(Icons.reply_rounded, size: 15),
              label: const Text(
                'Odpowiedz / Poproś ponownie',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGradeRow(BuildContext context, Grade grade) {
    final dateStr = DateFormat('d MMM', 'pl_PL').format(grade.date);
    return InkWell(
      onTap: () => GradeDetailsModal.show(context, grade),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            GradeBadgePill(
              value: grade.rawValue,
              numericValue: grade.numericValue,
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.subjectName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${grade.categoryName} • waga ${grade.weight}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopShortcutTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
