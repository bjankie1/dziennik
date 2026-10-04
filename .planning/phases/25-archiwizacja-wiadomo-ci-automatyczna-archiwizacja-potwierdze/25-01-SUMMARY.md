---
phase: 25-archiwizacja-wiadomo-ci-automatyczna-archiwizacja-potwierdze
plan: 01
subsystem: messages-archiving-and-notifications
tags: [flutter, firestore, cloud-functions, telegram, messages, attendance]
requires: []
provides:
  - MessageThread.isArchived, MessageThread.isAutoArchived, and MessageThread.isSystemJustificationConfirmation
  - SchoolDataCacheManager archive overrides (prefArchiveOverrides) and FirestoreMessagesDataSource.archiveMessage
  - Automatic read+archive of Librus system justification confirmation messages
  - Cloud Functions justification acceptance detection (from system messages and attendance/justifications transitions) and Telegram/Web Push/Alerts dispatch
affects:
  - lib/domain/models/message_thread.dart
  - lib/data/repositories/firestore/school_data_cache_manager.dart
  - lib/data/repositories/firestore/firestore_messages_data_source.dart
  - functions/src/sync_service.js
  - functions/src/telegram_service.js
tech-stack:
  added: []
  patterns: [auto-archive-rule, notification-deduplication]
key-files:
  created:
    - test/data/repositories/message_archiving_test.dart
    - functions/test/justification_notifications.test.js
  modified:
    - lib/domain/models/message_thread.dart
    - lib/data/repositories/school_repository.dart
    - lib/data/repositories/mock_school_repository.dart
    - lib/data/repositories/firestore/school_data_cache_manager.dart
    - lib/data/repositories/firestore/firestore_messages_data_source.dart
    - lib/data/repositories/firestore_school_repository.dart
    - lib/presentation/providers/school_providers.dart
    - lib/presentation/screens/main_navigation_screen.dart
    - lib/presentation/screens/dashboard/dashboard_screen.dart
    - lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart
    - lib/domain/models/notification_settings.dart
    - lib/presentation/widgets/modals/notification_settings/notification_alerts_history_tab.dart
    - functions/src/sync_service.js
    - functions/src/telegram_service.js
key-decisions:
  - "Auto-archived system justification confirmation messages are automatically marked as read (D-03) and excluded from unread counters and Dashboard recent message cards (D-04)"
  - "Justification acceptance notifications (type: 'justification') are deduplicated by date across new confirmation messages and attendance status transitions, and sent to all paired Telegram chats (Parent & Student), Web Push, and Ostatnie alerty (D-06)"
patterns-established:
  - "Dual local (SharedPreferences) + remote (Firestore archivedMessageOverrides) persistence for message archive state"
requirements-completed:
  - REQ-MSG-ARCH-01
  - REQ-MSG-ARCH-02
  - REQ-NOTIF-ACC-01
duration: 10min
completed: 2026-10-04
---

# Phase 25 Plan 01: Message Archiving & Justification Notifications Summary

**Domain, repository, and Cloud Functions foundation for manual and automatic message archiving and justification acceptance notifications.**

## Accomplishments
- Added `isArchived`, `isAutoArchived`, and `MessageThread.isSystemJustificationConfirmation` to `MessageThread`.
- Added `archiveMessage(String msgId, {bool isArchived = true})` across `SchoolRepository`, `MockSchoolRepository`, `SchoolDataCacheManager`, `FirestoreMessagesDataSource`, and `FirestoreSchoolRepository` (keeping `FirestoreSchoolRepository` under 250 LOC).
- Automatically marked system justification confirmation messages as read and archived unless explicitly unarchived by the user (`D-03`), and excluded archived messages from unread counts and Dashboard recent messages (`D-04`).
- Implemented `isJustificationApprovalMessage` and `detectJustificationNotifications` in `functions/src/sync_service.js` and `type: "justification"` formatting in `functions/src/telegram_service.js` + Flutter Web Push / Alerts History routing (`D-06`).

## Task Commits
1. **Task 1: Add Message Archiving & Auto-Archive Domain/Repository Support** — `6f513a0`
2. **Task 2: Add Cloud Functions Justification Acceptance Detection, Auto-Archiving & Notifications** — `9eeda3a`
