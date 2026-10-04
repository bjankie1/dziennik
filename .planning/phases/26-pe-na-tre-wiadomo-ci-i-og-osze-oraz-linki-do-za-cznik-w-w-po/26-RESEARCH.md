# Phase 26: Pełna treść wiadomości i ogłoszeń oraz linki do załączników w powiadomieniach Telegram - Research

**Researched:** 2026-10-04
**Domain:** Cloud Functions (Node.js 20) — Librus Synergia HTML Scraping (`cheerio`), Sync Pipeline (`sync_service.js`), and Telegram Bot API HTML Notifications (`telegram_service.js`)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
#### Pełna treść i zachowanie przy bardzo długich wiadomościach/ogłoszeniach
- **D-01:** Powiadomienie na Telegramie o nowej wiadomości (`type: "message"`) oraz o nowym ogłoszeniu (`type: "announcement"`) wysyła pełną, wieloliniową treść (`content` / `body`) w jednej wiadomości Telegram z zachowaniem podziału na linie (`\n`).
- **D-02:** Jeśli treść wiadomości lub ogłoszenia przekracza bezpieczny budżet długości (~3500 znaków, tak aby cały komunikat HTML razem z nagłówkiem, załącznikami i linkiem stopki zmieścił się w limicie 4096 znaków Telegram Bot API), treść jest obcinana na granicy słowa/linii z dopiskiem `… (pełna treść w aplikacji)` przed sekcją załączników i linkiem dolnym.
- **D-03:** Dla każdej nowo wykrytej wiadomości (`!prevMsgIds.has(m.id)`), która nie ma jeszcze wczytanej pełnej treści (`m.bodyLoaded !== true`) lub metadanych załączników, `sync_service.js` gwarantuje pobranie szczegółów wiadomości (`client.fetchMessageDetails(m.id, m.librusUrl)`) przed zbudowaniem obiektów `newNotifications`. Również ekstrakcja treści wiadomości w `librus_client.js` (`div.container-message-content`) powinna korzystać z `_extractMultilineElementText`, aby zachować znaczniki `<br>` i podziały wierszy.

#### Prezentacja załączników na Telegramie
- **D-04:** Jeśli wiadomość posiada załączniki (`attachmentFiles: [{ name, path }]` lub `attachments: [name]`), pod treścią wiadomości w powiadomieniu Telegram dodawana jest sekcja:
  `📎 <b>Załączniki (X):</b>`
  a każdy załącznik posiadający ścieżkę `path` jest renderowany jako klikalny link HTML:
  `• <a href="https://lepsza-szkola.web.app/api/downloadAttachment?path=${encodeURIComponent(att.path)}">${escapeHtml(att.name)}</a>`
  (jeśli załącznik ma tylko nazwę bez ścieżki `path`, wyświetlana jest sama nazwa `• ${escapeHtml(att.name)}`).
- **D-05:** Nie wysyłamy osobnych plików binarnych przez `sendDocument` — klikalne linki prowadzące do endpointu `/api/downloadAttachment` w wiadomości tekstowej są wystarczające i nie obciążają czasu wykonania Cloud Function.

#### Układ powiadomień (Wiadomość vs Ogłoszenie, deep link i „Ostatnie alerty”)
- **D-06:** Rozdzielamy wizualnie szablony w `formatNotificationForTelegram`:
  - Dla `type: "message"`: nagłówek `📬 <b>Nowa wiadomość w Librusie</b> (${safeStudent})`, temat, nadawca/data, pełna treść wiadomości, opcjonalna sekcja `📎 <b>Załączniki (X):</b>` z linkami oraz bezpośredni deep link do wątku: `🔗 <a href="https://lepsza-szkola.web.app/wiadomosci/${encodeURIComponent(msgId)}">Otwórz wiadomość w EduSync</a>` (lub `/wiadomosci`, jeśli `messageId` nie jest dostępny).
  - Dla `type: "announcement"`: nagłówek `📢 <b>Nowe ogłoszenie szkolne</b> (${safeStudent})`, tytuł ogłoszenia, autor/data, pełna wieloliniowa treść ogłoszenia oraz link `🔗 <a href="https://lepsza-szkola.web.app/wiadomosci">Otwórz ogłoszenia w EduSync</a>`.
- **D-07:** W obiekcie powiadomienia zapisywanym w Firestore (`students/{id}/notifications/{notifId}`):
  - Pole `body` pozostaje zwięzłym opisem metadanych (np. `${m.sender} • ${m.date}` lub `${a.author} (${a.date})`) na potrzeby kompaktowej listy w zakładce „Ostatnie alerty” w oknie Ustawień powiadomień.
  - Dodatkowe pola `content` (pełna treść wiadomości/ogłoszenia), `messageId` (ID wiadomości do deep linku) oraz `attachmentFiles` (lista `{ name, path }`) są dołączane do obiektu powiadomienia i wykorzystywane przez `formatNotificationForTelegram`.

