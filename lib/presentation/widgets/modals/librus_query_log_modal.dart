import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/librus_query_log.dart';
import '../../providers/librus_log_provider.dart';

class LibrusQueryLogModal extends ConsumerStatefulWidget {
  const LibrusQueryLogModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960, maxHeight: 800),
          child: const LibrusQueryLogModal(),
        ),
      ),
    );
  }

  @override
  ConsumerState<LibrusQueryLogModal> createState() => _LibrusQueryLogModalState();
}

class _LibrusQueryLogModalState extends ConsumerState<LibrusQueryLogModal> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(librusLogsProvider);
    final filteredLogs = ref.watch(filteredLibrusLogsProvider);
    final kpi = ref.watch(librusLogKpiProvider);
    final filter = ref.watch(librusLogFilterProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header
          _buildHeader(context),

          const Divider(height: 1, thickness: 1, color: AppColors.surfaceContainerHigh),

          // 2. KPI Summary Cards
          _buildKpiBar(kpi),

          const Divider(height: 1, thickness: 1, color: AppColors.surfaceContainerHigh),

          // 3. Search & Filter Bar
          _buildFilterBar(filter),

          const Divider(height: 1, thickness: 1, color: AppColors.surfaceContainerHigh),

          // 4. Access Log Table Header
          _buildTableHeader(),

          const Divider(height: 1, thickness: 1, color: AppColors.surfaceContainerHigh),

          // 5. Access Log Table Body
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Nie udało się załadować dziennika zapytań: $err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () => ref.read(librusLogsProvider.notifier).refresh(),
                        child: const Text('Spróbuj ponownie'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (_) {
                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.manage_search_rounded,
                            size: 48,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Brak zapytań spełniających wybrane kryteria',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Zmień filtry modułów lub zresetuj wyszukiwanie.',
                            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredLogs.length,
                  separatorBuilder: (ctx, i) => Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    return _buildLogRow(log);
                  },
                );
              },
            ),
          ),

          // 6. Footer Info
          _buildFooter(filteredLogs.length, kpi.totalCount),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.terminal_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Dziennik zapytań Librus (Access Log)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006C4A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF006C4A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 12, color: Color(0xFF006C4A)),
                          SizedBox(width: 4),
                          Text(
                            'Tryb Stealth (Chrome 133)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF006C4A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Rejestr odpytywania serwerów Librus Synergia • Throttling, cisza nocna (22:30-06:30) i jitter 1.0-2.5s',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Odśwież dziennik',
            onPressed: () => ref.read(librusLogsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Zamknij',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiBar(LibrusLogKpi kpi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppColors.surfaceContainerLowest,
      child: Row(
        children: [
          Expanded(
            child: _buildKpiCard(
              label: 'Wszystkie zapytania',
              value: '${kpi.totalCount}',
              subtitle: '${kpi.cronCount} cron • ${kpi.manualCount} ręcznych',
              icon: Icons.sync_alt_rounded,
              iconColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKpiCard(
              label: 'Średni czas trwania',
              value: '${kpi.avgDurationMs.toStringAsFixed(0)} ms',
              subtitle: 'Human jitter: 1.0–2.5 s',
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKpiCard(
              label: 'Skuteczność (200 OK)',
              value: '${kpi.successRate.toStringAsFixed(1)}%',
              subtitle: '${kpi.successCount} OK • ${kpi.errorCount} błędów',
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKpiCard(
              label: 'Ochrona rate limit',
              value: kpi.rateLimitedCount == 0 ? 'Bezpiecznie' : '${kpi.rateLimitedCount} blokad 429',
              subtitle: 'Cisza nocna: 22:30–06:30',
              icon: Icons.verified_user_outlined,
              iconColor: kpi.rateLimitedCount == 0 ? const Color(0xFF10B981) : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(LibrusLogFilterState filter) {
    final modules = [
      'Wszystkie',
      'Oceny',
      'Plan lekcji',
      'Frekwencja',
      'Wiadomości',
      'Profil / Sesja',
      'Autoryzacja',
      'Cache',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.surfaceContainerLow,
      child: Row(
        children: [
          // Search input
          SizedBox(
            width: 240,
            height: 36,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(librusLogFilterProvider.notifier).setSearchQuery(val),
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Szukaj endpointu, statusu...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                fillColor: AppColors.surfaceContainerLowest,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Module chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: modules.map((m) {
                  final isSelected = filter.selectedModule == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(m),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceContainerLowest,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => ref.read(librusLogFilterProvider.notifier).setModule(m),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Error filter chip
          FilterChip(
            label: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.error),
                SizedBox(width: 4),
                Text('Tylko błędy / 429'),
              ],
            ),
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: filter.onlyErrors ? Colors.white : AppColors.error,
            ),
            selected: filter.onlyErrors,
            selectedColor: AppColors.error,
            backgroundColor: AppColors.error.withValues(alpha: 0.08),
            visualDensity: VisualDensity.compact,
            onSelected: (_) => ref.read(librusLogFilterProvider.notifier).toggleOnlyErrors(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
      child: const Row(
        children: [
          SizedBox(width: 90, child: Text('CZAS', style: _headerStyle)),
          SizedBox(width: 75, child: Text('METODA', style: _headerStyle)),
          Expanded(child: Text('MODUŁ / ENDPOINT', style: _headerStyle)),
          SizedBox(width: 90, child: Text('TRIGGER', style: _headerStyle)),
          SizedBox(width: 100, child: Text('CZAS TRWANIA', style: _headerStyle)),
          SizedBox(width: 120, child: Text('STATUS', style: _headerStyle)),
          SizedBox(width: 85, child: Text('ROZMIAR', style: _headerStyle)),
        ],
      ),
    );
  }

  Widget _buildLogRow(LibrusQueryLog log) {
    Color methodColor;
    if (log.method == 'POST') {
      methodColor = const Color(0xFF7C3AED);
    } else if (log.method == 'CACHE') {
      methodColor = const Color(0xFF0D9488);
    } else {
      methodColor = const Color(0xFF2563EB);
    }

    Color durationColor;
    if (log.durationMs < 500) {
      durationColor = const Color(0xFF059669);
    } else if (log.durationMs < 1500) {
      durationColor = const Color(0xFFD97706);
    } else {
      durationColor = const Color(0xFFEA580C);
    }

    Color statusBg;
    Color statusFg;
    if (log.isRateLimited) {
      statusBg = const Color(0xFFFFFBEB);
      statusFg = const Color(0xFFB45309);
    } else if (log.isError) {
      statusBg = const Color(0xFFFEF2F2);
      statusFg = AppColors.error;
    } else {
      statusBg = const Color(0xFFF0FDF4);
      statusFg = const Color(0xFF16A34A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 90,
            child: Tooltip(
              message: log.formattedDateTime,
              child: Text(
                log.formattedTime,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),

          // Method
          SizedBox(
            width: 75,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log.method,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: methodColor,
                  ),
                ),
              ),
            ),
          ),

          // Module & Endpoint
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.module,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        log.endpoint,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (log.error != null && log.error!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      log.error!,
                      style: const TextStyle(fontSize: 10, color: AppColors.error),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Trigger
          SizedBox(
            width: 90,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: log.isCron
                      ? const Color(0xFF059669).withValues(alpha: 0.12)
                      : const Color(0xFF4F46E5).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log.isCron ? 'CRON' : 'RĘCZNY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: log.isCron ? const Color(0xFF059669) : const Color(0xFF4F46E5),
                  ),
                ),
              ),
            ),
          ),

          // Duration
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: durationColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  log.durationText,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: durationColor,
                  ),
                ),
              ],
            ),
          ),

          // Status
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusFg.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${log.status} ${log.statusText}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // Size
          SizedBox(
            width: 85,
            child: Text(
              log.sizeText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(int filteredCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Wyświetlono $filteredCount z $totalCount zarejestrowanych zapytań',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const Row(
            children: [
              Icon(Icons.lock_clock_outlined, size: 14, color: AppColors.onSurfaceVariant),
              SizedBox(width: 6),
              Text(
                'Nocna przerwa w odpytywaniu: 22:30 – 06:30 (Europe/Warsaw)',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: AppColors.onSurfaceVariant,
  );
}
