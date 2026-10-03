import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../domain/models/attendance_record.dart';
import '../mock_school_repository.dart';
import 'school_data_cache_manager.dart';

class FirestoreAttendanceDataSource {
  final SchoolDataCacheManager cacheManager;
  final MockSchoolRepository mockFallback;
  final http.Client? _httpClientOverride;

  FirestoreAttendanceDataSource({
    required this.cacheManager,
    MockSchoolRepository? mockFallback,
    http.Client? httpClient,
  })  : mockFallback = mockFallback ?? MockSchoolRepository(),
        _httpClientOverride = httpClient;

  http.Client get _httpClient => _httpClientOverride ?? cacheManager.httpClient;
  FirebaseFirestore get _firestore => cacheManager.firestore;

  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    await cacheManager.ensureJustificationOverridesLoaded();
    final data = await cacheManager.getStudentData();
    if (data == null) {
      final list = await mockFallback.getAttendanceRecords();
      return list.map((rec) {
        final reason = cacheManager.getJustificationOverride(rec.id);
        if (reason != null) {
          return AttendanceRecord(
            id: rec.id,
            date: rec.date,
            lessonNumber: rec.lessonNumber,
            subjectName: rec.subjectName,
            type: rec.type,
            timeSlot: rec.timeSlot,
            justificationStatus: JustificationStatus.requested,
            justificationReason: reason,
            classroom: rec.classroom,
            teacherName: rec.teacherName,
          );
        }
        return rec;
      }).toList();
    }
    if (data['attendance'] == null) return [];

    final rawList = data['attendance'] as List<dynamic>? ?? [];
    if (rawList.isEmpty) return [];

    final rawJustifications = data['justifications'] as List<dynamic>? ?? [];
    final rawTimetable = data['timetable'] as List<dynamic>? ?? const [];

    String cleanSubjectName(String s) {
      return s
          .replaceFirst(RegExp(r'^odwołane\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^zastępstwo\s*', caseSensitive: false), '')
          .trim();
    }

    Map<String, String> lookupTimetableSlot(
      int weekday,
      int lessonNum,
      String subjectName,
    ) {
      if (rawTimetable.isEmpty) return const {};
      final cleanSub = cleanSubjectName(subjectName).toLowerCase();

      Map<dynamic, dynamic>? matchedSlot;
      // 1. Exact match by dayOfWeek + lessonNumber
      for (final entry in rawTimetable) {
        if (entry is Map &&
            entry['dayOfWeek'] == weekday &&
            entry['lessonNumber'] == lessonNum) {
          matchedSlot = entry;
          break;
        }
      }
      // 2. Fallback match by dayOfWeek + subject
      if (matchedSlot == null && cleanSub.isNotEmpty && cleanSub != 'lekcja') {
        for (final entry in rawTimetable) {
          if (entry is Map && entry['dayOfWeek'] == weekday) {
            final tSub = cleanSubjectName(
              (entry['subject'] as String?) ??
                  (entry['subjectName'] as String?) ??
                  '',
            ).toLowerCase();
            if (tSub.isNotEmpty &&
                (tSub == cleanSub ||
                    tSub.contains(cleanSub) ||
                    cleanSub.contains(tSub))) {
              matchedSlot = entry;
              break;
            }
          }
        }
      }
      // 3. Fallback match across any day by subject for teacher/room
      if (matchedSlot == null && cleanSub.isNotEmpty && cleanSub != 'lekcja') {
        for (final entry in rawTimetable) {
          if (entry is Map) {
            final tSub = cleanSubjectName(
              (entry['subject'] as String?) ??
                  (entry['subjectName'] as String?) ??
                  '',
            ).toLowerCase();
            if (tSub.isNotEmpty &&
                (tSub == cleanSub ||
                    tSub.contains(cleanSub) ||
                    cleanSub.contains(tSub))) {
              matchedSlot = entry;
              break;
            }
          }
        }
      }

      if (matchedSlot == null) return const {};
      var teacher = ((matchedSlot['teacherName'] as String?) ??
              (matchedSlot['teacher'] as String?) ??
              '')
          .trim();
      if (teacher.toLowerCase().contains('czajkowska')) {
        teacher = 'Melska Grażyna';
      }
      final room = ((matchedSlot['classroom'] as String?) ??
              (matchedSlot['room'] as String?) ??
              '')
          .trim();
      final sub = cleanSubjectName(
        ((matchedSlot['subjectName'] as String?) ??
                (matchedSlot['subject'] as String?) ??
                '')
            .trim(),
      );
      return {
        'teacher': teacher,
        'room': room == 'Sala szkolna' ? '' : room,
        'subject': sub,
      };
    }

    final slotTimes = {
      0: '07:10 - 07:55',
      1: '08:00 - 08:45',
      2: '08:55 - 09:40',
      3: '09:50 - 10:35',
      4: '10:45 - 11:30',
      5: '11:45 - 12:30',
      6: '12:45 - 13:30',
      7: '13:40 - 14:25',
      8: '14:35 - 15:20',
    };

