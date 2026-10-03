---
phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea
verified: 2026-10-03T16:56:20Z
status: passed
score: 17/17 must-haves verified
covered_files:
  - ".planning/REQUIREMENTS.md"
  - ".planning/phases/21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea/21-01-PLAN.md"
  - ".planning/phases/21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea/21-01-SUMMARY.md"
  - ".planning/phases/21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea/21-02-PLAN.md"
  - ".planning/phases/21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea/21-02-SUMMARY.md"
  - ".planning/phases/21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea/21-03-PLAN.md"
  - ".planning/phases/21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea/21-03-SUMMARY.md"
  - ".planning/phases/21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea/21-04-PLAN.md"
  - ".planning/phases/21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea/21-04-SUMMARY.md"
  - "lib/core/utils/polish_date_formatter.dart"
  - "lib/domain/models/justification_request.dart"
  - "lib/domain/models/message_thread.dart"
  - "lib/presentation/screens/attendance/attendance_screen.dart"
  - "lib/presentation/screens/attendance/widgets/attendance_day_group_card.dart"
  - "lib/presentation/screens/attendance/widgets/attendance_filter_bar.dart"
  - "lib/presentation/screens/attendance/widgets/attendance_semester_kpi_card.dart"
  - "lib/presentation/screens/attendance/widgets/floating_justification_dock.dart"
  - "lib/presentation/screens/attendance/widgets/pending_teacher_accordion_banner.dart"
  - "lib/presentation/screens/attendance/widgets/requested_attendance_details_sheet.dart"
  - "lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart"
  - "lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart"
  - "lib/presentation/screens/messages/message_thread_screen.dart"
  - "lib/presentation/screens/messages/widgets/message_accordion_tile.dart"
  - "lib/presentation/screens/messages/widgets/message_reply_composer.dart"
  - "lib/presentation/screens/messages/widgets/message_task_banner.dart"
  - "lib/presentation/screens/messages/widgets/message_thread_header_card.dart"
  - "lib/presentation/widgets/common/justification_approval_dialogs.dart"
  - "lib/presentation/widgets/common/justification_request_banner.dart"
  - "lib/presentation/widgets/modals/notification_settings/notification_alerts_history_tab.dart"
  - "lib/presentation/widgets/modals/notification_settings/notification_categories_card.dart"
  - "lib/presentation/widgets/modals/notification_settings/notification_section_card.dart"
  - "lib/presentation/widgets/modals/notification_settings/telegram_channel_card.dart"
  - "lib/presentation/widgets/modals/notification_settings/telegram_step_by_step_guide.dart"
  - "lib/presentation/widgets/modals/notification_settings/web_push_channel_card.dart"
  - "lib/presentation/widgets/modals/notification_settings_modal.dart"
  - "test/core/utils/polish_date_formatter_test.dart"
  - "test/presentation/screens/messages_timestamp_test.dart"
covered_digest: "v1:sha256:33ad77a7bf8283aab9001413d2080615d68615918a2d9f44d31f883e9e5d257c"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 21: Refaktoryzacja monolitycznych widoków UI (>1 600 LOC), wspólne komponenty i optymalizacja granic przebudowy Riverpod — Verification Report

