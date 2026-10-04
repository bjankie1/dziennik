---
phase: 26-pe-na-tre-wiadomo-ci-i-og-osze-oraz-linki-do-za-cznik-w-w-po
verified: 2026-10-04T14:48:00+02:00
status: passed
score: 5/5 must-haves verified
---

# Phase 26: Pełna treść wiadomości i ogłoszeń oraz linki do załączników w powiadomieniach Telegram Verification Report

**Phase Goal:** Wzbogacenie powiadomień wysyłanych na Telegram o nowej wiadomości oraz o nowym ogłoszeniu szkolnym tak, aby zawierały pełną, sformatowaną treść wiadomości/ogłoszenia (z zachowaniem podziału na linie i bezpiecznym dzieleniem lub obcinaniem względem limitu 4096 znaków Telegram API) oraz informację o załącznikach wiadomości wraz z bezpośrednimi linkami do ich pobrania.
**Verified:** 2026-10-04T14:48:00+02:00
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Powiadomienia Telegram o nowej wiadomości (`type: 'message'`) oraz o nowym ogłoszeniu (`type: 'announcement'`) zawierają pełną, wieloliniową treść (`content` / `body`) w jednej wiadomości z zachowaniem podziału na linie (`\n`) zgodnie z D-01 (`REQ-NOTIF-TG-MSG-01`, `REQ-NOTIF-TG-ANN-01`) | ✓ VERIFIED | `LibrusClient._extractMultilineElementText` (`functions/src/librus_client.js:309-324`) preserves `\n` for announcements (`line 340`), message list detail loop (`lines 724-727`), and `fetchMessageDetails` (`lines 782-785`). `buildMessageAndAnnouncementNotifications` (`functions/src/sync_service.js:671,728`) populates `content`, and `formatNotificationForTelegram` (`functions/src/telegram_service.js:109-202`) renders multiline `safeContent`. Exercised by unit tests in `functions/test/telegram_notifications.test.js`. |
| 2 | Gdy treść wiadomości lub ogłoszenia przekracza bezpieczny budżet (~3500 znaków po escapowaniu HTML lub dynamiczny limit względem 4096 znaków całego komunikatu), tekst jest obcinany przed escapowaniem HTML na granicy słowa/linii z dopiskiem `… (pełna treść w aplikacji)` przed sekcją załączników i linkiem stopki zgodnie z D-02 | ✓ VERIFIED | `truncateTelegramContent` (`functions/src/telegram_service.js:20-47`) slices raw plain text before `escapeHtml()`, snaps to the last `\n` or space (`>= 60%` of candidate length), and appends `… (pełna treść w aplikacji)`. `formatNotificationForTelegram` (`lines 147-155, 192-199`) computes dynamic `contentBudget` from `4096 - (headerBlock.length + attachmentsBlock.length + footerBlock.length + 4)`. Verified on a ~6800-char body with `<script>`, `&`, `>` and 2 attachments (`functions/test/telegram_notifications.test.js:212-250`). |
| 3 | Dla każdej nowo wykrytej wiadomości (`!prevMsgIds.has(m.id)`), która nie ma jeszcze wczytanej pełnej treści (`m.bodyLoaded !== true`) lub listy załączników (`m.hasAttachments && !m.attachmentFiles?.length`), `sync_service.js` dociąga szczegóły przez `client.fetchMessageDetails(m.id, m.librusUrl)` przed zbudowaniem powiadomienia, a `librus_client.js` używa `_extractMultilineElementText` dla `div.container-message-content` zgodnie z D-03 (`REQ-NOTIF-TG-MSG-01`) | ✓ VERIFIED | `buildMessageAndAnnouncementNotifications` (`functions/src/sync_service.js:685-720`) checks `needsBody` and `needsAttachments` for each new regular message and awaits `client.fetchMessageDetails(m.id, m.librusUrl)` inside a `try/catch` block before constructing notification payloads. `mergeAndIndexMessages` (`lines 588-595`) also copies `attachmentFiles` during incremental indexing. Verified in `functions/test/message_body_indexing.test.js:266-449`. |
| 4 | Wiadomości z załącznikami renderują na Telegramie sekcję `📎 <b>Załączniki (X):</b>` z klikalnymi linkami HTML do `https://lepsza-szkola.web.app/api/downloadAttachment?path=...` (lub samą nazwą przy braku `path`) bez wysyłania binarnych plików przez `sendDocument` zgodnie z D-04 i D-05 (`REQ-NOTIF-TG-ATT-01`) | ✓ VERIFIED | `formatMessageAttachmentsForTelegram` (`functions/src/telegram_service.js:53-91`) formats `attachmentFiles` / `attachments` into `\n📎 <b>Załączniki (X):</b>\n` with `encodeURIComponent(att.path)` links pointing to `https://lepsza-szkola.web.app/api/downloadAttachment?path=...` and plain filename fallback when `path` is empty. Backed by `exports.downloadAttachment` (`functions/index.js:793`) and `/api/downloadAttachment` rewrite (`firebase.json:64`). |
| 5 | `formatNotificationForTelegram` rozdziela szablony wiadomości (`📬 <b>Nowa wiadomość w Librusie</b>` + deep link `/wiadomosci/{msgId}`) oraz ogłoszeń (`📢 <b>Nowe ogłoszenie szkolne</b>` + link `/wiadomosci`) zgodnie z D-06, natomiast w dokumentach Firestore pole `body` pozostaje zwięzłym opisem metadanych dla zakładki „Ostatnie alerty”, a pełna treść i załączniki są przekazywane w polach `content`, `messageId` i `attachmentFiles` zgodnie z D-07 | ✓ VERIFIED | `functions/src/telegram_service.js:109-202` implements distinct `case "message"` (`📬 <b>Nowa wiadomość w Librusie</b>` + `/wiadomosci/${encodeURIComponent(rawMsgId)}`) and `case "announcement"` (`📢 <b>Nowe ogłoszenie szkolne</b>` + `/wiadomosci`) templates. `functions/src/sync_service.js:666-676,722-740` preserves compact `body` (`${sender} • ${date}` / `${author} (${date})`) while storing `content`, `messageId`, and `attachmentFiles`. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `functions/src/librus_client.js` | Multiline message body extraction via `_extractMultilineElementText` in `fetchMessages` and `fetchMessageDetails` | ✓ VERIFIED | Exists, substantive (`1132` lines), wired into `sync_service.js` and `functions/index.js`; uses `this._extractMultilineElementText` at lines `724-727` and `782-785`. |
| `functions/src/sync_service.js` | `buildMessageAndAnnouncementNotifications` helper with pre-notification `fetchMessageDetails` hydration and enriched notification payload fields (`content`, `messageId`, `attachmentFiles`) | ✓ VERIFIED | Exists, substantive (`756` lines), exports `buildMessageAndAnnouncementNotifications` (`line 753`) and invokes it inside `syncStudentData` (`lines 228-234`). |
| `functions/src/telegram_service.js` | `truncateTelegramContent`, `formatMessageAttachmentsForTelegram`, and distinct message vs announcement HTML templates in `formatNotificationForTelegram` | ✓ VERIFIED | Exists, substantive (`461` lines), exports `truncateTelegramContent` and `formatMessageAttachmentsForTelegram` (`lines 452-454`), wired into `dispatchTelegramNotificationsForStudent` (`line 318`). |
| `functions/test/telegram_notifications.test.js` | Unit tests covering multiline scraping, pre-notification hydration, attachment download links, HTML entity escaping, and 4096-character truncation | ✓ VERIFIED | Exists, substantive (`251` lines), 6 comprehensive unit tests passing via `node:test`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `functions/src/librus_client.js` | `functions/src/sync_service.js` | `fetchMessages` and `fetchMessageDetails` returning multiline `body` and `attachmentFiles [{ name, path }]` | ✓ WIRED | `sync_service.js` imports `LibrusClient` (`line 2`), calls `client.fetchAll()` (`line 135`) and `client.fetchMessageDetails(m.id, m.librusUrl)` in `mergeAndIndexMessages` (`line 583`) and `buildMessageAndAnnouncementNotifications` (`line 698`). |
| `functions/src/sync_service.js` | `functions/src/telegram_service.js` | `buildMessageAndAnnouncementNotifications` passing enriched notification objects (`content`, `messageId`, `attachmentFiles`) to `dispatchTelegramNotificationsForStudent` | ✓ WIRED | `sync_service.js` imports `dispatchTelegramNotificationsForStudent` (`line 3`), pushes `msgAndAnnNotifs` into `newNotifications` (`lines 228-234`), and passes `newNotifications` to `dispatchTelegramNotificationsForStudent` (`lines 286-291`), which formats each notification via `formatNotificationForTelegram` (`telegram_service.js:318`). |
| `functions/src/telegram_service.js` | `functions/index.js` (`/api/downloadAttachment`) | Clickable `<a href="https://lepsza-szkola.web.app/api/downloadAttachment?path=...">` links in Telegram HTML | ✓ WIRED | `formatMessageAttachmentsForTelegram` (`telegram_service.js:84`) generates `/api/downloadAttachment?path=${encodeURIComponent(att.path)}` URLs served by `exports.downloadAttachment` (`functions/index.js:793`) via Firebase Hosting rewrite (`firebase.json:64`). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `functions/src/librus_client.js` | `m.body`, `m.attachmentFiles`, `ann.content` | Librus Synergia HTML (`div.container-message-content`, `table.decorated.big`, `_parseMessageAttachments`) | Yes — live Cheerio HTML extraction preserving `<br>`, `<p>`, and attachment download paths | ✓ FLOWING |
| `functions/src/sync_service.js` | `notif.content`, `notif.messageId`, `notif.attachmentFiles`, `notif.body` | `freshData.messages` / `freshData.announcements` + on-demand `client.fetchMessageDetails(m.id, m.librusUrl)` | Yes — persisted to `students/{login}/notifications/{id}` and passed in-memory to `dispatchTelegramNotificationsForStudent` | ✓ FLOWING |
| `functions/src/telegram_service.js` | `htmlText` (`safeContent`, `attachmentsBlock`, `footerBlock`) | `notif` payload fields formatted by `formatNotificationForTelegram` and posted via `sendTelegramMessage` (`axios.post` to Telegram Bot API) | Yes — full multiline HTML with clickable download links and thread deep links | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase 26 unit & integration tests (multiline scraping, detail hydration, Telegram templates, attachment links, 4096-char truncation) | `npm --prefix functions test` | 25 suites, 95 tests, 95 passed, 0 failed (`441ms`) | ✓ PASS |
| Commit integrity check (`71f0929`, `2282922`) | `gsd-tools query verify.commits 71f0929 2282922` | `all_valid: true` (`2/2` commits verified in git history) | ✓ PASS |

