# Phase 25: Archiwizacja wiadomości, automatyczna archiwizacja potwierdzeń usprawiedliwień i powiadomienia o akceptacji — Research

**Researched:** 2026-10-04
**Status:** Complete

## 1. Existing Architecture Analysis

### 1.1 Messages Domain & Data Layer
- **`MessageThread` (`lib/domain/models/message_thread.dart`)**:
  - Currently stores `id`, `senderName`, `senderInitials`, `senderRole`, `subject`, `preview`, `body`, `timestamp`, `isUnread`, `isImportant`, `attachments`, `attachmentUrls`, `hasAttachments`, `driveAttachments`, `messages`.
  - Needs `final bool isArchived;` and `final bool isAutoArchived;` (both defaulting to `false`) plus `MessageThread.isSystemJustificationConfirmation(...)`.
- **`SchoolDataCacheManager` (`lib/data/repositories/firestore/school_data_cache_manager.dart`)**:
  - Already manages `prefReadOverrides = 'edusync_read_messages_overrides'` via `_localReadOverrides`.
  - Adding `prefArchiveOverrides = 'edusync_archived_messages_overrides'` with `_localArchiveOverrides`, `ensureArchiveOverridesLoaded()`, `getArchiveOverride(String msgId)`, and `setArchiveOverride(String msgId, bool isArchived)` follows the exact same pattern.
- **`FirestoreMessagesDataSource` (`lib/data/repositories/firestore/firestore_messages_data_source.dart`)**:
  - Line 64 already identifies `lowerSender.contains('usprawiedliwieni')` -> `role = 'System Librus'`.
  - When mapping messages in `getMessages()`:
    - Checks `isSystemJustificationConfirmation` (sender contains `usprawiedliwieni` / `system librus` OR subject/body contains `zaakceptowano usprawiedliwienie` / `usprawiedliwienie zostało zaakceptowane` / `potwierdzenie usprawiedliwienia`) or backend `item['isAutoArchived'] == true`.
    - Priority order for `isArchived`:
      1. Local override in `SchoolDataCacheManager.getArchiveOverride(id)`
      2. Remote override in `data['archivedMessageOverrides']?[id]` or explicit `item['isArchived']`
      3. Auto-archive rule (`isAutoArchived == true`)
    - Per `D-03`: When a message is auto-archived (and not explicitly overridden by the user), `isUnread` is forced to `false` so it never inflates unread badges.
- **Facade Line Count Constraint (`lib/data/repositories/firestore_school_repository.dart`)**:
  - Phase 24 test `test/data/repositories/firestore_messages_and_schedule_test.dart` enforces `< 250 LOC` on `lib/data/repositories/firestore_school_repository.dart` (currently 243 lines). When adding `archiveMessage`, keep `FirestoreSchoolRepository` under 245 lines.

### 1.2 Cloud Functions Notification & Sync Pipeline
- **`sync_service.js` (`functions/src/sync_service.js`)**:
  - Compares `prevData` and `freshData` for `subjects` (grades), `announcements`, `messages`, and `exams`.
  - Currently, any new message in `freshData.messages` produces a notification with `type: "message"`.
  - Enhancement for `D-03` & `D-06`:
    - Helper `isJustificationApprovalMessage(m)` checks if a message is a Librus justification acceptance confirmation.
    - Matching messages in `freshData.messages` are tagged with `isAutoArchived: true`, `isArchived: true`, `isRead: true`, `unread: false` (unless previously unarchived in `prevData.archivedMessageOverrides`).
    - New justification approval messages generate a `type: "justification"` notification instead of `type: "message"`.
    - Additionally, compare `prevData.attendance` / `prevData.justifications` with `freshData.attendance` / `freshData.justifications` to detect lessons or justification periods that transitioned from unexcused/requested to `excused`/`zaakceptowano`, deduplicating by date so a single teacher approval produces one `type: "justification"` notification.
- **`telegram_service.js` (`functions/src/telegram_service.js`)**:
  - Add `case "justification":` in `formatNotificationForTelegram` with header `✅ <b>Zaakceptowano usprawiedliwienie!</b> (${safeStudent})` and deep link `https://lepsza-szkola.web.app/frekwencja`.
  - In `isCategoryEnabled(settings, notifType)`, return `true` (or `settings.notifyMessages !== false`) for `"justification"`, dispatching to all paired family Telegram chats (both Parent and Student, per `D-06`).

### 1.3 Attendance Accepted Justifications UI (`AttendanceScreen`)
- **`AttendanceFilterBar` (`lib/presentation/screens/attendance/widgets/attendance_filter_bar.dart`)**:
  - Currently displays `'Usprawiedliwione'` without a count on filter chip `2`. Adding `required this.excusedCount` (or default `0`) and rendering `'Usprawiedliwione ($excusedCount)'` aligns it with `Do usprawiedliwienia ($unexcusedCount)` and `Oczekujące ($pendingCount)`.
- **`AcceptedJustificationsSummaryCard` & `AttendanceLessonRow`**:
  - When `_activeFilter == 2` (`Usprawiedliwione`), display `AcceptedJustificationsSummaryCard` above the day groups summarizing accepted justifications (days count, total excused lessons count, and recent justification reasons), and enhance `AttendanceLessonRow` to show a clear badge `Zaakceptowano przez wychowawcę` along with the justification reason.

## 2. Validation Architecture
- **Unit & Repository Tests**:
  - `flutter test test/data/repositories/message_archiving_test.dart` — verifies manual archiving/unarchiving, `SharedPreferences` + Firestore persistence, auto-archiving and auto-read of justification confirmation messages, and `FirestoreSchoolRepository < 250 LOC`.
  - `node --test functions/test/justification_notifications.test.js` — verifies `isJustificationApprovalMessage`, auto-archiving in `sync_service.js`, detection of newly accepted justifications, and Telegram HTML formatting for `type: "justification"`.
- **Widget Tests**:
  - `flutter test test/presentation/screens/messages_archive_and_attendance_accepted_test.dart` — verifies the `Pokaż zarchiwizowane (X)` chip in `MessagesScreen`, archiving/restoring a message from the list and `MessageThreadScreen`, and the `Usprawiedliwione (X)` chip + `AcceptedJustificationsSummaryCard` + `Zaakceptowano przez wychowawcę` status in `AttendanceScreen`.
