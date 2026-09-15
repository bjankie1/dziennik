import 'grade.dart';

class Subject {
  final String id;
  final String name;
  final String teacherName;
  final List<Grade> grades;
  final double? weightedAverageSem1;
  final double? weightedAverageSem2;
  final int? predictedGrade;
  final int? finalGrade;

  const Subject({
    required this.id,
    required this.name,
    required this.teacherName,
    required this.grades,
    this.weightedAverageSem1,
    this.weightedAverageSem2,
    this.predictedGrade,
    this.finalGrade,
  });

  double calculateWeightedAverage(int term) {
    final termGrades = grades.where((g) => g.term == term && g.isCountedToAverage).toList();
    if (termGrades.isEmpty) return 0.0;
    double weightedSum = 0;
    int totalWeight = 0;
    for (final g in termGrades) {
      weightedSum += g.numericValue * g.weight;
      totalWeight += g.weight;
    }
    return totalWeight == 0 ? 0.0 : (weightedSum / totalWeight);
  }
}