### the agent's Discretion
- Dokładny próg znaków obcięcia treści (np. 3400–3500 znaków po escapowaniu HTML), aby cały payload `htmlText` nigdy nie przekroczył 4096 znaków narzuconych przez Telegram Bot API.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REQ-NOTIF-TG-MSG-01 | Powiadomienie na Telegramie o nowej wiadomości z Librusa zawiera nadawcę, temat oraz pełną treść wiadomości (`body`), a jeśli pełna treść nie była jeszcze pobrana dla danej nowej wiadomości podczas synchronizacji, backend dociąga szczegóły wiadomości (`fetchMessageDetails`) przed wysłaniem powiadomienia. | Supported by updating `LibrusClient.fetchMessages` and `LibrusClient.fetchMessageDetails` (`functions/src/librus_client.js:724,779`) to use `this._extractMultilineElementText($, ...)` on `div.container-message-content`, guaranteeing `fetchMessageDetails` hydration for newly detected messages in `functions/src/sync_service.js`, attaching `content` and `messageId` to notification payloads, and rendering full multiline body + thread deep link in `formatNotificationForTelegram` (`functions/src/telegram_service.js`). |
| REQ-NOTIF-TG-ANN-01 | Powiadomienie na Telegramie o nowym ogłoszeniu szkolnym zawiera autora, tytuł oraz pełną, wieloliniową treść ogłoszenia (`content`). | Supported by preserving `content: a.content || ""` on announcement notification payloads in `functions/src/sync_service.js:229-240` and separating `case "announcement":` from `case "message":` in `formatNotificationForTelegram` (`functions/src/telegram_service.js:27-34`) with header `📢 <b>Nowe ogłoszenie szkolne</b> (${safeStudent})` and multiline `content`. |
| REQ-NOTIF-TG-ATT-01 | Jeśli nowa wiadomość posiada załączniki (`attachmentFiles`), powiadomienie na Telegramie wypisuje listę nazw załączników wraz z klikalnymi linkami pozwalającymi na ich pobranie (np. przez endpoint `/api/downloadAttachment?path=...` na domenie aplikacji `https://lepsza-szkola.web.app`). | Supported by propagating `attachmentFiles` (`[{ name, path }]`) and `attachments` (`[name]`) when hydrating details in `sync_service.js` and onto `newNotifications`, then rendering `📎 <b>Załączniki (X):</b>` with `<a href="https://lepsza-szkola.web.app/api/downloadAttachment?path=...">` links in `formatNotificationForTelegram`. |
</phase_requirements>

## Summary

Phase 26 is a pure backend enhancement inside `functions/src/` (`librus_client.js`, `sync_service.js`, `telegram_service.js`) and its unit test suite in `functions/test/`. No Flutter UI changes or new npm dependencies are required because the frontend `SchoolNotificationItem.fromFirestore` (`lib/domain/models/notification_settings.dart:148-168`) and `NotificationAlertsHistoryTab` (`lib/presentation/widgets/modals/notification_settings/notification_alerts_history_tab.dart:165-174`) read only `title` and compact `body`, ignoring extra document fields (`content`, `messageId`, `attachmentFiles`).

Three concrete gaps exist in the current implementation:
1. **Multiline loss in message scraping:** While `LibrusClient.fetchAnnouncements` already uses `this._extractMultilineElementText($, $(rows[2]).find("td").first())` (`[VERIFIED: functions/src/librus_client.js:340]`), `fetchMessages` and `fetchMessageDetails` still use `$$("div.container-message-content").text().trim()` (`[VERIFIED: functions/src/librus_client.js:724]` and `[VERIFIED: functions/src/librus_client.js:779]`), which collapses `<br>` and `</p>` tags into a single line if no literal newline exists in raw HTML.
2. **Missing detail/attachment hydration on new messages & notification creation:** In `functions/src/sync_service.js:604-610`, `mergeAndIndexMessages` copies `details.body` when calling `client.fetchMessageDetails(m.id, m.librusUrl)`, but does not copy `details.attachmentFiles`, `details.attachments`, or `details.hasAttachments`. Furthermore, if more than 10 new messages arrive at once or a new message had `m.bodyLoaded !== true` after `fetchMessages`, `syncStudentData` (`functions/src/sync_service.js:227-255`) builds `newNotifications` with only `title` and `body: "${m.sender} • ${m.date}"`, omitting `content`, `messageId`, and `attachmentFiles`.
3. **Minimal Telegram template without content, attachments, or length guard:** `formatNotificationForTelegram` (`[VERIFIED: functions/src/telegram_service.js:27-34]`) merges `case "message":` and `case "announcement":` into a single 4-line stub showing only `safeTitle` and `safeBody`, with no full text, no attachment links, no `/wiadomosci/${msgId}` deep link, and no truncation logic to protect against Telegram Bot API's 4096-character HTML message limit.

