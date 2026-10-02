import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/polish_date_formatter.dart';
import '../../../domain/models/attendance_record.dart';
import '../../../domain/models/justification_request.dart';
import '../../providers/auth_providers.dart';
import '../../providers/school_providers.dart';
import '../../screens/attendance/widgets/parent_approval_modal.dart';
import '../../screens/attendance/widgets/parent_rejection_modal.dart';
import '../../screens/attendance/widgets/student_response_modal.dart';

/// Shared banner widget for parent pending justification approval and student
/// rejected justification response across Dashboard (Mobile/Desktop) and
/// AttendanceScreen (`REQ-ARCH-01`, `REQ-ARCH-02`, `T-21-01`).
class JustificationRequestBanner extends ConsumerWidget {
  final bool showDetailsLink;
  final bool compact;
  final bool useIndigoStyle;
  final double topSpacing;
  final double bottomSpacing;

  const JustificationRequestBanner({
    super.key,
    this.showDetailsLink = true,
    this.compact = false,
    this.useIndigoStyle = false,
    this.topSpacing = 0,
    this.bottomSpacing = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(
      appUserProvider.select(
        (u) => (isStudent: u?.isStudent ?? false, displayName: u?.displayName),
      ),
    );
    final pendingReq = ref.watch(
      justificationRequestsProvider.select(
        (asyncVal) => asyncVal.value?.where((r) => r.status.isPending).firstOrNull,
      ),
    );
    final rejectedReq = ref.watch(
      justificationRequestsProvider.select(
        (asyncVal) => asyncVal.value?.where((r) => r.status.isRejected).firstOrNull,
      ),
    );

    // T-21-01: Strictly gate parent approval/rejection UI behind !user.isStudent
    if (!user.isStudent && pendingReq != null) {
      final attendanceRecords = ref.watch(
        attendanceProvider.select(
          (a) => a.value ?? const <AttendanceRecord>[],
        ),
      );
      final profileName = ref.watch(
        studentProfileProvider.select((s) => s.value?.name),
      );
      final banner = _buildParentPendingCard(
        context,
        ref,
        pendingReq: pendingReq,
        attendanceRecords: attendanceRecords,
        profileName: profileName,
        parentDisplayName: user.displayName,
      );
      return _wrapWithSpacing(banner);
    }

    if (user.isStudent && rejectedReq != null) {
      final banner = _buildStudentRejectedCard(
        context,
        ref,
        rejectedReq: rejectedReq,
      );
      return _wrapWithSpacing(banner);
    }

    return const SizedBox.shrink();
  }

  Widget _wrapWithSpacing(Widget child) {
    if (topSpacing == 0 && bottomSpacing == 0) return child;
    return Padding(
      padding: EdgeInsets.only(top: topSpacing, bottom: bottomSpacing),
      child: child,
    );
  }

  Widget _buildParentPendingCard(
    BuildContext context,
    WidgetRef ref, {
    required JustificationRequest pendingReq,
    required List<AttendanceRecord> attendanceRecords,
    required String? profileName,
    required String? parentDisplayName,
  }) {
    final studentName = pendingReq.effectiveStudentName(
      profileStudentName: profileName,
      currentParentName: parentDisplayName,
    );
    final resolved = pendingReq.resolveAttendanceRecords(attendanceRecords);
    final count = resolved.isNotEmpty
        ? resolved.length
        : (pendingReq.lessonNumbers.isNotEmpty
            ? pendingReq.lessonNumbers.length
            : pendingReq.recordIds.length);
    final lessonLabel = useIndigoStyle
        ? PolishDateFormatter.pluralizeLessonAccusative(count)
        : 'lekcji';
    final dateRange = pendingReq.formatDateRangeSummary(attendanceRecords);

    void openApprovalModal() {
      final approvedMessage = useIndigoStyle
          ? 'Usprawiedliwienie dla $studentName zostało wysłane do szkoły.'
          : (compact
              ? 'Usprawiedliwienie dla $studentName zostało zatwierdzone.'
              : 'Usprawiedliwienie dla $studentName zostało wysłane.');
      final approvedColor =
          useIndigoStyle ? AppColors.successDark : AppColors.secondary;

      ParentApprovalModal.show(
        context,
        pendingReq,
        availableRecords: attendanceRecords,
        studentDisplayName: studentName,
        onApprove: (pin) async {
          final ok = await ref
              .read(attendanceProvider.notifier)
              .approveJustification(pendingReq.id, pin);
          if (ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(approvedMessage),
                backgroundColor: approvedColor,
              ),
            );
          }
          return ok;
        },
        onApproveSelected: (pin, selectedIds) async {
          final ok = await ref
              .read(attendanceProvider.notifier)
              .approveJustification(
                pendingReq.id,
                pin,
                selectedRecordIds: selectedIds,
              );
          if (ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(approvedMessage),
                backgroundColor: approvedColor,
              ),
            );
          }
          return ok;
        },
        onReject: (reason) async {
          final ok = await ref
              .read(attendanceProvider.notifier)
              .rejectJustification(pendingReq.id, reason: reason);
          if (ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wniosek ucznia został odrzucony.'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return ok;
        },
      );
    }

    void openRejectionModal() {
      ParentRejectionModal.show(
        context,
        pendingReq,
        availableRecords: attendanceRecords,
        studentDisplayName: studentName,
        onReject: (reason) async {
          final ok = await ref
              .read(attendanceProvider.notifier)
              .rejectJustification(pendingReq.id, reason: reason);
          if (ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wniosek ucznia został odrzucony z komentarzem.'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return ok;
        },
      );
    }

    final subtitleText =
        '${dateRange.isNotEmpty ? "$dateRange • " : ""}$count $lessonLabel • ${pendingReq.reason}';

    if (useIndigoStyle) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('parent_pending_request_banner'),
          borderRadius: BorderRadius.circular(16),
          onTap: openApprovalModal,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.indigoSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.indigoBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
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
                            '$studentName prosi o usprawiedliwienie',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitleText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate700,
                            ),
                          ),
                          if (showDetailsLink) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Zobacz szczegóły →',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: openApprovalModal,
                        icon: const Icon(Icons.pin, size: 14),
                        label: const Text(
                          'Zatwierdź (PIN)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: openRejectionModal,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.danger,
                        ),
                        label: const Text(
                          'Odrzuć',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: AppColors.dangerBorderStrong,
                          ),
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('parent_pending_request_banner'),
          borderRadius: BorderRadius.circular(12),
          onTap: openApprovalModal,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warningBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.family_restroom_rounded,
                      size: 16,
                      color: AppColors.warningDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$studentName prosi o usprawiedliwienie',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warningDeep,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.warningText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showDetailsLink) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Zobacz szczegóły →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warningDark,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: FilledButton.icon(
                          onPressed: openApprovalModal,
                          icon: const Icon(Icons.pin, size: 14),
                          label: const Text(
                            'Zatwierdź (PIN)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
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
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: openRejectionModal,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.danger,
                        ),
                        label: const Text(
                          'Odrzuć',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.dangerBorder),
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
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('parent_pending_request_banner'),
        borderRadius: BorderRadius.circular(16),
        onTap: openApprovalModal,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warningBorder),
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
                  color: AppColors.warningDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$studentName prosi o usprawiedliwienie',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warningDeep,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warningText,
                      ),
                    ),
                    if (showDetailsLink) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Zobacz szczegóły →',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warningDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: openApprovalModal,
                    icon: const Icon(Icons.pin, size: 12),
                    label: const Text(
                      'Zatwierdź (PIN)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: openRejectionModal,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: AppColors.danger,
                    ),
                    label: const Text(
                      'Odrzuć',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.dangerBorder,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentRejectedCard(
    BuildContext context,
    WidgetRef ref, {
    required JustificationRequest rejectedReq,
  }) {
    final count = rejectedReq.lessonNumbers.isNotEmpty
        ? rejectedReq.lessonNumbers.length
        : rejectedReq.recordIds.length;
    final lessonLabel = PolishDateFormatter.pluralizeLessonAccusative(count);

    void openStudentResponseModal() {
      StudentResponseModal.show(
        context,
        rejectedReq,
        onRespond: (responseText) async {
          final ok = await ref
              .read(attendanceProvider.notifier)
              .respondToJustification(rejectedReq.id, responseText);
          if (ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Twoje wyjaśnienie zostało przekazane rodzicowi.',
                ),
                backgroundColor:
                    useIndigoStyle ? const Color(0xFF2563EB) : AppColors.primary,
              ),
            );
          }
          return ok;
        },
      );
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.dangerSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dangerSoftBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.danger,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rodzic odrzucił prośbę o usprawiedliwienie',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dangerDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Komentarz: „${rejectedReq.rejectionReason ?? 'Wymagane dodatkowe wyjaśnienie'}”',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.dangerDeep,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: FilledButton.icon(
                onPressed: openStudentResponseModal,
                icon: const Icon(Icons.reply_rounded, size: 15),
                label: const Text(
                  'Odpowiedz / Poproś ponownie',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
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

    if (useIndigoStyle) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.dangerSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dangerBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.danger,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rodzic odrzucił prośbę o usprawiedliwienie',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dangerTitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count $lessonLabel • Komentarz: „${rejectedReq.rejectionReason ?? 'Wymagane wyjaśnienie'}”',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dangerDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: openStudentResponseModal,
              icon: const Icon(Icons.reply_rounded, size: 16),
              label: const Text(
                'Odpowiedz / Poproś ponownie',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dangerSoftBorder),
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
              color: AppColors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rodzic odrzucił prośbę o usprawiedliwienie',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dangerDark,
                  ),
                ),
                Text(
                  '„${rejectedReq.rejectionReason ?? 'Brak podanego powodu'}”',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dangerDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: openStudentResponseModal,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Odpowiedz',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
