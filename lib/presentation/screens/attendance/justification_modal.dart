import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class JustificationModal extends StatefulWidget {
  final List<String> selectedRecordIds;
  final String initialReason;
  final DateTime? initialDate;
  final void Function(String reason, String pin, DateTime? selectedDate) onConfirm;

  const JustificationModal({
    super.key,
    required this.selectedRecordIds,
    this.initialReason = 'Wizyta lekarska',
    this.initialDate,
    required this.onConfirm,
  });

  static void show(
    BuildContext context,
    List<String> recordIds,
    String initialReason,
    void Function(String reason, String pin, DateTime? selectedDate) onConfirm, {
    DateTime? initialDate,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JustificationModal(
        selectedRecordIds: recordIds,
        initialReason: initialReason,
        initialDate: initialDate,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<JustificationModal> createState() => _JustificationModalState();
}

class _JustificationModalState extends State<JustificationModal> {
  late final TextEditingController _reasonController;
  final _pinController = TextEditingController(text: '1234');
  bool _pinError = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: widget.initialReason);
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildDateChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3525CD) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? const Color(0xFF3525CD) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF3525CD) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final yesterday = now.subtract(const Duration(days: 1));
    final mediaQuery = MediaQuery.of(context);

    final isCustomSelected = _selectedDate != null &&
        !_isSameDay(_selectedDate, now) &&
        !_isSameDay(_selectedDate, tomorrow) &&
        !_isSameDay(_selectedDate, yesterday);

    String subtitleText;
    if (_selectedDate != null) {
      final isToday = _isSameDay(_selectedDate, now);
      final isTom = _isSameDay(_selectedDate, tomorrow);
      final isYest = _isSameDay(_selectedDate, yesterday);
      final label = isToday
          ? 'dzisiaj'
          : isTom
              ? 'jutro'
              : isYest
                  ? 'wczoraj'
                  : DateFormat('dd.MM.yyyy').format(_selectedDate!);
      subtitleText = 'Zgłoszenie na $label (${DateFormat('dd.MM.yyyy').format(_selectedDate!)})';
    } else if (widget.selectedRecordIds.isNotEmpty) {
      subtitleText = 'Zgłoszenie dla ${widget.selectedRecordIds.length} wybranych lekcji';
    } else {
      subtitleText = 'Zgłoszenie nieobecności';
    }

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
                          'Autoryzacja e-Usprawiedliwienia',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          subtitleText,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Przewijana zawartość formularza
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wybór dnia (opcjonalnie)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Dzień nieobecności (opcjonalnie):',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                          ),
                          if (_selectedDate != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _selectedDate = null),
                              child: const Text(
                                'Wyczyść dzień',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3525CD)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildDateChip(
                              label: 'Dzisiaj',
                              isSelected: _isSameDay(_selectedDate, now),
                              onTap: () {
                                setState(() {
                                  _selectedDate = _isSameDay(_selectedDate, now) ? null : now;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildDateChip(
                              label: 'Jutro',
                              isSelected: _isSameDay(_selectedDate, tomorrow),
                              onTap: () {
                                setState(() {
                                  _selectedDate = _isSameDay(_selectedDate, tomorrow) ? null : tomorrow;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildDateChip(
                              label: 'Wczoraj',
                              isSelected: _isSameDay(_selectedDate, yesterday),
                              onTap: () {
                                setState(() {
                                  _selectedDate = _isSameDay(_selectedDate, yesterday) ? null : yesterday;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildDateChip(
                              label: isCustomSelected ? DateFormat('dd.MM.yyyy').format(_selectedDate!) : 'Wybierz datę...',
                              icon: Icons.calendar_month_outlined,
                              isSelected: isCustomSelected,
                              onTap: _pickCustomDate,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Powód nieobecności
                      const Text(
                        'Wybrany powód nieobecności:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF3525CD), width: 1.5),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),

                      // Kod PIN rodzica
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Kod PIN rodzica:',
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
                          errorText: _pinError ? 'Wymagany jest 4-cyfrowy kod PIN (np. 1234)' : null,
                        ),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 4),
                      ),
                    ],
                  ),
                ),
              ),

              // Przypięta na stałe dolna stopka z przyciskami akcji
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: () {
                    final pin = _pinController.text.trim();
                    if (pin.length < 4) {
                      setState(() => _pinError = true);
                      return;
                    }
                    final reason = _reasonController.text.trim();
                    widget.onConfirm(reason.isNotEmpty ? reason : 'Wizyta lekarska', pin, _selectedDate);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Zatwierdź i wyślij usprawiedliwienie',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
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
