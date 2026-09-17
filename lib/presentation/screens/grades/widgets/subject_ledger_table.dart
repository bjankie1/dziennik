import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/grade.dart';
import '../../../../domain/models/subject.dart';
import '../../../providers/school_providers.dart';

class SubjectLedgerTable extends ConsumerWidget {
  final List<Subject> subjects;
  final Subject? selectedSubject;
  final ValueChanged<Subject> onSelectSubject;
  final void Function(Grade grade, Subject subject) onTapGrade;

  const SubjectLedgerTable({
    super.key,
    required this.subjects,
    required this.selectedSubject,
    required this.onSelectSubject,
    required this.onTapGrade,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(gradesSearchQueryProvider);
    final term = ref.watch(gradesTermProvider);

    final filteredSubjects = subjects.where((s) {
      if (searchQuery.trim().isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.teacherName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Search & Legend Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    onChanged: (val) {
                      ref.read(gradesSearchQueryProvider.notifier).setQuery(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Szukaj przedmiotu lub nauczyciela...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Weights Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Wagi:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildLegendBadge('Waga 3 (Sprawdzian)', const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  _buildLegendBadge('Waga 2 (Kartkówka)', const Color(0xFFEFF4FF), const Color(0xFF4F46E5)),
                  const SizedBox(width: 6),
                  _buildLegendBadge('Waga 1 (Bieżąca)', const Color(0xFFF1F5F9), const Color(0xFF64748B)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Ledger Table Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.surfaceContainerLow,
                child: const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'PRZEDMIOT & PROWADZĄCY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'OCENY CZĄSTKOWE (WAGA)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'ŚR. WAŻ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'PRZEW.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        'OSTATNI WPIS',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table Rows
              if (filteredSubjects.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Nie znaleziono przedmiotów spełniających kryteria',
                      style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredSubjects.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: AppColors.surfaceContainerHigh,
                  ),
                  itemBuilder: (context, index) {
                    final subject = filteredSubjects[index];
                    final isSelected = selectedSubject?.id == subject.id;
                    return _buildTableRow(context, subject, isSelected, term);
                  },
                ),

              // Table Footer / Summary Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surfaceContainerLow,
                child: Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Łącznie w semestrze: ${subjects.length} przedmiotów zrealizowanych zgodnie z podstawą',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const Text(
                      'Średnia ogólna: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '4.82',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(BuildContext context, Subject s, bool isSelected, int term) {
    final avg = s.calculateWeightedAverage(term);
    final avgStr = avg > 0 ? avg.toStringAsFixed(2) : (s.weightedAverageSem1?.toStringAsFixed(2) ?? '4.80');

    // Predicted grade
    final predicted = s.predictedGrade != null
        ? '${s.predictedGrade}'
        : (avg >= 4.75 ? '5' : (avg >= 3.75 ? '4' : '3'));

    // Recent grade
    final gradesList = term == 3
        ? s.grades
        : s.grades.where((g) => g.term == term).toList();
    final lastGrade = gradesList.isNotEmpty ? gradesList.first : null;
    final lastDateStr = lastGrade != null
        ? DateFormat('d MMM yyyy', 'pl').format(lastGrade.date)
        : '-';

    return Material(
      color: isSelected
          ? AppColors.surfaceContainerHigh.withValues(alpha: 0.45)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onSelectSubject(s), // D-04: selects subject in inspector
        hoverColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 4, // 4px left primary accent bar (D-04)
              ),
            ),
          ),
          child: Row(
            children: [
              // Col 1: Subject & Teacher (Flex 4)
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    _buildSubjectAvatar(s.name),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  s.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (s.name.toLowerCase().contains('rozszerz') || s.name.endsWith('R'))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryFixed,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Rozszerz.',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.teacherName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Col 2: Grades Pills Wrap (Flex 4) - D-05: clicks DO NOT select row
              Expanded(
                flex: 4,
                child: gradesList.isEmpty
                    ? const Text(
                        'Brak ocen',
                        style: TextStyle(fontSize: 11, color: AppColors.outline),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: gradesList.map((grade) {
                          return _buildGradePill(grade, s);
                        }).toList(),
                      ),
              ),

              // Col 3: Average (60px)
              SizedBox(
                width: 60,
                child: Text(
                  avgStr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: avg >= 4.75 ? AppColors.secondary : AppColors.primary,
                  ),
                ),
              ),

              // Col 4: Predicted (60px)
              SizedBox(
                width: 60,
                child: Center(
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      predicted,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ),

              // Col 5: Last Entry Date & Teacher (100px)
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lastDateStr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      _abbreviateTeacher(s.teacherName),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectAvatar(String name) {
    String glyph;
    Color bg;
    Color text;

    final lower = name.toLowerCase();
    if (lower.contains('matemat')) {
      glyph = '∑';
      bg = AppColors.primaryContainer;
      text = Colors.white;
    } else if (lower.contains('fizyk')) {
      glyph = 'λ';
      bg = AppColors.primaryContainer;
      text = Colors.white;
    } else if (lower.contains('chem')) {
      glyph = '⚗';
      bg = const Color(0xFF0284C7);
      text = Colors.white;
    } else if (lower.contains('polski')) {
      glyph = 'PL';
      bg = AppColors.surfaceContainerHigh;
      text = AppColors.onSurface;
    } else if (lower.contains('angiel')) {
      glyph = 'EN';
      bg = AppColors.surfaceContainerHigh;
      text = AppColors.onSurface;
    } else if (lower.contains('inform')) {
      glyph = '</>';
      bg = AppColors.secondary;
      text = Colors.white;
    } else if (lower.contains('histori')) {
      glyph = '🏛';
      bg = AppColors.surfaceContainerHigh;
      text = AppColors.onSurface;
    } else if (lower.contains('biolog')) {
      glyph = '🧬';
      bg = const Color(0xFF059669);
      text = Colors.white;
    } else {
      glyph = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name;
      bg = AppColors.surfaceContainerHigh;
      text = AppColors.onSurface;
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        glyph,
        style: TextStyle(
          fontSize: glyph.length > 2 ? 11 : 13,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
  }

  /// Grade Pill with isolated tap handler (Decision D-05)
  Widget _buildGradePill(Grade grade, Subject subject) {
    Color pillBg;
    Color textColor;

    final isHigh = grade.numericValue >= 5.0;
    final isMid = grade.numericValue >= 4.0;

    if (grade.weight >= 3) {
      pillBg = isHigh
          ? AppColors.secondary
          : (isMid ? AppColors.primaryContainer : const Color(0xFFDC2626));
      textColor = Colors.white;
    } else if (grade.weight == 2) {
      pillBg = isHigh
          ? AppColors.secondary
          : (isMid ? AppColors.primaryContainer : AppColors.tertiaryFixedDim);
      textColor = (isHigh || isMid) ? Colors.white : AppColors.tertiary;
    } else {
      pillBg = isHigh
          ? AppColors.secondary
          : (isMid ? AppColors.primary : AppColors.surfaceContainerHighest);
      textColor = (isHigh || isMid) ? Colors.white : AppColors.onSurface;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // Crucial D-05: tapping pill triggers onTapGrade directly without selecting row!
        behavior: HitTestBehavior.opaque,
        onTap: () {
          onTapGrade(grade, subject);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                grade.rawValue,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                'w:${grade.weight}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  String _abbreviateTeacher(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length >= 3) {
      return '${parts[0]} ${parts[1][0]}. ${parts[2]}';
    } else if (parts.length == 2) {
      return '${parts[0][0]}. ${parts[1]}';
    }
    return fullName;
  }
}
