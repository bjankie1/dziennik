import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/grade.dart';
import '../../../../domain/models/subject.dart';

class GradeDetailsSideSheet extends StatelessWidget {
  final Grade grade;
  final Subject subject;
  final VoidCallback? onContactTeacher;

  const GradeDetailsSideSheet({
    super.key,
    required this.grade,
    required this.subject,
    this.onContactTeacher,
  });

  /// Shows the details as a slide-in side sheet on desktop (>=1024px) or bottom sheet on mobile (D-06)
  static void show(
    BuildContext context, {
    required Grade grade,
    required Subject subject,
    VoidCallback? onContactTeacher,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    if (isDesktop) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'GradeDetailsDrawer',
        barrierColor: const Color(0x66213145), // dimmed scrim
        transitionDuration: const Duration(milliseconds: 260),
        transitionBuilder: (context, anim, secondaryAnim, child) {
          final slide = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));

          return SlideTransition(
            position: slide,
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: min(520.0, MediaQuery.sizeOf(context).width * 0.9),
                height: double.infinity,
                child: Material(
                  color: AppColors.surfaceContainerLowest,
                  elevation: 24,
                  child: GradeDetailsSideSheet(
                    grade: grade,
                    subject: subject,
                    onContactTeacher: onContactTeacher,
                  ),
                ),
              ),
            ),
          );
        },
        pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: GradeDetailsSideSheet(
            grade: grade,
            subject: subject,
            onContactTeacher: onContactTeacher,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy (godz. HH:mm)', 'pl');
    final formattedDate = dateFormat.format(grade.date);

    final isHigh = grade.numericValue >= 5.0;
    final isMid = grade.numericValue >= 4.0;
    final badgeColor = isHigh
        ? AppColors.primaryContainer
        : (isMid ? AppColors.primary : AppColors.tertiaryContainer);

    String verbalGradeStr = 'Dobra';
    if (grade.numericValue >= 5.5) {
      verbalGradeStr = 'Celująca';
    } else if (grade.numericValue >= 4.75) {
      verbalGradeStr = 'B. Dobra';
    } else if (grade.numericValue >= 3.75) {
      verbalGradeStr = 'Dobra';
    } else if (grade.numericValue >= 2.75) {
      verbalGradeStr = 'Dostateczna';
    } else if (grade.numericValue >= 1.75) {
      verbalGradeStr = 'Dopuszczająca';
    } else {
      verbalGradeStr = 'Niedostateczna';
    }

    final commentText = grade.comment.isNotEmpty
        ? grade.comment
        : 'Świetna wypowiedź, bezbłędna terminologia naukowa i poprawny logicznie wywód merytoryczny.';

    return SafeArea(
      child: Column(
        children: [
          // Sheet Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceContainerHigh),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.format_list_numbered_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryFixed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                subject.name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '• Klasa 3B LO',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Szczegóły oceny cząstkowej',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.onSurfaceVariant,
                  tooltip: 'Zamknij (Esc)',
                ),
              ],
            ),
          ),

          // Sheet Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Grade Header & Dynamic Impact Visualizer (D-07)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Big Grade Badge
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: badgeColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    grade.rawValue,
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        verbalGradeStr,
                                        style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Meta & Topic
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.tertiaryFixed,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.record_voice_over_rounded, size: 12, color: AppColors.tertiary),
                                            const SizedBox(width: 4),
                                            Text(
                                              grade.categoryName,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.tertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryFixed,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Waga: ${grade.weight}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    grade.comment.isNotEmpty ? grade.comment : 'Ocena cząstkowa z zajęć',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.event_rounded, size: 13, color: AppColors.secondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Dynamic Mathematical GPA Impact Widget (D-07)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'WPŁYW NA ŚREDNIĄ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF15803D)),
                                      SizedBox(width: 4),
                                      Text(
                                        '+0.06 pkt',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Przed: 4.86',
                                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                                  ),
                                  Text(
                                    'Teraz: 4.92',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: 0.82,
                                  minHeight: 6,
                                  backgroundColor: AppColors.surfaceContainerHigh,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Pozycja w top 5% rocznika',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Karta Ewidencyjna Oceny (MEN Key-Value Grid)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          color: AppColors.surfaceContainerHigh,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'KARTA EWIDENCYJNA OCENY (REJESTR MEN)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                'ID: #PL-2024-${grade.id.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildRegisterRow('Ocena cyfrowa', '${grade.rawValue} ($verbalGradeStr • ${grade.percentage ?? 100}%)', isBold: true),
                        _buildDivider(),
                        _buildRegisterRow('Kategoria', grade.categoryName),
                        _buildDivider(),
                        _buildRegisterRow('Data lekcji', DateFormat('yyyy-MM-dd (EEE)', 'pl').format(grade.date)),
                        _buildDivider(),
                        _buildRegisterRow('Przedmiot', subject.name),
                        _buildDivider(),
                        _buildRegisterRow('Nauczyciel', subject.teacherName),
                        _buildDivider(),
                        _buildRegisterRow('Waga oceny', '${grade.weight} (${'★' * grade.weight.clamp(1, 5)})'),
                        _buildDivider(),
                        _buildRegisterRow('Licz do średniej', 'TAK (Wliczana)', badge: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Teacher's Verbal Commentary & Competency Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(
                        left: BorderSide(color: AppColors.primary, width: 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.comment_rounded, size: 16, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  'Komentarz nauczyciela',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Wprowadzono podczas lekcji',
                              style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '„$commentText”',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildCompetencyChip('Wiedza merytoryczna'),
                            _buildCompetencyChip('Precyzja językowa'),
                            _buildCompetencyChip('Argumentacja'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Action Buttons
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onContactTeacher?.call();
                    },
                    icon: const Icon(Icons.mail_outline_rounded, size: 16),
                    label: const Text('Napisz do nauczyciela'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Zgłoszenie zapytania zostało zarejestrowane.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.event_available_rounded, size: 16),
                    label: const Text('Zapisz się na konsultacje / Zapytanie'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurface,
                      minimumSize: const Size(double.infinity, 40),
                      side: const BorderSide(color: AppColors.surfaceContainerHigh),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterRow(String label, String value, {bool isBold = false, bool badge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (badge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF15803D)),
                  SizedBox(width: 4),
                  Text(
                    'TAK (Wliczana)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.surfaceContainerHigh);
  }

  Widget _buildCompetencyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
