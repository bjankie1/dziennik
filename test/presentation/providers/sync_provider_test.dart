import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edusync/presentation/providers/sync_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
  });
}