**Primary recommendation:** Implement Phase 26 as a single cohesive backend plan modifying `functions/src/librus_client.js`, `functions/src/sync_service.js`, and `functions/src/telegram_service.js`, accompanied by comprehensive `node:test` unit tests verifying multiline extraction, pre-notification `fetchMessageDetails` hydration, attachment download links, HTML entity escaping, and 4096-character truncation.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Multiline HTML-to-text extraction for Librus messages (`div.container-message-content`) | API / Backend (`functions/src/librus_client.js`) | — | Scraping and Cheerio DOM normalization happen exclusively in `LibrusClient` during sync and on-demand detail fetches. |
| Ensuring full body & attachment metadata are loaded for newly detected messages before notification dispatch | API / Backend (`functions/src/sync_service.js`) | Database / Storage (Firestore `students/{id}`) | `syncStudentData` detects state diffs (`!prevMsgIds.has(m.id)`, `!prevAnnIds.has(a.id)`) and persists both the student cache and `notifications` subcollection. |
| Telegram HTML formatting, attachment link generation (`/api/downloadAttachment`), and 4096-character truncation | API / Backend (`functions/src/telegram_service.js`) | — | `formatNotificationForTelegram` owns the presentation contract for Telegram Bot API (`parse_mode: "HTML"`). |
| Compact in-app alerts history ("Ostatnie alerty") & Web Push | Browser / Client (`lib/presentation/...`) | Database / Storage (Firestore `notifications`) | Continues consuming compact `title` and `body` fields unchanged per D-07. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `node` (Runtime) | `20` (`v25.8.0` local) | Cloud Functions v2 execution runtime | Declared in `functions/package.json:12-14`: `"engines": { "node": "20" }` `[VERIFIED: functions/package.json:12-14]`. |
| `cheerio` | `^1.0.0` | Parsing Librus Synergia HTML & multiline text extraction | Already installed in `functions/package.json:22`: `"cheerio": "^1.0.0"` `[VERIFIED: functions/package.json:22]` and `[VERIFIED: npm registry]`. |
| `axios` | `^1.7.9` | HTTP client for Librus scraping and Telegram Bot API `sendMessage` | Already installed in `functions/package.json:19`: `"axios": "^1.7.9"` `[VERIFIED: functions/package.json:19]` and `[VERIFIED: npm registry]`. |
| `firebase-admin` | `^12.0.0` | Firestore persistence for `students/{id}` and `notifications` subcollection | Already installed in `functions/package.json:17`: `"firebase-admin": "^12.0.0"` `[VERIFIED: functions/package.json:17]`. |
| `node:test` + `node:assert/strict` | Built-in | Backend unit test runner (`npm test` -> `node --test`) | Standard test runner configured in `functions/package.json:5`: `"test": "node --test"` `[VERIFIED: functions/package.json:5]`. |

### Supporting
No new external packages are needed for Phase 26. All URL encoding (`encodeURIComponent`), HTML escaping (`escapeHtml`), and string truncation use built-in JavaScript primitives.

**Installation:**
```bash
# No new packages required; existing dependencies in functions/package.json are sufficient.
```

## Package Legitimacy Audit

> No new packages are added in Phase 26. Existing packages in `functions/package.json` were audited via `gsd-tools query package-legitimacy check --ecosystem npm`:

| Package | Registry | Published | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----------|-----------|-------------|---------|-------------|
| `axios` | npm | 2026-08-26 | 139M/wk | `github.com/axios/axios` | `[OK]` | Existing dependency — approved `[VERIFIED: npm registry]` |
| `cheerio` | npm | 2026-01-23 | 33.1M/wk | `github.com/cheeriojs/cheerio` | `[OK]` | Existing dependency — approved `[VERIFIED: npm registry]` |
| `firebase-admin` | npm | 2026-09-23 | 11.0M/wk | `github.com/firebase/firebase-admin-node` | `[OK]` (official Google Firebase SDK; recent release date triggered automated `too-new` heuristic) | Existing dependency — no new install |
| `firebase-functions` | npm | 2026-09-15 | 3.2M/wk | `github.com/firebase/firebase-functions` | `[OK]` (official Google Firebase SDK; recent release date triggered automated `too-new` heuristic) | Existing dependency — no new install |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none (no new packages installed in this phase)

## Architecture Patterns

### System Architecture Diagram

```
[Librus Synergia HTML]
   ├── /ogloszenia ──────────────────────► LibrusClient.fetchAnnouncements()
   │                                          └── _extractMultilineElementText() ──► a.content (multiline)
   └── /wiadomosci/1/5 & /wiadomosci/... ─► LibrusClient.fetchMessages() / fetchMessageDetails()
                                              ├── _extractMultilineElementText() ──► m.body (multiline)
                                              └── _parseMessageAttachments() ──────► m.attachmentFiles [{name, path}]
                                                              │
                                                              ▼
                                           sync_service.js: mergeAndIndexMessages()
                                           + hydrateNewMessagesForNotifications()
                                              │
                                              ├─► Checks new messages (!prevMsgIds.has(m.id))
                                              ├─► If !m.bodyLoaded or missing attachmentFiles:
                                              │     calls client.fetchMessageDetails(m.id, m.librusUrl)
                                              ▼
                                           Builds newNotifications[] (D-07):
                                              ├── type: "announcement" -> { title, body: "author (date)", content: a.content }
                                              └── type: "message"      -> { title, body: "sender • date", content: m.body,
                                                                            messageId: m.id, attachmentFiles: m.attachmentFiles }
                                              │
                                              ├──────────────────────────────┐
                                              ▼                              ▼
                           Firestore: students/{id}/notifications    telegram_service.js:
                           (Used by UI "Ostatnie alerty" &           formatNotificationForTelegram(notif, studentName)
                            Web Push via compact `body`)                │
                                                                        ├─► Builds Header + Title + Meta (`body`)
                                                                        ├─► Builds Attachments HTML (`📎 Załączniki (X)`)
                                                                        │     with /api/downloadAttachment?path=...
                                                                        ├─► Builds Footer Deep Link (`/wiadomosci/${msgId}`)
                                                                        ├─► Truncates `rawContent` on word/line boundary
                                                                        │     BEFORE escapeHtml() so total HTML <= 4096 chars
                                                                        ▼
                                                                     Telegram Bot API: sendMessage (parse_mode: "HTML")
```

