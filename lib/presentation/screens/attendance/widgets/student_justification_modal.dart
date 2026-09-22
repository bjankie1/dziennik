import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

/// Modal bottom sheet allowing a student to submit an excuse request
/// to their parent for approval (REQ-ROLE-02, D-03).
/// Crucially: does NOT contain any PIN input.
class StudentJustificationModal extends StatefulWidget {
  final List<String> selectedRecordIds;
  final String initialReason;
  final DateTime? initialDate;
  final void Function(String reason, DateTime? selectedDate) onConfirm;

  const StudentJustificationModal({
    super.key,
    required this.selectedRecordIds,
    this.initialReason = 'Wizyta lekarska',
    this.initialDate,
    required this.onConfirm,
  });

  static void show(
    BuildContext context,
    List<String> recordIds, {
    String initialReason = 'Wizyta lekarska',
    DateTime? initialDate,
    required void Function(String reason, DateTime? selectedDate) onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StudentJustificationModal(
        selectedRecordIds: recordIds,
        initialReason: initialReason,
        initialDate: initialDate,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<StudentJustificationModal> createState() => _StudentJustificationModalState();
}

class _StudentJustificationModalState extends State<StudentJustificationModal> {
  late final TextEditingController _reasonController;
  DateTime? _selectedDate;

  final List<String> _quickReasons = const [
    'Wizyta lekarska',
    'Złe samopoczucie',
    'Sprawy urzędowe',
    'Zawody sportowe',
    'Sprawy rodzinne',
  ];

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: widget.initialReason);
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _reasonController.dispose();
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
      subtitleText = 'Prośba o usprawiedliwienie na $label (${DateFormat('dd.MM.yyyy').format(_selectedDate!)})';
    } else if (widget.selectedRecordIds.isNotEmpty) {
      final count = widget.selectedRecordIds.length;
      final label = count == 1 ? 'lekcji' : (count <= 4 ? 'lekcje' : 'lekcji');
      subtitleText = 'Prośba o usprawiedliwienie dla $count $label';
    } else {
      subtitleText = 'Prośba o usprawiedliwienie nieobecności';
    }

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Icon(Icons.family_restroom_rounded, color: Color(0xFF3525CD), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Poproś rodzica o usprawiedliwienie',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
            const SizedBox(height: 18),

            // Wybór dnia
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dzień nieobecności (opcjonalnie):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
                if (_selectedDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _selectedDate = null),
                    child: const Text(
                      'Wyczyść dzień',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3525CD)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 16),

            // Szybkie powody (Chips)
            const Text(
              'Szybki powód nieobecności:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickReasons.map((reason) {
                final isSelected = _reasonController.text == reason;
                return ChoiceChip(
                  label: Text(reason),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _reasonController.text = reason;
                      });
                    }
                  },
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Własny powód / edycja powodu
            const Text(
              'Treść uzasadnienia dla rodzica:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLength: 250,
              decoration: InputDecoration(
                hintText: 'Wpisz szczegółowy powód nieobecności...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

            // Informacja wyjaśniająca (Brak PIN-u!)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF3525CD)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Prośba zostanie przesłana do rodzica. Po zatwierdzeniu rodzic wyśle oficjalne e-usprawiedliwienie do szkoły za pomocą kodu PIN.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF312E81),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Przycisk wyślij prośbę do rodzica
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  final reason = _reasonController.text.trim();
                  widget.onConfirm(
                    reason.isNotEmpty ? reason : 'Wizyta lekarska',
                    _selectedDate,
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Wyślij prośbę do rodzica',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
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
