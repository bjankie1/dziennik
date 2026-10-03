---
phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea
plan: 02
subsystem: ui
tags: [flutter, riverpod, messages, google-drive, refactoring]

# Dependency graph
requires:
  - phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea
    provides: Shared PolishDateFormatter and JustificationRequestBanner foundations (21-01)
provides:
  - Pure domain methods on MessageThread (resolveSenderName, extractCcTeacherFromBody, looksLikeMessageWithAttachment, needsDetailsFetch, unsavedAttachmentsFor, withNormalizedSenderName, withMergedDetails, withSavedDriveAttachments) with unit tests
  - Modular MessageThreadHeaderCard, MessageTaskBanner (+ MessageAppBarTaskAction), MessageAccordionTile, and MessageReplyComposer widgets in lib/presentation/screens/messages/widgets/
  - Streamlined MessageThreadScreen coordinator reduced from 2 060 LOC to 340 LOC (< 350 LOC) with selective Riverpod .select(...) subscriptions
affects: [21-03, 21-04]

# Actuals (#2632)
plan_head_before: 10e64854585092abcf7d99bc1836fd494c825daf
actuals:
  tokens: 23951
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Domain-driven message parsing (resolveSenderName, extractCcTeacherFromBody, looksLikeMessageWithAttachment) on MessageThread"
    - "Isolated stateful leaf composer (MessageReplyComposer) owning TextEditingController/FocusNode and watching teachersProvider.select(...)"
    - "Selective Riverpod task lookup in MessageTaskBanner and MessageAppBarTaskAction via tasksStreamProvider.select(...)"

key-files:
  created:
    - lib/presentation/screens/messages/widgets/message_thread_header_card.dart
    - lib/presentation/screens/messages/widgets/message_task_banner.dart
    - lib/presentation/screens/messages/widgets/message_accordion_tile.dart
    - lib/presentation/screens/messages/widgets/message_reply_composer.dart
  modified:
    - lib/domain/models/message_thread.dart
    - test/presentation/screens/messages_timestamp_test.dart
    - lib/presentation/screens/messages/message_thread_screen.dart

key-decisions:
  - "Moved sender signature regex parsing, CC teacher extraction, attachment keyword heuristics, and immutable thread detail/Drive state transitions directly onto MessageThread so domain logic is testable without Flutter widgets"
  - "Isolated reply input state (_isReplying, _isSending, _replyRecipients, _replyController, _replyFocusNode) inside MessageReplyComposer with teachersProvider.select(...) so typing or modifying recipients never rebuilds the message list"
  - "Scoped task stream subscriptions to MessageTaskBanner and MessageAppBarTaskAction using tasksStreamProvider.select(...) so unrelated task edits do not rebuild MessageThreadScreen"

patterns-established:
  - "Screen Coordinator < 350 LOC: MessageThreadScreen orchestrates thread lifecycle and Google Drive actions while delegating UI sections to dedicated const/Consumer sub-widgets"
  - "Ephemeral Form Isolation: Encapsulating TextEditingController and FocusNode inside a leaf ConsumerStatefulWidget (MessageReplyComposer) to prevent parent scroll view rebuilds"

requirements-completed:
  - REQ-ARCH-01
  - REQ-ARCH-02

coverage:
  - id: D1
    description: "MessageThread domain methods (resolveSenderName, extractCcTeacherFromBody, looksLikeMessageWithAttachment) with unit test coverage"
    requirement: REQ-ARCH-01
    verification:
      - kind: unit
        ref: "test/presentation/screens/messages_timestamp_test.dart#MessageThread domain helpers (resolveSenderName, extractCcTeacherFromBody, looksLikeMessageWithAttachment)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Extracted MessageThreadHeaderCard, MessageTaskBanner, MessageAccordionTile, and MessageReplyComposer widgets and reduced message_thread_screen.dart from 2 060 LOC to 340 LOC (< 350 LOC)"
    requirement: REQ-ARCH-02
    verification:
      - kind: automated_ui
        ref: "test/message_attachments_test.dart"
        status: pass
      - kind: automated_ui
        ref: "test/presentation/screens/messages_timestamp_test.dart"
        status: pass
    human_judgment: false

# Metrics
duration: 12min
completed: 2026-10-03
status: complete
---

# Phase 21 Plan 02: MessageThreadScreen Decomposition & Domain Parsing Extraction Summary

