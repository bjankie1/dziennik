import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/subject.dart';
import '../../../domain/models/grade.dart';
import '../../providers/school_providers.dart';
import 'grade_details_modal.dart';
import 'average_simulator_modal.dart';
import 'widgets/academic_kpi_row.dart';
import 'widgets/subject_ledger_table.dart';
import 'widgets/subject_inspector_card.dart';
import 'widgets/average_trajectory_card.dart';
import 'widgets/grade_details_side_sheet.dart';

class _GradePalette {
  final Color bg;
  final Color text;
  final Color weightColor;
  final Color circleBg;

  const _GradePalette({
    required this.bg,
    required this.text,
    required this.weightColor,
    required this.circleBg,
  });
}

_GradePalette _getGradePalette(Grade grade) {
  final numVal = grade.numericValue;
  if (numVal >= 4.75) {
    // 5, 5+, 6
    return const _GradePalette(
      bg: Color(0xFFDCFCE7),
      text: Color(0xFF15803D),
      weightColor: Color(0xFF16A34A),
      circleBg: Color(0xFFBBF7D0),
    );
  } else if (numVal >= 3.75) {
    // 4, 4+
    return const _GradePalette(
      bg: Color(0xFFDBEAFE),
      text: Color(0xFF1D4ED8),
      weightColor: Color(0xFF2563EB),
      circleBg: Color(0xFFBFDBFE),
    );
  } else if (numVal >= 2.75) {
    // 3, 3+
    return const _GradePalette(
      bg: Color(0xFFFEF3C7),
      text: Color(0xFFB45309),
      weightColor: Color(0xFFD97706),
      circleBg: Color(0xFFFDE68A),
    );
  } else {
    // 1, 2
    return const _GradePalette(
      bg: Color(0xFFFEE2E2),
      text: Color(0xFFB91C1C),
      weightColor: Color(0xFFDC2626),
      circleBg: Color(0xFFFECACA),
    );
  }
}

Color _getSubjectDotColor(String subjectName) {
  final lower = subjectName.toLowerCase();
  if (lower.contains('matemat')) return const Color(0xFF4F46E5); // indigo
  if (lower.contains('polsk')) return const Color(0xFFB45309); // warm amber/brown
  if (lower.contains('angiel')) return const Color(0xFF059669); // emerald
  if (lower.contains('fizyk')) return const Color(0xFFD97706); // amber/orange
  if (lower.contains('chem')) return const Color(0xFF7C3AED); // purple
  if (lower.contains('biolog')) return const Color(0xFF16A34A); // green
  if (lower.contains('geograf')) return const Color(0xFF0284C7); // sky blue
  if (lower.contains('histor')) return const Color(0xFFC026D3); // fuchsia
  if (lower.contains('informa')) return const Color(0xFF2563EB); // royal blue
  return const Color(0xFF6366F1);
}

String _formatGradeDate(DateTime date) {
  const months = [
    'Stycznia',
    'Lutego',
    'Marca',
    'Kwietnia',
    'Maja',
    'Czerwca',
    'Lipca',
    'Sierpnia',
    'Września',
    'Października',
    'Listopada',
    'Grudnia',
  ];
  final monthName = (date.month >= 1 && date.month <= 12) ? months[date.month - 1] : '';
  return '${date.day} $monthName';
}

String _getGradesCountLabel(int count) {
  if (count == 1) return 'ocena cząstkowa';
  if (count >= 2 && count <= 4) return 'oceny cząstkowe';
  return 'ocen cząstkowych';
}

class GradesScreen extends ConsumerStatefulWidget {
  const GradesScreen({super.key});

