import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/grade.dart';
import '../../../../domain/models/subject.dart';
import '../../../providers/school_providers.dart';

class GradeDetailsSideSheet extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProfileProvider).value;
    final className = student?.className.isNotEmpty == true ? student!.className : '';
    String formattedDate;
    String registerDateStr;
    try {
      formattedDate =
          DateFormat('EEEE, d MMMM yyyy (godz. HH:mm)', 'pl').format(grade.date);
      registerDateStr = DateFormat('yyyy-MM-dd (EEE)', 'pl').format(grade.date);
    } catch (_) {
      final d = grade.date;
      final iso =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      formattedDate = iso;
      registerDateStr = iso;
    }

    final isCounted =
        grade.isCountedToAverage && grade.isMenScaleGrade && grade.weight > 0;

    Color badgeColor;
    String verbalGradeStr;
    if (!grade.isMenScaleGrade) {
      if (grade.rawValue.trim() == '+') {
        badgeColor = AppColors.secondary;
        verbalGradeStr = 'Aktywność (+)';
      } else if (grade.rawValue.trim() == '0') {
        badgeColor = AppColors.outline;
        verbalGradeStr = 'Brak zaliczenia (0)';
      } else {
        badgeColor = AppColors.outline;
        verbalGradeStr = 'Wpis informacyjny';
      }
    } else {
      final isHigh = grade.numericValue >= 5.0;
      final isMid = grade.numericValue >= 4.0;
      badgeColor = isHigh
          ? AppColors.primaryContainer
          : (isMid
              ? AppColors.primary
              : (grade.numericValue < 2.0
                  ? AppColors.error
                  : AppColors.tertiaryContainer));

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
    }

    final countedSubjectGrades = subject.grades
        .where(
          (g) => g.isCountedToAverage && g.isMenScaleGrade && g.weight > 0,
        )
        .toList();
    final double afterAvg = subject.calculateWeightedAverage(grade.term);
    double? beforeAvg;
    double? impactDelta;
    if (isCounted) {
      final otherGrades =
          countedSubjectGrades.where((g) => g.id != grade.id).toList();
      if (otherGrades.isNotEmpty) {
        double wSum = 0;
        int wTot = 0;
        for (final g in otherGrades) {
          wSum += g.numericValue * g.weight;
          wTot += g.weight;
        }
        if (wTot > 0) {
          beforeAvg = wSum / wTot;
          impactDelta = afterAvg - beforeAvg;
        }
      }
    }

    final pctSuffix = grade.percentage != null ? ' • ${grade.percentage}%' : '';
    final digitalGradeValue = '${grade.rawValue} ($verbalGradeStr$pctSuffix)';
    final weightRowValue = isCounted
        ? '${grade.weight} (${'★' * grade.weight.clamp(1, 5)})'
        : '— (Nieliczona)';

    final cleanComment = grade.comment.trim();
    final hasRealComment = cleanComment.isNotEmpty &&
        cleanComment.toLowerCase() != 'brak uwag' &&
        cleanComment.toLowerCase() != 'brak';
    final commentText = hasRealComment
        ? cleanComment
        : 'Brak dodatkowego komentarza nauczyciela.';

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
                            if (className.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '• Klasa $className',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
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
                                          color: isCounted
                                              ? AppColors.primaryFixed
                                              : AppColors.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isCounted
                                              ? 'Waga: ${grade.weight}'
                                              : 'Nieliczona do średniej',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isCounted
                                                ? AppColors.primary
                                                : AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    hasRealComment ? cleanComment : 'Ocena cząstkowa z zajęć',
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
                          child: !isCounted
                              ? Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        afterAvg > 0
                                            ? 'Wpis nie jest wliczany do średniej ważonej (aktualna średnia przedmiotu: ${afterAvg.toStringAsFixed(2)})'
                                            : 'Wpis nie jest wliczany do średniej ważonej',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'WPŁYW NA ŚREDNIĄ PRZEDMIOTU',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                        if (impactDelta != null)
                                          Row(
                                            children: [
                                              Icon(
                                                impactDelta >= 0
                                                    ? Icons.trending_up_rounded
                                                    : Icons.trending_down_rounded,
                                                size: 14,
                                                color: impactDelta >= 0
                                                    ? const Color(0xFF15803D)
                                                    : AppColors.error,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${impactDelta >= 0 ? '+' : ''}${impactDelta.toStringAsFixed(2)} pkt',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: impactDelta >= 0
                                                      ? const Color(0xFF15803D)
                                                      : AppColors.error,
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          const Text(
                                            'Pierwsza ocena liczona',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Przed: ${beforeAvg != null ? beforeAvg.toStringAsFixed(2) : '—'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          'Teraz: ${afterAvg.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (afterAvg / 6.0).clamp(0.0, 1.0),
                                        minHeight: 6,
                                        backgroundColor: AppColors.surfaceContainerHigh,
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          AppColors.secondary,
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
                        _buildRegisterRow('Ocena cyfrowa', digitalGradeValue, isBold: true),
                        _buildDivider(),
                        _buildRegisterRow('Kategoria', grade.categoryName),
                        _buildDivider(),
                        _buildRegisterRow('Data lekcji', registerDateStr),
                        _buildDivider(),
                        _buildRegisterRow('Przedmiot', subject.name),
                        _buildDivider(),
                        _buildRegisterRow('Nauczyciel', subject.teacherName),
                        _buildDivider(),
                        _buildRegisterRow('Waga oceny', weightRowValue),
                        _buildDivider(),
                        _buildRegisterRow(
                          'Licz do średniej',
                          isCounted ? 'TAK (Wliczana)' : 'NIE (Nieliczona)',
                          badge: true,
                          isCountedBadge: isCounted,
                        ),
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
                          hasRealComment ? '„$commentText”' : commentText,
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

  Widget _buildRegisterRow(
    String label,
    String value, {
    bool isBold = false,
    bool badge = false,
    bool isCountedBadge = true,
  }) {
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
                color: isCountedBadge
                    ? const Color(0xFFDCFCE7)
                    : AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCountedBadge
                        ? Icons.check_circle_rounded
                        : Icons.remove_circle_outline_rounded,
                    size: 12,
                    color: isCountedBadge
                        ? const Color(0xFF15803D)
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isCountedBadge
                          ? const Color(0xFF15803D)
                          : AppColors.onSurfaceVariant,
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
