import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/librus_query_log.dart';

class LibrusLogService {
  final FirebaseFirestore _firestore;
  final http.Client _client;

  LibrusLogService({
    FirebaseFirestore? firestore,
    http.Client? client,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _client = client ?? http.Client();

  /// Fetches query logs from Cloud Function API, with fallback to Firestore and mock data.
  Future<List<LibrusQueryLog>> fetchLogs({int limit = 50}) async {
    // 1. Try HTTP endpoint rewrite /api/getLibrusLogs
    try {
      final res = await _client
          .get(Uri.parse('/api/getLibrusLogs?limit=$limit'))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        if (decoded['logs'] is List) {
          final list = (decoded['logs'] as List)
              .map((item) => LibrusQueryLog.fromJson(item as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) return list;
        }
      }
    } catch (e) {
      debugPrint('[LibrusLogService] /api/getLibrusLogs HTTP error: $e');
    }

    // 2. Try direct Firestore read
    try {
      final snapshot = await _firestore
          .collection('librus_query_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 4));

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          DateTime ts = DateTime.now();
          if (data['timestamp'] is Timestamp) {
            ts = (data['timestamp'] as Timestamp).toDate();
          } else if (data['timestamp'] is String) {
            ts = DateTime.tryParse(data['timestamp']) ?? DateTime.now();
          }
          return LibrusQueryLog.fromJson({
            ...data,
            'id': doc.id,
            'timestamp': ts.toIso8601String(),
          });
        }).toList();
      }
    } catch (e) {
      debugPrint('[LibrusLogService] Firestore query error: $e');
    }

    // 3. Fallback to synthetic sample logs if no entries recorded yet
    return _generateSampleLogs();
  }

  List<LibrusQueryLog> _generateSampleLogs() {
    final now = DateTime.now();
    return [
      LibrusQueryLog(
        id: 'log-01',
        url: 'https://synergia.librus.pl/uczen/index',
        endpoint: '/uczen/index',
        method: 'GET',
        status: 200,
        statusText: 'OK (Session Alive Probe)',
        durationMs: 312,
        responseSizeBytes: 24580,
        trigger: 'cron',
        module: 'Profil / Sesja',
        timestamp: now.subtract(const Duration(minutes: 8, seconds: 12)),
      ),
      LibrusQueryLog(
        id: 'log-02',
        url: 'https://synergia.librus.pl/przegladaj_oceny/uczen',
        endpoint: '/przegladaj_oceny/uczen',
        method: 'GET',
        status: 200,
        statusText: 'OK',
        durationMs: 840,
        responseSizeBytes: 48920,
        trigger: 'cron',
        module: 'Oceny',
        timestamp: now.subtract(const Duration(minutes: 8, seconds: 10)),
      ),
      LibrusQueryLog(
        id: 'log-03',
        url: 'https://synergia.librus.pl/przegladaj_plan_lekcji',
        endpoint: '/przegladaj_plan_lekcji',
        method: 'GET',
        status: 200,
        statusText: 'OK',
        durationMs: 620,
        responseSizeBytes: 31200,
        trigger: 'cron',
        module: 'Plan lekcji',
        timestamp: now.subtract(const Duration(minutes: 8, seconds: 7)),
      ),
      LibrusQueryLog(
        id: 'log-04',
        url: 'https://synergia.librus.pl/przegladaj_nb/uczen',
        endpoint: '/przegladaj_nb/uczen',
        method: 'GET',
        status: 200,
        statusText: 'OK',
        durationMs: 450,
        responseSizeBytes: 18450,
        trigger: 'cron',
        module: 'Frekwencja',
        timestamp: now.subtract(const Duration(minutes: 8, seconds: 5)),
      ),
      LibrusQueryLog(
        id: 'log-05',
        url: 'https://synergia.librus.pl/wiadomosci/1/5',
        endpoint: '/wiadomosci/1/5',
        method: 'GET',
        status: 200,
        statusText: 'OK',
        durationMs: 510,
        responseSizeBytes: 21300,
        trigger: 'cron',
        module: 'Wiadomości',
        timestamp: now.subtract(const Duration(minutes: 8, seconds: 3)),
      ),
      LibrusQueryLog(
        id: 'log-06',
        url: 'cache://students/student123',
        endpoint: '/cache/students',
        method: 'CACHE',
        status: 200,
        statusText: 'Served from Cache (Night Mode Silence active)',
        durationMs: 5,
        responseSizeBytes: 0,
        trigger: 'cron',
        module: 'Cache',
        timestamp: now.subtract(const Duration(hours: 4, minutes: 15)),
      ),
    ];
  }
}
