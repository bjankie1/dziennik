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
    final termGrades = grades.where((g) {
      final matchesTerm = term == 3 || g.term == term;
      return matchesTerm &&
          g.isCountedToAverage &&
          g.isMenScaleGrade &&
          g.weight > 0;
    }).toList();
    if (termGrades.isEmpty) return 0.0;
    double weightedSum = 0;
    int totalWeight = 0;
    for (final g in termGrades) {
      weightedSum += g.numericValue * g.weight;
      totalWeight += g.weight;
    }
    return totalWeight == 0 ? 0.0 : (weightedSum / totalWeight);
  }

  int? predictedGradeForTerm(int term) {
    if (predictedGrade != null) return predictedGrade;
    final avg = calculateWeightedAverage(term);
    if (avg <= 0) return null;
    if (avg >= 5.50) return 6;
    if (avg >= 4.75) return 5;
    if (avg >= 3.75) return 4;
    if (avg >= 2.75) return 3;
    if (avg >= 1.75) return 2;
    return 1;
  }
}
