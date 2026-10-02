/// Shared Polish date, timestamp, and lesson pluralization utility (`REQ-ARCH-01`).
///
/// Centralizes Polish grammatical forms (weekday names, genitive month names,
/// and nominative/accusative pluralization of "lekcja") used across Attendance,
/// Dashboard, Grades, and Justification flows.
abstract final class PolishDateFormatter {
  static const List<String> weekdays = [
    'Poniedziałek',
    'Wtorek',
    'Środa',
    'Czwartek',
    'Piątek',
    'Sobota',
    'Niedziela',
  ];

  static const List<String> monthsGenitiveCapitalized = [
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

  static const List<String> monthsGenitive = [
    'stycznia',
    'lutego',
    'marca',
    'kwietnia',
    'maja',
    'czerwca',
    'lipca',
    'sierpnia',
    'września',
    'października',
    'listopada',
    'grudnia',
  ];

  /// Formats a Polish day header with capitalized genitive month and year,
  /// e.g. `'Wtorek, 29 Września 2026'`.
  static String formatDayHeader(DateTime date) {
    final dayName = (date.weekday >= 1 && date.weekday <= 7)
        ? weekdays[date.weekday - 1]
        : 'Dzień';
    final monthName = (date.month >= 1 && date.month <= 12)
        ? monthsGenitiveCapitalized[date.month - 1]
        : '';
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  /// Formats a short Polish day header with lowercase genitive month and no year,
  /// e.g. `'Poniedziałek, 16 marca'`.
  static String formatShortDayHeader(DateTime date) {
    final dayName = (date.weekday >= 1 && date.weekday <= 7)
        ? weekdays[date.weekday - 1]
        : 'Dzień';
    final monthName = (date.month >= 1 && date.month <= 12)
        ? monthsGenitive[date.month - 1]
        : '';
    return '$dayName, ${date.day} $monthName';
  }

  /// Formats a full Polish date with lowercase genitive month and year,
  /// e.g. `'16 marca 2026'`.
  static String formatFullDate(DateTime date) {
    final monthName = (date.month >= 1 && date.month <= 12)
        ? monthsGenitive[date.month - 1]
        : '';
    return '${date.day} $monthName ${date.year}';
  }

  /// Formats a zero-padded numeric date and time (`'dd.MM.yyyy, HH:mm'`).
  static String formatNumericDateTime(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString().padLeft(4, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yyyy, $hh:$min';
  }

  /// Formats a zero-padded short numeric date and time (`'dd.MM, HH:mm'`).
  static String formatNumericDateShortTime(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd.$mm, $hh:$min';
  }

  /// Returns the nominative/genitive noun form for [count]: `'lekcja'`, `'lekcje'`, or `'lekcji'`.
  static String lessonNounNominative(int count) {
    final absCount = count.abs();
    if (absCount == 1) return 'lekcja';
    final mod10 = absCount % 10;
    final mod100 = absCount % 100;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'lekcje';
    }
    return 'lekcji';
  }

  /// Formats a lesson count with its Polish noun, e.g. `'1 lekcja'`, `'2 lekcje'`, `'5 lekcji'`.
  static String pluralizeLesson(int count) {
    return '$count ${lessonNounNominative(count)}';
  }

  /// Returns the accusative/genitive noun form for [count]: `'lekcję'`, `'lekcje'`, or `'lekcji'`.
  static String pluralizeLessonAccusative(int count) {
    final absCount = count.abs();
    if (absCount == 1) return 'lekcję';
    final mod10 = absCount % 10;
    final mod100 = absCount % 100;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'lekcje';
    }
    return 'lekcji';
  }
}