**Phase Goal:** Doprowadzenie największych widoków aplikacji (`message_thread_screen.dart` – 2 059 LOC, `attendance_screen.dart` – 1 942 LOC, `notification_settings_modal.dart` – 1 642 LOC) do pełnej zgodności z dobrymi praktykami Fluttera i Riverpod poprzez dekompozycję monolitycznych klas `State` i prywatnych metod `Widget _build*()` na autonomiczne widgety `ConsumerWidget` / `StatelessWidget` z konstruktorami `const`, wydzielenie wspólnego komponentu `JustificationRequestBanner` oraz helpera `PolishDateFormatter`, a także zawężenie przebudów drzewa widgetów przez `.select(...)`.
**Verified:** 2026-10-03T16:56:20Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `PolishDateFormatter` in `lib/core/utils/polish_date_formatter.dart` provides pure static helpers `formatDayHeader`, `formatShortDayHeader`, `formatFullDate`, `formatNumericDateTime`, `formatNumericDateShortTime`, `pluralizeLesson`, and `pluralizeLessonAccusative`, and `JustificationRequest.formatPolishDayHeader` delegates to `PolishDateFormatter.formatDayHeader` (`REQ-ARCH-01`, Roadmap SC-2) | ✓ VERIFIED | `lib/core/utils/polish_date_formatter.dart` (127 LOC) defines `abstract final class PolishDateFormatter` with all required static helpers; `lib/domain/models/justification_request.dart:325-326` delegates `formatPolishDayHeader` to `PolishDateFormatter.formatDayHeader(date)`. |
| 2 | Unit tests in `test/core/utils/polish_date_formatter_test.dart` verify all Polish weekday names, genitive month names, date/time formatting, and Polish lesson pluralization rules (`1 lekcja`/`lekcję`, `2-4 lekcje`, `5+` and `12-14 lekcji`) (`REQ-ARCH-01`) | ✓ VERIFIED | `test/core/utils/polish_date_formatter_test.dart` (91 LOC, 6 tests) exercises all date/time formats and Polish pluralization edge cases (`0`, `1`, `2-4`, `5`, `11-14`, `21-25`) and passes 100%. |
| 3 | `JustificationRequestBanner` in `lib/presentation/widgets/common/justification_request_banner.dart` consolidates the parent pending justification banner and student rejected justification banner into a single `const ConsumerWidget` with selective Riverpod subscriptions and `ValueKey('parent_pending_request_banner')` support (`REQ-ARCH-01`, `REQ-ARCH-02`, Roadmap SC-2) | ✓ VERIFIED | `lib/presentation/widgets/common/justification_request_banner.dart` (849 LOC) implements `const JustificationRequestBanner` using `.select(...)` on `appUserProvider`, `justificationRequestsProvider`, `attendanceProvider`, and `studentProfileProvider`, preserving `const ValueKey('parent_pending_request_banner')` across default, `compact`, and `useIndigoStyle` variants. |
| 4 | `DashboardMobileView` and `DashboardMetricsColumn` replace their ~300 LOC inline justification banner blocks with `JustificationRequestBanner(showDetailsLink: true)` while preserving `ParentApprovalModal`, `ParentRejectionModal`, and `StudentResponseModal` flows (`REQ-ARCH-01`, `REQ-ARCH-02`, Roadmap SC-2) | ✓ VERIFIED | `dashboard_mobile_view.dart:278-281` renders `const JustificationRequestBanner(showDetailsLink: true, bottomSpacing: 10)` (reduced to 710 LOC) and `dashboard_metrics_column.dart:337` renders `const JustificationRequestBanner(showDetailsLink: true, compact: true)` (reduced to 645 LOC). Verified by `test/attendance_justification_modal_test.dart` and `test/dashboard_screen_test.dart`. |
| 5 | `MessageThread` in `lib/domain/models/message_thread.dart` exposes pure domain helpers `resolveSenderName({String? overrideBody})`, `extractCcTeacherFromBody([String? overrideBody])`, and `static looksLikeMessageWithAttachment(String text)` with zero Flutter/Riverpod dependencies and unit test coverage in `test/presentation/screens/messages_timestamp_test.dart` (`REQ-ARCH-01`) | ✓ VERIFIED | `lib/domain/models/message_thread.dart:308-353` defines `resolveSenderName`, `extractCcTeacherFromBody`, and `looksLikeMessageWithAttachment` (plus immutable state helpers `needsDetailsFetch`, `unsavedAttachmentsFor`, `withNormalizedSenderName`, `withMergedDetails`, `withSavedDriveAttachments`) with only `package:intl/intl.dart` imported. Covered by 5 unit tests in `test/presentation/screens/messages_timestamp_test.dart:109-217`. |
| 6 | `MessageThreadHeaderCard` and `MessageTaskBanner` (plus `MessageAppBarTaskAction`) are extracted into `lib/presentation/screens/messages/widgets/`, and `MessageTaskBanner` uses `tasksStreamProvider.select(...)` so unrelated task list mutations do not rebuild the message thread screen (`REQ-ARCH-01`, `REQ-ARCH-02`, Roadmap SC-3) | ✓ VERIFIED | `message_thread_header_card.dart` (136 LOC) and `message_task_banner.dart` (396 LOC) define `const` widgets; `MessageAppBarTaskAction` (`line 57`) and `MessageTaskBanner` (`line 151`) both watch `tasksStreamProvider.select((asyncVal) => asyncVal.value?.where((t) => t.matchesMessage(thread.id)).firstOrNull)`. |
| 7 | `MessageAccordionTile` in `lib/presentation/screens/messages/widgets/message_accordion_tile.dart` renders collapsed/expanded message items and Gmail-style Google Drive attachment buttons while preserving `ValueKey('save_all_drive_button')`, `ValueKey('download_attachment_$file')`, `ValueKey('drive_spinner_$file')`, `ValueKey('open_drive_$file')`, and `ValueKey('save_drive_$file')` (`REQ-ARCH-01`, `REQ-ARCH-02`) | ✓ VERIFIED | `message_accordion_tile.dart` (542 LOC) defines `const MessageAccordionTile` preserving all 5 `ValueKey`s (`lines 297, 389, 440, 453, 489`) and passes all 7 widget tests in `test/message_attachments_test.dart`. |
| 8 | `MessageReplyComposer` in `lib/presentation/screens/messages/widgets/message_reply_composer.dart` encapsulates its own `TextEditingController`, `FocusNode`, `_isReplying`, `_isSending`, and `_replyRecipients` state and watches `teachersProvider.select(...)` so typing a reply or changing recipients never rebuilds the message list (`REQ-ARCH-01`, `REQ-ARCH-02`, Roadmap SC-3) | ✓ VERIFIED | `message_reply_composer.dart` (454 LOC) defines `const MessageReplyComposer` (`ConsumerStatefulWidget`), encapsulates `_isReplying`, `_isSending`, `_replyRecipients`, `_replyController`, and `_replyFocusNode` (`lines 23-27`), and watches `teachersProvider.select((a) => a.value ?? const [])` (`lines 134-136`). |
| 9 | `lib/presentation/screens/messages/message_thread_screen.dart` is reduced from 2 060 LOC to `< 350 LOC` acting solely as the thread coordinator (`REQ-ARCH-01`, Roadmap SC-1) | ✓ VERIFIED | `wc -l lib/presentation/screens/messages/message_thread_screen.dart` is **340 LOC** (< 350 LOC), with zero private `Widget _build*()` methods. |
| 10 | `AttendanceSemesterKpiCard`, `PendingTeacherAccordionBanner`, and `AttendanceFilterBar` are extracted into `lib/presentation/screens/attendance/widgets/` with `const` constructors, and `PendingTeacherAccordionBanner` owns its local `_isExpanded` and `_isCancellingPending` state so expanding/collapsing the accordion or cancelling pending items does not rebuild the entire `AttendanceScreen` (`REQ-ARCH-01`, `REQ-ARCH-02`, Roadmap SC-3) | ✓ VERIFIED | `attendance_semester_kpi_card.dart` (305 LOC), `pending_teacher_accordion_banner.dart` (405 LOC), and `attendance_filter_bar.dart` (150 LOC) all have `const` constructors; `_PendingTeacherAccordionBannerState` owns `_isExpanded` and `_isCancellingPending` locally (`lines 24-25`). |
| 11 | `PendingTeacherAccordionBanner` preserves `ValueKey('pending_teacher_banner_toggle')`, `ValueKey('cancel_all_pending_button')`, `ValueKey('confirm_cancel_all_pending_button')`, and `ValueKey('cancel_pending_${rec.id}')` along with `AnimatedSize`, `AnimatedRotation`, and `PolishDateFormatter.formatDayHeader` (`REQ-ARCH-01`, `REQ-ARCH-02`) | ✓ VERIFIED | `pending_teacher_accordion_banner.dart` preserves all 4 `ValueKey`s (`lines 48, 113, 134, 315`), `AnimatedRotation` (`line 97`), `AnimatedSize` (`line 190`), and `PolishDateFormatter.formatDayHeader` (`line 206`). Verified by `test/attendance_pending_requests_test.dart`. |
| 12 | `AttendanceDayGroupCard`, `FloatingJustificationDock`, and `RequestedAttendanceDetailsSheet` are extracted into `lib/presentation/screens/attendance/widgets/`; `FloatingJustificationDock` owns `_selectedQuickReason` locally, and `RequestedAttendanceDetailsSheet` preserves `ValueKey('close_requested_details_modal_button')` (`REQ-ARCH-01`, `REQ-ARCH-02`, Roadmap SC-3) | ✓ VERIFIED | `attendance_day_group_card.dart` (303 LOC), `floating_justification_dock.dart` (310 LOC, owning `_selectedQuickReason` at `line 28`), and `requested_attendance_details_sheet.dart` (230 LOC, preserving `ValueKey('close_requested_details_modal_button')` at `line 204`) are extracted and wired. |
| 13 | `lib/presentation/screens/attendance/attendance_screen.dart` is reduced from 1 952 LOC to `< 350 LOC`, wires `JustificationRequestBanner(useIndigoStyle: true, bottomSpacing: 14)` and `PolishDateFormatter`, and passes all attendance widget tests (`REQ-ARCH-01`, `REQ-ARCH-02`, Roadmap SC-1, SC-2) | ✓ VERIFIED | `wc -l lib/presentation/screens/attendance/attendance_screen.dart` is **273 LOC** (< 350 LOC), renders `const JustificationRequestBanner(useIndigoStyle: true, bottomSpacing: 14)` (`lines 116-119`), watches `appUserProvider.select((u) => u?.isStudent ?? false)` (`lines 43-45`), and passes `test/attendance_pending_requests_test.dart` and `test/attendance_justification_modal_test.dart`. |
| 14 | `NotificationSectionCard`, `TelegramStepByStepGuide`, and `TelegramChannelCard` are extracted into `lib/presentation/widgets/modals/notification_settings/` with `const` constructors; `TelegramChannelCard` owns its local `TextEditingController`s and loading flags (`_isGeneratingCode`, `_isVerifyingCode`, `_isSendingTelegramTest`, `_showTelegramGuide`, `_showAdvancedBotConfig`) so typing in `@BotFather` token/chatId fields or toggling the guide only rebuilds `TelegramChannelCard` (`REQ-ARCH-01`, `REQ-ARCH-02`, Roadmap SC-3) | ✓ VERIFIED | `notification_section_card.dart` (115 LOC), `telegram_step_by_step_guide.dart` (264 LOC), and `telegram_channel_card.dart` (738 LOC) all define `const` constructors; `TelegramChannelCardState` owns `_botTokenController`, `_botUsernameController`, `_manualChatIdController`, and all 5 boolean state flags (`lines 28-36`). |
| 15 | `TelegramChannelCard` and `TelegramStepByStepGuide` preserve `ValueKey('telegram_step_by_step_guide_button')`, `ValueKey('telegram_guide_show_token_field_button')`, `ValueKey('telegram_guide_content')`, `ValueKey('copy_newbot_button')`, and `ValueKey('open_botfather_button')` along with all 4 steps and the `'Invalid bot passed'` warning box (`REQ-ARCH-01`, `REQ-ARCH-02`) | ✓ VERIFIED | `telegram_channel_card.dart:509` and `telegram_step_by_step_guide.dart:24, 78, 92, 115, 159` preserve all 5 `ValueKey`s, `Krok 1`–`Krok 4`, and the `'Invalid bot passed'` warning box. Verified by `test/presentation/widgets/notification_settings_modal_test.dart`. |
| 16 | `WebPushChannelCard`, `NotificationCategoriesCard`, and `NotificationAlertsHistoryTab` are extracted into `lib/presentation/widgets/modals/notification_settings/` using Dart 3 record `.select(...)` subscriptions on `notificationChannelSettingsProvider` and `schoolNotificationsStreamProvider` (`REQ-ARCH-01`, `REQ-ARCH-02`, Roadmap SC-3) | ✓ VERIFIED | `web_push_channel_card.dart:24-34`, `notification_categories_card.dart:12-25`, and `notification_alerts_history_tab.dart:19-28` all use Dart 3 record/field `.select(...)` selectors on `notificationChannelSettingsProvider` and `schoolNotificationsStreamProvider`. |
| 17 | `lib/presentation/widgets/modals/notification_settings_modal.dart` is reduced from 1 643 LOC to `< 350 LOC`, preserves bottom `'Zapisz ustawienia'` persistence of pending controller edits, and passes `test/presentation/widgets/notification_settings_modal_test.dart` (`REQ-ARCH-01`, `REQ-ARCH-02`, Roadmap SC-1, SC-4) | ✓ VERIFIED | `wc -l lib/presentation/widgets/modals/notification_settings_modal.dart` is **333 LOC** (< 350 LOC), flushes `_telegramCardKey.currentState?.savePendingConfigIfNeeded()` on `'Zapisz ustawienia'` (`lines 67-82, 317-325`), and passes all tests in `test/presentation/widgets/notification_settings_modal_test.dart` plus `flutter analyze` with 0 issues. |

