import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'auth_providers.dart';
import 'school_providers.dart';

class SyncState {
  final bool isSyncing;

  /// Real time of the last successful Librus sync (local time), taken from the
  /// backend snapshot. Null when not yet known.
  final DateTime? lastSyncTime;
  final String statusMessage;
  final String? connectedLogin;
  final bool isDemoMode;

  const SyncState({
    required this.isSyncing,
    required this.lastSyncTime,
    required this.statusMessage,
    this.connectedLogin,
    required this.isDemoMode,
  });

  String get formattedLastSync => formatLastSync(DateTime.now());

  /// Formats [lastSyncTime] relative to [now] with a correct day label.
  String formatLastSync(DateTime now) {
    final last = lastSyncTime?.toLocal();
    if (last == null) return 'brak danych';

    final diff = now.difference(last);
    // Guard against clock skew: never present a sync from the future.
    if (diff.inSeconds < 45) {
      return 'przed chwilą';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min temu';
    }

    final time = DateFormat('HH:mm', 'pl_PL').format(last);
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    final dayDiff = today.difference(lastDay).inDays;
    if (dayDiff == 0) return 'dzisiaj o $time';
    if (dayDiff == 1) return 'wczoraj o $time';
    return '${DateFormat('dd.MM', 'pl_PL').format(last)} o $time';
  }

  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    String? statusMessage,
    String? connectedLogin,
    bool? isDemoMode,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      statusMessage: statusMessage ?? this.statusMessage,
      connectedLogin: connectedLogin ?? this.connectedLogin,
      isDemoMode: isDemoMode ?? this.isDemoMode,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  static const Duration cooldownDuration = Duration(seconds: 120);
  DateTime? _lastSyncTriggerTime;

  @override
  SyncState build() {
    // Keep the displayed sync time in line with the backend snapshot
    // (scheduled syncs + on-demand syncs both update it).
    ref.listen(studentProfileProvider, (_, next) {
      final serverTime = next.asData?.value.lastSyncTime;
      if (serverTime != null) {
        state = state.copyWith(lastSyncTime: serverTime);
      }
    });

    _init();
    return const SyncState(
      isSyncing: false,
      lastSyncTime: null,
      statusMessage: 'Połączono z serwerem Synergia',
      connectedLogin: null,
      isDemoMode: true,
    );
  }

  Future<void> _init() async {
    // Defer until build() has returned so `state` is initialized.
    await Future<void>.microtask(() {});

    // Profile may already be loaded before this notifier was created.
    final initialServerTime =
        ref.read(studentProfileProvider).asData?.value.lastSyncTime;
    if (initialServerTime != null) {
      state = state.copyWith(lastSyncTime: initialServerTime);
    }

    final connService = ref.read(librusConnectionServiceProvider);
    final isDemo = await connService.isDemoMode();
    final login = await connService.getConnectedLogin();
    state = state.copyWith(
      isDemoMode: isDemo,
      connectedLogin: login,
    );
  }

  bool _isNightSilence(DateTime dt) {
    final totalMinutes = dt.hour * 60 + dt.minute;
    return totalMinutes >= 22 * 60 + 30 || totalMinutes < 6 * 60 + 30;
  }

  Future<void> syncNow({bool ignoreCooldown = false}) async {
    if (state.isSyncing) return;

    final now = DateTime.now();
    if (!ignoreCooldown && _lastSyncTriggerTime != null) {
      final elapsed = now.difference(_lastSyncTriggerTime!);
      if (elapsed < cooldownDuration) {
        final remaining = (cooldownDuration - elapsed).inSeconds;
        state = state.copyWith(
          statusMessage: 'Odczekaj jeszcze ${remaining}s przed kolejnym odświeżeniem.',
        );
        return;
      }
    }

    _lastSyncTriggerTime = now;

    state = state.copyWith(
      isSyncing: true,
      statusMessage: 'Synchronizacja z Librus Synergia w toku...',
    );

    try {
      // Trigger cloud synchronization endpoint with 45s timeout for sequential scraping
      final uri = Uri.parse('/api/syncNow');
      try {
        final res = await http.get(uri).timeout(const Duration(seconds: 45));
        if (res.statusCode != 200) {
          // Fallback to absolute Cloud Function URL
          await http.get(Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/syncNow'))
              .timeout(const Duration(seconds: 45));
        }
      } catch (_) {
        // Direct call fallback
        try {
          await http.get(Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/syncNow'))
              .timeout(const Duration(seconds: 45));
        } catch (_) {}
      }

      final connService = ref.read(librusConnectionServiceProvider);
      final isDemo = await connService.isDemoMode();
      final login = await connService.getConnectedLogin();

      // Refresh all providers
      ref.invalidate(studentProfileProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(recentGradesProvider);
      ref.invalidate(subjectsProvider);
      ref.invalidate(upcomingExamProvider);
      ref.invalidate(weekScheduleProvider);
      ref.invalidate(announcementsProvider);
      ref.invalidate(messagesProvider);
      ref.invalidate(attendanceProvider);

      final isNight = _isNightSilence(now);
      final successMsg = isNight
          ? 'Zsynchronizowano na żądanie (serwery w trybie nocnym)'
          : 'Wszystkie dane są aktualne';

      // lastSyncTime is updated by the studentProfileProvider listener once the
      // refreshed backend snapshot arrives (so it reflects the real sync time).
      state = state.copyWith(
        isSyncing: false,
        statusMessage: successMsg,
        isDemoMode: isDemo,
        connectedLogin: login,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        statusMessage: 'Błąd synchronizacji: $e',
      );
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
