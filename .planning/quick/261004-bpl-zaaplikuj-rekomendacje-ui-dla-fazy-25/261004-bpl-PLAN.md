---
phase: quick-261004-bpl
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/presentation/screens/messages/messages_screen.dart
  - lib/presentation/screens/messages/message_thread_screen.dart
  - lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart
  - test/presentation/screens/messages_archive_and_attendance_accepted_test.dart
autonomous: true
requirements: [UI-REV-25]
must_haves:
  truths:
    - "Card-level Archiwizuj/Przywróć button in MessagesScreen has at least 32px height for comfortable mobile touch targets"
    - "MessagesScreen and MessageThreadScreen display identical SnackBar copy ('Wiadomość przeniesiona do archiwum' / 'Przywrócono wiadomość do skrzynki odbiorczej') and 4s duration"
    - "AcceptedJustificationsSummaryCard uses full Polish paucal pluralization for lesson counts (including >20 like 22 lekcje), 11px badge text, and semantic M3 surface/text tokens"
  artifacts:
    - path: "lib/presentation/screens/messages/messages_screen.dart"
      provides: ">=32px archive pill touch target, 11px archive badge text, and 4s SnackBar"
    - path: "lib/presentation/screens/messages/message_thread_screen.dart"
      provides: "Unified archive SnackBar copy"
    - path: "lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart"
      provides: "Full Polish pluralization helper, 11px approval badge, and semantic M3 tokens"
---

<objective>
Zaaplikowanie wszystkich rekomendacji z audytu wizualnego `25-UI-REVIEW.md` dla Fazy 25 (ergonomia obszaru dotyku przycisku archiwizacji, ujednolicenie komunikatów SnackBar, pełna polska odmiana liczebników w karcie zaakceptowanych usprawiedliwień, podniesienie czytelności plakietek z 10px do 11px oraz ujednolicenie tokenów kolorystycznych).
</objective>

<tasks>

<task type="auto">
  <name>Task 1: Apply Phase 25 UI audit fixes across MessagesScreen, MessageThreadScreen, and AcceptedJustificationsSummaryCard</name>
  <files>
    lib/presentation/screens/messages/messages_screen.dart
    lib/presentation/screens/messages/message_thread_screen.dart
    lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart
    test/presentation/screens/messages_archive_and_attendance_accepted_test.dart
  </files>
  <action>
    1. In `lib/presentation/screens/messages/messages_screen.dart`:
       - Update `_toggleArchiveMessage` SnackBar duration from `3s` to `4s`.
       - Increase `Auto-archiwum` / `Zarchiwizowana` badge icon size from `10` to `12` and text `fontSize` from `10` to `11`.
       - In `_buildArchiveActionButton`, set `constraints: const BoxConstraints(minHeight: 32)` and `padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)` with `Alignment.center` so the touch target is at least 32px tall.
    2. In `lib/presentation/screens/messages/message_thread_screen.dart`:
       - Unify `_toggleArchiveStatus` SnackBar message with `MessagesScreen`: `'Wiadomość przeniesiona do archiwum'` / `'Przywrócono wiadomość do skrzynki odbiorczej'`.
    3. In `lib/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart`:
       - Add static `formatLessonsCount(int count)` implementing full Polish paucal pluralization (`1 lekcja`, `2-4 / 22-24 lekcje`, `5-21 / 25+ lekcji`).
       - Increase `'Zaakceptowano przez wychowawcę'` badge `fontSize` from `10` to `11`.
       - Replace `Colors.white` / `AppColors.slate900` / `AppColors.slate600` with `AppColors.surfaceContainerLowest` / `AppColors.onSurface` / `AppColors.onSurfaceVariant`.
    4. In `test/presentation/screens/messages_archive_and_attendance_accepted_test.dart`:
       - Verify archive button minimum height (`>= 32px`) and Polish pluralization for >20 lessons (`AcceptedJustificationsSummaryCard.formatLessonsCount(22) == '22 lekcje'`).
  </action>
  <verify>
    <automated>flutter test test/presentation/screens/messages_archive_and_attendance_accepted_test.dart && flutter analyze lib/presentation/screens/messages/ lib/presentation/screens/attendance/</automated>
  </verify>
  <done>All 3 top priority fixes and minor warnings from 25-UI-REVIEW.md are implemented and verified by widget tests.</done>
</task>

</tasks>
