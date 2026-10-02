import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/attendance_record.dart';
import '../../../../domain/models/justification_request.dart';

/// Modal bottom sheet allowing a parent to reject a student's justification request
/// with a dedicated question or comment (REQ-ROLE-04, D-02, D-03, D-05).
class ParentRejectionModal extends StatefulWidget {
  final JustificationRequest request;
  final Future<bool> Function(String reason) onReject;
  final List<AttendanceRecord> availableRecords;
  final String? studentDisplayName;

  const ParentRejectionModal({
    super.key,
    required this.request,
    required this.onReject,
    this.availableRecords = const [],
    this.studentDisplayName,
  });

  static void show(
    BuildContext context,
    JustificationRequest request, {
    required Future<bool> Function(String reason) onReject,
    List<AttendanceRecord> availableRecords = const [],
    String? studentDisplayName,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ParentRejectionModal(
        request: request,
        onReject: onReject,
        availableRecords: availableRecords,
        studentDisplayName: studentDisplayName,
      ),
    );
  }

  @override
  State<ParentRejectionModal> createState() => _ParentRejectionModalState();
}

class _ParentRejectionModalState extends State<ParentRejectionModal> {
  late final TextEditingController _reasonController;
  bool _isProcessing = false;
  String? _errorMessage;

  static const List<String> _quickSuggestions = [
    'Dlaczego opuściłeś tę lekcję?',
    'Przynieś zaświadczenie lekarskie',
    'Porozmawiamy o tym w domu',
    'Nie zgadzam się na nieobecność',
  ];

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: _quickSuggestions.first);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Wybrane lekcje';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Dzisiaj (${DateFormat('dd.MM.yyyy').format(dt)})';
    }
    return DateFormat('dd.MM.yyyy').format(dt);
  }

  Future<void> _handleSubmit() async {
    final text = _reasonController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Wpisz powód odmowy lub wybierz jedną z podpowiedzi.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final success = await widget.onReject(text);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Wystąpił błąd podczas zapisywania odmowy.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final resolvedRecords = widget.request.resolveAttendanceRecords(widget.availableRecords);
    final groupedByDay = JustificationRequest.groupRecordsByDay(resolvedRecords);
    final studentName = widget.studentDisplayName ?? widget.request.effectiveStudentName();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.90,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + bottomInset),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.dangerContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: AppColors.danger,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Odrzucenie prośby',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Wyjaśnij uczniowi ($studentName) powód odmowy lub zadaj pytanie',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Zamknij',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.slate500),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Scrollable middle content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Request summary card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  studentName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                Text(
                                  groupedByDay.length > 1
                                      ? widget.request.formatDateRangeSummary(widget.availableRecords)
                                      : _formatDate(widget.request.date),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...groupedByDay.entries.map((entry) {
                              final dayRecords = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      JustificationRequest.formatPolishDayHeader(dayRecords.first.date),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slate700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...dayRecords.map((rec) {
                                      final hasTeacherOrRoom =
                                          (rec.teacherName != null && rec.teacherName!.isNotEmpty) ||
                                          (rec.classroom != null && rec.classroom!.isNotEmpty);
                                      final teacherRoomText = hasTeacherOrRoom
                                          ? '${rec.teacherName ?? "Nauczyciel"}${rec.classroom != null && rec.classroom!.isNotEmpty ? " • Sala ${rec.classroom}" : ""}'
                                          : null;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '• Lekcja ${rec.lessonNumber} • ${rec.timeSlot} — ${rec.subjectName}${teacherRoomText != null ? " ($teacherRoomText)" : ""}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.slate600,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.slate200),
                              ),
                              child: Text(
                                'Powód ucznia: „${widget.request.reason}”',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.slate700,
                                ),
                              ),
                            ),
                            if (widget.request.dialogHistory.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Historia rozmowy z uczniem:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...widget.request.dialogHistory.map((entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      '${entry.senderName}: ${entry.message}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.slate600,
                                      ),
                                    ),
                                  )),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Szybkie szablony odpowiedzi:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Suggestion chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _quickSuggestions.map((suggestion) {
                          final isSelected = _reasonController.text == suggestion;
                          return ChoiceChip(
                            label: Text(suggestion),
                            selected: isSelected,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onSelected: (selected) {
                              setState(() {
                                _reasonController.text = suggestion;
                                _errorMessage = null;
                              });
                            },
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.dangerDark : AppColors.slate600,
                            ),
                            selectedColor: AppColors.dangerContainer,
                            backgroundColor: AppColors.slate100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? AppColors.dangerBorder : Colors.transparent,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      // Custom comment TextField
                      TextField(
                        controller: _reasonController,
                        maxLines: 3,
                        maxLength: 250,
                        decoration: InputDecoration(
                          labelText: 'Komentarz rodzica (widoczny dla: $studentName)',
                          hintText: 'Wpisz treść wiadomości lub pytania...',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: AppColors.slate50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.slate300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.slate200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                          ),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Pinned Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.slate300),
                      ),
                      child: const Text(
                        'Anuluj',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isProcessing ? null : _handleSubmit,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: Text(
                        _isProcessing ? 'Zapisywanie...' : 'Przekaż odmowę ($studentName)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
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
      ),
    );
  }
}
