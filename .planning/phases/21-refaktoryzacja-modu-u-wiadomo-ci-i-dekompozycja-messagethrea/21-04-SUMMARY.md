---
phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea
plan: 04
subsystem: ui
tags: [flutter, riverpod, notifications, telegram, web-push, refactoring]

# Dependency graph
requires:
  - phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea
    provides: Shared PolishDateFormatter and Riverpod .select(...) patterns established in 21-01
provides:
  - NotificationSectionCard const StatelessWidget wrapper for notification channel and category cards
  - TelegramStepByStepGuide const StatelessWidget for the 4-step @BotFather setup guide with all ValueKeys preserved
  - TelegramChannelCard ConsumerStatefulWidget with isolated TextEditingControllers and savePendingConfigIfNeeded()
  - WebPushChannelCard, NotificationCategoriesCard, and NotificationAlertsHistoryTab with Dart 3 record .select(...) subscriptions
  - Streamlined NotificationSettingsModal coordinator reduced from 1 643 LOC to 333 LOC (< 350 LOC)
affects: []

# Actuals (#2632)
plan_head_before: db1b7af0d1d5f3008204bca95811764c6c2ace86
actuals:
  tokens: 33349
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dart 3 record selectors with Riverpod .select(...) for notificationChannelSettingsProvider and schoolNotificationsStreamProvider"
    - "GlobalKey<TelegramChannelCardState> coordinator pattern for flushing unsaved text controller edits on modal save"

key-files:
  created:
    - lib/presentation/widgets/modals/notification_settings/notification_section_card.dart
    - lib/presentation/widgets/modals/notification_settings/telegram_step_by_step_guide.dart
    - lib/presentation/widgets/modals/notification_settings/telegram_channel_card.dart
    - lib/presentation/widgets/modals/notification_settings/web_push_channel_card.dart
    - lib/presentation/widgets/modals/notification_settings/notification_categories_card.dart
    - lib/presentation/widgets/modals/notification_settings/notification_alerts_history_tab.dart
  modified:
    - lib/presentation/widgets/modals/notification_settings_modal.dart

key-decisions:
  - "Decomposed NotificationSettingsModal (1 643 -> 333 LOC) into 6 focused sub-widgets in lib/presentation/widgets/modals/notification_settings/ with Dart 3 record .select(...) subscriptions"
  - "Exposed savePendingConfigIfNeeded() on TelegramChannelCardState via GlobalKey so the modal's bottom 'Zapisz ustawienia' button flushes pending @BotFather token/username/chatId edits before closing"

patterns-established:
  - "Card-level Riverpod .select(...) with Dart 3 records prevents unrelated channel or category toggles from rebuilding sibling cards"

requirements-completed:
  - REQ-ARCH-01
  - REQ-ARCH-02

coverage:
  - id: D1
    description: "Extracted NotificationSectionCard, TelegramStepByStepGuide, and TelegramChannelCard into lib/presentation/widgets/modals/notification_settings/ with isolated TextEditingControllers, ValueKeys, and @BotFather getMe resolution"
    requirement: REQ-ARCH-01
    verification:
      - kind: automated_ui
        ref: "test/presentation/widgets/notification_settings_modal_test.dart"
        status: pass
    human_judgment: false
  - id: D2
    description: "Extracted WebPushChannelCard, NotificationCategoriesCard, and NotificationAlertsHistoryTab with Dart 3 record .select(...) subscriptions and reduced notification_settings_modal.dart from 1 643 LOC to 333 LOC (< 350 LOC)"
    requirement: REQ-ARCH-02
    verification:
      - kind: automated_ui
        ref: "test/presentation/widgets/notification_settings_modal_test.dart"
        status: pass
    human_judgment: false

# Metrics
duration: 7min
completed: 2026-10-03
status: complete
---

# Phase 21 Plan 04: NotificationSettingsModal Decomposition Summary