    return rawList.map((item) {
      final lessonNum = item['lessonNumber'] as int? ?? 1;
      final typeStr = item['type'] as String? ?? 'unexcused';
      final rawTooltip = (item['rawTooltip'] as String? ?? '').toLowerCase();
      final symbol = (item['symbol'] as String? ?? '').toLowerCase();
      final dateStr = item['date'] as String? ?? '';

      AttendanceType type = AttendanceType.absent;
      if (typeStr == 'excused' ||
          rawTooltip.contains('uspr') ||
          rawTooltip.contains('usprawiedliw') ||
          rawTooltip.contains('e-usprawiedliwienia') ||
          rawTooltip.contains('usprawiedliwienie dodane') ||
          symbol == 'u' ||
          symbol.startsWith('u') ||
          symbol.contains('unb')) {
        type = AttendanceType.excused;
      } else if (typeStr == 'exempted' ||
          rawTooltip.contains('zwolnieni') ||
          symbol.startsWith('zw')) {
        type = AttendanceType.exempted;
      } else if (typeStr == 'late' ||
          rawTooltip.contains('spóźn') ||
          symbol.startsWith('sp')) {
        type = AttendanceType.late;
      } else if (typeStr == 'present' ||
          (!rawTooltip.contains('nieobecn') && rawTooltip.contains('obecn')) ||
          symbol == 'ob' ||
          symbol == '•') {
        type = AttendanceType.present;
      }

      // Check justification status from backend or cross-check justifications list
      String? backendJustificationReason =
          item['justificationReason'] as String?;
      JustificationStatus backendStatus = JustificationStatus.none;
      if (item['justificationStatus'] == 'approved' ||
          type == AttendanceType.excused) {
        backendStatus = JustificationStatus.approved;
      } else if (item['justificationStatus'] == 'requested') {
        backendStatus = JustificationStatus.requested;
      }

      if (backendStatus == JustificationStatus.none &&
          rawJustifications.isNotEmpty) {
        for (final j in rawJustifications) {
          if (j is Map) {
            final period = (j['period'] as String? ?? '');
            final status = (j['status'] as String? ?? '').toLowerCase();
            if (dateStr.isNotEmpty && period.contains(dateStr)) {
              final mentionsLesson = period.toLowerCase().contains('lekcj');
              final lessonMatches = RegExp('\\b$lessonNum\\b').hasMatch(period);
              if (!mentionsLesson || lessonMatches) {
                if (status.contains('uspr') || status.contains('zaakcept')) {
                  backendStatus = JustificationStatus.approved;
                  type = AttendanceType.excused;
                  backendJustificationReason = j['content'] as String?;
                } else if (status.contains('oczekuj') ||
                    status.contains('przesłan') ||
                    status.contains('nowe')) {
                  backendStatus = JustificationStatus.requested;
                  backendJustificationReason = j['content'] as String?;
                }
                break;
              }
            }
          }
        }
      }

      DateTime dt;
      try {
        dt = DateTime.parse(dateStr);
      } catch (_) {
        dt = DateTime.now();
      }

      final id = item['id'] ?? cacheManager.generateUniqueId();
      final reason = cacheManager.getJustificationOverride(id);
      final isOverridden = reason != null;

      var resolvedSubject = ((item['subjectName'] as String?) ??
              (item['subject'] as String?) ??
              '')
          .trim();
      var resolvedTeacher = ((item['teacherName'] as String?) ??
              (item['teacher'] as String?) ??
              '')
          .trim();
      var resolvedClassroom = ((item['classroom'] as String?) ??
              (item['room'] as String?) ??
              '')
          .trim();
      if (resolvedClassroom == 'Sala szkolna') {
        resolvedClassroom = '';
      }

      if (resolvedTeacher.isEmpty ||
          resolvedClassroom.isEmpty ||
          resolvedSubject.isEmpty ||
          resolvedSubject == 'Lekcja') {
        final slotInfo = lookupTimetableSlot(
          dt.weekday,
          lessonNum,
          resolvedSubject,
        );
        if (resolvedTeacher.isEmpty &&
            (slotInfo['teacher']?.isNotEmpty ?? false)) {
          resolvedTeacher = slotInfo['teacher']!;
        }
        if (resolvedClassroom.isEmpty &&
            (slotInfo['room']?.isNotEmpty ?? false)) {
          resolvedClassroom = slotInfo['room']!;
        }
        if ((resolvedSubject.isEmpty || resolvedSubject == 'Lekcja') &&
            (slotInfo['subject']?.isNotEmpty ?? false)) {
          resolvedSubject = slotInfo['subject']!;
        }
      }
      if (resolvedSubject.isEmpty) {
        resolvedSubject = 'Lekcja';
      }

      return AttendanceRecord(
        id: id,
        date: dt,
        lessonNumber: lessonNum,
        subjectName: resolvedSubject,
        type: type,
        timeSlot: (item['timeSlot'] as String?) ??
            slotTimes[lessonNum] ??
            'Lekcja $lessonNum',
        justificationStatus: isOverridden
            ? JustificationStatus.requested
            : backendStatus,
        justificationReason: reason ?? backendJustificationReason,
        classroom: resolvedClassroom.isNotEmpty ? resolvedClassroom : null,
        teacherName: resolvedTeacher.isNotEmpty ? resolvedTeacher : null,
      );
    }).toList();
  }

  Future<Map<String, dynamic>> getAttendanceStats() async {
    final data = await cacheManager.getStudentData();
    if (data != null && data['attendanceStats'] is Map) {
      final s = data['attendanceStats'] as Map<String, dynamic>;
      return {
        'presenceCount': s['presenceCount'] ?? 142,
        'absenceCount': s['absenceCount'] ?? 6,
        'lateCount': s['lateCount'] ?? 2,
        'excusedCount': s['excusedCount'] ?? 3,
        'percentage': (s['percentage'] as num?)?.toDouble() ?? 94.2,
      };
    }
    return {
      'presenceCount': 142,
      'absenceCount': 6,
      'lateCount': 2,
      'excusedCount': 3,
      'percentage': 94.2,
    };
  }

  Future<void> submitJustification(
    List<String> recordIds,
    String reason, {
    DateTime? date,
  }) async {
    await cacheManager.setJustificationOverrides(recordIds, reason);

    // Send directly to Librus Synergia e-Usprawiedliwienia through Cloud Function
    try {
      final records = await getAttendanceRecords();
      final selected = records.where((r) => recordIds.contains(r.id)).toList();

      String? dateFromStr;
      String? dateToStr;
      final hoursByDate = <String, List<int>>{};
      bool isByHours = true;

      if (date != null) {
        final dStr =
            "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        dateFromStr = dStr;
        dateToStr = dStr;

        final matchingRecords = records
            .where(
              (r) =>
                  r.date.year == date.year &&
                  r.date.month == date.month &&
                  r.date.day == date.day,
            )
            .toList();

        await cacheManager.setJustificationOverrides(
          [...recordIds, ...matchingRecords.map((r) => r.id)],
          reason,
        );

        if (matchingRecords.isNotEmpty) {
          hoursByDate[dStr] =
              matchingRecords.map((r) => r.lessonNumber).toList();
          isByHours = true;
        } else {
          isByHours = false;
        }
      } else if (selected.isNotEmpty) {
        for (final rec in selected) {
          final dateStr =
              "${rec.date.year.toString().padLeft(4, '0')}-${rec.date.month.toString().padLeft(2, '0')}-${rec.date.day.toString().padLeft(2, '0')}";
          hoursByDate.putIfAbsent(dateStr, () => []).add(rec.lessonNumber);
        }

        final sortedDates = hoursByDate.keys.toList()..sort();
        dateFromStr = sortedDates.first;
        dateToStr = sortedDates.last;
        isByHours = true;
      }

      if (dateFromStr != null) {
        final payload = jsonEncode({
          'reason': reason,
          'dateFrom': dateFromStr,
          'dateTo': dateToStr ?? dateFromStr,
          'isByHours': isByHours,
          'hoursByDate': hoursByDate,
          'notifyOthers': true,
        });

        http.Response? res;
        try {
          res = await _httpClient.post(
            Uri.parse('/api/submitJustification'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          );
        } catch (_) {
          res = await _httpClient.post(
            Uri.parse(
              'https://europe-west3-lepsza-szkola.cloudfunctions.net/submitJustification',
            ),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          );
        }

        if (res.statusCode == 200) {
          debugPrint(
            '[FirestoreAttendanceDataSource] e-Usprawiedliwienie wysłane do Librusa: ${res.body}',
          );
        } else {
          debugPrint(
            '[FirestoreAttendanceDataSource] Błąd e-Usprawiedliwienia (${res.statusCode}): ${res.body}',
          );
        }
      }

      // Auto-correlate independent parent justifications with pending student requests in Firestore
      try {
        final justifiedDates = hoursByDate.keys.toSet();
        if (dateFromStr != null) justifiedDates.add(dateFromStr);
        final justifiedIds = recordIds.toSet();

        final reqSnap = await _firestore
            .collection('justification_requests')
            .where('status', isEqualTo: 'pendingParentApproval')
            .get();

        for (final doc in reqSnap.docs) {
          final data = doc.data();
          final reqIds = (data['recordIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toSet();
          final reqDate = (data['date'] ?? '').toString().split('T').first;

          final overlapsIds = reqIds.intersection(justifiedIds).isNotEmpty;
          final matchesDate =
              reqDate.isNotEmpty && justifiedDates.contains(reqDate);

          if (overlapsIds || matchesDate) {
            await doc.reference.set({
              'status': 'approved',
              'reviewedBy': 'parent',
              'reviewedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      } catch (corrErr) {
        debugPrint(
          '[FirestoreAttendanceDataSource] Auto-correlation warning: $corrErr',
        );
      }
    } catch (e) {
      debugPrint(
        '[FirestoreAttendanceDataSource] submitJustification error: $e',
      );
    }

    return mockFallback.submitJustification(recordIds, reason, date: date);
  }

  Future<void> cancelJustification(List<String> recordIds) async {
    await cacheManager.removeJustificationOverrides(recordIds);
    return mockFallback.cancelJustification(recordIds);
  }
}