### Recommended Project Structure
```
functions/
├── src/
│   ├── librus_client.js       # Update fetchMessages & fetchMessageDetails to use _extractMultilineElementText
│   ├── sync_service.js        # Hydrate missing details/attachments for new messages & enrich newNotifications
│   └── telegram_service.js    # Separate message/announcement templates, render attachments & deep links, safe truncation
└── test/
    ├── justification_notifications.test.js  # Existing tests (keep green)
    ├── message_body_indexing.test.js        # Existing tests (keep green)
    └── telegram_notifications.test.js       # New comprehensive unit tests for REQ-NOTIF-TG-MSG-01, ANN-01, ATT-01
```

### Pattern 1: Multiline Extraction in `LibrusClient.fetchMessages` and `LibrusClient.fetchMessageDetails` (D-03)
**What:** Reuse `this._extractMultilineElementText($, element)` (`[VERIFIED: functions/src/librus_client.js:309-324]`) when extracting `div.container-message-content` in both `fetchMessages()` (`functions/src/librus_client.js:724`) and `fetchMessageDetails()` (`functions/src/librus_client.js:779`).
**When to use:** Whenever scraping message bodies from Librus Synergia HTML.
**Current in-repo code (`[VERIFIED: functions/src/librus_client.js:722-729]` and `[VERIFIED: functions/src/librus_client.js:777-781]`):**
```javascript
// Verbatim from functions/src/librus_client.js:722-729
          const detailRes = await this.client.get(m.librusUrl);
          const $$ = cheerio.load(detailRes.data);
          const bodyText = $$("div.container-message-content").text().trim();
          if (bodyText) {
            m.body = bodyText;
            m.preview = bodyText.replace(/\s+/g, " ").substring(0, 90);
          }

// Verbatim from functions/src/librus_client.js:777-781
    const detailRes = await this.client.get(targetUrl);
    const $ = cheerio.load(detailRes.data);
    const bodyText = $("div.container-message-content").text().trim();
    const attachmentFiles = this._parseMessageAttachments($);
```
**Recommended replacement:**
```javascript
// In fetchMessages() (functions/src/librus_client.js:724):
const contentEl = $$("div.container-message-content").first();
const bodyText = contentEl.length
  ? this._extractMultilineElementText($$, contentEl)
  : "";

// In fetchMessageDetails() (functions/src/librus_client.js:779):
const contentEl = $("div.container-message-content").first();
const bodyText = contentEl.length
  ? this._extractMultilineElementText($, contentEl)
  : "";
```

### Pattern 2: Pre-Notification Message Detail Hydration & Enriched Notification Payloads (D-03, D-07)
**What:**
1. In `mergeAndIndexMessages` (`[VERIFIED: functions/src/sync_service.js:604-610]`), when `client.fetchMessageDetails(m.id, m.librusUrl)` succeeds, also copy `details.attachmentFiles`, `details.attachments`, and `details.hasAttachments` onto `m`.
2. Extract a pure/testable async helper `buildMessageAndAnnouncementNotifications({ prevData, freshData, client, timestampValue })` (or `ensureNewMessagesHydrated` + notification builder) called by `syncStudentData`:
   - For each new regular message (`!prevMsgIds.has(String(m.id)) && !isJustificationApprovalMessage(m)`), check if the full body or attachment list is missing:
     `const needsBody = m.bodyLoaded !== true && (!m.body || m.body.trim() === (m.subject || "").trim());`
     `const needsAttachments = Boolean(m.hasAttachments) && (!Array.isArray(m.attachmentFiles) || m.attachmentFiles.length === 0);`
     If `(needsBody || needsAttachments) && client && typeof client.fetchMessageDetails === "function"`, call `await client.fetchMessageDetails(m.id, m.librusUrl)` and update `m` in place (`m.body`, `m.preview`, `m.bodyLoaded = true`, `m.attachmentFiles`, `m.attachments`, `m.hasAttachments`).
   - Construct the `announcement` and `message` notification objects with `content`, `messageId`, `attachmentFiles`, and `attachments` while keeping `body` concise for the in-app "Ostatnie alerty" list (`[VERIFIED: functions/src/sync_service.js:228-255]`).

**Current in-repo code (`[VERIFIED: functions/src/sync_service.js:227-255]`):**
```javascript
// Verbatim from functions/src/sync_service.js:227-255
    // Detect new announcements
    const prevAnnIds = new Set((prevData.announcements || []).map(a => a.id));
    (freshData.announcements || []).forEach(a => {
      if (!prevAnnIds.has(a.id)) {
        newNotifications.push({
          id: `ann_${String(a.id).replace(/[^a-zA-Z0-9_-]/g, "_")}`,
          type: "announcement",
          title: `Nowe ogłoszenie: ${a.title}`,
          body: `${a.author} (${a.date})`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false
        });
      }
    });

    // Detect new regular messages (excluding auto-archived justification confirmations, which become 'justification' notifications)
    const prevMsgIds = new Set((prevData.messages || []).map(m => m.id));
    (freshData.messages || []).forEach(m => {
      if (!prevMsgIds.has(m.id) && !isJustificationApprovalMessage(m)) {
        newNotifications.push({
          id: `msg_${String(m.id).replace(/[^a-zA-Z0-9_-]/g, "_")}`,
          type: "message",
          title: `Nowa wiadomość: ${m.subject}`,
          body: `${m.sender} • ${m.date}`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false
        });
      }
    });
```

