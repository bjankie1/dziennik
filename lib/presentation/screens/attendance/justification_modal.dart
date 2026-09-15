import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class JustificationModal extends StatefulWidget {
  final List<String> selectedRecordIds;
  final Function(String reason) onConfirm;

  const JustificationModal({
    super.key,
    required this.selectedRecordIds,
    required this.onConfirm,
  });

  static void show(BuildContext context, List<String> recordIds, Function(String reason) onConfirm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JustificationModal(
        selectedRecordIds: recordIds,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<JustificationModal> createState() => _JustificationModalState();
}

class _JustificationModalState extends State<JustificationModal> {
  final _reasonController = TextEditingController();
  final List<String> _quickReasons = [
    'Wizyta lekarska / badania',
    'Złe samopoczucie / choroba',
    'Wypadek losowy / sprawy rodzinne',
    'Udział w zawodach sportowych',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified, color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'e-Usprawiedliwienie',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Zgłoszenie dla ${widget.selectedRecordIds.length} wybranych lekcji',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Wybierz szybki powód:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickReasons.map((reason) {
                return ActionChip(
                  label: Text(reason),
                  backgroundColor: AppColors.surfaceContainerLow,
                  side: const BorderSide(color: AppColors.surfaceContainerHigh),
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  onPressed: () {
                    setState(() => _reasonController.text = reason);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            const Text(
              'Treść uzasadnienia dla wychowawcy:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Wpisz powód absencji...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.outline),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  final reason = _reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wpisz lub wybierz powód nieobecności.')),
                    );
                    return;
                  }
                  widget.onConfirm(reason);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Wyślij e-Usprawiedliwienie', style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
