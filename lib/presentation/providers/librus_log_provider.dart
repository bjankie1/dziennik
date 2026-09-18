import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/librus_query_log.dart';
import '../../data/services/librus_log_service.dart';

final librusLogServiceProvider = Provider<LibrusLogService>((ref) {
  return LibrusLogService();
});

class LibrusLogFilterState {
  final String selectedModule;
  final bool onlyErrors;
  final String searchQuery;

  const LibrusLogFilterState({
    this.selectedModule = 'Wszystkie',
    this.onlyErrors = false,
    this.searchQuery = '',
  });

  LibrusLogFilterState copyWith({
    String? selectedModule,
    bool? onlyErrors,
    String? searchQuery,
  }) {
    return LibrusLogFilterState(
      selectedModule: selectedModule ?? this.selectedModule,
      onlyErrors: onlyErrors ?? this.onlyErrors,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class LibrusLogFilterNotifier extends Notifier<LibrusLogFilterState> {
  @override
  LibrusLogFilterState build() => const LibrusLogFilterState();

  void setModule(String module) {
    state = state.copyWith(selectedModule: module);
  }

  void toggleOnlyErrors() {
    state = state.copyWith(onlyErrors: !state.onlyErrors);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void reset() {
    state = const LibrusLogFilterState();
  }
}

final librusLogFilterProvider =
    NotifierProvider<LibrusLogFilterNotifier, LibrusLogFilterState>(
  LibrusLogFilterNotifier.new,
);

class LibrusLogsNotifier extends AsyncNotifier<List<LibrusQueryLog>> {
  @override
  Future<List<LibrusQueryLog>> build() async {
    final service = ref.read(librusLogServiceProvider);
    return service.fetchLogs();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(librusLogServiceProvider);
      return service.fetchLogs();
    });
  }
}

final librusLogsProvider =
    AsyncNotifierProvider<LibrusLogsNotifier, List<LibrusQueryLog>>(
  LibrusLogsNotifier.new,
);

final filteredLibrusLogsProvider = Provider<List<LibrusQueryLog>>((ref) {
  final logsAsync = ref.watch(librusLogsProvider);
  final filter = ref.watch(librusLogFilterProvider);

  return logsAsync.maybeWhen(
    data: (logs) {
      return logs.where((log) {
        if (filter.selectedModule != 'Wszystkie' &&
            log.module.toLowerCase() != filter.selectedModule.toLowerCase()) {
          return false;
        }
        if (filter.onlyErrors && !log.isError) {
          return false;
        }
        if (filter.searchQuery.isNotEmpty) {
          final q = filter.searchQuery.toLowerCase();
          final matchesEndpoint = log.endpoint.toLowerCase().contains(q);
          final matchesModule = log.module.toLowerCase().contains(q);
          final matchesStatus = log.status.toString().contains(q) || log.statusText.toLowerCase().contains(q);
          if (!matchesEndpoint && !matchesModule && !matchesStatus) {
            return false;
          }
        }
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

class LibrusLogKpi {
  final int totalCount;
  final int successCount;
  final int errorCount;
  final int rateLimitedCount;
  final int cronCount;
  final int manualCount;
  final double avgDurationMs;

  const LibrusLogKpi({
    required this.totalCount,
    required this.successCount,
    required this.errorCount,
    required this.rateLimitedCount,
    required this.cronCount,
    required this.manualCount,
    required this.avgDurationMs,
  });

  double get successRate => totalCount > 0 ? (successCount / totalCount) * 100 : 100.0;
}

final librusLogKpiProvider = Provider<LibrusLogKpi>((ref) {
  final logsAsync = ref.watch(librusLogsProvider);
  final logs = logsAsync.value ?? [];

  if (logs.isEmpty) {
    return const LibrusLogKpi(
      totalCount: 0,
      successCount: 0,
      errorCount: 0,
      rateLimitedCount: 0,
      cronCount: 0,
      manualCount: 0,
      avgDurationMs: 0.0,
    );
  }

  int success = 0;
  int errors = 0;
  int rateLimited = 0;
  int cron = 0;
  int manual = 0;
  int totalDuration = 0;

  for (final log in logs) {
    if (log.isSuccess) success++;
    if (log.isError) errors++;
    if (log.isRateLimited) rateLimited++;
    if (log.isCron) {
      cron++;
    } else {
      manual++;
    }
    totalDuration += log.durationMs;
  }

  return LibrusLogKpi(
    totalCount: logs.length,
    successCount: success,
    errorCount: errors,
    rateLimitedCount: rateLimited,
    cronCount: cron,
    manualCount: manual,
    avgDurationMs: logs.isNotEmpty ? (totalDuration / logs.length) : 0.0,
  );
});