### Pattern 3: Pre-Escape Plain-Text Truncation & Attachment Link Formatting in `telegram_service.js` (D-01, D-02, D-04, D-06)
**What:**
Telegram Bot API rejects `sendMessage` requests if `text.length > 4096` OR if an HTML entity/tag is broken mid-string. Therefore:
1. Build the fixed HTML sections first:
   - Header + Title + Metadata (`👤 ...`)
   - Optional Attachments block (`📎 <b>Załączniki (X):</b>\n• <a href="https://lepsza-szkola.web.app/api/downloadAttachment?path=...">...</a>`)
   - Footer Deep Link (`🔗 <a href="https://lepsza-szkola.web.app/wiadomosci/${encodeURIComponent(msgId)}">Otwórz wiadomość w EduSync</a>` or `/wiadomosci` for announcements)
2. Compute the dynamic character budget for the escaped body content:
   - Default content cap: `3500` characters (per D-02).
   - Hard ceiling guard: `const availableBudget = Math.min(maxContentChars, 4096 - fixedHtmlLength - 16)`.
3. Truncate `rawContent` **before** calling `escapeHtml`:
   - If `escapeHtml(rawContent).length <= availableBudget`, use `escapeHtml(rawContent)`.
   - Otherwise, reserve room for `const truncationSuffix = "… (pełna treść w aplikacji)"`, slice `rawContent` so `escapeHtml(slice).length <= availableBudget - truncationSuffix.length`, snap backward to the last newline `\n` or space `" "` (if at least 60% into the slice), trim trailing whitespace, escape via `escapeHtml(slice)`, and append `truncationSuffix`.

### Anti-Patterns to Avoid
- **Slicing after `escapeHtml(str)`:** Slicing an already HTML-escaped string at an arbitrary index can cut `&amp;`, `&lt;`, or `&gt;` in half (e.g., `&am`), or cut inside `<a href="...">`, causing malformed HTML or broken entities on Telegram. Always slice raw text and measure `escapeHtml(candidate).length`.
- **Treating `prevMessages: []` in `mergeAndIndexMessages` as "fetch all unindexed messages unconditionally":** Existing unit test `mergeAndIndexMessages incrementally fetches up to maxIncrementalFetch unindexed messages within maxIndexDepth` (`[VERIFIED: functions/test/message_body_indexing.test.js:55-107]`) passes `prevMessages: []` with 16 messages and asserts `assert.deepEqual(fetchedIds, ["11", "12", "13", "14"])`. Do not alter the `maxIncrementalFetch` cap inside `mergeAndIndexMessages`; instead, hydrate newly detected messages in the notification detection step (when `prevData` exists and `!prevMsgIds.has(m.id)`).
- **Overwriting `notif.body` in Firestore with the 3500-char message body:** `NotificationAlertsHistoryTab` (`[VERIFIED: lib/presentation/widgets/modals/notification_settings/notification_alerts_history_tab.dart:165-174]`) and Web Push (`[VERIFIED: lib/presentation/screens/main_navigation_screen.dart:114-119]`) render `item.body` directly without truncation. Per D-07, keep `notif.body` as `${m.sender} • ${m.date}` / `${a.author} (${a.date})` and store the full text in `notif.content`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTML `<br>` / `<p>` / bullet normalization in Librus messages | A second custom regex parser in `fetchMessages` / `fetchMessageDetails` | `LibrusClient.prototype._extractMultilineElementText($, element)` (`[VERIFIED: functions/src/librus_client.js:309-324]`) | Already battle-tested for announcements (Quick task `261004-d04`), handles `<br>`, block closing tags, HTML entities, bullets (`•`), numbered lists, and consecutive blank lines. |
| Telegram attachment file proxy | Uploading binary buffers to Telegram `sendDocument` during sync | Direct HTML link to existing `/api/downloadAttachment?path=...` (`[VERIFIED: functions/index.js:793-841]` & `[VERIFIED: firebase.json:63-69]`) | Per D-04 & D-05, avoids downloading binary files during scheduled sync runs and reuses the existing 302 redirect endpoint on `https://lepsza-szkola.web.app`. |

**Key insight:** Every building block for multiline extraction and attachment downloading already exists in `functions/src/librus_client.js` and `functions/index.js`; Phase 26 connects those assets end-to-end into the notification pipeline and Telegram formatter.

## Common Pitfalls

### Pitfall 1: Breaking Existing `mergeAndIndexMessages` Cap Tests
**What goes wrong:** Modifying `mergeAndIndexMessages` to ignore `maxIncrementalFetch` whenever `!prevById.has(m.id)` causes `functions/test/message_body_indexing.test.js` (`lines 55-107`) to fail because that test passes `prevMessages: []` and expects only 4 messages (`11..14`) to be fetched.
**Why it happens:** When `prevMessages` is empty, `prevById` is empty, making every message look "new".
**How to avoid:** Keep `mergeAndIndexMessages` respecting `maxIncrementalFetch` (only adding attachment property copying from `details`), and perform the guaranteed pre-notification hydration for new messages (`!prevMsgIds.has(String(m.id))`) in `buildMessageAndAnnouncementNotifications` (which only runs when `prevData` exists).
**Warning signs:** Running `cd functions && npm test` fails on `mergeAndIndexMessages incrementally fetches up to maxIncrementalFetch unindexed messages within maxIndexDepth`.

