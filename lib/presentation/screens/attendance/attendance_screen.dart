import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  int _activeFilter = 1; // 0=Wszystkie, 1=Do usprawiedliwienia (domyślny), 2=Usprawiedliwione
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

    final stats = statsAsync.value ?? {
      'presenceCount': 142,
      'absenceCount': 6,
      'lateCount': 2,
      'excusedCount': 3,
      'percentage': 94.2,
    };
    final percentage = (stats['percentage'] as num?)?.toDouble() ?? 94.2;
    final presence = stats['presenceCount'] ?? 142;
    final absences = stats['absenceCount'] ?? 6;
    final lates = stats['lateCount'] ?? 2;
    final excused = stats['excusedCount'] ?? 3;
    final unexcusedCount = (absences - excused) > 0 ? (absences - excused) : 3;

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
              // 1. Karta Stanu Semestru (Bento Header wg makiety)
              _buildSemesterStatusCard(percentage, presence, absences, lates, excused, unexcusedCount),
              const SizedBox(height: 14),

              // 2. Filtry kafelkowe i lista obecności
              attendanceAsync.when(
                data: (records) {
                  final unexcused = records
                      .where((r) => r.type == AttendanceType.absent && r.justificationStatus == JustificationStatus.none)
                      .toList();
                  final excusedList = records
                      .where((r) => r.type == AttendanceType.excused || r.justificationStatus == JustificationStatus.approved)
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
              child: _buildFloatingJustificationDock(context),
            ),
        ],
      ),
    );
  }

  Widget _buildSemesterStatusCard(
    double percentage,
    int presence,
    int absences,
    int lates,
    int excused,
    int unexcusedCount,
  ) {
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
              // Circular Progress Indicator (wg makiety)
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: CircularProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0),
                      strokeWidth: 8.5,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF006C4A)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'FREKWENCJA',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Szczegóły stanu semestru
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
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF15803D)),
                              SizedBox(width: 4),
                              Text(
                                'Cel osiągnięty',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        children: [
                          TextSpan(text: 'Min. ustawowe: '),
                          TextSpan(
                            text: '50%',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          TextSpan(text: ' • Cel szkoły: '),
                          TextSpan(
                            text: '90%',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (percentage / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF006C4A)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Legenda 3 kolorowych kropek
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLegendItem(const Color(0xFF059669), '$presence obecne'),
                        _buildLegendItem(const Color(0xFFDC2626), '$absences opuszczonych'),
                        _buildLegendItem(const Color(0xFFD97706), '$lates spóźn.'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Kolumny podsumowania
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
                _buildStatColumn('$presence', 'Obecności', const Color(0xFF059669)),
                _buildRichStatColumn('$unexcusedCount', ' / $excused', 'Nieusp. / Usp.'),
                _buildStatColumn('$lates', 'Spóźnienia', const Color(0xFFD97706)),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildStatColumn(String number, String label, Color color) {
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
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildRichStatColumn(String redNum, String greyPart, String label) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            text: redNum,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFFDC2626),
            ),
            children: [
              TextSpan(
                text: greyPart,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
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
    final isUnexcused = record.type == AttendanceType.absent &&
        record.justificationStatus == JustificationStatus.none;

    final accentColor = isUnexcused
        ? const Color(0xFFDC2626)
        : (isRequested ? const Color(0xFFD97706) : const Color(0xFF059669));

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
          : null,
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
                        : const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                          )),
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
                                    ? 'W trakcie decyzji (oczekuje na wychowawcę)'
                                    : 'Usprawiedliwiona${record.justificationReason != null ? " (${record.justificationReason})" : ""}'),
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

  Widget _buildFloatingJustificationDock(BuildContext context) {
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
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3525CD),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Wybrano lekcje do usprawiedliwienia',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(Icons.edit_calendar_outlined, size: 20, color: Color(0xFF64748B)),
              ],
            ),
            const SizedBox(height: 10),

            // Szybki powód
            const Text(
              'WYBIERZ SZYBKI POWÓD:',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
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

            // Przycisk wysyłki (otwiera modal z kodem PIN rodzica)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  JustificationModal.show(
                    context,
                    _selectedIds.toList(),
                    _selectedQuickReason,
                    (reason, pin) async {
                      final selectedList = _selectedIds.toList();
                      await ref.read(attendanceProvider.notifier).submitJustification(selectedList, reason);
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
                      'Wyślij usprawiedliwienie ($count $lessonLabel)',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Informacja o autoryzacji kodem PIN rodzica
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text(
                  'Wymagane zatwierdzenie kodem PIN rodzica w następnym kroku',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
