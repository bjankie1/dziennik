---
phase: quick-261006-j7z
plan: 01
subsystem: messages
tags: [messages, replies, librus, firestore, cache, riverpod]
requires: []
provides:
  - Backend Librus /wiadomosci/3/5/:id reply form submission and /wiadomosci/6 (Wysłane) sent-message scraping + thread correlation
  - Multi-layer reply persistence across SharedPreferences (local_message_replies_v1), in-memory cache, and Firestore students/{login}.messages[].replies
  - Sync-safe reply merging and deduplication in mergeAndIndexMessages
  - Accurate Parent/Student sender attribution and live reply synchronization in MessageThreadScreen and MessagesScreen
affects:
  - functions/src/librus_client.js
  - functions/src/sync_service.js
  - functions/index.js
  - lib/domain/models/message_thread.dart
  - lib/data/repositories/firestore/school_data_cache_manager.dart
  - lib/data/repositories/firestore/firestore_messages_data_source.dart
  - lib/presentation/screens/messages/widgets/message_reply_composer.dart
  - lib/presentation/screens/messages/message_thread_screen.dart
  - lib/presentation/screens/messages/messages_screen.dart
tech-stack:
  added: []
  patterns:
    - Multi-layer optimistic + durable reply persistence (SharedPreferences local_message_replies_v1 + Firestore messages[].replies + /wiadomosci/6 sent folder correlation)
key-files:
  created: []
  modified:
    - functions/src/librus_client.js
    - functions/src/sync_service.js
    - functions/index.js
    - functions/test/message_body_indexing.test.js
    - lib/domain/models/message_thread.dart
    - lib/data/repositories/firestore/school_data_cache_manager.dart
    - lib/data/repositories/firestore/firestore_messages_data_source.dart
    - lib/data/repositories/school_repository.dart
    - lib/data/repositories/firestore_school_repository.dart
    - lib/data/repositories/mock_school_repository.dart
    - lib/presentation/screens/messages/widgets/message_reply_composer.dart
    - lib/presentation/screens/messages/message_thread_screen.dart
    - lib/presentation/screens/messages/messages_screen.dart
    - test/data/repositories/firestore_messages_and_schedule_test.dart
decisions:
  - Persist sent replies simultaneously in account-scoped SharedPreferences (local_message_replies_v1), in-memory student cache, and Firestore students/{login}.messages[].replies so replies survive provider invalidations, route navigation, page reloads, and cross-device sessions
  - Scrape Librus /wiadomosci/6 (Wysłane) during fetchMessages(), strip quoted original message blocks via _stripQuotedReplyBody, and correlate sent replies back onto inbox threads by normalized subject and recipient surname
  - Preserve existing and fresh replies across background Librus sync cycles via mergeMessageReplies in mergeAndIndexMessages
metrics:
  duration: 23 min
  completed: 2026-10-06
status: complete
commits: 3
plan_head_before: e8674b05f11a38377f16bea89096840fa1173a44
plan_head_after: 89af6bf0070f7e661c3b53caba5ddf342abda02e
actuals:
  tokens: 18500
  tasks: 3
  commits: 3
---

# Quick Task 261006-j7z: Trwała persystencja i synchronizacja wysłanych odpowiedzi w wątkach wiadomości Summary

End-to-end persistence, Librus `/wiadomosci/6` (Wysłane) correlation, and UI synchronization for sent message replies across local cache, Firestore, and background sync cycles.

## Root Cause & Solution

Previously, sending a reply in a message thread (such as the thread with educator Sobota Łukasz, subject *"składka 21 zł na maturę próbną z Operonem"*) failed to persist because:
1. `FirestoreMessagesDataSource.sendMessage` only appended the reply to `mockFallback` and never persisted it to `SchoolDataCacheManager`, `SharedPreferences`, or Firestore, while `MessageReplyComposer` immediately invalidated `messagesProvider`.
2. `FirestoreMessagesDataSource.getMessages()` always constructed `MessageThread` with a 1-element `messages: [initialItem]` array, and `MessageThread.withMergedDetails()` overwrote `messages` with a 1-element list when hydrating full message details.
3. `LibrusClient.fetchMessages()` only scraped `/wiadomosci/5` (Odebrane) and ignored `/wiadomosci/6` (Wysłane), and `mergeAndIndexMessages` did not preserve `replies` across sync cycles.

