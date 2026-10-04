# Phase 26: Pełna treść wiadomości i ogłoszeń oraz linki do załączników w powiadomieniach Telegram - Context

**Gathered:** 2026-10-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Wzbogacenie powiadomień wysyłanych przez bota Telegram o nowej wiadomości z Librusa oraz o nowym ogłoszeniu szkolnym tak, aby zawierały pełną, wieloliniową treść wiadomości/ogłoszenia (z zachowaniem podziału na linie i bezpiecznym obcinaniem przy ~3500 znakach względem limitu 4096 znaków Telegram Bot API) oraz sekcję załączników wiadomości wraz z bezpośrednimi klikalnymi linkami HTML do ich pobrania (`https://lepsza-szkola.web.app/api/downloadAttachment?path=...`).

</domain>

<decisions>
## Implementation Decisions

### Pełna treść i zachowanie przy bardzo długich wiadomościach/ogłoszeniach
- **D-01:** Powiadomienie na Telegramie o nowej wiadomości (`type: "message"`) oraz o nowym ogłoszeniu (`type: "announcement"`) wysyła pełną, wieloliniową treść (`content` / `body`) w jednej wiadomości Telegram z zachowaniem podziału na linie (`\n`).
- **D-02:** Jeśli treść wiadomości lub ogłoszenia przekracza bezpieczny budżet długości (~3500 znaków, tak aby cały komunikat HTML razem z nagłówkiem, załącznikami i linkiem stopki zmieścił się w limicie 4096 znaków Telegram Bot API), treść jest obcinana na granicy słowa/linii z dopiskiem `… (pełna treść w aplikacji)` przed sekcją załączników i linkiem dolnym.
- **D-03:** Dla każdej nowo wykrytej wiadomości (`!prevMsgIds.has(m.id)`), która nie ma jeszcze wczytanej pełnej treści (`m.bodyLoaded !== true`) lub metadanych załączników, `sync_service.js` gwarantuje pobranie szczegółów wiadomości (`client.fetchMessageDetails(m.id, m.librusUrl)`) przed zbudowaniem obiektów `newNotifications`. Również ekstrakcja treści wiadomości w `librus_client.js` (`div.container-message-content`) powinna korzystać z `_extractMultilineElementText`, aby zachować znaczniki `<br>` i podziały wierszy.

### Prezentacja załączników na Telegramie
- **D-04:** Jeśli wiadomość posiada załączniki (`attachmentFiles: [{ name, path }]` lub `attachments: [name]`), pod treścią wiadomości w powiadomieniu Telegram dodawana jest sekcja:
  `📎 <b>Załączniki (X):</b>`
  a każdy załącznik posiadający ścieżkę `path` jest renderowany jako klikalny link HTML:
  `• <a href="https://lepsza-szkola.web.app/api/downloadAttachment?path=${encodeURIComponent(att.path)}">${escapeHtml(att.name)}</a>`
  (jeśli załącznik ma tylko nazwę bez ścieżki `path`, wyświetlana jest sama nazwa `• ${escapeHtml(att.name)}`).
- **D-05:** Nie wysyłamy osobnych plików binarnych przez `sendDocument` — klikalne linki prowadzące do endpointu `/api/downloadAttachment` w wiadomości tekstowej są wystarczające i nie obciążają czasu wykonania Cloud Function.

### Układ powiadomień (Wiadomość vs Ogłoszenie, deep link i „Ostatnie alerty”)
- **D-06:** Rozdzielamy wizualnie szablony w `formatNotificationForTelegram`:
  - Dla `type: "message"`: nagłówek `📬 <b>Nowa wiadomość w Librusie</b> (${safeStudent})`, temat, nadawca/data, pełna treść wiadomości, opcjonalna sekcja `📎 <b>Załączniki (X):</b>` z linkami oraz bezpośredni deep link do wątku: `🔗 <a href="https://lepsza-szkola.web.app/wiadomosci/${encodeURIComponent(msgId)}">Otwórz wiadomość w EduSync</a>` (lub `/wiadomosci`, jeśli `messageId` nie jest dostępny).
  - Dla `type: "announcement"`: nagłówek `📢 <b>Nowe ogłoszenie szkolne</b> (${safeStudent})`, tytuł ogłoszenia, autor/data, pełna wieloliniowa treść ogłoszenia oraz link `🔗 <a href="https://lepsza-szkola.web.app/wiadomosci">Otwórz ogłoszenia w EduSync</a>`.
