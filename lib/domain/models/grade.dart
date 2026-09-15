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
  });
}
