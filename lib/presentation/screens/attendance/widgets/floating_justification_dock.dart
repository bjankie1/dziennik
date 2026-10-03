import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/polish_date_formatter.dart';
import '../../../providers/school_providers.dart';
import '../justification_modal.dart';
import 'student_justification_modal.dart';

class FloatingJustificationDock extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  final bool isStudent;
  final VoidCallback onClearSelection;

  const FloatingJustificationDock({
    super.key,
    required this.selectedIds,
    required this.isStudent,
    required this.onClearSelection,
  });

  @override
  ConsumerState<FloatingJustificationDock> createState() =>
      _FloatingJustificationDockState();
}

class _FloatingJustificationDockState
    extends ConsumerState<FloatingJustificationDock> {
  String _selectedQuickReason = 'Wizyta lekarska';

  static const List<String> _quickReasons = [
    'Choroba',
    'Wizyta lekarska',
    'Sprawy rodzinne',
    'Zawody sportowe',
  ];

  @override
  Widget build(BuildContext context) {
    final count = widget.selectedIds.length;
    final lessonLabel = PolishDateFormatter.pluralizeLessonAccusative(count);
    final isStudent = widget.isStudent;

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
                    isStudent
                        ? Icons.family_restroom_rounded
                        : Icons.mark_email_read_outlined,
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
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.slate400,
                    size: 20,
                  ),
                  onPressed: widget.onClearSelection,
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
                      onTap: () =>
                          setState(() => _selectedQuickReason = reason),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.indigoSurface
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.slate200,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.slate700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Przycisk wysyłki (otwiera modal z kodem PIN rodzica lub modal prośby ucznia — T-21-05)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  if (widget.isStudent) {
                    StudentJustificationModal.show(
                      context,
                      widget.selectedIds.toList(),
                      initialReason: _selectedQuickReason,
                      onConfirm: (reason, selectedDate) async {
                        final selectedList = widget.selectedIds.toList();
                        final label =
                            PolishDateFormatter.pluralizeLessonAccusative(
                              selectedList.length,
                            );
                        await ref
                            .read(attendanceProvider.notifier)
                            .requestJustification(
                              selectedList,
                              reason,
                              date: selectedDate,
                            );
                        widget.onClearSelection();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Prośba o usprawiedliwienie (${selectedList.length} $label) została przesłana do rodzica.',
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
                      widget.selectedIds.toList(),
                      _selectedQuickReason,
                      (reason, pin, selectedDate) async {
                        final selectedList = widget.selectedIds.toList();
                        final label =
                            PolishDateFormatter.pluralizeLessonAccusative(
                              selectedList.length,
                            );
                        await ref
                            .read(attendanceProvider.notifier)
                            .submitJustification(
                              selectedList,
                              reason,
                              date: selectedDate,
                            );
                        widget.onClearSelection();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Wniosek o usprawiedliwienie (${selectedList.length} $label) został pomyślnie wysłany do wychowawcy.',
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isStudent
                          ? 'Poproś rodzica o usprawiedliwienie ($count $lessonLabel)'
                          : 'Wyślij usprawiedliwienie ($count $lessonLabel)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isStudent
                          ? Icons.send_rounded
                          : Icons.arrow_forward_rounded,
                      size: 16,
                    ),
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
                  isStudent
                      ? Icons.family_restroom_rounded
                      : Icons.shield_outlined,
                  size: 14,
                  color: AppColors.slate500,
                ),
                const SizedBox(width: 6),
                Text(
                  isStudent
                      ? 'Wniosek zostanie przekazany rodzicowi do zatwierdzenia kodem PIN'
                      : 'Wymagane zatwierdzenie kodem PIN rodzica w następnym kroku',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate500,
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
