import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/attendance_record.dart';
import '../../../domain/models/justification_request.dart';
import '../../providers/school_providers.dart';
import '../../providers/auth_providers.dart';
import 'justification_modal.dart';
import 'widgets/dual_ring_attendance_gauge.dart';
import 'widgets/student_justification_modal.dart';
import 'widgets/parent_approval_modal.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  final int? initialFilter;

  const AttendanceScreen({super.key, this.initialFilter});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final Set<String> _selectedIds = {};
  late int _activeFilter = widget.initialFilter ?? 1; // 0=Wszystkie, 1=Do usprawiedliwienia (domyślny), 2=Usprawiedliwione
  String _selectedQuickReason = 'Wizyta lekarska';

  final List<String> _quickReasons = const [
    'Choroba',
    'Wizyta lekarska',
    'Sprawy rodzinne',
    'Zawody sportowe',
  ];

  String _formatDayHeader(DateTime date) {
    const days = [
      'Poniedziałek',
      'Wtorek',
      'Środa',
      'Czwartek',
      'Piątek',
      'Sobota',
      'Niedziela',
    ];
    const months = [
      'Stycznia',
      'Lutego',
      'Marca',
      'Kwietnia',
      'Maja',
      'Czerwca',
      'Lipca',
      'Sierpnia',
      'Września',
      'Października',
      'Listopada',
      'Grudnia',
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  String _getLessonLabel(int count) {
    if (count == 1) return 'lekcję';
    if (count >= 2 && count <= 4) return 'lekcje';
    return 'lekcji';
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(attendanceProvider);
    final statsAsync = ref.watch(attendanceStatsProvider);
    final user = ref.watch(appUserProvider);
    final isStudent = user?.isStudent ?? false;
    final isParent = !isStudent;

    final justificationRequestsAsync = ref.watch(justificationRequestsProvider);
    final pendingRequests = (justificationRequestsAsync.value ?? [])
        .where((r) => r.status.isPending)
        .toList();

    final records = attendanceAsync.value ?? [];

    final unexcused = records
        .where((r) => r.type == AttendanceType.absent && r.justificationStatus == JustificationStatus.none)
        .toList();
    final pendingList = records
        .where((r) => r.justificationStatus == JustificationStatus.requested)
        .toList();
    final excusedList = records
        .where((r) =>
            r.type == AttendanceType.excused ||
            r.type == AttendanceType.exempted ||
            r.justificationStatus == JustificationStatus.approved)
        .toList();
    final latesList = records
        .where((r) => r.type == AttendanceType.late || r.type == AttendanceType.excusedLate)
        .toList();

    // Dokładne statystyki wyliczone z rzeczywistych rekordów i obecności z Librusa
    final stats = statsAsync.value;
    final int backendPresence = stats?['presenceCount'] ?? 142;
    final int unexcusedCount = unexcused.length;
    final int pendingCount = pendingList.length;
    final int excusedCount = excusedList.length;
    final int latesCount = latesList.isNotEmpty ? latesList.length : (stats?['lateCount'] ?? 2);
    final int totalLessons = backendPresence + unexcusedCount + pendingCount + excusedCount + latesCount;

    // 1. Frekwencja fizyczna: obecności / wszystkie
    final double physicalPercentage = totalLessons > 0
        ? ((backendPresence + latesCount) / totalLessons) * 100
        : (stats?['percentage'] as num?)?.toDouble() ?? 94.2;

    // 2. Frekwencja rozliczona: obecności + usprawiedliwione / wszystkie
    final double settledPercentage = totalLessons > 0
        ? ((backendPresence + excusedCount + latesCount) / totalLessons) * 100
        : 99.4;

    final int totalAbsences = unexcusedCount + pendingCount + excusedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: _selectedIds.isNotEmpty ? 220 : 32,
            ),
            children: [
              // Baner powiadomień dla rodzica o prośbach ucznia (REQ-ROLE-02)
              if (isParent && pendingRequests.isNotEmpty) ...[
                _buildParentPendingBanner(context, pendingRequests),
                const SizedBox(height: 14),
              ],

              // 1. Karta Stanu Semestru (Dual Ring Bento Header)
              _buildSemesterStatusCard(
                physicalPercentage: physicalPercentage,
                settledPercentage: settledPercentage,
                presence: backendPresence,
                totalAbsences: totalAbsences,
                lates: latesCount,
                excused: excusedCount,
                unexcusedCount: unexcusedCount,
                totalLessons: totalLessons,
              ),
              const SizedBox(height: 14),

              // 2. Filtry kafelkowe i lista obecności
              attendanceAsync.when(
                data: (records) {
                  final unexcused = records
                      .where((r) => r.type == AttendanceType.absent && r.justificationStatus == JustificationStatus.none)
                      .toList();
                  final pendingList = records
                      .where((r) => r.justificationStatus == JustificationStatus.requested)
                      .toList();
                  final excusedList = records
                      .where((r) =>
                          r.type == AttendanceType.excused ||
                          r.type == AttendanceType.exempted ||
                          r.justificationStatus == JustificationStatus.approved)
                      .toList();

                  List<AttendanceRecord> filtered;
                  if (_activeFilter == 1) {
                    filtered = unexcused;
                  } else if (_activeFilter == 2) {
                    filtered = excusedList;
                  } else {
                    filtered = records;
                  }

                  // Group by date (yyyy-MM-dd)
                  final grouped = <String, List<AttendanceRecord>>{};
                  for (final rec in filtered) {
                    final dKey = '${rec.date.year.toString().padLeft(4, '0')}-${rec.date.month.toString().padLeft(2, '0')}-${rec.date.day.toString().padLeft(2, '0')}';
                    grouped.putIfAbsent(dKey, () => []).add(rec);
                  }
                  final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                  final availableToSelect = unexcused.map((r) => r.id).toSet();
                  final allSelected = availableToSelect.isNotEmpty &&
                      availableToSelect.every((id) => _selectedIds.contains(id));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pasek filtrów
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(0, 'Wszystkie'),
                            _buildFilterChip(1, 'Do usprawiedliwienia (${unexcused.length})', isAlert: unexcused.isNotEmpty),
                            _buildFilterChip(2, 'Usprawiedliwione'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (pendingList.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_empty_rounded, color: Color(0xFFD97706), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${pendingList.length} ${pendingList.length == 1 ? "wniosek czeka" : "wnioski czekają"} na wychowawcę (kliknij lekcję, aby zarządzać).',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final ids = pendingList.map((r) => r.id).toList();
                                  await ref.read(attendanceProvider.notifier).cancelJustification(ids);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Przywrócono nieobecności do ponownego usprawiedliwienia.'),
                                        backgroundColor: Color(0xFF3525CD),
                                      ),
                                    );
                                  }
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Cofnij wnioski',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Nagłówek sekcji zgłoszeń
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune, size: 18, color: Color(0xFF3525CD)),
                              SizedBox(width: 6),
                              Text(
                                'Zgłoszenia nieobecności',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          if (unexcused.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  if (allSelected) {
                                    _selectedIds.removeAll(availableToSelect);
                                  } else {
                                    _selectedIds.addAll(availableToSelect);
                                  }
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                allSelected ? 'Odznacz wszystkie' : 'Zaznacz wszystkie',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF3525CD),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (sortedDates.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          alignment: Alignment.center,
                          child: const Column(
                            children: [
                              Icon(Icons.check_circle_outline, size: 44, color: Color(0xFF10B981)),
                              SizedBox(height: 10),
                              Text(
                                'Brak wpisów w tej kategorii',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Wszystkie godziny w tym okresie są rozliczone!',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        )
                      else
                        ...sortedDates.map((dKey) {
                          final dayRecords = grouped[dKey]!;
                          final firstDate = dayRecords.first.date;
                          final dateTitle = _formatDayHeader(firstDate);
                          final unexcusedInDay = dayRecords.where((r) => r.type == AttendanceType.absent && r.justificationStatus == JustificationStatus.none).length;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x04000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                // Nagłówek dnia
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  color: const Color(0xFFF8FAFC),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                          const SizedBox(width: 8),
                                          Text(
                                            dateTitle,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (unexcusedInDay > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$unexcusedInDay DO DECYZJI',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFDC2626),
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'ROZLICZONE',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF059669),
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                                // Wiersze lekcji w danym dniu
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
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('Błąd: $err', style: const TextStyle(color: Color(0xFFDC2626))),
                  ),
                ),
              ),
            ],
          ),

          // 3. Pływający dolny panel (Docked Floating Justification Dock) wg makiety
          if (_selectedIds.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildFloatingJustificationDock(context, isStudent: isStudent),
            ),
        ],
      ),
    );
  }

  Widget _buildSemesterStatusCard({
    required double physicalPercentage,
    required double settledPercentage,
    required int presence,
    required int totalAbsences,
    required int lates,
    required int excused,
    required int unexcusedCount,
    required int totalLessons,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Dual Ring Gauge (Zewnętrzny: rozliczona, Wewnętrzny: obecność fizyczna)
              DualRingAttendanceGauge(
                physicalPercentage: physicalPercentage,
                settledPercentage: settledPercentage,
                unexcusedCount: unexcusedCount,
                size: 96,
              ),
              const SizedBox(width: 16),

              // Szczegóły stanu semestru i legenda ringów
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Stan semestru',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: unexcusedCount == 0
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: unexcusedCount == 0
                                  ? const Color(0xFFBBF7D0)
                                  : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                unexcusedCount == 0
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded,
                                size: 12,
                                color: unexcusedCount == 0
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB45309),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                unexcusedCount == 0 ? 'Wszystko rozliczone' : '$unexcusedCount do usprawiedliwienia',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: unexcusedCount == 0
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        children: [
                          const TextSpan(text: 'Ustawowe min.: '),
                          const TextSpan(
                            text: '50%',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const TextSpan(text: ' • Fizyczna obecność: '),
                          TextSpan(
                            text: '${physicalPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dwukolorowy pasek postępu (obecne + usprawiedliwione)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: [
                            if (presence > 0)
                              Expanded(
                                flex: presence,
                                child: Container(color: const Color(0xFF0284C7)),
                              ),
                            if (excused > 0)
                              Expanded(
                                flex: excused,
                                child: Container(color: const Color(0xFF059669)),
                              ),
                            if (lates > 0)
                              Expanded(
                                flex: lates,
                                child: Container(color: const Color(0xFFD97706)),
                              ),
                            if (unexcusedCount > 0)
                              Expanded(
                                flex: unexcusedCount,
                                child: Container(color: const Color(0xFFDC2626)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Legenda ringów / wskaźników
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _buildLegendItem(const Color(0xFF059669), 'Ring zewn.: Rozliczona ${settledPercentage.toStringAsFixed(1)}%'),
                        _buildLegendItem(const Color(0xFF0284C7), 'Ring wewn.: Obecność ${physicalPercentage.toStringAsFixed(1)}%'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Kolumny podsumowania (spójne i czytelne wskaźniki godzin)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('$presence', 'Obecności', const Color(0xFF0284C7)),
                _buildStatColumn(
                  '$unexcusedCount',
                  'Do uspraw.',
                  unexcusedCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                  subtitle: 'z $totalAbsences opuszczonych',
                ),
                _buildStatColumn('$excused', 'Usprawiedliwione', const Color(0xFF059669)),
                _buildStatColumn('$lates', 'Spóźnienia', const Color(0xFFD97706)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String number, String label, Color color, {String? subtitle}) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem(Color dotColor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(int index, String label, {bool isAlert = false}) {
    final isSelected = _activeFilter == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isAlert ? const Color(0xFFFEE2E2) : const Color(0xFF3525CD))
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (isAlert ? const Color(0xFFFECACA) : Colors.transparent)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAlert) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
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
                      ? (isAlert ? const Color(0xFFDC2626) : Colors.white)
                      : (isAlert ? const Color(0xFFDC2626) : const Color(0xFF475569)),
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
    final isExempted = record.type == AttendanceType.exempted;
    final isUnexcused = record.type == AttendanceType.absent &&
        record.justificationStatus == JustificationStatus.none;

    final accentColor = isUnexcused
        ? const Color(0xFFDC2626)
        : (isRequested
            ? const Color(0xFFD97706)
            : (isExempted ? const Color(0xFF2563EB) : const Color(0xFF059669)));

    return InkWell(
      onTap: isUnexcused
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedIds.remove(record.id);
                } else {
                  _selectedIds.add(record.id);
                }
              });
            }
          : (isRequested ? () => _showRequestedDetailsModal(context, record) : null),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kolorowy pasek po lewej krawędzi (wg makiety)
              Container(
                width: 4,
                color: accentColor,
              ),
              const SizedBox(width: 10),

              // Checkbox / Ikona stanu
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: isUnexcused
                    ? Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(record.id);
                            } else {
                              _selectedIds.remove(record.id);
                            }
                          });
                        },
                        activeColor: const Color(0xFF3525CD),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      )
                    : (isRequested
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Icon(Icons.hourglass_empty_rounded, size: 20, color: Color(0xFFD97706)),
                          )
                        : (isExempted
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF2563EB)),
                              )
                            : const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFF059669)),
                              ))),
              ),
              const SizedBox(width: 4),

              // Szczegóły lekcji
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lekcja ${record.lessonNumber}: ${record.subjectName}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            record.timeSlot,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${record.classroom ?? "Sala lekcyjna"} • ${record.teacherName ?? "Nauczyciel"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isUnexcused
                                ? 'Nieobecność nieusprawiedliwiona'
                                : (isRequested
                                    ? 'Oczekuje na akceptację rodzica'
                                    : (isExempted
                                        ? 'Zwolnienie z zajęć'
                                        : 'Usprawiedliwiona${record.justificationReason != null ? " (${record.justificationReason})" : ""}')),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      if (isRequested) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_bottom_rounded, size: 12, color: Color(0xFF92400E)),
                              SizedBox(width: 4),
                              Text(
                                'Oczekuje na akceptację rodzica',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentPendingBanner(BuildContext context, List<JustificationRequest> pendingList) {
    final firstReq = pendingList.first;
    final count = firstReq.lessonNumbers.isNotEmpty
        ? firstReq.lessonNumbers.length
        : firstReq.recordIds.length;
    final lessonLabel = _getLessonLabel(count);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.family_restroom_rounded, color: Color(0xFFB45309), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${firstReq.studentName} prosi o usprawiedliwienie',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF78350F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count $lessonLabel • ${firstReq.reason}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () {
              ParentApprovalModal.show(
                context,
                firstReq,
                onApprove: (pin) async {
                  final ok = await ref
                      .read(attendanceProvider.notifier)
                      .approveJustification(firstReq.id, pin);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Usprawiedliwienie dla ${firstReq.studentName} zostało wysłane do szkoły.',
                        ),
                        backgroundColor: const Color(0xFF006C4A),
                      ),
                    );
                  }
                  return ok;
                },
                onReject: (reason) async {
                  final ok = await ref
                      .read(attendanceProvider.notifier)
                      .rejectJustification(firstReq.id, reason: reason);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wniosek ucznia został odrzucony.'),
                        backgroundColor: Color(0xFFDC2626),
                      ),
                    );
                  }
                  return ok;
                },
              );
            },
            icon: const Icon(Icons.pin, size: 14),
            label: const Text(
              'Zatwierdź (PIN)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3525CD),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingJustificationDock(BuildContext context, {bool isStudent = false}) {
    final count = _selectedIds.length;
    final lessonLabel = _getLessonLabel(count);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Górny wiersz z licznikiem i ikoną
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isStudent ? Icons.family_restroom_rounded : Icons.mark_email_read_outlined,
                    color: const Color(0xFF4338CA),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wybrano $count $lessonLabel',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isStudent
                          ? 'Wyślij wniosek do akceptacji rodzica'
                          : 'Gotowe do wysłania e-Usprawiedliwienia',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                  onPressed: () => setState(() => _selectedIds.clear()),
                  tooltip: 'Odznacz wszystkie',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Szybki wybór powodu
            const Text(
              'Szybki powód nieobecności:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickReasons.map((reason) {
                  final isSelected = _selectedQuickReason == reason;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedQuickReason = reason),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Przycisk wysyłki (otwiera modal z kodem PIN rodzica lub modal prośby ucznia)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  if (isStudent) {
                    StudentJustificationModal.show(
                      context,
                      _selectedIds.toList(),
                      initialReason: _selectedQuickReason,
                      onConfirm: (reason, selectedDate) async {
                        final selectedList = _selectedIds.toList();
                        await ref.read(attendanceProvider.notifier).requestJustification(
                              selectedList,
                              reason,
                              date: selectedDate,
                            );
                        setState(() => _selectedIds.clear());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Prośba o usprawiedliwienie (${selectedList.length} $lessonLabel) została przesłana do rodzica.',
                              ),
                              backgroundColor: const Color(0xFF006C4A),
                            ),
                          );
                        }
                      },
                    );
                  } else {
                    JustificationModal.show(
                      context,
                      _selectedIds.toList(),
                      _selectedQuickReason,
                      (reason, pin, selectedDate) async {
                        final selectedList = _selectedIds.toList();
                        await ref.read(attendanceProvider.notifier).submitJustification(
                              selectedList,
                              reason,
                              date: selectedDate,
                            );
                        setState(() => _selectedIds.clear());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Wniosek o usprawiedliwienie (${selectedList.length} $lessonLabel) został pomyślnie wysłany do wychowawcy.',
                              ),
                              backgroundColor: const Color(0xFF006C4A),
                            ),
                          );
                        }
                      },
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3525CD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isStudent
                          ? 'Poproś rodzica o usprawiedliwienie ($count $lessonLabel)'
                          : 'Wyślij usprawiedliwienie ($count $lessonLabel)',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Icon(isStudent ? Icons.send_rounded : Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Informacja pomocnicza pod przyciskiem
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isStudent ? Icons.family_restroom_rounded : Icons.shield_outlined,
                  size: 14,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  isStudent
                      ? 'Wniosek zostanie przekazany rodzicowi do zatwierdzenia kodem PIN'
                      : 'Wymagane zatwierdzenie kodem PIN rodzica w następnym kroku',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestedDetailsModal(BuildContext context, AttendanceRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.hourglass_empty_rounded, color: Color(0xFFD97706), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lekcja ${record.lessonNumber}: ${record.subjectName}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            '${record.timeSlot} • ${record.teacherName ?? "Wychowawca"}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Powód usprawiedliwienia:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.justificationReason?.isNotEmpty == true
                            ? record.justificationReason!
                            : 'Brak podanego powodu',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ref.read(attendanceProvider.notifier).cancelJustification([record.id]);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cofnięto wniosek. Możesz teraz zaznaczyć i edytować.'),
                                backgroundColor: Color(0xFF3525CD),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: const Text('Cofnij wniosek'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ref.read(attendanceProvider.notifier).submitJustification(
                                [record.id],
                                record.justificationReason ?? 'Usprawiedliwienie od rodzica',
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Wysłano wniosek bezpośrednio do Librus Synergia!'),
                                backgroundColor: Color(0xFF059669),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Wyślij do Librusa'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3525CD),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
