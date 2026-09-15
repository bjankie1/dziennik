import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/subject.dart';
import '../../../domain/models/grade.dart';
import '../../providers/school_providers.dart';
import 'grade_details_modal.dart';
import 'average_simulator_modal.dart';

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

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Term Switcher & Simulator Button
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
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
              IconButton.filledTonal(
                onPressed: () {
                  final avg = studentAsync.value?.overallAverage ?? 4.82;
                  if (cleanSubjects.isNotEmpty) {
                    AverageSimulatorModal.show(context, cleanSubjects, avg);
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerLow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.calculate, color: AppColors.primary, size: 20),
                tooltip: 'Symulator ocen',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Summary Stats Bento Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
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
                            letterSpacing: 0.6,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${studentAsync.value?.overallAverage ?? 4.82}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Row(
                              children: [
                                Icon(Icons.arrow_upward, size: 16, color: AppColors.secondary),
                                Text(
                                  '+0.14',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
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
                            color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars, size: 14, color: AppColors.onSecondaryContainer),
                              SizedBox(width: 4),
                              Text(
                                'Top 5% w 3B',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pozycja: 2 / 28',
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Scholarship Progress
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.school, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Stypendium naukowe (próg 4.75)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            'Spełniony (+0.07)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 86,
                              child: Container(height: 8, color: AppColors.primary),
                            ),
                            Expanded(
                              flex: 14,
                              child: Container(height: 8, color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Bazowa: 4.00', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                          Text('Cel: 4.75', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text('Maks: 6.00', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Subjects Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Przedmioty',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cleanSubjects.isNotEmpty ? cleanSubjects.length : (subjectsAsync.value?.length ?? 12)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Text(
                'Dotknij ocenę po szczegóły',
                style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 4. Subjects List
          subjectsAsync.when(
            data: (_) => Column(
              children: cleanSubjects.map((sub) => _buildSubjectCard(sub)).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Błąd: $err'),
          ),
          const SizedBox(height: 30),
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    final isExpanded = _expandedSubjectIds.contains(subject.id);
    final avg = subject.weightedAverageSem1 ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Accordion Header
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
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
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
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              subject.teacherName,
                              style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              avg.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onPrimaryFixedVariant,
                              ),
                            ),
                            const Text(
                              'Ważona',
                              style: TextStyle(fontSize: 8, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.outline,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Grade Badges Preview Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: subject.grades.map((grade) {
                      return InkWell(
                        onTap: () => GradeDetailsModal.show(context, grade),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: RichText(
                            text: TextSpan(
                              text: grade.rawValue,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSecondaryFixedVariant,
                              ),
                              children: [
                                TextSpan(
                                  text: ' (w:${grade.weight})',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSecondaryFixedVariant.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
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

          // Expanded Content: Full Grade List with Details
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0x10000000)),
            Container(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                children: [
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
    return InkWell(
      onTap: () => GradeDetailsModal.show(context, grade),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                grade.rawValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
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
                        grade.categoryName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'waga ${grade.weight}',
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  Text(
                    grade.comment,
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.info_outline, size: 16, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
