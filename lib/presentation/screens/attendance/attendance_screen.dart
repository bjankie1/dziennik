import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/attendance_record.dart';
import '../../providers/school_providers.dart';
import 'justification_modal.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final Set<String> _selectedIds = {};
  int _activeFilter = 0; // 0=Wszystkie, 1=Do usprawiedliwienia, 2=Usprawiedliwione, 3=Spóźnienia

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(attendanceProvider);
    final statsAsync = ref.watch(attendanceStatsProvider);

    final stats = statsAsync.value ?? {
      'presenceCount': 142,
      'absenceCount': 2,
      'lateCount': 0,
      'excusedCount': 0,
      'percentage': 98.6,
    };
    final percentage = (stats['percentage'] as num?)?.toDouble() ?? 98.6;
    final presence = stats['presenceCount'] ?? 142;
    final absences = stats['absenceCount'] ?? 2;
    final lates = stats['lateCount'] ?? 0;
    final excused = stats['excusedCount'] ?? 0;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Attendance Circular Stats Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Circular Progress
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 84,
                          height: 84,
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 8,
                            backgroundColor: AppColors.surfaceContainer,
                            valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const Text(
                              'FREKWENCJA',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Stan semestru',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, size: 12, color: AppColors.secondary),
                                    SizedBox(width: 3),
                                    Text(
                                      'Cel osiągnięty',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                              children: [
                                TextSpan(text: 'Min. ustawowe: '),
                                TextSpan(text: '50%', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                                TextSpan(text: ' • Cel szkoły: '),
                                TextSpan(text: '90%', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (percentage / 100).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceContainer,
                              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$presence obecne', style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                              Text('$absences opuszcz.', style: const TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold)),
                              Text('$lates spóźn.', style: const TextStyle(fontSize: 10, color: AppColors.tertiary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3 Numbers Breakdown Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(number: '$presence', label: 'Obecności', color: AppColors.secondary),
                      _StatColumn(number: '$absences / $excused', label: 'Nieusp. / Usp.', color: AppColors.error),
                      _StatColumn(number: '$lates', label: 'Spóźnienia', color: AppColors.tertiaryContainer),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Filter Pills & List of Records
          attendanceAsync.when(
            data: (records) {
              final unexcused = records.where((r) => r.type == AttendanceType.absent && r.justificationStatus == JustificationStatus.none).toList();
              final excused = records.where((r) => r.type == AttendanceType.excused || r.justificationStatus == JustificationStatus.approved).toList();
              final lates = records.where((r) => r.type == AttendanceType.late).toList();

              List<AttendanceRecord> filtered;
              if (_activeFilter == 1) {
                filtered = unexcused;
              } else if (_activeFilter == 2) {
                filtered = excused;
              } else if (_activeFilter == 3) {
                filtered = lates;
              } else {
                filtered = records;
              }

              // Group by date string (yyyy-MM-dd)
              final grouped = <String, List<AttendanceRecord>>{};
              for (final rec in filtered) {
                final dKey = DateFormat('yyyy-MM-dd').format(rec.date);
                grouped.putIfAbsent(dKey, () => []).add(rec);
              }
              final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(0, 'Wszystkie (${records.length})'),
                        _buildFilterChip(1, 'Do usprawiedliwienia (${unexcused.length})', isAlert: unexcused.isNotEmpty),
                        _buildFilterChip(2, 'Usprawiedliwione (${excused.length})'),
                        _buildFilterChip(3, 'Spóźnienia (${lates.length})'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.rule, size: 18, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Zgłoszenia nieobecności',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      if (unexcused.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedIds.length == unexcused.length) {
                                _selectedIds.clear();
                              } else {
                                _selectedIds.addAll(unexcused.map((r) => r.id));
                              }
                            });
                          },
                          child: Text(
                            _selectedIds.length == unexcused.length ? 'Odznacz wszystkie' : 'Zaznacz wszystkie',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (sortedDates.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceContainerHigh),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 44, color: AppColors.secondary.withValues(alpha: 0.8)),
                          const SizedBox(height: 10),
                          const Text(
                            'Brak wpisów w tej kategorii',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Wszystkie godziny w tym okresie są w porządku!',
                            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  else
                    ...sortedDates.map((dKey) {
                      final dayRecords = grouped[dKey]!;
                      final firstDate = dayRecords.first.date;
                      final rawDateTitle = DateFormat('EEEE, d MMMM yyyy', 'pl_PL').format(firstDate);
                      final dateTitle = rawDateTitle.isNotEmpty
                          ? '${rawDateTitle[0].toUpperCase()}${rawDateTitle.substring(1)}'
                          : rawDateTitle;
                      final unexcusedInDay = dayRecords.where((r) => r.type == AttendanceType.absent).length;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceContainerHigh),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              color: AppColors.surfaceContainerLow,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month, size: 16, color: AppColors.outline),
                                      const SizedBox(width: 6),
                                      Text(
                                        dateTitle,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  if (unexcusedInDay > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$unexcusedInDay do decyzji',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              children: dayRecords.map((rec) => _buildAbsenceRow(rec)).toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Błąd: $err', style: const TextStyle(color: AppColors.error))),
            ),
          ),
          const SizedBox(height: 20),

          // Submit Justification Button
          if (_selectedIds.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  JustificationModal.show(context, _selectedIds.toList(), (reason) {
                    ref.read(attendanceProvider.notifier).submitJustification(_selectedIds.toList(), reason);
                    setState(() => _selectedIds.clear());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wniosek o e-Usprawiedliwienie został wysłany!')),
                    );
                  });
                },
                icon: const Icon(Icons.send, size: 18),
                label: Text(
                  'Usprawiedliw zaznaczone (${_selectedIds.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, {bool isAlert = false}) {
    final isSelected = _activeFilter == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isAlert ? AppColors.errorContainer : AppColors.primary)
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isAlert ? AppColors.error.withValues(alpha: 0.3) : AppColors.surfaceContainerHigh),
            ),
          ),
          child: Row(
            children: [
              if (isAlert) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? (isAlert ? AppColors.onErrorContainer : Colors.white)
                      : (isAlert ? AppColors.error : AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbsenceRow(AttendanceRecord record) {
    final isSelected = _selectedIds.contains(record.id);
    final isRequested = record.justificationStatus == JustificationStatus.requested;

    return InkWell(
      onTap: isRequested
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  _selectedIds.remove(record.id);
                } else {
                  _selectedIds.add(record.id);
                }
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x0A000000))),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isRequested ? false : isSelected,
              onChanged: isRequested
                  ? null
                  : (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(record.id);
                        } else {
                          _selectedIds.remove(record.id);
                        }
                      });
                    },
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.lessonNumber}. ${record.subjectName}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    record.timeSlot,
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (isRequested)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'W TRAKCIE DECYZJI',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.onTertiaryFixed),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NIEOBECNOŚĆ',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.onErrorContainer),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String number;
  final String label;
  final Color color;

  const _StatColumn({required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
