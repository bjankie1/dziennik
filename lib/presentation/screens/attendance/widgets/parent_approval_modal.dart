import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/attendance_record.dart';
import '../../../../domain/models/justification_request.dart';
import 'parent_rejection_modal.dart';

/// Modal bottom sheet allowing a parent to review, approve with 4-digit PIN,
/// or reject an excuse request submitted by a student (REQ-ROLE-02, D-03, D-04, D-05, D-06, T-14-03).
class ParentApprovalModal extends StatefulWidget {
  final JustificationRequest request;
  final Future<bool> Function(String pin) onApprove;
  final Future<bool> Function(String pin, List<String> selectedRecordIds)? onApproveSelected;
  final Future<bool> Function(String? reason) onReject;
  final List<AttendanceRecord> availableRecords;
  final String? studentDisplayName;

  const ParentApprovalModal({
    super.key,
    required this.request,
    required this.onApprove,
    this.onApproveSelected,
    required this.onReject,
    this.availableRecords = const [],
    this.studentDisplayName,
  });

  static void show(
    BuildContext context,
    JustificationRequest request, {
    required Future<bool> Function(String pin) onApprove,
    Future<bool> Function(String pin, List<String> selectedRecordIds)? onApproveSelected,
    required Future<bool> Function(String? reason) onReject,
    List<AttendanceRecord> availableRecords = const [],
    String? studentDisplayName,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ParentApprovalModal(
        request: request,
        onApprove: onApprove,
        onApproveSelected: onApproveSelected,
        onReject: onReject,
        availableRecords: availableRecords,
        studentDisplayName: studentDisplayName,
      ),
    );
  }

  @override
  State<ParentApprovalModal> createState() => _ParentApprovalModalState();
}

class _ParentApprovalModalState extends State<ParentApprovalModal> {
  final _pinController = TextEditingController(text: '1234');
  bool _pinError = false;
  String? _pinErrorMessage;
  bool _isProcessing = false;
  late final List<AttendanceRecord> _resolvedRecords;
  late final Set<String> _selectedRecordIds;