**Score:** 17/17 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/core/utils/polish_date_formatter.dart` | Shared `PolishDateFormatter` utility class | ✓ VERIFIED | 127 LOC, pure static methods for Polish dates & lesson pluralization, imported in 6 files |
| `test/core/utils/polish_date_formatter_test.dart` | Unit tests for `PolishDateFormatter` | ✓ VERIFIED | 91 LOC, 6 unit tests covering all methods and edge cases |
| `lib/presentation/widgets/common/justification_request_banner.dart` | Shared `JustificationRequestBanner` widget | ✓ VERIFIED | 849 LOC, `const ConsumerWidget` with `.select(...)`, used in 3 screens |
| `lib/presentation/widgets/common/justification_approval_dialogs.dart` | Clean barrel export replacing unused 312-LOC duplicate | ✓ VERIFIED | 2 LOC barrel exporting `polish_date_formatter.dart` and `justification_request_banner.dart` |
| `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart` | Mobile dashboard using `JustificationRequestBanner` & `PolishDateFormatter` | ✓ VERIFIED | 710 LOC (-340 LOC), wired to `JustificationRequestBanner` and `PolishDateFormatter.formatShortDayHeader` |
| `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart` | Desktop dashboard metrics column using `JustificationRequestBanner` | ✓ VERIFIED | 645 LOC (-317 LOC), wired to `JustificationRequestBanner(showDetailsLink: true, compact: true)` |
| `lib/domain/models/message_thread.dart` | Domain methods `resolveSenderName`, `extractCcTeacherFromBody`, `looksLikeMessageWithAttachment` | ✓ VERIFIED | 467 LOC, pure domain methods + immutable thread transformation helpers |
| `lib/presentation/screens/messages/widgets/message_thread_header_card.dart` | `MessageThreadHeaderCard` `const StatelessWidget` | ✓ VERIFIED | 136 LOC, renders thread subject, `NOWA`/`Ważne` badges, sender role, message count pill |
| `lib/presentation/screens/messages/widgets/message_task_banner.dart` | `MessageTaskBanner` & `MessageAppBarTaskAction` `const ConsumerWidget`s | ✓ VERIFIED | 396 LOC, selective `tasksStreamProvider.select(...)` subscriptions |
| `lib/presentation/screens/messages/widgets/message_accordion_tile.dart` | `MessageAccordionTile` `const StatelessWidget` | ✓ VERIFIED | 542 LOC, collapsible message items and Google Drive attachment buttons with all `ValueKey`s |
| `lib/presentation/screens/messages/widgets/message_reply_composer.dart` | `MessageReplyComposer` `ConsumerStatefulWidget` | ✓ VERIFIED | 454 LOC, isolated reply `TextEditingController`/`FocusNode` and `teachersProvider.select(...)` |
| `lib/presentation/screens/messages/message_thread_screen.dart` | Streamlined `MessageThreadScreen` coordinator (< 350 LOC) | ✓ VERIFIED | **340 LOC**, delegates UI to the 4 extracted message widgets |
| `lib/presentation/screens/attendance/widgets/attendance_semester_kpi_card.dart` | `AttendanceSemesterKpiCard` `const StatelessWidget` | ✓ VERIFIED | 305 LOC, renders `DualRingAttendanceGauge`, status pill, progress bar, legend, 4 KPI columns |
| `lib/presentation/screens/attendance/widgets/pending_teacher_accordion_banner.dart` | `PendingTeacherAccordionBanner` `ConsumerStatefulWidget` | ✓ VERIFIED | 405 LOC, isolated `_isExpanded`/`_isCancellingPending`, `AnimatedSize`/`AnimatedRotation`, all `ValueKey`s |
| `lib/presentation/screens/attendance/widgets/attendance_filter_bar.dart` | `AttendanceFilterBar` `const StatelessWidget` | ✓ VERIFIED | 150 LOC, 4 filter chips, `bannerSlot`, and select/deselect all header row |
| `lib/presentation/screens/attendance/widgets/attendance_day_group_card.dart` | `AttendanceDayGroupCard` & `AttendanceLessonRow` `const StatelessWidget`s | ✓ VERIFIED | 303 LOC, day-grouped attendance rows using `PolishDateFormatter.formatDayHeader` |
| `lib/presentation/screens/attendance/widgets/floating_justification_dock.dart` | `FloatingJustificationDock` `ConsumerStatefulWidget` | ✓ VERIFIED | 310 LOC, isolated `_selectedQuickReason`, role-gated `StudentJustificationModal`/`JustificationModal` |
| `lib/presentation/screens/attendance/widgets/requested_attendance_details_sheet.dart` | `RequestedAttendanceDetailsSheet` `ConsumerStatefulWidget` | ✓ VERIFIED | 230 LOC, modal bottom sheet with `static show` helper and `close_requested_details_modal_button` key |
| `lib/presentation/screens/attendance/attendance_screen.dart` | Streamlined `AttendanceScreen` coordinator (< 350 LOC) | ✓ VERIFIED | **273 LOC**, delegates UI to `JustificationRequestBanner` and 6 attendance sub-widgets |
| `lib/presentation/widgets/modals/notification_settings/notification_section_card.dart` | `NotificationSectionCard` `const StatelessWidget` | ✓ VERIFIED | 115 LOC, reusable card wrapper for notification channels and categories |
| `lib/presentation/widgets/modals/notification_settings/telegram_step_by_step_guide.dart` | `TelegramStepByStepGuide` `const StatelessWidget` | ✓ VERIFIED | 264 LOC, 4-step `@BotFather` guide with warning box and all `ValueKey`s |
| `lib/presentation/widgets/modals/notification_settings/telegram_channel_card.dart` | `TelegramChannelCard` & `TelegramChannelCardState` | ✓ VERIFIED | 738 LOC, isolated controllers, pairing flow, and `savePendingConfigIfNeeded()` |
| `lib/presentation/widgets/modals/notification_settings/web_push_channel_card.dart` | `WebPushChannelCard` `ConsumerStatefulWidget` | ✓ VERIFIED | 163 LOC, Dart 3 record `.select(...)` subscription for Web Push settings |
| `lib/presentation/widgets/modals/notification_settings/notification_categories_card.dart` | `NotificationCategoriesCard` `const ConsumerWidget` | ✓ VERIFIED | 129 LOC, Dart 3 record `.select(...)` subscription for 4 event categories |
| `lib/presentation/widgets/modals/notification_settings/notification_alerts_history_tab.dart` | `NotificationAlertsHistoryTab` `const ConsumerWidget` | ✓ VERIFIED | 215 LOC, selective `schoolNotificationsStreamProvider.select(...)` subscription |
| `lib/presentation/widgets/modals/notification_settings_modal.dart` | Streamlined `NotificationSettingsModal` coordinator (< 350 LOC) | ✓ VERIFIED | **333 LOC**, coordinates tabs, feedback banner, and `GlobalKey<TelegramChannelCardState>` save footer |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/domain/models/justification_request.dart` | `lib/core/utils/polish_date_formatter.dart` | `JustificationRequest.formatPolishDayHeader` → `PolishDateFormatter.formatDayHeader` | ✓ WIRED | Verified at `justification_request.dart:325-326` |
| `lib/presentation/widgets/common/justification_request_banner.dart` | `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart` | `ParentApprovalModal.show` and `ParentRejectionModal.show` | ✓ WIRED | Verified at `justification_request_banner.dart:123, 178` |
| `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart` | `lib/presentation/widgets/common/justification_request_banner.dart` | `const JustificationRequestBanner(showDetailsLink: true, bottomSpacing: 10)` | ✓ WIRED | Verified at `dashboard_mobile_view.dart:278-281` |
| `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart` | `lib/presentation/widgets/common/justification_request_banner.dart` | `const JustificationRequestBanner(showDetailsLink: true, compact: true)` | ✓ WIRED | Verified at `dashboard_metrics_column.dart:337` |
| `lib/presentation/screens/messages/message_thread_screen.dart` | `lib/domain/models/message_thread.dart` | `withNormalizedSenderName`, `needsDetailsFetch`, `withMergedDetails`, `withSavedDriveAttachments` | ✓ WIRED | Verified at `message_thread_screen.dart:34, 78, 84, 194, 233, 256` and `message_reply_composer.dart:32, 132` |
| `lib/presentation/screens/messages/widgets/message_task_banner.dart` | `lib/presentation/providers/tasks_provider.dart` | `ref.watch(tasksStreamProvider.select(...))` | ✓ WIRED | Verified at `message_task_banner.dart:56-60, 150-154` |
| `lib/presentation/screens/messages/widgets/message_reply_composer.dart` | `lib/presentation/providers/school_providers.dart` | `ref.watch(teachersProvider.select(...))` and `schoolRepositoryProvider.sendMessage` | ✓ WIRED | Verified at `message_reply_composer.dart:69-79, 134-136` |
| `lib/presentation/screens/attendance/attendance_screen.dart` | `lib/presentation/widgets/common/justification_request_banner.dart` | `const JustificationRequestBanner(useIndigoStyle: true, bottomSpacing: 14)` | ✓ WIRED | Verified at `attendance_screen.dart:116-119` |
| `lib/presentation/screens/attendance/widgets/pending_teacher_accordion_banner.dart` | `lib/core/utils/polish_date_formatter.dart` | `PolishDateFormatter.formatDayHeader(dayRecords.first.date)` | ✓ WIRED | Verified at `pending_teacher_accordion_banner.dart:206-208` |
| `lib/presentation/screens/attendance/widgets/attendance_day_group_card.dart` | `lib/presentation/screens/attendance/widgets/requested_attendance_details_sheet.dart` | `RequestedAttendanceDetailsSheet.show(context, record)` | ✓ WIRED | Verified at `attendance_day_group_card.dart:166` |
| `lib/presentation/widgets/modals/notification_settings/telegram_channel_card.dart` | `lib/presentation/widgets/modals/notification_settings/telegram_step_by_step_guide.dart` | `TelegramStepByStepGuide` rendered when `_showTelegramGuide` is true | ✓ WIRED | Verified at `telegram_channel_card.dart:590-600` |
| `lib/presentation/widgets/modals/notification_settings/notification_categories_card.dart` | `lib/presentation/providers/notification_settings_provider.dart` | `ref.watch(notificationChannelSettingsProvider.select(...))` | ✓ WIRED | Verified at `notification_categories_card.dart:12-25` |
| `lib/presentation/widgets/modals/notification_settings_modal.dart` | `lib/presentation/widgets/modals/notification_settings/telegram_channel_card.dart` | `GlobalKey<TelegramChannelCardState>` flushing `savePendingConfigIfNeeded()` | ✓ WIRED | Verified at `notification_settings_modal.dart:36-37, 71, 272-276` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `justification_request_banner.dart` | `pendingReq`, `rejectedReq`, `attendanceRecords`, `profileName` | `justificationRequestsProvider.select(...)`, `attendanceProvider.select(...)`, `studentProfileProvider.select(...)` | Yes | ✓ FLOWING |
| `message_task_banner.dart` | `existingTask`, `suggestion` | `tasksStreamProvider.select(...)` + `SchoolTask.suggestFromMessage(...)` | Yes | ✓ FLOWING |
| `message_reply_composer.dart` | `teachers`, `sendMessage` | `teachersProvider.select(...)`, `schoolRepositoryProvider.sendMessage(...)` | Yes | ✓ FLOWING |
| `attendance_screen.dart` & sub-widgets | `records`, `stats`, `pendingList` | `attendanceProvider`, `attendanceStatsProvider`, `attendanceProvider.notifier` | Yes | ✓ FLOWING |
| `telegram_channel_card.dart`, `web_push_channel_card.dart`, `notification_categories_card.dart`, `notification_alerts_history_tab.dart` | `telegramSlice`, `slice`, `categories`, `items` | `notificationChannelSettingsProvider.select(...)`, `schoolNotificationsStreamProvider.select(...)`, `notificationChannelsServiceProvider` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Target files strictly `< 350 LOC` each | `wc -l lib/presentation/screens/messages/message_thread_screen.dart lib/presentation/screens/attendance/attendance_screen.dart lib/presentation/widgets/modals/notification_settings_modal.dart` | `340`, `273`, `333` LOC (all `< 350`) | ✓ PASS |
| Zero static analysis issues across codebase | `flutter analyze` | `No issues found! (ran in 1.7s)` | ✓ PASS |
| All Phase 21 unit & widget test suites pass | `flutter test test/core/utils/polish_date_formatter_test.dart test/presentation/screens/messages_timestamp_test.dart test/message_attachments_test.dart test/attendance_pending_requests_test.dart test/attendance_justification_modal_test.dart test/presentation/widgets/notification_settings_modal_test.dart test/dashboard_screen_test.dart` | `00:03 +43: All tests passed!` | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED (no probes declared in Phase 21 plans or repository `scripts/`).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| `REQ-ARCH-01` | `21-01`, `21-02`, `21-03`, `21-04` | Dekompozycja monolitycznych widoków UI (`message_thread_screen.dart` – 2 059 LOC, `attendance_screen.dart` – 1 942 LOC, `notification_settings_modal.dart` – 1 642 LOC) na autonomiczne klasy `ConsumerWidget` / `StatelessWidget` z konstruktorami `const` (< 350 LOC na plik) oraz ekstrakcja współdzielonych komponentów (`JustificationRequestBanner`, `PolishDateFormatter`). | ✓ SATISFIED | `message_thread_screen.dart` = 340 LOC, `attendance_screen.dart` = 273 LOC, `notification_settings_modal.dart` = 333 LOC; 16 dedicated widget classes extracted into `widgets/` directories plus shared `JustificationRequestBanner` and `PolishDateFormatter`. |
| `REQ-ARCH-02` | `21-01`, `21-02`, `21-03`, `21-04` | Optymalizacja granic przebudowy (`rebuild scope`) poprzez zastąpienie prywatnych metod `Widget _build*()` osobnymi klasami widgetów oraz zastosowanie selektywnych subskrypcji Riverpod (`ref.watch(...select(...))`), tak aby lokalne interakcje (checkboxy, rozwijanie sekcji, wpisywanie tekstu) nie przebudowywały całych ekranów. | ✓ SATISFIED | Private `_build*()` methods in all 3 screens replaced with `const` widget classes; Dart 3 record and field `.select(...)` selectors wired in `JustificationRequestBanner`, `MessageTaskBanner`, `MessageAppBarTaskAction`, `MessageReplyComposer`, `AttendanceScreen`, `NotificationSettingsModal`, `TelegramChannelCard`, `WebPushChannelCard`, `NotificationCategoriesCard`, and `NotificationAlertsHistoryTab`. |

No orphaned requirements found in `REQUIREMENTS.md` for Phase 21 (only `REQ-ARCH-01` and `REQ-ARCH-02` map to Phase 21).

### Anti-Patterns Found

None — zero `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER`, or stub implementations found across all 28 created/modified files.

### Human Verification Required

None — all must-have truths and UI interaction flows are covered and verified by automated unit and widget tests.

### Gaps Summary

No gaps found. All 4 plans in Phase 21 achieved their targets with 100% test pass rate and 0 analyzer warnings.

---

_Verified: 2026-10-03T16:56:20Z_
_Verifier: the agent (gsd-verifier)_
