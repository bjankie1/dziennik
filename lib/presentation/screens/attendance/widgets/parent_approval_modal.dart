import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/justification_request.dart';

/// Modal bottom sheet allowing a parent to review, approve with 4-digit PIN,
/// or reject an excuse request submitted by a student (REQ-ROLE-02, D-04, T-14-03).
class ParentApprovalModal extends StatefulWidget {
  final JustificationRequest request;
  final Future<bool> Function(String pin) onApprove;
  final Future<bool> Function(String? reason) onReject;

  const ParentApprovalModal({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  static void show(
    BuildContext context,
    JustificationRequest request, {
    required Future<bool> Function(String pin) onApprove,
    required Future<bool> Function(String? reason) onReject,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ParentApprovalModal(
        request: request,
        onApprove: onApprove,
        onReject: onReject,
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

  @override
  void dispose() {
    _pinController.dispose();
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

  Future<void> _handleApprove() async {
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

    final success = await widget.onApprove(pin);
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
    setState(() => _isProcessing = true);
    final success = await widget.onReject('Odrzucone przez rodzica');
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final lessonText = req.lessonNumbers.isNotEmpty
        ? 'Lekcje: ${req.lessonNumbers.join(", ")}'
        : '${req.recordIds.length} wybrane godziny';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Nagłówek modala
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF3525CD), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Autoryzacja wniosku ucznia',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Wniosek od: ${req.studentName}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Podsumowanie wniosku
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(req.date),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Oczekuje',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        lessonText,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                  if (req.subjectNames.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.menu_book_outlined, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Przedmioty: ${req.subjectNames.join(", ")}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.comment_outlined, size: 15, color: Color(0xFF3525CD)),
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sekcja kodu PIN rodzica
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Wprowadź kod PIN rodzica:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            const SizedBox(height: 20),

            // Przyciski akcji
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : _handleApprove,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(
                  _isProcessing ? 'Wysyłanie do Librusa...' : 'Zatwierdź z PIN-em',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
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
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                child: const Text(
                  'Anuluj',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
