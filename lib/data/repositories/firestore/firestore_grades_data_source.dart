import '../../../domain/models/grade.dart';
import '../../../domain/models/subject.dart';
import '../mock_school_repository.dart';
import 'school_data_cache_manager.dart';

class FirestoreGradesDataSource {
  final SchoolDataCacheManager cacheManager;
  final MockSchoolRepository mockFallback;

  FirestoreGradesDataSource({
    required this.cacheManager,
    MockSchoolRepository? mockFallback,
  }) : mockFallback = mockFallback ?? MockSchoolRepository();

  Future<List<Subject>> getSubjects() async {
    final data = await cacheManager.getStudentData();
    if (data == null) {
      return mockFallback.getSubjects();
    }
    if (data['subjects'] == null) {
      return [];
    }

    final rawSubjects = data['subjects'] as List<dynamic>? ?? [];
    if (rawSubjects.isEmpty) return [];

    final validSubjects = rawSubjects.where((s) {
      if (s is! Map) return false;
      final rawName = (s['name'] as String? ?? '').trim();
      if (rawName.isEmpty || rawName.length < 2 || rawName.length > 40) {
        return false;
      }
      if (rawName.contains('\n') || rawName.contains('\r')) return false;

      final lower = rawName.toLowerCase();
      if (lower.contains('kategoria') ||
          lower.contains('brak ocen') ||
          lower.contains('ocena opisowa') ||
          lower.contains('punkty startowe') ||
          lower.contains('suma') ||
          lower.contains('okres 1') ||
          lower.contains('okres 2') ||
          lower.contains('zachowanie')) {
        return false;
      }
      return true;
    }).toList();

    if (validSubjects.isEmpty) return [];

    final rawTimetable = data['timetable'] as List<dynamic>? ?? [];
    final ttTeachers = <String, String>{};
    for (final t in rawTimetable) {
      if (t is Map) {
        final rawSubj = (t['subject'] as String? ?? '').trim();
        final rawTeach = (t['teacher'] as String? ?? '').trim();
        if (rawSubj.isNotEmpty && rawTeach.isNotEmpty) {
          final cleanSubj = rawSubj
              .replaceFirst(
                RegExp(r'^(zastępstwo|odwołane)\s*', caseSensitive: false),
                '',
              )
              .trim();
          final cleanTeach =
              rawTeach.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
          ttTeachers.putIfAbsent(cleanSubj.toLowerCase(), () => cleanTeach);
        }
      }
    }

    return validSubjects.map((s) {
      final sName = s['name'] as String? ?? 'Przedmiot';
      final avg = (s['currentAverage'] as num?)?.toDouble();
      var teacher = s['teacher'] as String? ?? '';
      if (teacher.isEmpty) {
        teacher = ttTeachers[sName.toLowerCase()] ?? '';
      }
      final rawGrades = s['grades'] as List<dynamic>? ?? [];

      final grades = rawGrades.map((g) {
        final val = g['value'] as String? ?? '5';
        final numVal = (g['numericalValue'] as num?)?.toDouble() ?? 5.0;
        final weight = (g['weight'] as num?)?.toInt() ?? 1;
        final cat = g['category'] as String? ?? 'Ocena';
        final dateStr = g['date'] as String? ?? '';

        DateTime dt;
        try {
          dt = DateTime.parse(dateStr.split(' ')[0]);
        } catch (_) {
          dt = DateTime.now();
        }

        final tooltip = g['rawTooltip'] as String? ?? '';
        final pctMatch = RegExp(r'(\d{1,3})\s*%').firstMatch(tooltip);
        int? pct = pctMatch != null ? int.tryParse(pctMatch.group(1)!) : null;
        if (pct == null && numVal > 0) {
          if (numVal >= 6.0) {
            pct = 100;
          } else if (numVal >= 5.0) {
            pct = (90 + (numVal - 5.0) * 10).round();
          } else if (numVal >= 4.0) {
            pct = (75 + (numVal - 4.0) * 15).round();
          } else if (numVal >= 3.0) {
            pct = (60 + (numVal - 3.0) * 15).round();
          } else if (numVal >= 2.0) {
            pct = (45 + (numVal - 2.0) * 15).round();
          } else {
            pct = 30;
          }
        }

        String cleanComment = '';
        final commentMatch = RegExp(
          r'Komentarz:\s*([^<]+)',
          caseSensitive: false,
        ).firstMatch(tooltip);
        if (commentMatch != null) {
          cleanComment = commentMatch.group(1)!.trim();
        } else if (!tooltip.contains('Kategoria:') &&
            !tooltip.contains('Waga:')) {
          cleanComment = tooltip.trim();
        }

        return Grade(
          id: g['id'] ?? cacheManager.generateUniqueId(),
          subjectName: sName,
          rawValue: val,
          numericValue: numVal,
          weight: weight,
          category: GradeCategory.activity,
          categoryName: cat,
          comment: cleanComment.isNotEmpty ? cleanComment : 'Brak uwag',
          teacher: g['teacher'] ?? teacher,
          date: dt,
          term: 1,
          percentage: pct,
        );
      }).toList();

      return Subject(
        id: s['id'] ?? sName.toLowerCase(),
        name: sName,
        teacherName: teacher.isNotEmpty ? teacher : 'Nauczyciel',
        grades: grades,
        weightedAverageSem1:
            avg != null && avg > 0 ? avg : (grades.isNotEmpty ? 5.0 : null),
      );
    }).toList();
  }

  Future<List<Grade>> getRecentGrades() async {
    final subjects = await getSubjects();
    final allGrades = <Grade>[];
    for (final s in subjects) {
      allGrades.addAll(s.grades);
    }
    final data = await cacheManager.getStudentData();
    if (data == null && allGrades.isEmpty) {
      return mockFallback.getRecentGrades();
    }
    allGrades.sort((a, b) => b.date.compareTo(a.date));
    return allGrades;
  }
}
