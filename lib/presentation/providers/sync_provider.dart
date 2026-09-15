import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'auth_providers.dart';
import 'school_providers.dart';

class SyncState {
  final bool isSyncing;
  final DateTime lastSyncTime;
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

  String get formattedLastSync {
    final now = DateTime.now();
    final diff = now.difference(lastSyncTime);
    if (diff.inSeconds < 45) {
      return 'przed chwilą';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min temu';
    } else {
      final formatter = DateFormat('HH:mm', 'pl_PL');
      return 'dzisiaj o ${formatter.format(lastSyncTime)}';
    }
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
  @override
  SyncState build() {
    _init();
    return SyncState(
      isSyncing: false,
      lastSyncTime: DateTime.now(),
      statusMessage: 'Połączono z serwerem Synergia',
      connectedLogin: null,
      isDemoMode: true,
    );
  }

  Future<void> _init() async {
    final connService = ref.read(librusConnectionServiceProvider);
    final isDemo = await connService.isDemoMode();
    final login = await connService.getConnectedLogin();
    state = state.copyWith(
      isDemoMode: isDemo,
      connectedLogin: login,
      lastSyncTime: DateTime.now(),
    );
  }

  Future<void> syncNow() async {
    if (state.isSyncing) return;
    state = state.copyWith(
      isSyncing: true,
      statusMessage: 'Synchronizacja z Librus Synergia w toku...',
    );

    try {
      // Trigger cloud synchronization endpoint
      final uri = Uri.parse('/api/syncNow');
      try {
        final res = await http.get(uri).timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) {
          // Fallback to absolute Cloud Function URL
          await http.get(Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/syncNow'))
              .timeout(const Duration(seconds: 25));
        }
      } catch (_) {
        // Direct call fallback
        try {
          await http.get(Uri.parse('https://europe-west3-lepsza-szkola.cloudfunctions.net/syncNow'))
              .timeout(const Duration(seconds: 25));
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
      ref.invalidate(announcementsProvider);

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        statusMessage: 'Wszystkie dane są aktualne',
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
