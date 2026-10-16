enum GradeCategory {
  exam, // Sprawdzian
  quiz, // Kartkówka
  oral, // Odpowiedź ustna
  homework, // Praca domowa
  activity, // Aktywność
  project, // Projekt
}

class Grade {
  final String id;
  final String subjectName;
  final String rawValue; // "5", "5-", "4+", etc.
  final double numericValue;
  final int weight;
  final GradeCategory category;
  final String categoryName;
  final String comment;
  final String teacher;
  final DateTime date;
  final int term; // 1 or 2
  final bool isCountedToAverage;
  final int? percentage;

  const Grade({
    required this.id,
    required this.subjectName,
    required this.rawValue,
    required this.numericValue,
    required this.weight,
    required this.category,
    required this.categoryName,
    required this.comment,
    required this.teacher,
    required this.date,
    required this.term,
    this.isCountedToAverage = true,
    this.percentage,
  });

  bool get isMenScaleGrade => numericValue >= 1.0 && numericValue <= 6.0;

  int? get menScaleBucket {
    if (!isMenScaleGrade) return null;
    final digitMatch = RegExp(r'[1-6]').firstMatch(rawValue);
    if (digitMatch != null) {
      return int.parse(digitMatch.group(0)!);
    }
    return numericValue.floor().clamp(1, 6);
  }

  static double? tryParseMenValue(String rawValue) {
    final cleaned = rawValue.trim();
    if (cleaned.isEmpty) return null;
    final match =
        RegExp(r'^([1-6])([+-])?$|^([+-])([1-6])$').firstMatch(cleaned);
    if (match != null) {
      final digitStr = match.group(1) ?? match.group(4)!;
      final modStr = match.group(2) ?? match.group(3);
      double val = double.parse(digitStr);
      if (modStr == '+') {
        val += 0.5;
      } else if (modStr == '-') {
        val -= 0.25;
      }
      return val.clamp(1.0, 6.0);
    }
    final parsed = double.tryParse(cleaned.replaceAll(',', '.'));
    if (parsed != null && parsed >= 1.0 && parsed <= 6.0) {
      return parsed;
    }
    return null;
  }
}
