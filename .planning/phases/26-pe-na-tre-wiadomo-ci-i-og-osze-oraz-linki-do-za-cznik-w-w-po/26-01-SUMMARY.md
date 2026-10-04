---
phase: 26-pe-na-tre-wiadomo-ci-i-og-osze-oraz-linki-do-za-cznik-w-w-po
plan: 01
subsystem: api
tags: [telegram, cloud-functions, cheerio, librus, notifications, html-formatting]

requires:
  - phase: 18-powiadomienia-w-czasie-rzeczywistym-telegram-bot-i-web-push
    provides: Telegram Bot API dispatcher and Firestore notifications subcollection
  - phase: 25-archiwizacja-wiadomo-ci-automatyczna-archiwizacja-potwierdze
    provides: Message auto-archive & justification notification detection pipeline
provides:
  - Multiline HTML-to-text extraction for Librus message bodies via _extractMultilineElementText in fetchMessages and fetchMessageDetails
  - Guaranteed pre-notification message body and attachment hydration via buildMessageAndAnnouncementNotifications in sync_service.js
  - Enriched Firestore notification payload fields (content, messageId, attachmentFiles) preserving compact body metadata for in-app alerts
  - Distinct Telegram HTML templates for messages and school announcements with clickable /api/downloadAttachment?path=... links, thread deep links, and safe word/line-boundary truncation within 4096 characters
affects: [telegram_service, sync_service, librus_client, notifications]

actuals:
  tokens: 8494
  tasks: 2
  commits: 2
  plan_head_before: 3858a73e85705ad12e0a08fa2c2ee0933e30e3bf
  plan_head_after: 2282922a089e15aab8f51714dbd78dd72d999c5b

tech-stack:
  added: []
  patterns:
    - "Pre-escape plain-text truncation on word/line boundaries with post-escape length budget enforcement (<= 3500 content / <= 4096 total Telegram HTML)"
    - "Pre-notification message detail hydration ensuring newly detected messages beyond top-10 or missing attachmentFiles call fetchMessageDetails before dispatch"
    - "Dual-field notification schema keeping body compact for in-app alerts/Web Push while storing full multiline text in content"

key-files:
  created:
    - functions/test/telegram_notifications.test.js
  modified:
    - functions/src/librus_client.js
    - functions/src/sync_service.js
    - functions/src/telegram_service.js
    - functions/test/message_body_indexing.test.js

key-decisions:
  - "Preserved compact notif.body ('sender • date' / 'author (date)') for the in-app 'Ostatnie alerty' list and Web Push while attaching full multiline text in notif.content, thread ID in notif.messageId, and attachment metadata in notif.attachmentFiles (D-07)"
  - "Sliced raw unescaped text on word/line boundaries before calling escapeHtml() while measuring escapeHtml(candidate).length against dynamic remaining budget so HTML entities (&amp;, &lt;, &gt;) are never cut mid-token and total HTML never exceeds 4096 characters (D-02)"
  - "Rendered message attachments as clickable HTML links to https://lepsza-szkola.web.app/api/downloadAttachment?path=... instead of uploading binary files via sendDocument (D-04, D-05)"

patterns-established:
  - "truncateTelegramContent(rawText, maxEscapedChars): pre-escape word/line-boundary slicer with HTML-escaped length measurement"
  - "buildMessageAndAnnouncementNotifications({ prevData, freshData, client, timestampValue }): testable async notification builder with on-demand Librus detail hydration"

requirements-completed:
  - REQ-NOTIF-TG-MSG-01
  - REQ-NOTIF-TG-ANN-01
  - REQ-NOTIF-TG-ATT-01

coverage:
  - id: D1
    description: "Multiline message scraping via _extractMultilineElementText and pre-notification fetchMessageDetails hydration for new messages missing body or attachmentFiles"
    requirement: REQ-NOTIF-TG-MSG-01
    verification:
      - kind: unit
        ref: "functions/test/message_body_indexing.test.js#LibrusClient.fetchMessages and fetchMessageDetails preserve multiline line breaks via _extractMultilineElementText"
        status: pass
      - kind: unit
        ref: "functions/test/message_body_indexing.test.js#buildMessageAndAnnouncementNotifications hydrates unindexed new messages and populates content, messageId, and attachmentFiles while keeping body compact"
        status: pass
      - kind: unit
        ref: "functions/test/telegram_notifications.test.js#formatNotificationForTelegram renders message template with full multiline content, attachment download links, and deep link"
        status: pass
    human_judgment: false
  - id: D2
    description: "Distinct school announcement Telegram notification template (📢 Nowe ogłoszenie szkolne) with author, title, and full multiline content"
    requirement: REQ-NOTIF-TG-ANN-01
    verification:
      - kind: unit
        ref: "functions/test/telegram_notifications.test.js#formatNotificationForTelegram renders distinct announcement template with full multiline content"
        status: pass
    human_judgment: false
  - id: D3
    description: "Telegram message attachment section (📎 Załączniki (X):) with clickable /api/downloadAttachment?path=... links and 4096-character truncation guard"
    requirement: REQ-NOTIF-TG-ATT-01
    verification:
      - kind: unit
        ref: "functions/test/telegram_notifications.test.js#formatMessageAttachmentsForTelegram handles null, empty array, single attachment, and string array cleanly"
        status: pass
      - kind: unit
        ref: "functions/test/telegram_notifications.test.js#truncateTelegramContent and formatNotificationForTelegram safely truncate >5000-char content with HTML characters within 4096-char limit"
        status: pass
    human_judgment: false

