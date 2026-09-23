import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/justification_request.dart';

/// Modal bottom sheet allowing a student to view the parent's rejection comment
/// and reply / re-submit with clarification (REQ-ROLE-04, D-02).
class StudentResponseModal extends StatefulWidget {
  final JustificationRequest request;
  final Future<bool> Function(String responseText) onRespond;

  const StudentResponseModal({
    super.key,
    required this.request,
    required this.onRespond,
  });

  static void show(
    BuildContext context,
    JustificationRequest request, {
    required Future<bool> Function(String responseText) onRespond,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StudentResponseModal(
        request: request,
        onRespond: onRespond,
      ),
    );
  }

  @override
  State<StudentResponseModal> createState() => _StudentResponseModalState();
}

class _StudentResponseModalState extends State<StudentResponseModal> {
  late final TextEditingController _replyController;
  bool _isProcessing = false;
  String? _errorMessage;

  static const List<String> _quickStudentChips = [
    'Miałem wizytę lekarską (mam zaświadczenie)',
    'Korki na trasie do szkoły i opóźnienie autobusu',
    'Źle się czułem rano, możemy porozmawiać',
  ];

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Wybrane lekcje';
    return DateFormat('dd.MM.yyyy').format(dt);
  }

  Future<void> _handleSubmit() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Wpisz treść wyjaśnienia przed wysłaniem.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final success = await widget.onRespond(text);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Wystąpił błąd podczas wysyłania odpowiedzi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final parentReason = widget.request.rejectionReason ?? 'Odmowa rodzica';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.question_answer_rounded,
                    color: Color(0xFFD97706),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Odpowiedź rodzicowi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Uzupełnij wyjaśnienie, aby rodzic mógł zatwierdzić prośbę',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Parent comment banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.comment_bank_outlined, size: 16, color: Color(0xFFB45309)),
                      const SizedBox(width: 8),
                      Text(
                        'Komentarz rodzica (${_formatDate(widget.request.date)}):',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '„$parentReason”',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ],
              ),
            ),

            // Dialog history if more than 1 entry
            if (widget.request.dialogHistory.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Historia wątku:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              ...widget.request.dialogHistory.map((entry) {
                final isParent = entry.isParent;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isParent ? const Color(0xFFF8FAFC) : const Color(0xFFEFF6FF),
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

            const SizedBox(height: 14),

            const Text(
              'Szybkie wyjaśnienie:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickStudentChips.map((chipText) {
                return ActionChip(
                  label: Text(chipText),
                  onPressed: () {
                    setState(() {
                      _replyController.text = chipText;
                      _errorMessage = null;
                    });
                  },
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                  ),
                  backgroundColor: const Color(0xFFEFF6FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // TextField
            TextField(
              controller: _replyController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Twoja odpowiedź dla rodzica',
                hintText: 'Napisz co się stało...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
              ),
            ],

            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text(
                      'Anuluj',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
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
                      _isProcessing ? 'Wysyłanie...' : 'Wyślij i poproś ponownie',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
  }
}