### Pitfall 2: HTML Entity Expansion Pushing Message Over 4096 Characters
**What goes wrong:** A message of 3500 raw characters containing many `<`, `>`, or `&` characters expands past 4096 characters after `escapeHtml()`, causing Telegram Bot API to return `400 Bad Request: message is too long`.
**Why it happens:** `&` becomes `&amp;` (5x length) and `<` becomes `&lt;` (4x length).
**How to avoid:** Measure `escapeHtml(candidate).length` against the remaining character budget (capped at both `3500` for content and `4096 - fixedSectionsLength` for the whole message).
**Warning signs:** `formatNotificationForTelegram` returns a string with `.length > 4096` when given input rich in `<`, `>`, `&` plus multiple attachments.

### Pitfall 3: Double-Prefixing Titles or Missing Fallback Fields in `formatNotificationForTelegram`
**What goes wrong:** Callers may pass a Firestore notification object (`{ type: "message", title: "Nowa wiadomość: Zebranie", body: "Jan Kowalski • 2026-10-04", content: "Pełna treść..." }`) OR a raw message-like object in unit tests (`{ type: "message", subject: "Zebranie", sender: "Jan Kowalski", date: "2026-10-04", body: "Pełna treść..." }`).
**Why it happens:** `sync_service.js` constructs Firestore notification objects with `title`, `body` (metadata), and `content` (full text), whereas direct callers/tests might pass `subject`/`sender`/`body` or `author`/`title`/`content`.
**How to avoid:** In `formatNotificationForTelegram`, normalize both shapes cleanly:
- If `notif.content` is non-empty, treat `notif.body` (or `sender`/`author` + `date`) as the metadata line and `notif.content` as the full message/announcement text.
- If `notif.content` is absent and `notif.sender` or `notif.author` is provided alongside `notif.body`, treat `sender`/`author` (+ `date`) as the metadata line and `notif.body` as the full text.
- If only `notif.body` is provided (legacy shape without `content` or `sender`), render `notif.body` cleanly without duplicating it.

## Code Examples

Verified patterns from the repository:

### 1. Current `formatNotificationForTelegram` and `escapeHtml` (`[VERIFIED: functions/src/telegram_service.js:4-35]`)
```javascript
// Verbatim quote from functions/src/telegram_service.js:4-35
function escapeHtml(str = "") {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

/**
 * Formats an EduSync notification event into a rich HTML Telegram message.
 */
function formatNotificationForTelegram(notif, studentName = "Oskar") {
  const safeTitle = escapeHtml(notif.title || "Powiadomienie ze szkoły");
  const safeBody = escapeHtml(notif.body || "");
  const safeStudent = escapeHtml(studentName);

  switch (notif.type) {
    case "grade":
      return (
        `🎓 <b>Nowa ocena w dzienniku!</b> (${safeStudent})\n\n` +
        `📌 <b>${safeTitle}</b>\n` +
        (safeBody ? `📝 ${safeBody}\n` : "") +
        `\n🔗 <a href="https://lepsza-szkola.web.app/oceny">Otwórz Oceny w EduSync</a>`
      );
    case "message":
    case "announcement":
      return (
        `📬 <b>Nowa wiadomość w Librusie</b> (${safeStudent})\n\n` +
        `📌 <b>${safeTitle}</b>\n` +
        (safeBody ? `👤 ${safeBody}\n` : "") +
        `\n🔗 <a href="https://lepsza-szkola.web.app/wiadomosci">Otwórz Wiadomości w EduSync</a>`
      );
```