**Decomposed `NotificationSettingsModal` (`1 643 → 333 LOC`) into 6 modular sub-widgets in `lib/presentation/widgets/modals/notification_settings/` with Dart 3 record `.select(...)` subscriptions, isolated Telegram `TextEditingController`s, and a bottom `'Zapisz ustawienia'` persistence bar.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-10-03T16:45:21Z
- **Completed:** 2026-10-03T16:52:36Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Extracted `NotificationSectionCard` (`const StatelessWidget`), `TelegramStepByStepGuide` (`const StatelessWidget`), and `TelegramChannelCard` (`ConsumerStatefulWidget` / `TelegramChannelCardState`) into `lib/presentation/widgets/modals/notification_settings/`, preserving `telegram_step_by_step_guide_button`, `telegram_guide_show_token_field_button`, `telegram_guide_content`, `copy_newbot_button`, `open_botfather_button`, all 4 `@BotFather` setup steps, and the `'Invalid bot passed'` warning box.
- Isolated `_botTokenController`, `_botUsernameController`, `_manualChatIdController`, and loading/guide toggles inside `TelegramChannelCardState` and exposed `savePendingConfigIfNeeded()` (with `@` sanitization per T-21-07 and automatic `fetchBotUsername` resolution).
- Extracted `WebPushChannelCard`, `NotificationCategoriesCard`, and `NotificationAlertsHistoryTab` using Dart 3 record `.select(...)` selectors on `notificationChannelSettingsProvider` and `schoolNotificationsStreamProvider` so toggling categories or Web Push never rebuilds sibling cards.
- Reduced `lib/presentation/widgets/modals/notification_settings_modal.dart` from 1 643 LOC to 333 LOC (`< 350 LOC`) and added a footer bar with `'Zapisz ustawienia'` (`ValueKey('save_notification_settings_button')`) that flushes pending Telegram configuration before closing.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract NotificationSectionCard, TelegramStepByStepGuide & TelegramChannelCard into modals/notification_settings/** - `fdf64ea` (feat)
2. **Task 2: Extract WebPushChannelCard, NotificationCategoriesCard & NotificationAlertsHistoryTab and Reduce notification_settings_modal.dart to < 350 LOC** - `1f76e18` (refactor)

## Files Created/Modified
- `lib/presentation/widgets/modals/notification_settings/notification_section_card.dart` - Reusable `const StatelessWidget` card wrapper with icon badge, status pill, and optional trailing switch
- `lib/presentation/widgets/modals/notification_settings/telegram_step_by_step_guide.dart` - 4-step `@BotFather` setup guide with `Invalid bot passed` warning and preserved `ValueKey`s
- `lib/presentation/widgets/modals/notification_settings/telegram_channel_card.dart` - Isolated Telegram pairing, `@BotFather` token/chatId inputs, test ping, and `savePendingConfigIfNeeded()`
- `lib/presentation/widgets/modals/notification_settings/web_push_channel_card.dart` - Browser Web Push toggle and test push button with Dart 3 record `.select(...)` subscription
- `lib/presentation/widgets/modals/notification_settings/notification_categories_card.dart` - Event category switches using Dart 3 record `.select(...)` equality
- `lib/presentation/widgets/modals/notification_settings/notification_alerts_history_tab.dart` - Sent alerts history list with mark-all-read, Web Push re-trigger, and route navigation
- `lib/presentation/widgets/modals/notification_settings_modal.dart` - Streamlined 333-LOC modal coordinator with tabs, feedback banner, and bottom save bar

## Decisions Made
- Used Dart 3 record selectors inside `TelegramChannelCard`, `WebPushChannelCard`, and `NotificationCategoriesCard` so Firestore updates to one channel or category only rebuild the affected card.
- Wired a `GlobalKey<TelegramChannelCardState>` from `NotificationSettingsModal` to `TelegramChannelCard` so clicking `'Zapisz ustawienia'` in the modal footer persists any unsubmitted edits in the `@BotFather` token/username/chatId text fields before closing.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 21 is complete: all three target UI monoliths are under 350 LOC (`message_thread_screen.dart` = 340 LOC, `attendance_screen.dart` = 273 LOC, `notification_settings_modal.dart` = 333 LOC), shared `PolishDateFormatter` and `JustificationRequestBanner` are in place, and all widget/unit tests pass with 0 analyzer issues.

## Self-Check: PASSED
- Verified all 6 created files and `notification_settings_modal.dart` exist on disk.
- Verified commits `fdf64ea` and `1f76e18` exist in git history.
- Verified `notification_settings_modal.dart` is 333 LOC (< 350 LOC), `flutter analyze` reports 0 issues, and all 43 Phase 21 tests pass.

---
*Phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea*
*Completed: 2026-10-03*
