import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/justification_request.dart';
import '../../providers/school_providers.dart';

/// Shared dialogs and alert banner for approving or rejecting student justification requests (`REQ-ROLE-02`, `REQ-ROLE-04`, `REQ-ARCH-02`).
class JustificationApprovalDialogs {
  static void showPinApproveDialog(
    BuildContext context,
    WidgetRef ref,
    JustificationRequest request,
  ) {
    final pinController = TextEditingController();
    bool isSubmitting = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Autoryzacja Rodzica (PIN)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zatwierdzasz prośbę Oskara o usprawiedliwienie (${request.recordIds.length} lekcji). Powód: "${request.reason}".',
                style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Kod PIN rodzica (domyślnie 1234)',
                  errorText: errorMsg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() {
                        isSubmitting = true;
                        errorMsg = null;
                      });
                      final ok = await ref
                          .read(attendanceProvider.notifier)
                          .approveJustification(request.id, pinController.text.trim());
                      if (ok) {
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Prośba Oskara została zatwierdzona i wysłana do Librusa!'),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() {
                          isSubmitting = false;
                          errorMsg = 'Nieprawidłowy kod PIN';
                        });
                      }
                    },
              icon: isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 16),
              label: const Text('Zatwierdź i wyślij'),
            ),
          ],
        ),
      ),
    );
  }

  static void showRejectOrAskDialog(
    BuildContext context,
    WidgetRef ref,
    JustificationRequest request,
  ) {
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Odrzuć lub dopytaj Oskara',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wpisz powód odrzucenia lub pytanie do Oskara (widoczne również na Czacie Rodzinnym):',
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'np. Dlaczego nie byłeś na matematyce?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      final comment = commentController.text.trim().isNotEmpty
                          ? commentController.text.trim()
                          : 'Rodzic poprosił o wyjaśnienie nieobecności.';
                      await ref
                          .read(attendanceProvider.notifier)
                          .rejectJustification(request.id, reason: comment);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wysłano pytanie / powód odrzucenia do Oskara.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Odrzuć i wyślij komentarz'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner card displayed when Oskar has pending or rejected justification requests (`REQ-ROLE-02`, `REQ-ROLE-04`).
class JustificationRequestBannerCard extends ConsumerWidget {
  final JustificationRequest request;
  final bool isParent;

  const JustificationRequestBannerCard({
    super.key,
    required this.request,
    required this.isParent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRejected = request.status.isRejected;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRejected ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRejected ? const Color(0xFFFCA5A5) : const Color(0xFFFCD34D),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRejected ? Icons.error_outline_rounded : Icons.pending_actions_rounded,
            color: isRejected ? AppColors.error : const Color(0xFFB45309),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRejected
                      ? 'Prośba o usprawiedliwienie wymaga wyjaśnienia'
                      : 'Prośba od Oskara o usprawiedliwienie (${request.recordIds.length} lekcji)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isRejected ? AppColors.error : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Powód ucznia: "${request.reason}"',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
                ),
                if (request.rejectionReason != null && request.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Komentarz rodzica: "${request.rejectionReason}"',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (isParent && !isRejected) ...[
                      FilledButton.icon(
                        onPressed: () => JustificationApprovalDialogs.showPinApproveDialog(
                          context,
                          ref,
                          request,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 15),
                        label: const Text(
                          'Zatwierdź (PIN)',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF92400E),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => JustificationApprovalDialogs.showRejectOrAskDialog(
                          context,
                          ref,
                          request,
                        ),
                        icon: const Icon(Icons.help_outline_rounded, size: 15, color: AppColors.error),
                        label: const Text(
                          'Odrzuć / Dopytaj',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                    TextButton.icon(
                      onPressed: () => context.go('/frekwencja'),
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text(
                        'Szczegóły we Frekwencji',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
