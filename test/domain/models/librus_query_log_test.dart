import 'package:flutter_test/flutter_test.dart';
import 'package:edusync/domain/models/librus_query_log.dart';

void main() {
  group('LibrusQueryLog Model Tests', () {
    test('should parse fromJson and evaluate status helpers correctly', () {
      final json = {
        'id': 'log-123',
        'url': 'https://synergia.librus.pl/przegladaj_oceny/uczen',
        'endpoint': '/przegladaj_oceny/uczen',
        'method': 'GET',
        'status': 200,
        'statusText': 'OK',
        'durationMs': 450,
        'responseSizeBytes': 45000,
        'trigger': 'cron',
        'module': 'Oceny',
        'timestamp': '2026-09-18T10:30:00.000Z',
      };

      final log = LibrusQueryLog.fromJson(json);

      expect(log.id, 'log-123');
      expect(log.endpoint, '/przegladaj_oceny/uczen');
      expect(log.isSuccess, true);
      expect(log.isError, false);
      expect(log.isRateLimited, false);
      expect(log.isCron, true);
      expect(log.durationText, '450 ms');
      expect(log.sizeText, '43.9 KB');
    });

    test('should detect 429 rate limited and cache hit statuses', () {
      final rateLimitedLog = LibrusQueryLog.fromJson({
        'id': 'rl-1',
        'endpoint': '/przegladaj_plan_lekcji',
        'status': 429,
        'method': 'GET',
        'trigger': 'manual',
        'durationMs': 120,
      });

      expect(rateLimitedLog.isRateLimited, true);
      expect(rateLimitedLog.isError, true);
      expect(rateLimitedLog.isSuccess, false);
      expect(rateLimitedLog.isCron, false);

      final cacheLog = LibrusQueryLog.fromJson({
        'id': 'cache-1',
        'endpoint': '/cache/students',
        'status': 200,
        'method': 'CACHE',
        'durationMs': 4,
      });

      expect(cacheLog.isCacheHit, true);
      expect(cacheLog.isSuccess, true);
      expect(cacheLog.durationText, '4 ms');
    });
  });
}