  @override
  void initState() {
    super.initState();
    _resolvedRecords = widget.request.resolveAttendanceRecords(widget.availableRecords);
    _selectedRecordIds = _resolvedRecords.map((r) => r.id).toSet();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _toggleRecord(String recordId) {
    if (_isProcessing) return;
    setState(() {
      if (_selectedRecordIds.contains(recordId)) {
        _selectedRecordIds.remove(recordId);
      } else {
        _selectedRecordIds.add(recordId);
      }
      if (_selectedRecordIds.isNotEmpty && _pinError) {
        _pinError = false;
        _pinErrorMessage = null;
      }
    });
  }

  void _toggleAll() {
    if (_isProcessing) return;
    setState(() {
      if (_selectedRecordIds.length == _resolvedRecords.length) {
        _selectedRecordIds.clear();
      } else {
        _selectedRecordIds
          ..clear()
          ..addAll(_resolvedRecords.map((r) => r.id));
        _pinError = false;
        _pinErrorMessage = null;
      }
    });
  }

  Future<void> _handleApprove() async {
    if (_selectedRecordIds.isEmpty) {
      setState(() {
        _pinError = true;
        _pinErrorMessage = 'Wybierz co najmniej jedną lekcję do usprawiedliwienia.';
      });
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() {
        _pinError = true;
        _pinErrorMessage = 'Wymagany jest 4-cyfrowy kod PIN (np. 1234)';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _pinError = false;
      _pinErrorMessage = null;
    });

    final selectedList = _resolvedRecords
        .where((r) => _selectedRecordIds.contains(r.id))
        .map((r) => r.id)
        .toList();

    final success = widget.onApproveSelected != null
        ? await widget.onApproveSelected!(pin, selectedList)
        : await widget.onApprove(pin);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isProcessing = false;
        _pinError = true;
        _pinErrorMessage = 'Niepoprawny kod PIN rodzica (domyślny: 1234).';
      });
    }
  }

  Future<void> _handleReject() async {
    Navigator.pop(context);
    ParentRejectionModal.show(
      context,
      widget.request,
      availableRecords: widget.availableRecords,
      studentDisplayName: widget.studentDisplayName,
      onReject: (reason) => widget.onReject(reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final mediaQuery = MediaQuery.of(context);
    final studentName = widget.studentDisplayName ?? req.effectiveStudentName();
    final groupedByDay = JustificationRequest.groupRecordsByDay(_resolvedRecords);
    final allSelected = _selectedRecordIds.length == _resolvedRecords.length;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.90,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: mediaQuery.viewInsets.bottom + 12,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stały nagłówek
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF3525CD), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Autoryzacja wniosku ucznia',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Wniosek od: $studentName',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Oczekuje',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Przewijana zawartość środkowa
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Uzasadnienie ucznia + historia Q&A
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.comment_outlined, size: 16, color: Color(0xFF3525CD)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Uzasadnienie ucznia:',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '"${req.reason}"',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (req.dialogHistory.isNotEmpty) ...[
                              const Divider(height: 16, color: Color(0xFFE2E8F0)),
                              const Text(
                                'Historia rozmowy z uczniem:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 6),
                              ...req.dialogHistory.map((entry) {
                                final isParent = entry.isParent;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isParent ? Colors.white : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isParent ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry.senderName}: ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isParent ? const Color(0xFF475569) : const Color(0xFF1D4ED8),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry.message,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nagłówek sekcji lekcji + przełącznik zaznaczenia
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Objęte lekcje (${_selectedRecordIds.length} z ${_resolvedRecords.length})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (_resolvedRecords.length > 1)
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: _toggleAll,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  allSelected ? 'Odznacz wszystkie' : 'Zaznacz wszystkie',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3525CD),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Lista lekcji pogrupowana dniami
                      ...groupedByDay.entries.map((entry) {
                        final dayRecords = entry.value;
                        final dayHeader = JustificationRequest.formatPolishDayHeader(dayRecords.first.date);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF3525CD)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        dayHeader,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...dayRecords.map((rec) {
                                final isChecked = _selectedRecordIds.contains(rec.id);
                                final hasTeacherOrRoom =
                                    (rec.teacherName != null && rec.teacherName!.isNotEmpty) ||
                                    (rec.classroom != null && rec.classroom!.isNotEmpty);
                                final teacherRoomSubtitle = hasTeacherOrRoom
                                    ? '${rec.teacherName ?? "Nauczyciel"}${rec.classroom != null && rec.classroom!.isNotEmpty ? " • Sala ${rec.classroom}" : ""}'
                                    : null;

                                return InkWell(
                                  key: ValueKey('approval_lesson_row_${rec.id}'),
                                  onTap: () => _toggleRecord(rec.id),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Checkbox(
                                          key: ValueKey('approval_checkbox_${rec.id}'),
                                          value: isChecked,
                                          activeColor: AppColors.primary,
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          onChanged: _isProcessing ? null : (_) => _toggleRecord(rec.id),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: isChecked
                                                            ? const Color(0xFFEEF2FF)
                                                            : const Color(0xFFE2E8F0),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        'Lekcja ${rec.lessonNumber} • ${rec.timeSlot}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          color: isChecked
                                                              ? const Color(0xFF3525CD)
                                                              : const Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                rec.subjectName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: isChecked
                                                      ? const Color(0xFF0F172A)
                                                      : const Color(0xFF94A3B8),
                                                  decoration: isChecked ? null : TextDecoration.lineThrough,
                                                ),
                                              ),
                                              if (teacherRoomSubtitle != null) ...[
                                                const SizedBox(height: 1),
                                                Text(
                                                  teacherRoomSubtitle,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 4),

                      // Sekcja kodu PIN rodzica
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Wprowadź kod PIN rodzica:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Domyślny PIN: 1234',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        enabled: !_isProcessing,
                        decoration: InputDecoration(
                          counterText: '',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _pinError ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _pinError ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF3525CD), width: 1.5),
                          ),
                          errorText: _pinError ? (_pinErrorMessage ?? 'Wymagany jest 4-cyfrowy kod PIN') : null,
                        ),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 4),
                      ),
                    ],
                  ),
                ),
              ),

              // Przypięte na stałe przyciski akcji
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: (_isProcessing || _selectedRecordIds.isEmpty) ? null : _handleApprove,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(
                    _isProcessing
                        ? 'Wysyłanie do Librusa...'
                        : (_selectedRecordIds.isEmpty
                            ? 'Wybierz co najmniej 1 lekcję'
                            : 'Zatwierdź z PIN-em (${_selectedRecordIds.length} z ${_resolvedRecords.length} lekcji)'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _handleReject,
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFDC2626)),
                  label: const Text(
                    'Odrzuć wniosek',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFDC2626)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'Anuluj',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
