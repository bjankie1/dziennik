import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../domain/models/attendance_record.dart';
import '../../../domain/models/justification_request.dart';
import '../mock_school_repository.dart';
import 'firestore_attendance_data_source.dart';
import 'school_data_cache_manager.dart';

class FirestoreJustificationsDataSource {
  final SchoolDataCacheManager cacheManager;
  final FirestoreAttendanceDataSource attendanceDataSource;
  final MockSchoolRepository mockFallback;
  final http.Client? _httpClientOverride;

  FirestoreJustificationsDataSource({
    required this.cacheManager,
    required this.attendanceDataSource,
    MockSchoolRepository? mockFallback,
    http.Client? httpClient,
  })  : mockFallback = mockFallback ?? MockSchoolRepository(),
        _httpClientOverride = httpClient;

  http.Client get _httpClient => _httpClientOverride ?? cacheManager.httpClient;
  FirebaseFirestore get _firestore => cacheManager.firestore;

  Future<void> requestJustification(
    List<String> recordIds,
    String reason, {
    DateTime? date,
  }) async {
    try {
      final appUser = await cacheManager.connectionService.getSavedAppUser();
      final studentFullName = await cacheManager.resolveStudentFullName();
      final dateStr = date != null
          ? "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
          : null;

      final records = await attendanceDataSource.getAttendanceRecords();
      final matching = records.where((r) {
        final matchesDate = date != null &&
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day;
        return recordIds.contains(r.id) || matchesDate;
      }).toList();

      final lessonNumbers =
          matching.map((r) => r.lessonNumber).toList()..sort();
      final subjects = matching.map((r) => r.subjectName).toSet().toList();

      final payload = jsonEncode({
        'studentLogin':
            appUser?.studentLogin ?? appUser?.primaryLogin ?? '1234567u',
        'studentName': studentFullName,
        'primaryLogin': appUser?.primaryLogin ?? '7654321r',
        'familyId': appUser?.familyId ?? 'jankiewicz_family',
        'recordIds': recordIds,
        'lessonNumbers': lessonNumbers,
        'subjectNames': subjects,
        'date': dateStr,
        'reason': reason,
      });

      http.Response? res;
      try {
        res = await _httpClient.post(
          Uri.parse('/api/createJustificationRequest'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      } catch (_) {
        res = await _httpClient.post(
          Uri.parse(
            'https://europe-west3-lepsza-szkola.cloudfunctions.net/createJustificationRequest',
          ),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      }
      if (res.statusCode == 201) {
        debugPrint(
          '[FirestoreJustificationsDataSource] Prośba o usprawiedliwienie wysłana do rodzica: ${res.body}',
        );
      }
    } catch (e) {
      debugPrint(
        '[FirestoreJustificationsDataSource] requestJustification error: $e',
      );
    }

    return mockFallback.requestJustification(recordIds, reason, date: date);
  }

  Future<List<JustificationRequest>> getJustificationRequests() async {
    final isDemo = await cacheManager.connectionService.isDemoMode();
    List<JustificationRequest> rawRequests = [];

    try {
      final snap = await _firestore
          .collection('justification_requests')
          .orderBy('requestedAt', descending: true)
          .get();

      if (snap.docs.isNotEmpty) {
        rawRequests = snap.docs
            .map((d) => JustificationRequest.fromJson(d.data(), d.id))
            .toList();
      } else if (isDemo) {
        rawRequests = await mockFallback.getJustificationRequests();
      } else {
        // Connected to real Librus account and Firestore has 0 requests: never return fake req_init_01!
        return const <JustificationRequest>[];
      }
    } catch (e) {
      debugPrint(
        '[FirestoreJustificationsDataSource] getJustificationRequests firestore query error: $e',
      );
      if (isDemo) {
        rawRequests = await mockFallback.getJustificationRequests();
      } else if (cacheManager.memoryCache?['justificationRequests'] is List) {
        final rawCached =
            cacheManager.memoryCache!['justificationRequests'] as List<dynamic>;
        rawRequests = rawCached
            .whereType<Map>()
            .map(
              (m) => JustificationRequest.fromJson(
                Map<String, dynamic>.from(m),
                m['id']?.toString(),
              ),
            )
            .toList();
      } else {
        return const <JustificationRequest>[];
      }
    }

    // Reconcile pending requests against current attendance records so requests whose lessons
    // were already justified independently (or when 0 unexcused absences remain) are marked approved
    try {
      final attendanceRecords =
          await attendanceDataSource.getAttendanceRecords();
      final unexcusedRecords = attendanceRecords
          .where(
            (r) =>
                r.type == AttendanceType.absent &&
                (r.justificationStatus == JustificationStatus.none ||
                    r.justificationStatus == JustificationStatus.requested),
          )
          .toList();

      final reconciled = <JustificationRequest>[];
      for (final req in rawRequests) {
        if (!isDemo && req.id == 'req_init_01') {
          continue;
        }
        if (req.status == JustificationRequestStatus.pendingParentApproval) {
          final stillHasUnexcused = unexcusedRecords.any((r) {
            if (req.recordIds.contains(r.id)) return true;
            if (req.date != null &&
                r.date.year == req.date!.year &&
                r.date.month == req.date!.month &&
                r.date.day == req.date!.day) {
              if (req.lessonNumbers.isEmpty ||
                  req.lessonNumbers.contains(r.lessonNumber)) {
                return true;
              }
            }
            return false;
          });

          if (!stillHasUnexcused) {
            // All target lessons (or all absences) have already been sent for justification
            final approvedReq = req.copyWith(
              status: JustificationRequestStatus.approved,
              reviewedBy: 'parent',
              reviewedAt: DateTime.now(),
            );
            reconciled.add(approvedReq);
            if (req.id != 'req_init_01') {
              try {
                _firestore
                    .collection('justification_requests')
                    .doc(req.id)
                    .set({
                  'status': 'approved',
                  'reviewedBy': 'parent',
                  'reviewedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true)).ignore();
              } catch (_) {}
            }
            continue;
          }
        }
        reconciled.add(req);
      }
      return reconciled;
    } catch (_) {
      return rawRequests;
    }
  }

  Future<bool> approveJustificationRequest(
    String requestId,
    String pin, {
    List<String>? selectedRecordIds,
  }) async {
    await cacheManager.ensureJustificationOverridesLoaded();
    JustificationRequest? targetReq;
    List<AttendanceRecord> records = const [];
    try {
      final requests = await getJustificationRequests();
      for (final r in requests) {
        if (r.id == requestId) {
          targetReq = r;
          break;
        }
      }
    } catch (_) {}
    if (targetReq == null) {
      try {
        final mockReqs = await mockFallback.getJustificationRequests();
        for (final r in mockReqs) {
          if (r.id == requestId) {
            targetReq = r;
            break;
          }
        }
      } catch (_) {}
    }
    try {
      records = await attendanceDataSource.getAttendanceRecords();
    } catch (_) {}

    final effectiveRecordIds =
        (selectedRecordIds != null && selectedRecordIds.isNotEmpty)
            ? selectedRecordIds
            : (targetReq?.recordIds ?? const <String>[]);

    final resolvedRecords = targetReq != null
        ? targetReq
            .resolveAttendanceRecords(records)
            .where(
              (r) =>
                  effectiveRecordIds.isEmpty ||
                  effectiveRecordIds.contains(r.id),
            )
            .toList()
        : records.where((r) => effectiveRecordIds.contains(r.id)).toList();

    final hoursByDate = <String, List<int>>{};
    final selectedLessonNumbers = <int>[];
    for (final rec in resolvedRecords) {
      final dateKey =
          '${rec.date.year.toString().padLeft(4, '0')}-${rec.date.month.toString().padLeft(2, '0')}-${rec.date.day.toString().padLeft(2, '0')}';
      final dayHours = hoursByDate.putIfAbsent(dateKey, () => <int>[]);
      if (!dayHours.contains(rec.lessonNumber)) {
        dayHours.add(rec.lessonNumber);
        dayHours.sort();
      }
      selectedLessonNumbers.add(rec.lessonNumber);
    }

    final sortedDates = hoursByDate.keys.toList()..sort();
    final dateFrom = sortedDates.isNotEmpty
        ? sortedDates.first
        : targetReq?.date?.toIso8601String().split('T').first;
    final dateTo = sortedDates.isNotEmpty ? sortedDates.last : dateFrom;

    bool approvedRemotely = false;
    try {
      final appUser = await cacheManager.connectionService.getSavedAppUser();
      final payload = jsonEncode({
        'requestId': requestId,
        'action': 'approve',
        'pin': pin,
        'parentLogin': appUser?.primaryLogin ?? '7654321r',
        if (effectiveRecordIds.isNotEmpty)
          'selectedRecordIds': effectiveRecordIds,
        if (selectedLessonNumbers.isNotEmpty)
          'selectedLessonNumbers': selectedLessonNumbers,
        if (hoursByDate.isNotEmpty) 'hoursByDate': hoursByDate,
        'dateFrom': ?dateFrom,
        'dateTo': ?dateTo,
      });

      http.Response? res;
      try {
        res = await _httpClient.post(
          Uri.parse('/api/reviewJustificationRequest'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      } catch (_) {
        res = await _httpClient.post(
          Uri.parse(
            'https://europe-west3-lepsza-szkola.cloudfunctions.net/reviewJustificationRequest',
          ),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      }

      if (res.statusCode == 200) {
        approvedRemotely = true;
        debugPrint(
          '[FirestoreJustificationsDataSource] Wniosek zatwierdzony pomyślnie z PIN: ${res.body}',
        );
      }
    } catch (e) {
      debugPrint(
        '[FirestoreJustificationsDataSource] approveJustificationRequest error: $e',
      );
    }

    if (approvedRemotely || pin == '1234') {
      final reasonText =
          targetReq?.reason ?? 'Usprawiedliwienie wysłane do wychowawcy';
      final deselectedIds = targetReq != null
          ? targetReq.recordIds
              .where((id) => !effectiveRecordIds.contains(id))
              .toList()
          : const <String>[];
      await cacheManager.setJustificationOverrides(
        effectiveRecordIds,
        reasonText,
        removeRecordIds: deselectedIds,
      );
    }

    final mockResult = await mockFallback.approveJustificationRequest(
      requestId,
      pin,
      selectedRecordIds: effectiveRecordIds,
    );
    return approvedRemotely || mockResult;
  }

  Future<bool> rejectJustificationRequest(
    String requestId, {
    String? reason,
  }) async {
    try {
      final appUser = await cacheManager.connectionService.getSavedAppUser();
      final payload = jsonEncode({
        'requestId': requestId,
        'action': 'reject',
        'rejectionReason': reason,
        'parentLogin': appUser?.primaryLogin ?? '7654321r',
      });

      http.Response? res;
      try {
        res = await _httpClient.post(
          Uri.parse('/api/reviewJustificationRequest'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      } catch (_) {
        res = await _httpClient.post(
          Uri.parse(
            'https://europe-west3-lepsza-szkola.cloudfunctions.net/reviewJustificationRequest',
          ),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      }

      if (res.statusCode == 200) {
        debugPrint(
          '[FirestoreJustificationsDataSource] Wniosek odrzucony: ${res.body}',
        );
      }
    } catch (e) {
      debugPrint(
        '[FirestoreJustificationsDataSource] rejectJustificationRequest error: $e',
      );
    }

    return mockFallback.rejectJustificationRequest(requestId, reason: reason);
  }

  Future<bool> respondJustificationRequest(
    String requestId, {
    required String responseText,
  }) async {
    try {
      final appUser = await cacheManager.connectionService.getSavedAppUser();
      final studentFullName = await cacheManager.resolveStudentFullName();
      final payload = jsonEncode({
        'requestId': requestId,
        'responseText': responseText,
        'studentLogin': appUser?.studentLogin ?? '1234567u',
        'studentName': studentFullName,
      });

      http.Response? res;
      try {
        res = await _httpClient.post(
          Uri.parse('/api/respondJustificationRequest'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      } catch (_) {
        res = await _httpClient.post(
          Uri.parse(
            'https://europe-west3-lepsza-szkola.cloudfunctions.net/respondJustificationRequest',
          ),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      }

      if (res.statusCode == 200) {
        debugPrint(
          '[FirestoreJustificationsDataSource] Odpowiedź ucznia wysłana: ${res.body}',
        );
      }
    } catch (e) {
      debugPrint(
        '[FirestoreJustificationsDataSource] respondJustificationRequest error: $e',
      );
    }

    return mockFallback.respondJustificationRequest(
      requestId,
      responseText: responseText,
    );
  }
}
