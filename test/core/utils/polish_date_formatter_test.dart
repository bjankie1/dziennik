import 'package:flutter_test/flutter_test.dart';
import 'package:edusync/core/utils/polish_date_formatter.dart';
import 'package:edusync/domain/models/justification_request.dart';

void main() {
  group('PolishDateFormatter', () {
    test('formatDayHeader formats weekday, day, capitalized genitive month, and year', () {
      expect(
        PolishDateFormatter.formatDayHeader(DateTime(2026, 9, 29)),
        equals('Wtorek, 29 Września 2026'),
      );
      expect(
        PolishDateFormatter.formatDayHeader(DateTime(2026, 3, 16)),
        equals('Poniedziałek, 16 Marca 2026'),
      );
      expect(
        PolishDateFormatter.formatDayHeader(DateTime(2026, 1, 4)),
        equals('Niedziela, 4 Stycznia 2026'),
      );
    });

    test('JustificationRequest.formatPolishDayHeader delegates to PolishDateFormatter.formatDayHeader', () {
      final date = DateTime(2026, 9, 29);
      expect(
        JustificationRequest.formatPolishDayHeader(date),
        equals(PolishDateFormatter.formatDayHeader(date)),
      );
      expect(
        JustificationRequest.formatPolishDayHeader(date),
        equals('Wtorek, 29 Września 2026'),
      );
    });

    test('formatShortDayHeader and formatFullDate format lowercase genitive months', () {
      expect(
        PolishDateFormatter.formatShortDayHeader(DateTime(2026, 3, 16)),
        equals('Poniedziałek, 16 marca'),
      );
      expect(
        PolishDateFormatter.formatFullDate(DateTime(2026, 3, 16)),
        equals('16 marca 2026'),
      );
      expect(
        PolishDateFormatter.formatFullDate(DateTime(2026, 10, 2)),
        equals('2 października 2026'),
      );
    });

    test('formatNumericDateTime and formatNumericDateShortTime zero-pad date and time', () {
      final dt = DateTime(2026, 3, 5, 9, 7);
      expect(
        PolishDateFormatter.formatNumericDateTime(dt),
        equals('05.03.2026, 09:07'),
      );
      expect(
        PolishDateFormatter.formatNumericDateShortTime(dt),
        equals('05.03, 09:07'),
      );
    });

    test('pluralizeLesson and lessonNounNominative apply Polish pluralization rules', () {
      expect(PolishDateFormatter.pluralizeLesson(0), equals('0 lekcji'));
      expect(PolishDateFormatter.pluralizeLesson(1), equals('1 lekcja'));
      expect(PolishDateFormatter.pluralizeLesson(2), equals('2 lekcje'));
      expect(PolishDateFormatter.pluralizeLesson(3), equals('3 lekcje'));
      expect(PolishDateFormatter.pluralizeLesson(4), equals('4 lekcje'));
      expect(PolishDateFormatter.pluralizeLesson(5), equals('5 lekcji'));
      expect(PolishDateFormatter.pluralizeLesson(11), equals('11 lekcji'));
      expect(PolishDateFormatter.pluralizeLesson(12), equals('12 lekcji'));
      expect(PolishDateFormatter.pluralizeLesson(13), equals('13 lekcji'));
      expect(PolishDateFormatter.pluralizeLesson(14), equals('14 lekcji'));
      expect(PolishDateFormatter.pluralizeLesson(21), equals('21 lekcji'));
      expect(PolishDateFormatter.pluralizeLesson(22), equals('22 lekcje'));
      expect(PolishDateFormatter.pluralizeLesson(24), equals('24 lekcje'));
      expect(PolishDateFormatter.pluralizeLesson(25), equals('25 lekcji'));
    });

    test('pluralizeLessonAccusative returns accusative Polish lesson nouns', () {
      expect(PolishDateFormatter.pluralizeLessonAccusative(0), equals('lekcji'));
      expect(PolishDateFormatter.pluralizeLessonAccusative(1), equals('lekcję'));
      expect(PolishDateFormatter.pluralizeLessonAccusative(2), equals('lekcje'));
      expect(PolishDateFormatter.pluralizeLessonAccusative(3), equals('lekcje'));
      expect(PolishDateFormatter.pluralizeLessonAccusative(4), equals('lekcje'));
      expect(PolishDateFormatter.pluralizeLessonAccusative(5), equals('lekcji'));
      expect(PolishDateFormatter.pluralizeLessonAccusative(12), equals('lekcji'));
      expect(PolishDateFormatter.pluralizeLessonAccusative(14), equals('lekcji'));
      expect(PolishDateFormatter.pluralizeLessonAccusative(22), equals('lekcje'));
    });
  });
}
