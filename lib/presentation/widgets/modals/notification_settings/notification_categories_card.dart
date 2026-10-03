import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/notification_settings_provider.dart';
import 'notification_section_card.dart';

class NotificationCategoriesCard extends ConsumerWidget {
  const NotificationCategoriesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(
      notificationChannelSettingsProvider.select(
        (asyncVal) => asyncVal.value == null
            ? null
            : (
                familyId: asyncVal.value!.familyId,
                roleKey: asyncVal.value!.roleKey,
                grades: asyncVal.value!.notifyGrades,
                messages: asyncVal.value!.notifyMessages,
                exams: asyncVal.value!.notifyExams,
                familyChat: asyncVal.value!.notifyFamilyChat,
              ),
      ),
    );

    if (categories == null) {
      return const SizedBox.shrink();
    }

    final service = ref.read(notificationChannelsServiceProvider);

    return NotificationSectionCard(
      icon: Icons.category_outlined,
      iconBg: const Color(0xFFFEF3C7),
      iconColor: const Color(0xFFD97706),
      title: 'Kategorie powiadomień (Filtry zdarzeń)',
      subtitle:
          'Wybierz, o jakich zdarzeniach szkolnych chcesz otrzymywać alerty na Telegram i Web Push',
      child: Column(
        children: [
          _buildCategoryToggle(
            icon: Icons.verified_outlined,
            title: 'Nowe oceny i średnie',
            subtitle:
                'Przedmiot, stopień, waga oceny, kategoria oraz nauczyciel',
            value: categories.grades,
            onChanged: (val) => service.updateSettings(
              familyId: categories.familyId,
              roleKey: categories.roleKey,
              patch: {'notifyGrades': val},
            ),
          ),
          const Divider(height: 1),
          _buildCategoryToggle(
            icon: Icons.mail_outline_rounded,
            title: 'Nowe wiadomości i ogłoszenia z Librusa',
            subtitle:
                'Powiadomienia o nowych wiadomościach od nauczycieli i wychowawcy',
            value: categories.messages,
            onChanged: (val) => service.updateSettings(
              familyId: categories.familyId,
              roleKey: categories.roleKey,
              patch: {'notifyMessages': val},
            ),
          ),
          const Divider(height: 1),
          _buildCategoryToggle(
            icon: Icons.event_note_rounded,
            title: 'Nadchodzące sprawdziany i kartkówki',
            subtitle:
                'Nowe wpisy w terminarzu sprawdzianów wraz z zakresem materiału',
            value: categories.exams,
            onChanged: (val) => service.updateSettings(
              familyId: categories.familyId,
              roleKey: categories.roleKey,
              patch: {'notifyExams': val},
            ),
          ),
          const Divider(height: 1),
          _buildCategoryToggle(
            icon: Icons.forum_outlined,
            title: 'Czat rodzinny i wnioski o e-usprawiedliwienie',
            subtitle:
                'Nowe wiadomości od rodzica/ucznia oraz prośby o akceptację usprawiedliwienia',
            value: categories.familyChat,
            onChanged: (val) => service.updateSettings(
              familyId: categories.familyId,
              roleKey: categories.roleKey,
              patch: {'notifyFamilyChat': val},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      secondary: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