### Key Changes

- **Task 1 (`362f828`) — Backend Librus reply submission, `/wiadomosci/6` scraping & sync preservation**:
  - Updated `LibrusClient.sendMessage` in `functions/src/librus_client.js` to load `/wiadomosci/3/5/:replyToId`, extract hidden CSRF/form fields (`requestkey`, `DoKogo`, `temat`, etc.), and submit the reply via `POST /wiadomosci`.
  - Updated `LibrusClient.fetchMessages` to scrape `/wiadomosci/6` (Wysłane), strip quoted original message blocks (`----- Wiadomość oryginalna -----` / `Użytkownik ... napisał:`), and attach sent replies onto matching inbox threads by normalized subject (`Re:`/`Odp:` stripped) and recipient surname.
  - Added `mergeMessageReplies` in `functions/src/sync_service.js` and wired it into `mergeAndIndexMessages` so `replies` are preserved and deduplicated across sync cycles.
  - Updated `exports.sendMessage` in `functions/index.js` to validate body length (`<= 10000`), invoke `client.sendMessage`, and append the reply onto `students/{targetStudentId}.messages[i].replies` in Firestore.
- **Task 2 (`5610e8b`) — Flutter reply persistence, hydration & `MessageThread` model preservation**:
  - Added `MessageThread.copyWithMessages` and updated `MessageThread.withMergedDetails` in `lib/domain/models/message_thread.dart` to preserve `...messages.skip(1)` when hydrating full body/attachments.
  - Added account-scoped `local_message_replies_v1` persistence (`ensureLocalRepliesLoaded`, `getLocalReplies`, `addLocalReply`, and `_applyLocalRepliesToData`) in `lib/data/repositories/firestore/school_data_cache_manager.dart`.
  - Updated `FirestoreMessagesDataSource.getMessages` to hydrate `MessageThread.messages` with `[initialItem, ...replyItems]` from Firestore `item['replies']` and `cacheManager.getLocalReplies(id)` (deduplicated and sorted chronologically).
  - Updated `FirestoreMessagesDataSource.sendMessage` to persist replies locally, POST to `/api/sendMessage` with fallback to `https://europe-west3-lepsza-szkola.cloudfunctions.net/sendMessage`, and persist replies to Firestore `students/{targetLogin}`.
- **Task 3 (`89af6bf`) — Thread UI synchronization, Parent/Student attribution & inbox reply indicators**:
  - Updated `MessageReplyComposer` to resolve `senderName` and `senderRole` (`'Rodzic'` vs `'Uczeń'`) from `appUserProvider` instead of hardcoding `'Uczeń'`.
  - Updated `MessageThreadScreen` (`didUpdateWidget`, `build`, and `onReplySent`) to merge incoming/provider replies with `_currentThread` without losing hydrated first-message details or optimistic replies.
  - Updated `MessagesScreen._buildMessageCard` to show an `Odpowiedzi: X` badge chip and `Ty: ...` preview prefix when a thread has sent replies.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Extended `sendMessage` signature across `SchoolRepository`, `FirestoreSchoolRepository`, and `MockSchoolRepository`**
- **Found during:** Task 2
- **Issue:** Passing `senderName` and `senderRole` from `MessageReplyComposer` to `SchoolRepository.sendMessage` and `mockFallback.sendMessage` required matching optional named parameters on the repository interface and implementations.
- **Fix:** Added optional `String? senderName, String? senderRole` parameters to `SchoolRepository.sendMessage`, `FirestoreSchoolRepository.sendMessage` (keeping facade at 218 LOC, strictly `< 250` LOC), and `MockSchoolRepository.sendMessage`.
- **Files modified:** `lib/data/repositories/school_repository.dart`, `lib/data/repositories/firestore_school_repository.dart`, `lib/data/repositories/mock_school_repository.dart`
- **Commit:** `5610e8b`

## Verification

- `node --test functions/test/message_body_indexing.test.js` — 10/10 tests passed.
- `flutter test test/data/repositories/firestore_messages_and_schedule_test.dart` — 11/11 unit and widget tests passed (including `firestore_school_repository.dart < 250 LOC` check).
- `flutter analyze lib/data/repositories/firestore/ lib/domain/models/message_thread.dart lib/presentation/screens/messages/` — No issues found.

## Self-Check: PASSED