**Decomposed `message_thread_screen.dart` from 2 060 LOC to a 340-LOC coordinator by moving sender/CC/attachment regex parsing into `MessageThread` and extracting `MessageThreadHeaderCard`, `MessageTaskBanner`, `MessageAccordionTile`, and `MessageReplyComposer` with `.select(...)` rebuild boundaries.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-10-03T16:24:00Z
- **Completed:** 2026-10-03T16:36:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Moved `resolveSenderName`, `extractCcTeacherFromBody`, `looksLikeMessageWithAttachment`, and immutable thread transformation helpers (`needsDetailsFetch`, `unsavedAttachmentsFor`, `withNormalizedSenderName`, `withMergedDetails`, `withSavedDriveAttachments`) onto `MessageThread` (`lib/domain/models/message_thread.dart`) and added unit test coverage in `test/presentation/screens/messages_timestamp_test.dart`.
- Extracted `MessageThreadHeaderCard` (`lib/presentation/screens/messages/widgets/message_thread_header_card.dart`) and `MessageTaskBanner` + `MessageAppBarTaskAction` (`lib/presentation/screens/messages/widgets/message_task_banner.dart`) watching `tasksStreamProvider.select(...)` so unrelated task changes never rebuild `MessageThreadScreen`.
- Extracted `MessageAccordionTile` (`lib/presentation/screens/messages/widgets/message_accordion_tile.dart`) preserving all Gmail-style collapsible message behaviors and Google Drive attachment `ValueKey`s (`save_all_drive_button`, `download_attachment_$file`, `drive_spinner_$file`, `open_drive_$file`, `save_drive_$file`).
- Extracted `MessageReplyComposer` (`lib/presentation/screens/messages/widgets/message_reply_composer.dart`) encapsulating `_isReplying`, `_isSending`, `_replyRecipients`, `_replyController`, and `_replyFocusNode` with `teachersProvider.select(...)`, reducing `lib/presentation/screens/messages/message_thread_screen.dart` from 2 060 LOC to 340 LOC.

## Task Commits

Each task was committed atomically:

1. **Task 1: Move Sender/CC/Attachment Parsing to MessageThread Domain Model & Extract MessageThreadHeaderCard and MessageTaskBanner** - `07197f9` (feat)
2. **Task 2: Extract MessageAccordionTile and MessageReplyComposer & Reduce message_thread_screen.dart to < 350 LOC** - `1d3bf62` (refactor)

## Files Created/Modified
- `lib/domain/models/message_thread.dart` - Added `resolveSenderName`, `extractCcTeacherFromBody`, `looksLikeMessageWithAttachment`, and immutable state transformation helpers on `MessageThread`
- `test/presentation/screens/messages_timestamp_test.dart` - Added unit test group verifying `resolveSenderName`, `extractCcTeacherFromBody`, and `looksLikeMessageWithAttachment`
- `lib/presentation/screens/messages/widgets/message_thread_header_card.dart` - Extracted `MessageThreadHeaderCard` `StatelessWidget` for subject, unread/important badges, sender role, and message count pill
- `lib/presentation/screens/messages/widgets/message_task_banner.dart` - Extracted `MessageTaskBanner` and `MessageAppBarTaskAction` `ConsumerWidget`s with `tasksStreamProvider.select(...)`
- `lib/presentation/screens/messages/widgets/message_accordion_tile.dart` - Extracted `MessageAccordionTile` `StatelessWidget` for collapsible message cards and Google Drive attachment actions
- `lib/presentation/screens/messages/widgets/message_reply_composer.dart` - Extracted `MessageReplyComposer` `ConsumerStatefulWidget` isolating reply input state and `teachersProvider.select(...)`
- `lib/presentation/screens/messages/message_thread_screen.dart` - Streamlined from 2 060 LOC to 340 LOC coordinator

## Decisions Made
- Added immutable domain helpers (`withNormalizedSenderName`, `withMergedDetails`, `withSavedDriveAttachments`, `needsDetailsFetch`, `unsavedAttachmentsFor`) on `MessageThread` and consolidated single/bulk Google Drive upload flows into `_saveAttachmentsToDrive(..., {required bool isBulk})` in `MessageThreadScreen`, keeping the screen coordinator concise (340 LOC) while preserving 100% behavioral parity.
- Preserved the strict Google Drive URL allowlist (`https://drive.google.com/` and `https://docs.google.com/`) in `_openSavedDriveAttachment` per threat model `T-21-03` and bounded regex quantifiers in `MessageThread.resolveSenderName` per `T-21-04`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `MessageThreadScreen` decomposition is complete (< 350 LOC) and all message attachment and timestamp tests pass. Ready for `21-03-PLAN.md` (`AttendanceScreen` decomposition).

## Self-Check: PASSED
- Verified all created/modified files exist on disk.
- Verified commits `07197f9` and `1d3bf62` exist in git history.
- Verified `message_thread_screen.dart` line count is 340 (< 350 LOC), `flutter analyze` reports 0 issues, and all 23 tests in `message_attachments_test.dart` and `messages_timestamp_test.dart` pass.

---
*Phase: 21-refaktoryzacja-modu-u-wiadomo-ci-i-dekompozycja-messagethrea*
*Completed: 2026-10-03*
