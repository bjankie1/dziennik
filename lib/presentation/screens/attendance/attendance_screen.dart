import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/attendance_record.dart';
import '../../../domain/models/justification_request.dart';
import '../../providers/school_providers.dart';
import '../../providers/auth_providers.dart';
import 'justification_modal.dart';
import 'widgets/dual_ring_attendance_gauge.dart';
import 'widgets/student_justification_modal.dart';
import 'widgets/parent_approval_modal.dart';
import 'widgets/parent_rejection_modal.dart';
import 'widgets/student_response_modal.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  final int? initialFilter;

  const AttendanceScreen({super.key, this.initialFilter});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final Set<String> _selectedIds = {};
  late int _activeFilter = widget.initialFilter ?? 1; // 0=Wszystkie, 1=Do usprawiedliwienia (domyślny), 2=Usprawiedliwione, 3=Oczekujące
  bool _isPendingBannerExpanded = false;
  bool _isCancellingPending = false;
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
    final allJustifications = justificationRequestsAsync.value ?? [];
    final pendingRequests = allJustifications
        .where((r) => r.status.isPending)
        .toList();
    final rejectedRequests = allJustifications
        .where((r) => r.status.isRejected)
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
      backgroundColor: AppColors.slate50,
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
              // Baner powiadomień dla rodzica o prośbach ucznia (REQ-ROLE-02, REQ-ROLE-04)
              if (isParent && pendingRequests.isNotEmpty) ...[
                _buildParentPendingBanner(context, pendingRequests),
                const SizedBox(height: 14),
              ],

              // Baner powiadomień dla ucznia o odrzuconych prośbach (REQ-ROLE-04, D-02)
              if (isStudent && rejectedRequests.isNotEmpty) ...[
                _buildStudentRejectedBanner(context, rejectedRequests),
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
                  } else if (_activeFilter == 3) {
                    filtered = pendingList;
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
                            _buildFilterChip(3, 'Oczekujące (${pendingList.length})'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (pendingList.isNotEmpty) ...[
                        _buildPendingTeacherAccordionBanner(context, pendingList),
                      ],

                      // Nagłówek sekcji zgłoszeń
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune, size: 18, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Zgłoszenia nieobecności',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slate900,
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
                                  color: AppColors.primary,
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
                            border: Border.all(color: AppColors.slate200),
                          ),
                          alignment: Alignment.center,
                          child: const Column(
                            children: [
                              Icon(Icons.check_circle_outline, size: 44, color: AppColors.success),
                              SizedBox(height: 10),
                              Text(
                                'Brak wpisów w tej kategorii',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Wszystkie godziny w tym okresie są rozliczone!',
                                style: TextStyle(fontSize: 12, color: AppColors.slate500),
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
                              border: Border.all(color: AppColors.slate200),
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
                                  color: AppColors.slate50,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.slate500),
                                          const SizedBox(width: 8),
                                          Text(
                                            dateTitle,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.slate900,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (unexcusedInDay > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.dangerSurfaceAlt,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$unexcusedInDay DO DECYZJI',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.danger,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.successSurface,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'ROZLICZONE',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.success,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: AppColors.slate100),

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
                    child: Text('Błąd: $err', style: const TextStyle(color: AppColors.danger)),
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
        border: Border.all(color: AppColors.slate200),
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
                            color: AppColors.slate900,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: unexcusedCount == 0
                                ? AppColors.successSurface
                                : AppColors.warningSurfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: unexcusedCount == 0
                                  ? AppColors.successBorder
                                  : AppColors.warningBorder,
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
                                    ? AppColors.successDark
                                    : AppColors.warningText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                unexcusedCount == 0 ? 'Wszystko rozliczone' : '$unexcusedCount do usprawiedliwienia',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: unexcusedCount == 0
                                      ? AppColors.successDark
                                      : AppColors.warningText,
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
                        style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                        children: [
                          const TextSpan(text: 'Ustawowe min.: '),
                          const TextSpan(
                            text: '50%',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate900),
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
                                child: Container(color: AppColors.success),
                              ),
                            if (lates > 0)
                              Expanded(
                                flex: lates,
                                child: Container(color: AppColors.warningIcon),
                              ),
                            if (unexcusedCount > 0)
                              Expanded(
                                flex: unexcusedCount,
                                child: Container(color: AppColors.danger),
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
                        _buildLegendItem(AppColors.success, 'Ring zewn.: Rozliczona ${settledPercentage.toStringAsFixed(1)}%'),
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
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('$presence', 'Obecności', const Color(0xFF0284C7)),
                _buildStatColumn(
                  '$unexcusedCount',
                  'Do uspraw.',
                  unexcusedCount > 0 ? AppColors.danger : AppColors.slate500,
                  subtitle: 'z $totalAbsences opuszczonych',
                ),
                _buildStatColumn('$excused', 'Usprawiedliwione', AppColors.success),
                _buildStatColumn('$lates', 'Spóźnienia', AppColors.warningIcon),
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
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate900),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500),
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
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.slate600,
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
                ? (isAlert ? AppColors.dangerSurfaceAlt : AppColors.primary)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (isAlert ? AppColors.dangerBorder : Colors.transparent)
                  : AppColors.slate200,
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
                    color: AppColors.danger,
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
                      ? (isAlert ? AppColors.danger : Colors.white)
                      : (isAlert ? AppColors.danger : AppColors.slate600),
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
        ? AppColors.danger
        : (isRequested
            ? AppColors.warningIcon
            : (isExempted ? const Color(0xFF2563EB) : AppColors.success));

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
          border: Border(bottom: BorderSide(color: AppColors.slate100)),
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
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      )
                    : (isRequested
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Icon(Icons.hourglass_empty_rounded, size: 20, color: AppColors.warningIcon),
                          )
                        : (isExempted
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF2563EB)),
                              )
                            : const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Icon(Icons.check_circle_outline_rounded, size: 20, color: AppColors.success),
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
                              color: AppColors.slate900,
                            ),
                          ),
                          Text(
                            record.timeSlot,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${record.classroom ?? "Sala lekcyjna"} • ${record.teacherName ?? "Nauczyciel"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
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
                                    ? 'Oczekuje na wychowawcę${record.justificationReason != null && record.justificationReason!.isNotEmpty ? " (${record.justificationReason})" : ""}'
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

  Widget _buildPendingTeacherAccordionBanner(
    BuildContext context,
    List<AttendanceRecord> pendingList,
  ) {
    final groupedByDay = JustificationRequest.groupRecordsByDay(
      pendingList,
      descendingDays: true,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('pending_teacher_banner_toggle'),
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _isPendingBannerExpanded = !_isPendingBannerExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_empty_rounded,
                      color: AppColors.warningIcon,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pendingList.length} ${pendingList.length == 1 ? "wniosek czeka" : "wnioski czekają"} na wychowawcę',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warningTitle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _isPendingBannerExpanded
                                      ? 'Ukryj szczegóły'
                                      : 'Pokaż szczegóły',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warningText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              AnimatedRotation(
                                turns: _isPendingBannerExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: AppColors.warningText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('cancel_all_pending_button'),
                      onPressed: _isCancellingPending
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                useRootNavigator: true,
                                builder: (dialogCtx) => AlertDialog(
                                  title: const Text(
                                    'Cofnąć wszystkie oczekujące wnioski?',
                                  ),
                                  content: Text(
                                    'Czy na pewno chcesz cofnąć wszystkie oczekujące wnioski (${pendingList.length})? Nieobecności wrócą do puli do ponownego usprawiedliwienia.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogCtx).pop(false),
                                      child: const Text('Anuluj'),
                                    ),
                                    FilledButton(
                                      key: const ValueKey(
                                        'confirm_cancel_all_pending_button',
                                      ),
                                      onPressed: () =>
                                          Navigator.of(dialogCtx).pop(true),
                                      child: const Text('Cofnij wszystkie'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true || !mounted) return;
                              setState(() => _isCancellingPending = true);
                              try {
                                final ids =
                                    pendingList.map((r) => r.id).toList();
                                await ref
                                    .read(attendanceProvider.notifier)
                                    .cancelJustification(ids);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Przywrócono nieobecności do ponownego usprawiedliwienia.',
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isCancellingPending = false);
                                }
                              }
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Cofnij wszystkie',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warningText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _isPendingBannerExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(height: 1, color: AppColors.warningBorder),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: groupedByDay.entries.map((entry) {
                            final dayRecords = entry.value;
                            final dayHeader =
                                _formatDayHeader(dayRecords.first.date);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 13,
                                        color: AppColors.warningTitle,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          dayHeader,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.warningDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ...dayRecords.map((rec) {
                                    final hasTeacherOrRoom =
                                        (rec.teacherName != null &&
                                                rec.teacherName!.isNotEmpty) ||
                                            (rec.classroom != null &&
                                                rec.classroom!.isNotEmpty);
                                    final teacherRoomSubtitle = hasTeacherOrRoom
                                        ? '${rec.teacherName ?? "Nauczyciel"}${rec.classroom != null && rec.classroom!.isNotEmpty ? " • Sala ${rec.classroom}" : ""}'
                                        : null;
                                    final sentReason =
                                        (rec.justificationReason != null &&
                                                rec.justificationReason!
                                                    .isNotEmpty)
                                            ? rec.justificationReason!
                                            : 'Usprawiedliwienie wysłane do wychowawcy';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.warningBorder,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Lekcja ${rec.lessonNumber} • ${rec.timeSlot}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.warningText,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  rec.subjectName,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.slate900,
                                                  ),
                                                ),
                                                if (teacherRoomSubtitle !=
                                                    null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    teacherRoomSubtitle,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.slate500,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Powód: $sentReason',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.warningTitle,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            key: ValueKey(
                                              'cancel_pending_${rec.id}',
                                            ),
                                            onPressed: _isCancellingPending
                                                ? null
                                                : () async {
                                                    setState(
                                                      () => _isCancellingPending =
                                                          true,
                                                    );
                                                    try {
                                                      await ref
                                                          .read(
                                                            attendanceProvider
                                                                .notifier,
                                                          )
                                                          .cancelJustification([
                                                            rec.id,
                                                          ]);
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Cofnięto wniosek dla przedmiotu ${rec.subjectName}.',
                                                            ),
                                                            backgroundColor:
                                                                AppColors.primary,
                                                          ),
                                                        );
                                                      }
                                                    } finally {
                                                      if (mounted) {
                                                        setState(
                                                          () =>
                                                              _isCancellingPending =
                                                                  false,
                                                        );
                                                      }
                                                    }
                                                  },
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: AppColors.warningAccent,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              minimumSize: const Size(0, 36),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'Cofnij',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.warningText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildParentPendingBanner(BuildContext context, List<JustificationRequest> pendingList) {
    final firstReq = pendingList.first;
    final attendanceRecords =
        ref.watch(attendanceProvider).value ?? const <AttendanceRecord>[];
    final studentProfile = ref.watch(studentProfileProvider).value;
    final user = ref.watch(appUserProvider);
    final studentName = firstReq.effectiveStudentName(
      profileStudentName: studentProfile?.name,
      currentParentName: user?.displayName,
    );
    final resolved = firstReq.resolveAttendanceRecords(attendanceRecords);
    final count = resolved.isNotEmpty
        ? resolved.length
        : (firstReq.lessonNumbers.isNotEmpty
            ? firstReq.lessonNumbers.length
            : firstReq.recordIds.length);
    final lessonLabel = _getLessonLabel(count);
    final dateRange = firstReq.formatDateRangeSummary(attendanceRecords);

    void openApprovalModal() {
      ParentApprovalModal.show(
        context,
        firstReq,
        availableRecords: attendanceRecords,
        studentDisplayName: studentName,
        onApprove: (pin) async {
          final ok = await ref
              .read(attendanceProvider.notifier)
              .approveJustification(firstReq.id, pin);
          if (ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Usprawiedliwienie dla $studentName zostało wysłane do szkoły.',
                ),
                backgroundColor: AppColors.successDark,
              ),
            );
          }
          return ok;
        },
        onApproveSelected: (pin, selectedIds) async {
          final ok = await ref
              .read(attendanceProvider.notifier)
              .approveJustification(
                firstReq.id,
                pin,
                selectedRecordIds: selectedIds,
              );
          if (ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Usprawiedliwienie dla $studentName zostało wysłane do szkoły.',
                ),
                backgroundColor: AppColors.successDark,
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
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return ok;
        },
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('parent_pending_request_banner'),
        borderRadius: BorderRadius.circular(16),
        onTap: openApprovalModal,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.indigoSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.indigoBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.family_restroom_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$studentName prosi o usprawiedliwienie',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateRange.isNotEmpty ? "$dateRange • " : ""}$count $lessonLabel • ${firstReq.reason}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Zobacz szczegóły →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: openApprovalModal,
                      icon: const Icon(Icons.pin, size: 14),
                      label: const Text(
                        'Zatwierdź (PIN)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ParentRejectionModal.show(
                          context,
                          firstReq,
                          availableRecords: attendanceRecords,
                          studentDisplayName: studentName,
                          onReject: (reason) async {
                            final ok = await ref
                                .read(attendanceProvider.notifier)
                                .rejectJustification(firstReq.id, reason: reason);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Wniosek ucznia został odrzucony z komentarzem.'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                            return ok;
                          },
                        );
                      },
                      icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                      label: const Text(
                        'Odrzuć',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.dangerBorderStrong),
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentRejectedBanner(BuildContext context, List<JustificationRequest> rejectedList) {
    final firstReq = rejectedList.first;
    final count = firstReq.lessonNumbers.isNotEmpty
        ? firstReq.lessonNumbers.length
        : firstReq.recordIds.length;
    final lessonLabel = _getLessonLabel(count);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dangerBorder),
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
            child: const Icon(Icons.info_outline_rounded, color: AppColors.danger, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rodzic odrzucił prośbę o usprawiedliwienie',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dangerTitle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count $lessonLabel • Komentarz: „${firstReq.rejectionReason ?? 'Wymagane wyjaśnienie'}”',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dangerDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () {
              StudentResponseModal.show(
                context,
                firstReq,
                onRespond: (responseText) async {
                  final ok = await ref
                      .read(attendanceProvider.notifier)
                      .respondToJustification(firstReq.id, responseText);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Twoje wyjaśnienie zostało przekazane rodzicowi.'),
                        backgroundColor: Color(0xFF2563EB),
                      ),
                    );
                  }
                  return ok;
                },
              );
            },
            icon: const Icon(Icons.reply_rounded, size: 16),
            label: const Text(
              'Odpowiedz / Poproś ponownie',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
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
        border: Border.all(color: AppColors.slate200),
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
                    color: AppColors.indigoSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isStudent ? Icons.family_restroom_rounded : Icons.mark_email_read_outlined,
                    color: AppColors.primary,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      Text(
                        isStudent
                          ? 'Wyślij wniosek do akceptacji rodzica'
                          : 'Gotowe do wysłania e-Usprawiedliwienia',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.slate400, size: 20),
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
                color: AppColors.slate500,
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
                          color: isSelected ? AppColors.indigoSurface : AppColors.slate100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.slate200,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.slate700,
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
                              backgroundColor: AppColors.successDark,
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
                              backgroundColor: AppColors.successDark,
                            ),
                          );
                        }
                      },
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
                  color: AppColors.slate500,
                ),
                const SizedBox(width: 6),
                Text(
                  isStudent
                      ? 'Wniosek zostanie przekazany rodzicowi do zatwierdzenia kodem PIN'
                      : 'Wymagane zatwierdzenie kodem PIN rodzica w następnym kroku',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500),
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
      useRootNavigator: true,
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
                      color: AppColors.slate300,
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
                        color: AppColors.warningSurfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.hourglass_empty_rounded, color: AppColors.warningIcon, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lekcja ${record.lessonNumber}: ${record.subjectName}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate900),
                          ),
                          Text(
                            '${record.timeSlot} • ${record.teacherName ?? "Wychowawca"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_bottom_rounded, size: 14, color: AppColors.warningTitle),
                      SizedBox(width: 6),
                      Text(
                        'Oczekuje na wychowawcę w Librusie',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warningTitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Powód usprawiedliwienia:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.justificationReason?.isNotEmpty == true
                            ? record.justificationReason!
                            : 'Brak podanego powodu',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isCancellingPending
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                setState(() => _isCancellingPending = true);
                                try {
                                  await ref
                                      .read(attendanceProvider.notifier)
                                      .cancelJustification([record.id]);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cofnięto wniosek. Możesz teraz zaznaczyć i edytować.',
                                        ),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isCancellingPending = false);
                                  }
                                }
                              },
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: const Text('Cofnij wniosek'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.slate600,
                          side: const BorderSide(color: AppColors.slate300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('close_requested_details_modal_button'),
                        onPressed: () => Navigator.pop(ctx),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Zamknij',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
