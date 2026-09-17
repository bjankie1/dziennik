import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/grade.dart';
import '../../../domain/models/subject.dart';
import 'widgets/grade_details_side_sheet.dart';

class GradeDetailsModal extends StatelessWidget {
  final Grade grade;

  const GradeDetailsModal({super.key, required this.grade});

  static void show(
    BuildContext context,
    Grade grade, {
    Subject? subject,
    VoidCallback? onContactTeacher,
  }) {
    final targetSubject = subject ??
        Subject(
          id: grade.id,
          name: grade.subjectName,
          teacherName: grade.teacher,
          grades: [grade],
        );
    GradeDetailsSideSheet.show(
      context,
      grade: grade,
      subject: targetSubject,
      onContactTeacher: onContactTeacher,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy, HH:mm', 'pl');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header: Subject & Value Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grade.subjectName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        grade.teacher,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    grade.rawValue,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Metadata Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildMetaRow(
                    context,
                    icon: Icons.bookmark_outline,
                    label: 'Kategoria',
                    value: grade.categoryName,
                    badgeColor: AppColors.primaryFixed,
                    badgeTextColor: AppColors.onPrimaryFixedVariant,
                  ),
                  const Divider(height: 16, color: Color(0x15000000)),
                  _buildMetaRow(
                    context,
                    icon: Icons.scale_outlined,
                    label: 'Waga oceny',
                    value: 'Waga ${grade.weight}',
                    badgeColor: AppColors.secondaryFixed,
                    badgeTextColor: AppColors.onSecondaryFixedVariant,
                  ),
                  const Divider(height: 16, color: Color(0x15000000)),
                  _buildMetaRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Data wpisu',
                    value: dateFormat.format(grade.date),
                  ),
                  const Divider(height: 16, color: Color(0x15000000)),
                  _buildMetaRow(
                    context,
                    icon: Icons.calculate_outlined,
                    label: 'Wpływ na średnią',
                    value: grade.isCountedToAverage ? 'Liczona do średniej' : 'Nieliczona',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Teacher Comment / Description
            Text(
              'Komentarz nauczyciela',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Text(
                grade.comment.isNotEmpty ? grade.comment : 'Brak dodatkowego komentarza.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface,
                      height: 1.4,
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  foregroundColor: AppColors.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Zamknij', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.outline),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const Spacer(),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: badgeTextColor ?? AppColors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
          ),
      ],
    );
  }
}
