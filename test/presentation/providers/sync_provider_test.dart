import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:edusync/presentation/providers/sync_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('pl_PL'));

  group('SyncProvider Cooldown & Status Tests', () {
    test('initial state is configured with sensible defaults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(syncProvider);
      expect(state.isSyncing, false);
      expect(state.statusMessage, contains('Połączono'));
    });

    test('cooldownDuration is 120 seconds (2 minutes)', () {
      expect(SyncNotifier.cooldownDuration, const Duration(seconds: 120));
    });

    test('formattedLastSync returns expected relative labels', () {
      final now = DateTime.now();
      final syncStateJustNow = SyncState(
        isSyncing: false,
        lastSyncTime: now.subtract(const Duration(seconds: 10)),
        statusMessage: 'OK',
        isDemoMode: true,
      );
      expect(syncStateJustNow.formattedLastSync, 'przed chwilą');

      final syncStateMinAgo = SyncState(
        isSyncing: false,
        lastSyncTime: now.subtract(const Duration(minutes: 15)),
        statusMessage: 'OK',
        isDemoMode: true,
      );
      expect(syncStateMinAgo.formattedLastSync, '15 min temu');
    });

    SyncState stateAt(DateTime? t) => SyncState(
          isSyncing: false,
          lastSyncTime: t,
          statusMessage: 'OK',
          isDemoMode: false,
        );

    test('sync from yesterday is labelled "wczoraj", not "dzisiaj"', () {
      final now = DateTime(2026, 9, 29, 17, 45);
      final state = stateAt(DateTime(2026, 9, 28, 17, 58));
      expect(state.formatLastSync(now), 'wczoraj o 17:58');
    });

    test('sync earlier today uses "dzisiaj"', () {
      final now = DateTime(2026, 9, 29, 17, 45);
      final state = stateAt(DateTime(2026, 9, 29, 6, 30));
      expect(state.formatLastSync(now), 'dzisiaj o 06:30');
    });

    test('older sync shows date', () {
      final now = DateTime(2026, 9, 29, 17, 45);
      final state = stateAt(DateTime(2026, 9, 25, 12, 5));
      expect(state.formatLastSync(now), '25.09 o 12:05');
    });

    test('future timestamp (clock skew) is never shown as future time', () {
      final now = DateTime(2026, 9, 29, 17, 45);
      final state = stateAt(DateTime(2026, 9, 29, 17, 58));
      expect(state.formatLastSync(now), 'przed chwilą');
    });

    test('UTC backend timestamp is converted to local time', () {
      final utc = DateTime.utc(2026, 9, 29, 10, 0);
      final now = utc.toLocal().add(const Duration(hours: 2));
      final expected = 'dzisiaj o ${utc.toLocal().hour.toString().padLeft(2, '0')}:00';
      expect(stateAt(utc).formatLastSync(now), expected);
    });

    test('missing sync time shows "brak danych"', () {
      expect(stateAt(null).formatLastSync(DateTime.now()), 'brak danych');
    });
  });
}