### Probe Execution

No phase-specific shell probes (`scripts/*/tests/probe-*.sh`) declared for Phase 26; behavioral verification is covered by `node:test` suites in `functions/test/`.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| `REQ-NOTIF-TG-MSG-01` | `26-01-PLAN.md` | Powiadomienie na Telegramie o nowej wiadomości z Librusa zawiera nadawcę, temat oraz pełną treść wiadomości (`body`), a jeśli pełna treść nie była jeszcze pobrana dla danej nowej wiadomości podczas synchronizacji, backend dociąga szczegóły wiadomości (`fetchMessageDetails`) przed wysłaniem powiadomienia. | ✓ SATISFIED | `librus_client.js:724-727,782-785` (multiline body scraping), `sync_service.js:680-741` (pre-notification `fetchMessageDetails` hydration & `content`/`messageId` fields), `telegram_service.js:109-163` (`📬 Nowa wiadomość w Librusie` template + `/wiadomosci/:id` deep link). |
| `REQ-NOTIF-TG-ANN-01` | `26-01-PLAN.md` | Powiadomienie na Telegramie o nowym ogłoszeniu szkolnym zawiera autora, tytuł oraz pełną, wieloliniową treść ogłoszenia (`content`). | ✓ SATISFIED | `sync_service.js:663-677` (`content: String(a.content \|\| "").trim()`), `telegram_service.js:164-202` (`📢 Nowe ogłoszenie szkolne` template with title, author/date, and multiline `safeContent`). |
| `REQ-NOTIF-TG-ATT-01` | `26-01-PLAN.md` | Jeśli nowa wiadomość posiada załączniki (`attachmentFiles`), powiadomienie na Telegramie wypisuje listę nazw załączników wraz z klikalnymi linkami pozwalającymi na ich pobranie (`/api/downloadAttachment?path=...` na domenie `https://lepsza-szkola.web.app`). | ✓ SATISFIED | `telegram_service.js:53-91` (`formatMessageAttachmentsForTelegram` rendering `📎 <b>Załączniki (X):</b>` and `<a href="https://lepsza-szkola.web.app/api/downloadAttachment?path=...">` links), `sync_service.js:588-595,704-711,732-737`. |

**Orphaned requirements check:** Cross-referenced `.planning/REQUIREMENTS.md` lines 143–145 and 179–181 (`Phase 26`). All 3 requirements mapped to Phase 26 (`REQ-NOTIF-TG-MSG-01`, `REQ-NOTIF-TG-ANN-01`, `REQ-NOTIF-TG-ATT-01`) are claimed in `26-01-PLAN.md` and verified. Zero orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK` markers or stub implementations found in modified files | — | None |

### Human Verification Required

None — all observable truths, HTML formatting templates, attachment URL encodings, pre-notification detail hydration paths, and 4096-character truncation invariants are deterministically verified via automated unit tests (`95/95` passing).

### Gaps Summary

No gaps found. All 5 must-have truths from `26-01-PLAN.md` and all 4 Success Criteria from `ROADMAP.md` (covering `REQ-NOTIF-TG-MSG-01`, `REQ-NOTIF-TG-ANN-01`, `REQ-NOTIF-TG-ATT-01`, and decisions `D-01` through `D-07`) are implemented, wired end-to-end across `librus_client.js`, `sync_service.js`, and `telegram_service.js`, and verified by automated tests.

---

_Verified: 2026-10-04T14:48:00+02:00_
_Verifier: the agent (gsd-verifier)_