### 2. Recommended `truncateTelegramContent` and Attachment Link Formatter for `functions/src/telegram_service.js`
```javascript
const TELEGRAM_MAX_MESSAGE_LENGTH = 4096;
const TELEGRAM_DEFAULT_CONTENT_BUDGET = 3500;
const TELEGRAM_TRUNCATION_SUFFIX = "… (pełna treść w aplikacji)";

function truncateTelegramContent(rawText = "", maxEscapedChars = TELEGRAM_DEFAULT_CONTENT_BUDGET) {
  const normalized = String(rawText || "")
    .replace(/\r\n?/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
  if (!normalized) return "";

  const fullEscaped = escapeHtml(normalized);
  if (fullEscaped.length <= maxEscapedChars) {
    return fullEscaped;
  }

  const suffix = TELEGRAM_TRUNCATION_SUFFIX;
  const targetEscapedLen = Math.max(80, maxEscapedChars - suffix.length - 1);

  let sliceLen = Math.min(normalized.length, targetEscapedLen);
  let candidate = normalized.slice(0, sliceLen);

  while (escapeHtml(candidate).length > targetEscapedLen && candidate.length > 1) {
    const excess = escapeHtml(candidate).length - targetEscapedLen;
    candidate = candidate.slice(0, Math.max(1, candidate.length - Math.max(1, excess)));
  }

  // Snap to last newline or space boundary if within the last 40% of the candidate
  const minBreakPos = Math.floor(candidate.length * 0.6);
  const lastNewline = candidate.lastIndexOf("\n");
  const lastSpace = candidate.lastIndexOf(" ");
  const breakIdx = Math.max(lastNewline, lastSpace);
  if (breakIdx >= minBreakPos) {
    candidate = candidate.slice(0, breakIdx);
  }

  return `${escapeHtml(candidate.trimEnd())}${suffix}`;
}

function formatMessageAttachmentsForTelegram(notif) {
  const rawFiles = Array.isArray(notif?.attachmentFiles) && notif.attachmentFiles.length > 0
    ? notif.attachmentFiles
    : Array.isArray(notif?.attachments)
      ? notif.attachments
      : [];

  const normalized = rawFiles
    .map((item) => {
      if (!item) return null;
      if (typeof item === "string") {
        const name = item.trim();
        return name ? { name, path: "" } : null;
      }
      if (typeof item === "object") {
        const name = String(item.name || item.fileName || "Załącznik").trim();
        const path = String(item.path || item.downloadPath || "").trim();
        return name || path ? { name: name || "Załącznik", path } : null;
      }
      return null;
    })
    .filter(Boolean);

  if (normalized.length === 0) return "";

  const lines = normalized.map((att) => {
    const safeName = escapeHtml(att.name);
    if (att.path) {
      const href = /^https?:\/\//i.test(att.path)
        ? att.path
        : `https://lepsza-szkola.web.app/api/downloadAttachment?path=${encodeURIComponent(att.path)}`;
      return `• <a href="${href}">${safeName}</a>`;
    }
    return `• ${safeName}`;
  });

  return `\n📎 <b>Załączniki (${normalized.length}):</b>\n${lines.join("\n")}\n`;
}
```

### 3. Existing `_extractMultilineElementText` and `_parseMessageAttachments` in `functions/src/librus_client.js` (`[VERIFIED: functions/src/librus_client.js:309-324]` and `[VERIFIED: functions/src/librus_client.js:746-772]`)
```javascript
// Verbatim quote from functions/src/librus_client.js:309-324
  _extractMultilineElementText($, element) {
    const rawHtml = $(element).html() || "";
    const normalizedHtml = rawHtml
      .replace(/<br\s*\/?>\s*\r?\n?/gi, "\n")
      .replace(/<\/(p|div|li|tr|h[1-6])>\s*\r?\n?/gi, "\n");
    const decoded = cheerio.load(`<div>${normalizedHtml}</div>`)("div").text();
    return decoded
      .replace(/\r\n?/g, "\n")
      .replace(/([^\n])\s*([•▪◦])\s+/g, "$1\n$2 ")
      .replace(/([."”!)])\s+(\d+\.\s+[A-ZĄĆĘŁŃÓŚŹŻ])/g, "$1\n\n$2")
      .split("\n")
      .map(line => line.replace(/[^\S\n]+/g, " ").trim())
      .join("\n")
      .replace(/\n{3,}/g, "\n\n")
      .trim();
  }

// Verbatim quote from functions/src/librus_client.js:746-772
  _parseMessageAttachments($) {
    const attachmentFiles = [];
    const seenPaths = new Set();

    $("img[onclick*='pobierz_zalacznik'], a[onclick*='pobierz_zalacznik'], a[href*='pobierz_zalacznik']").each((idx, el) => {
      const rawAttr = ($(el).attr("onclick") || $(el).attr("href") || "").replace(/\\\//g, "/");
      const pathMatch = rawAttr.match(/(\/wiadomosci\/pobierz_zalacznik\/\d+\/\d+)/);
      if (!pathMatch) return;

      const downloadPath = pathMatch[1];
      if (seenPaths.has(downloadPath)) return;
      seenPaths.add(downloadPath);

      const tr = $(el).closest("tr");
      let fileName = tr.find("td").first().text().trim().replace(/\s+/g, " ");
      if (!fileName || fileName.toLowerCase() === "pliki:") {
        fileName = `Zalacznik_${idx + 1}`;
      }

      attachmentFiles.push({
        name: fileName,
        path: downloadPath
      });
    });

    return attachmentFiles;
  }
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `$$("div.container-message-content").text().trim()` collapsing `<br>` line breaks in messages | `this._extractMultilineElementText($$, contentEl)` preserving `<br>`, block tags, and bullet lists | Phase 26 (extending Quick task `261004-d04`) | Messages and announcements retain readable paragraphs and lists in Firestore and Telegram. |
| Stub 4-line Telegram alert (`Nowa wiadomość w Librusie` + sender/date only, shared with announcements) | Distinct `message` vs `announcement` HTML templates with full body (`<=3500` budget / `<=4096` total), clickable `/api/downloadAttachment` links, and `/wiadomosci/:id` deep links | Phase 26 | Parents and students can read the entire message/announcement and download attachments directly from Telegram without opening Librus. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None — all technical claims, file paths, schemas, and line numbers were verified directly in the repository and via tool runs in this session. | — | — |

## Open Questions

None — all implementation decisions (`D-01` through `D-07`) are locked in `26-CONTEXT.md`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | `functions/` runtime & test runner (`node --test`) | ✓ | `v25.8.0` (engines: `20`) `[VERIFIED: local shell]` | — |
| npm | Package & script runner (`npm test`) | ✓ | `11.11.0` `[VERIFIED: local shell]` | — |

**Missing dependencies with no fallback:**
- None

**Missing dependencies with fallback:**
- None

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Node.js built-in test runner (`node:test` + `node:assert/strict`) `[VERIFIED: functions/package.json:5]` |
| Config file | `functions/package.json` (`"scripts": { "test": "node --test" }`) `[VERIFIED: functions/package.json:4-6]` |
| Quick run command | `node --test functions/test/telegram_notifications.test.js functions/test/justification_notifications.test.js functions/test/message_body_indexing.test.js` |
| Full suite command | `npm --prefix functions test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-NOTIF-TG-MSG-01 | New message notification includes sender, subject, full multiline `body`/`content`, deep link `/wiadomosci/:id`, and hydrates missing details via `client.fetchMessageDetails` during sync before notification creation | unit | `node --test functions/test/telegram_notifications.test.js` | ❌ Wave 0 (create in Plan 26-01) |
| REQ-NOTIF-TG-ANN-01 | New school announcement notification uses distinct header `📢 <b>Nowe ogłoszenie szkolne</b>`, includes author, title, and full multiline `content` | unit | `node --test functions/test/telegram_notifications.test.js` | ❌ Wave 0 (create in Plan 26-01) |
| REQ-NOTIF-TG-ATT-01 | Message with `attachmentFiles` renders `📎 <b>Załączniki (X):</b>` with clickable `https://lepsza-szkola.web.app/api/downloadAttachment?path=...` links (and plain name fallback when `path` is absent), while escaping `<`, `>`, `&` and respecting the 4096-char Telegram HTML limit | unit | `node --test functions/test/telegram_notifications.test.js` | ❌ Wave 0 (create in Plan 26-01) |

### Sampling Rate
- **Per task commit:** `node --test functions/test/telegram_notifications.test.js functions/test/justification_notifications.test.js functions/test/message_body_indexing.test.js`
- **Per wave merge:** `npm --prefix functions test`
- **Phase gate:** Full backend test suite (`npm --prefix functions test` — all suites green) before verification.

### Wave 0 Gaps
- [ ] `functions/test/telegram_notifications.test.js` — covers `REQ-NOTIF-TG-MSG-01`, `REQ-NOTIF-TG-ANN-01`, `REQ-NOTIF-TG-ATT-01`, HTML escaping (`<`, `>`, `&`), word/line-boundary truncation within 4096 chars, and `LibrusClient` multiline message extraction.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Existing Telegram pairing and Librus session auth unchanged |
| V3 Session Management | no | Unchanged |
| V4 Access Control | yes | `/api/downloadAttachment` (`[VERIFIED: functions/src/librus_client.js:792-796]`) enforces `cleanPath.startsWith("/wiadomosci/pobierz_zalacznik/")` to prevent SSRF / arbitrary path traversal |
| V5 Input Validation & Output Encoding | yes | `escapeHtml(str)` (`[VERIFIED: functions/src/telegram_service.js:4-9]`) encodes `&`, `<`, `>` on all untrusted Librus fields (sender, subject, content, attachment names) before injecting into Telegram HTML template; `encodeURIComponent(att.path)` encodes query parameters |
| V6 Cryptography | no | Unchanged |

### Known Threat Patterns for Node.js + Telegram Bot API (`parse_mode: "HTML"`)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| HTML Tag Injection / Broken Telegram Payload via `<`, `>`, `&` in teacher message body or attachment filename | Tampering / Denial of Service | Pass every user/teacher-controlled string through `escapeHtml` *after* plain-text truncation so neither raw `<script>`/`<b>` tags nor half-sliced `&amp;` entities can break Telegram Bot API entity parsing. |
| Open Redirect / SSRF via `path` query parameter on `/api/downloadAttachment` | Tampering / Elevation of Privilege | `LibrusClient.resolveAttachmentDownloadUrl` (`[VERIFIED: functions/src/librus_client.js:794-796]`) strictly validates `!cleanPath.startsWith("/wiadomosci/pobierz_zalacznik/")` and ` _parseMessageAttachments` (`[VERIFIED: functions/src/librus_client.js:752]`) extracts only `/(\/wiadomosci\/pobierz_zalacznik\/\d+\/\d+)/`. |

## Sources

### Primary (HIGH confidence)
- `functions/src/telegram_service.js` (`lines 1-290`) — `escapeHtml`, `formatNotificationForTelegram`, `sendTelegramMessage`, `dispatchTelegramNotificationsForStudent` `[VERIFIED: functions/src/telegram_service.js:1-290]`
- `functions/src/sync_service.js` (`lines 189-338, 520-662`) — `syncStudentData`, notification object construction, `mergeAndIndexMessages` `[VERIFIED: functions/src/sync_service.js:189-662]`
- `functions/src/librus_client.js` (`lines 309-352, 627-812`) — `_extractMultilineElementText`, `fetchAnnouncements`, `fetchMessages`, `_parseMessageAttachments`, `fetchMessageDetails`, `resolveAttachmentDownloadUrl` `[VERIFIED: functions/src/librus_client.js:309-812]`
- `functions/index.js` (`lines 793-841`) & `firebase.json` (`lines 63-69`) — `/api/downloadAttachment` rewrite and Cloud Function implementation `[VERIFIED: functions/index.js:793-841]`
- `functions/test/justification_notifications.test.js` (`lines 1-195`) & `functions/test/message_body_indexing.test.js` (`lines 1-266`) — existing `node:test` patterns and assertions `[VERIFIED: functions/test/message_body_indexing.test.js:1-266]`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new dependencies; uses existing Node.js 20, `cheerio`, `axios`, and `node:test` verified in repo.
- Architecture: HIGH — all integration points in `librus_client.js`, `sync_service.js`, and `telegram_service.js` were inspected line-by-line.
- Pitfalls: HIGH — identified exact interactions with existing unit tests (`message_body_indexing.test.js`), Flutter's `SchoolNotificationItem` consumer, HTML entity expansion, and Telegram's 4096-character limit.

**Research date:** 2026-10-04
**Valid until:** 2026-11-04
