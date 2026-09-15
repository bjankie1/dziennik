import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/subject.dart';

class AverageSimulatorModal extends StatefulWidget {
  final List<Subject> subjects;
  final double currentOverallAverage;

  const AverageSimulatorModal({
    super.key,
    required this.subjects,
    required this.currentOverallAverage,
  });

  static void show(BuildContext context, List<Subject> subjects, double currentOverallAverage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AverageSimulatorModal(
        subjects: subjects,
        currentOverallAverage: currentOverallAverage,
      ),
    );
  }

  @override
  State<AverageSimulatorModal> createState() => _AverageSimulatorModalState();
}

class _AverageSimulatorModalState extends State<AverageSimulatorModal> {
  late String _selectedSubjectId;
  int _simulatedGrade = 5;
  int _simulatedWeight = 3;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.subjects.first.id;
  }

  Subject get _selectedSubject =>
      widget.subjects.firstWhere((s) => s.id == _selectedSubjectId);

  double _calculateSimulatedSubjectAverage() {
    final sub = _selectedSubject;
    double weightedSum = 0;
    int totalWeight = 0;
    for (final g in sub.grades.where((g) => g.isCountedToAverage)) {
      weightedSum += g.numericValue * g.weight;
      totalWeight += g.weight;
    }
    weightedSum += _simulatedGrade * _simulatedWeight;
    totalWeight += _simulatedWeight;
    return totalWeight == 0 ? 0.0 : (weightedSum / totalWeight);
  }

  double _calculateSimulatedOverallAverage() {
    double totalSubjectAverages = 0;
    for (final s in widget.subjects) {
      if (s.id == _selectedSubjectId) {
        totalSubjectAverages += _calculateSimulatedSubjectAverage();
      } else {
        totalSubjectAverages += (s.weightedAverageSem1 ?? 4.5);
      }
    }
    return totalSubjectAverages / widget.subjects.length;
  }

  @override
  Widget build(BuildContext context) {
    final curSubAvg = _selectedSubject.weightedAverageSem1 ?? 4.0;
    final newSubAvg = _calculateSimulatedSubjectAverage();
    final newOverallAvg = _calculateSimulatedOverallAverage();
    final diff = newOverallAvg - widget.currentOverallAverage;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calculate, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Symulator Średniej "Co jeśli"',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'Sprawdź wpływ przewidywanej oceny na wyniki',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Live Comparison Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryFixed),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Średnia ogólna',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            newOverallAvg.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            diff >= 0
                                ? '+${diff.toStringAsFixed(2)}'
                                : diff.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: diff >= 0 ? AppColors.secondary : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(height: 40, width: 1, color: AppColors.outlineVariant),
                  Column(
                    children: [
                      Text(
                        _selectedSubject.name,
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            newSubAvg.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ' (było ${curSubAvg.toStringAsFixed(2)})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Subject Selector
            const Text(
              'Wybierz przedmiot',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubjectId,
                  isExpanded: true,
                  items: widget.subjects.map((s) {
                    return DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSubjectId = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Grade Picker (1..6)
            const Text(
              'Symulowana ocena',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [1, 2, 3, 4, 5, 6].map((grade) {
                final isSelected = _simulatedGrade == grade;
                return InkWell(
                  onTap: () => setState(() => _simulatedGrade = grade),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$grade',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Weight Picker (1, 2, 3, 4, 5)
            const Text(
              'Waga oceny',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Row(
              children: [1, 2, 3, 4].map((w) {
                final isSelected = _simulatedWeight == w;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text('Waga $w'),
                    selected: isSelected,
                    selectedColor: AppColors.primaryFixed,
                    backgroundColor: AppColors.surfaceContainerLow,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.onPrimaryFixedVariant : AppColors.onSurfaceVariant,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _simulatedWeight = w);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Zatwierdź i Zamknij', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
