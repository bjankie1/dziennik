import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/attendance_record.dart';
import '../../../providers/school_providers.dart';

class RequestedAttendanceDetailsSheet extends ConsumerStatefulWidget {
  final AttendanceRecord record;

  const RequestedAttendanceDetailsSheet({
    super.key,
    required this.record,
  });

  static Future<void> show(BuildContext context, AttendanceRecord record) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RequestedAttendanceDetailsSheet(record: record),
    );
  }

  @override
  ConsumerState<RequestedAttendanceDetailsSheet> createState() =>
      _RequestedAttendanceDetailsSheetState();
}

class _RequestedAttendanceDetailsSheetState
    extends ConsumerState<RequestedAttendanceDetailsSheet> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.hourglass_empty_rounded,
                    color: AppColors.warningIcon,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lekcja ${record.lessonNumber}: ${record.subjectName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      Text(
                        '${record.timeSlot} • ${record.teacherName ?? "Wychowawca"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warningSurfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 14,
                    color: AppColors.warningTitle,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Oczekuje na wychowawcę w Librusie',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warningTitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Powód usprawiedliwienia:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.justificationReason?.isNotEmpty == true
                        ? record.justificationReason!
                        : 'Brak podanego powodu',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isCancelling
                        ? null
                        : () async {
                            final messenger =
                                ScaffoldMessenger.maybeOf(context);
                            final notifier =
                                ref.read(attendanceProvider.notifier);
                            setState(() => _isCancelling = true);
                            Navigator.pop(context);
                            try {
                              await notifier.cancelJustification([record.id]);
                              messenger?.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cofnięto wniosek. Możesz teraz zaznaczyć i edytować.',
                                  ),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isCancelling = false);
                              }
                            }
                          },
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: const Text('Cofnij wniosek'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.slate600,
                      side: const BorderSide(color: AppColors.slate300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('close_requested_details_modal_button'),
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Zamknij',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