duration: 24min
completed: 2026-10-04
status: complete
---

# Phase 26 Plan 01: Pełna treść wiadomości i ogłoszeń oraz linki do załączników w powiadomieniach Telegram Summary

**Full multiline Librus message and school announcement Telegram notifications with pre-notification detail hydration, clickable `/api/downloadAttachment` links, `/wiadomosci/:id` thread deep links, and pre-escape word-boundary truncation within Telegram's 4096-character HTML limit**

## Performance

- **Duration:** 24 min
- **Started:** 2026-10-04T12:13:45Z
- **Completed:** 2026-10-04T12:38:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Updated `LibrusClient.fetchMessages` and `LibrusClient.fetchMessageDetails` in `functions/src/librus_client.js` to extract `div.container-message-content` using `_extractMultilineElementText`, preserving `<br>`, paragraph breaks, and bullet lists while keeping list `preview` single-line (`D-03`, `REQ-NOTIF-TG-MSG-01`).
- Updated `mergeAndIndexMessages` and added `buildMessageAndAnnouncementNotifications` in `functions/src/sync_service.js` to copy attachment metadata during incremental indexing and guarantee on-demand `client.fetchMessageDetails` hydration for any newly detected message missing its full body or `attachmentFiles`, storing `content`, `messageId`, and `attachmentFiles` alongside compact `body` metadata (`D-03`, `D-07`).
- Implemented `truncateTelegramContent`, `formatMessageAttachmentsForTelegram`, and separate `message` vs `announcement` HTML templates in `functions/src/telegram_service.js` with clickable `https://lepsza-szkola.web.app/api/downloadAttachment?path=...` links, `/wiadomosci/{msgId}` deep links, and word/line-boundary truncation before `escapeHtml()` (`D-01`, `D-02`, `D-04`, `D-05`, `D-06`, `REQ-NOTIF-TG-ANN-01`, `REQ-NOTIF-TG-ATT-01`).
- Added comprehensive unit tests in `functions/test/telegram_notifications.test.js` and `functions/test/message_body_indexing.test.js` (95/95 backend tests passing).

## Task Commits

Each task was committed atomically:

1. **Task 1: Multiline Message Scraping & Pre-Notification Detail/Attachment Hydration (D-03, D-07)** - `71f0929` (feat)
2. **Task 2: Full-Content & Attachment-Link Telegram HTML Formatter with 4096-Char Truncation & Unit Tests (D-01, D-02, D-04, D-05, D-06)** - `2282922` (feat)

## Files Created/Modified

- `functions/src/librus_client.js` - Replaced `.text().trim()` with `_extractMultilineElementText` for `div.container-message-content` in `fetchMessages` and `fetchMessageDetails`
- `functions/src/sync_service.js` - Added attachment metadata copying in `mergeAndIndexMessages` and extracted `buildMessageAndAnnouncementNotifications` with pre-notification `fetchMessageDetails` hydration
- `functions/src/telegram_service.js` - Added `truncateTelegramContent`, `formatMessageAttachmentsForTelegram`, and distinct `message` / `announcement` branches in `formatNotificationForTelegram`
- `functions/test/message_body_indexing.test.js` - Added unit tests for multiline scraping, incremental attachment hydration, and `buildMessageAndAnnouncementNotifications`
- `functions/test/telegram_notifications.test.js` - Created unit test suite covering message/announcement Telegram formatting, attachment links, HTML entity escaping, and 4096-character truncation

## Decisions Made

- Kept `notif.body` as compact sender/author + date metadata for the in-app "Ostatnie alerty" history tab and Web Push while adding `notif.content`, `notif.messageId`, and `notif.attachmentFiles` for rich Telegram rendering (`D-07`).
- Performed truncation on raw plain text at word/line boundaries before calling `escapeHtml()`, dynamically bounding `escapeHtml(candidate).length` so neither `<`/`>`/`&` expansion nor long attachment lists can push the payload past 4096 characters or split an HTML entity (`D-02`).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 26 plan 26-01 is complete and verified by automated unit tests (`npm --prefix functions test` — 95 passing tests).
- Ready for phase verification or deployment of updated Cloud Functions.

## Self-Check: PASSED

- FOUND: `functions/src/librus_client.js`
- FOUND: `functions/src/sync_service.js`
- FOUND: `functions/src/telegram_service.js`
- FOUND: `functions/test/message_body_indexing.test.js`
- FOUND: `functions/test/telegram_notifications.test.js`
- FOUND: `71f0929`
- FOUND: `2282922`

---
*Phase: 26-pe-na-tre-wiadomo-ci-i-og-osze-oraz-linki-do-za-cznik-w-w-po*
*Completed: 2026-10-04*
