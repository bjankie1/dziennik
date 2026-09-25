---
phase: 18
phase_name: "Powiadomienia w czasie rzeczywistym: Telegram Bot i Web Push"
review_date: "2026-09-25"
depth: standard
mode: "--fix --auto"
status: fixed_and_verified
findings_summary:
  critical: 1
  warning: 4
  info: 0
  fixed: 5
---

# Phase 18 Code Review Report (`18-REVIEW.md`)

## Scope Reviewed
- `functions/src/telegram_service.js`
- `functions/src/sync_service.js`
- `functions/index.js`
- `firestore.rules`
- `web/sw-notifications.js`
- `web/index.html`
- `lib/domain/models/notification_settings.dart`
- `lib/core/utils/web_push_browser_helper_stub.dart`
- `lib/core/utils/web_push_browser_helper_web.dart`
- `lib/core/services/notification_channels_service.dart`
- `lib/presentation/providers/notification_settings_provider.dart`
- `lib/presentation/widgets/modals/notification_settings_modal.dart`
- `lib/presentation/widgets/app_desktop_header.dart`
- `lib/presentation/screens/main_navigation_screen.dart`

---

## Findings & Auto-Fix Log (`--fix --auto`)

### 1. [CRITICAL] Unescaped HTML in Telegram Bot messages (`MainNavigationScreen`, `NotificationChannelsService`, `functions/index.js`)
- **Problem**: `MainNavigationScreen` (when forwarding new family chat messages to Telegram) and `NotificationChannelsService.sendTestTelegram` / `functions/index.js` interpolated `newMsg.senderName`, `newMsg.text`, and `studentName` directly into `parse_mode: 'HTML'` strings without escaping `<`, `>`, and `&`. Any message containing `<` or `&` caused Telegram Bot API to return `400 Bad Request: can't parse entities` or allowed HTML injection.
- **Fix Applied**: Added `NotificationChannelsService.escapeTelegramHtml()` in Dart and `escapeHtml()` in `functions/index.js`, sanitizing all dynamic fields before constructing Telegram HTML payloads.

### 2. [WARNING] Initial Firestore snapshot flood / duplicate notifications on app reload (`MainNavigationScreen`, `NotificationChannelsService`)
- **Problem**: `ref.listen(schoolNotificationsStreamProvider, ...)` and `ref.listen(familyChatMessagesProvider, ...)` compared `previous.value` with `next.value`. When `previous.value` was an initial empty list `[]` and Firestore emitted historical records, or when widgets rebuilt, historical items could be treated as newly arrived events and trigger duplicate Web Push / Telegram notifications.
- **Fix Applied**:
  1. Added session-level deduplication (`_dispatchedEventIds`) and timestamp freshness check (`<= 5 minutes` old and `!item.isRead`) in `NotificationChannelsService` and `MainNavigationScreen`.
  2. Ignored initial transition when `previous == null || !previous.hasValue || previous.value!.isEmpty` unless the newest event was created within the last 90 seconds.

### 3. [WARNING] 15-minute pairing code expiration & Telegram message timestamp validation (`telegram_service.js`, `NotificationChannelsService`)
- **Problem**: `verifyAndPairCodeFromUpdates` and `verifyPairingCode` matched the 6-digit code in `getUpdates` without verifying that the Firestore pairing code had not expired (`pairingCodeExpiresAt`) or that the Telegram message timestamp (`msg.date`) was recent.
- **Fix Applied**: Added expiration checks against `pairingCodeExpiresAt` in Firestore and validated that the matched Telegram `message.date` is within the last 20 minutes (`1200` seconds).

### 4. [WARNING] Safe substring formatting for `pairingCode` & mark-as-read workflow in `NotificationSettingsModal`
- **Problem**: `settings.pairingCode!.substring(0, 3)` assumed `pairingCode` is always at least 3 chars, which could throw a `RangeError` on malformed data. Additionally, notifications in Tab 2 (`Ostatnie alerty`) lacked a way to be marked as read (`isRead: true`).
- **Fix Applied**: Added safe formatting helper `_formatPairingCode(String? code)` and added `markNotificationAsRead` / `markAllNotificationsAsRead` in `NotificationChannelsService` with a „Oznacz jako przeczytane” button in `NotificationSettingsModal`.

### 5. [WARNING] Idempotent notification document IDs in `functions/src/sync_service.js`
- **Problem**: `grade_${g.id}_${Date.now()}` and `exam_${Date.now()}_${Math.random()}` included timestamps/random suffixes in Firestore document IDs, which could create duplicate notification documents if two sync runs overlapped.
- **Fix Applied**: Changed notification document IDs to deterministic keys (`grade_${g.id}`, `msg_${m.id}`, `ann_${a.id}`, `exam_${examSlug}`) so `notifBatch.set(notifRef, notif)` is idempotent.