- **D-07:** W obiekcie powiadomienia zapisywanym w Firestore (`students/{id}/notifications/{notifId}`):
  - Pole `body` pozostaje zwięzłym opisem metadanych (np. `${m.sender} • ${m.date}` lub `${a.author} (${a.date})`) na potrzeby kompaktowej listy w zakładce „Ostatnie alerty” w oknie Ustawień powiadomień.
  - Dodatkowe pola `content` (pełna treść wiadomości/ogłoszenia), `messageId` (ID wiadomości do deep linku) oraz `attachmentFiles` (lista `{ name, path }`) są dołączane do obiektu powiadomienia i wykorzystywane przez `formatNotificationForTelegram`.

### the agent's Discretion
- Dokładny próg znaków obcięcia treści (np. 3400–3500 znaków po escapowaniu HTML), aby cały payload `htmlText` nigdy nie przekroczył 4096 znaków narzuconych przez Telegram Bot API.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` — Definicja celu i kryteriów sukcesu Fazy 26 (`REQ-NOTIF-TG-MSG-01`, `REQ-NOTIF-TG-ANN-01`, `REQ-NOTIF-TG-ATT-01`)
- `.planning/REQUIREMENTS.md` — Istniejące wymagania dla powiadomień Telegram (`REQ-NOTIF-01`, `REQ-NOTIF-02`, `REQ-NOTIF-ACC-01`)

### Backend Notification & Sync Pipeline
- `functions/src/telegram_service.js` — Formatowanie HTML powiadomień Telegram (`formatNotificationForTelegram`) i wysyłka przez Bot API (`sendTelegramMessage`, `dispatchTelegramNotificationsForStudent`)
- `functions/src/sync_service.js` — Wykrywanie nowych ogłoszeń i wiadomości (`syncStudentData`), dogrywanie treści wiadomości (`mergeAndIndexMessages`) i przekazywanie powiadomień do `dispatchTelegramNotificationsForStudent`
- `functions/src/librus_client.js` — Pobieranie wiadomości (`fetchMessages`, `fetchMessageDetails`, `_parseMessageAttachments`), ogłoszeń (`fetchAnnouncements`, `_extractMultilineElementText`) oraz rozwiązywanie linków załączników (`resolveAttachmentDownloadUrl`)
- `functions/index.js` — Endpoint HTTP `exports.downloadAttachment` obsługujący `/api/downloadAttachment?path=...`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LibrusClient._extractMultilineElementText($, element)` w `functions/src/librus_client.js`: Już konwertuje `<br>` i znaczniki blokowe na `\n` dla ogłoszeń; można go użyć również dla `div.container-message-content` w `fetchMessages` i `fetchMessageDetails`.
- `LibrusClient._parseMessageAttachments($)` w `functions/src/librus_client.js`: Zwraca tablicę `{ name, path }`, gdzie `path` ma postać `/wiadomosci/pobierz_zalacznik/{msgId}/{attId}`.
- Endpoint `/api/downloadAttachment?path=...` (`functions/index.js` + rewrite w `firebase.json`): Publiczny endpoint przekierowujący 302 do bezpośredniego pobrania pliku z Librus Synergia.

### Established Patterns
- `escapeHtml(str)` w `functions/src/telegram_service.js`: Escapuje `&`, `<`, `>` przed wstawieniem tekstu do szablonu `parse_mode: "HTML"`.
- Jednostkowe testy backendu w `functions/test/` (Node `node:test` / `assert`) testujące `sync_service.js` i `telegram_service.js`.

### Integration Points
- `functions/src/sync_service.js` (linie 227–256 i `mergeAndIndexMessages`): Miejsce tworzenia obiektów `newNotifications` dla `announcement` i `message`.
- `functions/src/telegram_service.js` (`formatNotificationForTelegram`): Miejsce budowy wiadomości HTML dla Telegrama.

</code_context>

<specifics>
## Specific Ideas

- Linki do załączników w powiadomieniu Telegram mają otwierać bezpośrednio pobieranie załącznika (`https://lepsza-szkola.web.app/api/downloadAttachment?path=...`), dokładnie tak jak w widoku wiadomości w aplikacji webowej.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 26-pe-na-tre-wiadomo-ci-i-og-osze-oraz-linki-do-za-cznik-w-w-po*
*Context gathered: 2026-10-04*