  @override
  ConsumerState<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends ConsumerState<GradesScreen> {
  int _selectedTerm = 1; // 1 = Semestr 1, 2 = Semestr 2, 3 = Roczna
  final Set<String> _expandedSubjectIds = {'sub_mat', 'sub_pol'}; // default expanded

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentProfileProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    final cleanSubjects = (subjectsAsync.value ?? []).where((s) {
      final name = s.name.trim();
      if (name.isEmpty || name.length > 40 || name.contains('\n') || name.contains('\r')) return false;
      final lower = name.toLowerCase();
      if (lower.contains('kategoria') ||
          lower.contains('brak ocen') ||
          lower.contains('punkty startowe') ||
          lower.contains('suma') ||
          lower.contains('okres 1') ||
          lower.contains('okres 2') ||
          lower.contains('ocena opisowa') ||
          lower.contains('zachowanie')) {
        return false;
      }
      return true;
    }).toList();

    final selectedSubject = ref.watch(selectedGradesSubjectProvider);
    final desktopTerm = ref.watch(gradesTermProvider);

    final student = studentAsync.value;
    final overallAvg = student?.overallAverage ?? 4.82;
    final className = student?.className ?? 'Klasa';
    final schoolName = student?.schoolName ?? 'Liceum';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024; // D-01
        if (isDesktop) {
          return _buildDesktopLayout(
            context,
            cleanSubjects,
            overallAvg,
            selectedSubject,
            desktopTerm,
            className: className,
            schoolName: schoolName,
          );
        }
        return _buildMobileLayout(
          context,
          cleanSubjects,
          overallAvg,
          subjectsAsync,
          student?.className ?? 'Klasa',
        );
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    List<Subject> cleanSubjects,
    double overallAvg,
    Subject? selectedSubject,
    int term, {
    required String className,
    required String schoolName,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Academic Context & Breadcrumbs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Semestr $term / 2024-2025',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('•', style: TextStyle(color: AppColors.outline)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Text(
                            'Klasa $className',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('•', style: TextStyle(color: AppColors.outline)),
                    ),
                    Text(
                      schoolName,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                // Action Toolbar
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list_rounded, size: 16),
                      label: const Text('Filtruj wg wag'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        backgroundColor: AppColors.surfaceContainerLowest,
                        side: const BorderSide(color: AppColors.surfaceContainerHigh),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Eksportuj (PDF/XLS)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        backgroundColor: AppColors.surfaceContainerLowest,
                        side: const BorderSide(color: AppColors.surfaceContainerHigh),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Drukuj'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        backgroundColor: AppColors.surfaceContainerLowest,
                        side: const BorderSide(color: AppColors.surfaceContainerHigh),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        if (cleanSubjects.isNotEmpty) {
                          AverageSimulatorModal.show(context, cleanSubjects, overallAvg);
                        }
                      },
                      icon: const Icon(Icons.calculate_rounded, size: 18),
                      label: const Text('Przelicz GPA'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Title & Period Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oceny i Średnie',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Zestawienie wyników akademickich, wag cząstkowych i symulacja klasyfikacji rocznej',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildDesktopPeriodTab(1, 'Semestr 1 (Trwający)', term),
                      _buildDesktopPeriodTab(2, 'Semestr 2', term),
                      _buildDesktopPeriodTab(3, 'Klasyfikacja Roczna', term),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Academic Performance Metric Banners (Top KPI Row)
            const AcademicKpiRow(),
            const SizedBox(height: 24),

            // 4. Master-Detail Desktop Layout (8 cols + 4 cols)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Ledger Table (~68% / 8 cols)
                Expanded(
                  flex: 8,
                  child: Column(
                    children: [
                      SubjectLedgerTable(
                        subjects: cleanSubjects,
                        selectedSubject: selectedSubject,
                        onSelectSubject: (s) {
                          ref.read(selectedGradesSubjectProvider.notifier).select(s);
                        },
                        onTapGrade: (grade, subject) {
                          // D-05: clicking a grade pill directly opens GradeDetailsSideSheet WITHOUT changing selected subject in inspector
                          GradeDetailsSideSheet.show(
                            context,
                            grade: grade,
                            subject: subject,
                            onContactTeacher: () {
                              ref.read(currentNavIndexProvider.notifier).setIndex(4);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const AverageTrajectoryCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Right Column: Subject Inspector Card (~32% / 4 cols)
                Expanded(
                  flex: 4,
                  child: SubjectInspectorCard(
                    subject: selectedSubject,
                    onTapGrade: (grade, subject) {
                      GradeDetailsSideSheet.show(
                        context,
                        grade: grade,
                        subject: subject,
                        onContactTeacher: () {
                          ref.read(currentNavIndexProvider.notifier).setIndex(4);
                        },
                      );
                    },
                    onSimulateGpa: () {
                      if (cleanSubjects.isNotEmpty) {
                        AverageSimulatorModal.show(context, cleanSubjects, overallAvg);
                      }
                    },
                    onContactTeacher: () {
                      ref.read(currentNavIndexProvider.notifier).setIndex(4);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopPeriodTab(int termIndex, String label, int activeTerm) {
    final isSelected = activeTerm == termIndex;
    return GestureDetector(
      onTap: () {
        ref.read(gradesTermProvider.notifier).setTerm(termIndex);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    List<Subject> cleanSubjects,
    double overallAvg,
    AsyncValue<List<Subject>> subjectsAsync,
    String className,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Term Switcher & Simulator Filter Button (Matches Mockup)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      _buildTermTab(1, 'Semestr 1'),
                      _buildTermTab(2, 'Semestr 2'),
                      _buildTermTab(3, 'Roczna'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: IconButton(
                  onPressed: () {
                    if (cleanSubjects.isNotEmpty) {
                      AverageSimulatorModal.show(context, cleanSubjects, overallAvg);
                    }
                  },
                  icon: const Icon(Icons.tune, color: Color(0xFF475569), size: 20),
                  tooltip: 'Symulator i filtry',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Summary Stats Bento Banner (Matches Mockup)
          _buildSummaryStatsCard(className, overallAvg),
          const SizedBox(height: 16),

          // 3. Subjects Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Przedmioty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cleanSubjects.isNotEmpty ? cleanSubjects.length : (subjectsAsync.value?.length ?? 12)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                'Kliknij, aby rozwinąć historię',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Subjects List
          subjectsAsync.when(
            data: (_) => Column(
              children: cleanSubjects.map((sub) => _buildSubjectCard(sub)).toList(),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Błąd pobierania ocen: $err'),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTermTab(int term, String label) {
    final isSelected = _selectedTerm == term;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTerm = term),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStatsCard(String className, double overallAvg) {
    final isEligible = overallAvg >= 4.75;
    final diff = overallAvg - 4.75;
    final diffText = isEligible
        ? 'Spełniony (+${diff.toStringAsFixed(2)})'
        : 'Brakuje -${(-diff).toStringAsFixed(2)}';

    // Calculate progress segments for 4.00 .. 4.75 .. 6.00 bar (Total span = 2.0)
    final clampedAvg = overallAvg.clamp(4.0, 6.0);
    final bluePortion = (clampedAvg < 4.75 ? (clampedAvg - 4.0) : 0.75) / 2.0;
    final greenPortion = (clampedAvg > 4.75 ? (clampedAvg - 4.75) : 0.0) / 2.0;
    final remainingPortion = (1.0 - (bluePortion + greenPortion)).clamp(0.0, 1.0);

    final blueFlex = (bluePortion * 1000).round();
    final greenFlex = (greenPortion * 1000).round();
    final remainingFlex = (remainingPortion * 1000).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ŚREDNIA WAŻONA OCEN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        overallAvg.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 14, color: Color(0xFF16A34A)),
                          SizedBox(width: 2),
                          Text(
                            '+0.14',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFF15803D)),
                        const SizedBox(width: 4),
                        Text(
                          'Top 5% w $className',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pozycja: 2 / 28',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Scholarship Progress Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 16, color: Color(0xFF4338CA)),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Stypendium naukowe (próg 4.75)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      diffText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isEligible ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      if (blueFlex > 0)
                        Expanded(
                          flex: blueFlex,
                          child: Container(height: 8, color: const Color(0xFF4338CA)),
                        ),
                      if (greenFlex > 0)
                        Expanded(
                          flex: greenFlex,
                          child: Container(height: 8, color: const Color(0xFF10B981)),
                        ),
                      if (remainingFlex > 0)
                        Expanded(
                          flex: remainingFlex,
                          child: Container(height: 8, color: const Color(0xFFE2E8F0)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bazowa: 4.00',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      'Cel: 4.75',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                    Text(
                      'Maks: 6.00',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    final isExpanded = _expandedSubjectIds.contains(subject.id);
    final avg = subject.weightedAverageSem1 ?? 0.0;
    final isHighAvg = avg >= 4.75;
    final dotColor = _getSubjectDotColor(subject.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Accordion Header (Click anywhere to expand/collapse)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSubjectIds.remove(subject.id);
                } else {
                  _expandedSubjectIds.add(subject.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              subject.teacherName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isHighAvg ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isHighAvg ? const Color(0xFFBBF7D0) : const Color(0xFFDBEAFE),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              avg.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isHighAvg ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
                              ),
                            ),
                            Text(
                              'Ważona',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: isHighAvg ? const Color(0xFF16A34A) : const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // In-Row Grade Badges Preview (Pills directly visible without expanding)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: subject.grades.map((grade) {
                      final palette = _getGradePalette(grade);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => GradeDetailsModal.show(context, grade),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: palette.bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: palette.circleBg.withValues(alpha: 0.6),
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                text: grade.rawValue,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: palette.text,
                                ),
                                children: [
                                  TextSpan(
                                    text: ' (w:${grade.weight})',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: palette.weightColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content: Detailed Grade List (SZCZEGÓŁOWY WYKAZ OCEN)
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SZCZEGÓŁOWY WYKAZ OCEN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${subject.grades.length} ${_getGradesCountLabel(subject.grades.length)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...subject.grades.map((g) => _buildExpandedGradeRow(g)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final subjects = ref.read(subjectsProvider).value ?? [];
                        final avg = ref.read(studentProfileProvider).value?.overallAverage ?? 4.82;
                        AverageSimulatorModal.show(context, subjects, avg);
                      },
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('Symuluj ocenę dla tego przedmiotu'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedGradeRow(Grade grade) {
    final palette = _getGradePalette(grade);
    final hasComment = grade.comment.isNotEmpty &&
        grade.comment.trim().toLowerCase() != 'brak uwag' &&
        grade.comment.trim().toLowerCase() != 'brak';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => GradeDetailsModal.show(context, grade),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Grade Badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.circleBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  grade.rawValue,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Date, Weight and Comment
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.categoryName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatGradeDate(grade.date)} • Waga: ${grade.weight}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasComment ? '"${grade.comment}"' : 'Brak uwag',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: hasComment ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Percentage Badge (if available)
              if (grade.percentage != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '${grade.percentage}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
