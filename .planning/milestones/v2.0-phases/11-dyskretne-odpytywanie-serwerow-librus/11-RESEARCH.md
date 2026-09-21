# Phase 11: Dyskretne odpytywanie serwerów Librus (rate limiting, harmonogram nocny) - Research

**Phase:** Phase 11  
**Author:** GSD Phase Researcher  
**Status:** Complete  
**Date:** 2026-09-18  

---

## Executive Summary

Phase 11 implements a stealthy, respectful, and resilient communication strategy with Librus Synergia servers. The goal is to eliminate any behavior that could flag automated scraping or trigger rate limits:
1. **Cisza nocna (22:30 – 06:30)**: Complete suspension of background automated syncs.
2. **Dynamiczny harmonogram**: Differentiated frequency (30–40 min with random jitter during school hours 07:00–16:30; 60 min in the evening 16:30–22:30; only twice a day at 11:00 and 19:00 on weekends).
3. **Sekwencyjne pobieranie modułów**: Replacing `Promise.all` simultaneous blast with human-paced sequential requests with 1.0–2.5s jitter between tabs.
4. **Nowoczesny profil przeglądarki**: Replacing 14-year-old Firefox 10 (from 2012) with a modern Chrome 133 profile and full HTTP client hints (`Sec-Ch-Ua`, `Sec-Fetch-*`, `Accept-Language: pl`).
5. **Trwałość sesji i ponowne użycie ciasteczek**: Reusing session cookies across function invocations via `tough-cookie` serialization stored in Firestore/memory, invoking OAuth login only when the session actually expires.
6. **Dynamiczny backoff (429/503)**: Pausing automated requests for 15–30 minutes upon encountering rate limits or server errors, serving Firestore cache safely.
7. **Client-side cooldown (2 min)**: Guarding on-demand manual sync in Flutter with a 120-second cooldown timer and clear user feedback.

---

## 1. Cloud Functions v2 Scheduler & Gatekeeper Engine

### Current Situation
In `functions/index.js` (lines 171–194):
- Schedule is hardcoded to `"every 30 minutes"` 24/7.
- Calls `syncStudentData` regardless of time of day, day of week, or server load.
- Invocations hit at exact `:00` and `:30` minute marks without any jitter.

### Technical Discovery & Architecture
Cloud Functions v2 uses Cloud Scheduler backed by Pub/Sub or HTTPS targets.
A single cron expression cannot natively express "every 35 min from 07:00 to 16:30, every 60 min from 16:30 to 22:30, and twice daily on weekends".
However, combining a **fine-grained Cloud Scheduler tick** (`*/10 6-22 * * *` in `Europe/Warsaw`) with an **in-function Gatekeeper Engine** (`functions/src/sync_scheduler.js`) provides exact, resilient control:

1. **Cloud Scheduler Configuration**:
   - `schedule: "*/10 6-22 * * *"` with `timeZone: "Europe/Warsaw"`.
   - Between 23:00 and 05:59 Warsaw time, Cloud Scheduler is completely dormant (0 invocations, 0 cost).
   - Invocations trigger from 06:00 to 22:50.
   - Timeout increased from 60s to 300s (`timeoutSeconds: 300`) to accommodate sequential scraping delays and jitter.

2. **Timezone & Time Parts Evaluation**:
   Node 20 has built-in `Intl.DateTimeFormat` for zero-dependency, DST-accurate Warsaw time parsing:
   ```javascript
   function getWarsawTimeParts(date = new Date()) {
     const formatter = new Intl.DateTimeFormat("en-US", {
       timeZone: "Europe/Warsaw",
       hour12: false,
       weekday: "short",
       year: "numeric",
       month: "numeric",
       day: "numeric",
       hour: "numeric",
       minute: "numeric",
       second: "numeric"
     });
     const parts = {};
     formatter.formatToParts(date).forEach(p => { parts[p.type] = p.value; });
     return {
       dayOfWeek: parts.weekday, // 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
       hour: parseInt(parts.hour, 10),
       minute: parseInt(parts.minute, 10),
       second: parseInt(parts.second, 10),
       dateString: `${parts.year}-${parts.month.padStart(2, '0')}-${parts.day.padStart(2, '0')}`
     };
   }
   ```

3. **Gating Logic Rules**:
   - **Night Silence (D-01)**:
     If Warsaw time is between 22:30 and 06:30 (`totalMinutes >= 1350 || totalMinutes < 390`):
     Immediately return `{ shouldRun: false, reason: "night_silence" }`.
   - **Backoff Check (D-08)**:
     If Firestore `system/librus_sync_state` has `backoffUntil` and `now < backoffUntil`:
     Immediately return `{ shouldRun: false, reason: "backoff_active", backoffUntil }`.
   - **Weekend Gating (D-03)**:
     If `weekday === 'Sat' || weekday === 'Sun'`:
     Allowed slots: 11:00 (11:00–11:29) and 19:00 (19:00–19:29).
     If current hour is not 11 and not 19 -> return `{ shouldRun: false, reason: "weekend_outside_slot" }`.
     If already synced today during this slot -> return `{ shouldRun: false, reason: "weekend_slot_already_synced" }`.
   - **School Days (Pn–Pt, D-02)**:
     - 06:30 – 07:00: Early wake-up buffer, return `{ shouldRun: false, reason: "pre_school_buffer" }`.
     - 07:00 – 16:30 (school hours): Target interval 30–40 min with random jitter.
       If `now - lastScheduledSync < targetIntervalMinutes * 60 * 1000` -> skip.
     - 16:30 – 22:30 (evening hours): Target interval 60 min.
       If `now - lastScheduledSync < 55 * 60 * 1000` -> skip.

4. **In-Invocation Random Jitter**:
   When `shouldRun` is true, sleep for a random jitter between 15s and 75s before initiating HTTP calls:
   `await sleep(randomInt(15000, 75000));`
   This ensures Librus server logs never see synchronization requests landing at exactly `:00` seconds or predictable intervals.

---

## 2. Session Management & CookieJar Persistence (D-07)

### Current Problem
Currently, `LibrusClient.constructor()` instantiates a fresh `new CookieJar()` every time.
Every call to `fetchAll()` triggers:
```javascript
await this.authenticate();
```
which posts user credentials to `https://api.librus.pl/OAuth/Authorization?client_id=46`.
This means 40+ OAuth logins every single day. Normal human users log in once and keep their browser cookies active for days.

### Solution: `SessionManager` & CookieJar Serialization
`tough-cookie` v5.1.2 is installed in `functions/`. It supports native JSON serialization:
- `jar.toJSON()` produces a clean serializable object.
- `CookieJar.fromJSON(serializedObj)` restores the exact cookies, domain bindings, and flags synchronously.

### Implementation Architecture
Create `functions/src/session_manager.js`:
- **Storage**: Firestore collection `librus_sessions`, document id = `login`.
- **In-Memory Cache**: A module-level `Map<string, { jar: CookieJar, expiresAt: number }>` to avoid Firestore reads when Cloud Run instances remain warm.
- **Session Expiry & Validation**:
  - Store `expiresAt` (default 4–6 hours from last successful auth).
  - When scraping, if a response indicates an expired session (e.g. redirected to `https://synergia.librus.pl/loguj/...` or `portal.librus.pl`, or status 302, or HTML containing `action="/loguj"`), the client transparently re-authenticates via OAuth, persists the new cookies to Firestore, and re-executes the failed call.
  - Result: 95% reduction in OAuth authorization calls.

---

## 3. Human-Paced Sequential Scraping with Jitter (D-05)

### Current Problem
`functions/src/librus_client.js` lines 48-57:
```javascript
const [infoData, annData, gradesData, ttData, attData, msgData, justData, terminarzData] = await Promise.all([
  this.fetchStudentInfo(),
  this.fetchAnnouncements(),
  this.fetchGrades(),
  this.fetchTimetable(),
  this.fetchAttendance(),
  this.fetchMessages(),
  this.fetchJustifications(),
  this.fetchTerminarz()
]);
```
Firing 8 concurrent HTTP requests to Synergia within the same millisecond is a telltale sign of an automated bot and puts unnecessary load on their servers.

### Sequential Implementation Architecture
Replace `Promise.all` with a sequential pipeline mimicking a human reading the portal:
1. `fetchStudentInfo()` (Dashboard / Basic info)
2. `await sleep(jitter(1000, 2500))`
3. `fetchAnnouncements()` (Ogłoszenia / Szczęśliwy numerek)
4. `await sleep(jitter(1000, 2500))`
5. `fetchGrades()` (Oceny)
6. `await sleep(jitter(1000, 2500))`
7. `fetchTimetable()` (Plan lekcji)
8. `await sleep(jitter(1000, 2500))`
9. `fetchAttendance()` (Frekwencja)
10. `await sleep(jitter(1000, 2500))`
11. `fetchTerminarz()` (Terminarz / Sprawdziany)
12. `await sleep(jitter(1000, 2500))`
13. `fetchMessages()` (Wiadomości)
14. `await sleep(jitter(1000, 2500))`
15. `fetchJustifications()` (e-Usprawiedliwienia)

In `fetchMessages()`:
Currently it fetches full bodies for up to 10 messages. Add a gentle jitter (500–1000ms) between individual message body fetches or limit to the latest 5 messages.

**Total Timing Breakdown**:
- 7 intervals of 1.0–2.5s jitter = ~12s.
- 8 module requests = ~6s.
- Total execution time = ~18–25 seconds.
- `timeoutSeconds` for `syncNow` increased from 60s to 120s.
- `timeoutSeconds` for `scheduledLibrusSync` increased from 60s to 300s.

---

## 4. Modern Browser Profile & Anti-Fingerprinting (D-06)

### Current Problem
`librus_client.js` line 18:
```javascript
headers: {
  "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:10.0) Gecko/20100101 Firefox/10.0"
}
```
Firefox 10.0 was released in January 2012. Using a 2012 User-Agent without modern headers (`Sec-Ch-Ua`, `Sec-Fetch-*`, `Accept-Language`) is an immediate bot signal.

### Modern Browser Headers Profile
Replace with current Chrome 133 on Windows 10/11 headers:
```javascript
const MODERN_BROWSER_HEADERS = {
  "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
  "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
  "Accept-Language": "pl,en-US;q=0.9,en;q=0.8",
  "Accept-Encoding": "gzip, deflate, br, zstd",
  "Sec-Ch-Ua": '"Not(A:Brand";v="99", "Google Chrome";v="133", "Chromium";v="133"',
  "Sec-Ch-Ua-Mobile": "?0",
  "Sec-Ch-Ua-Platform": '"Windows"',
  "Sec-Fetch-Dest": "document",
  "Sec-Fetch-Mode": "navigate",
  "Sec-Fetch-Site": "same-origin",
  "Sec-Fetch-User": "?1",
  "Upgrade-Insecure-Requests": "1",
  "Cache-Control": "max-age=0"
};
```
Add dynamic `Referer` headers based on navigation flow (e.g. `Referer: https://synergia.librus.pl/uczen/index` when visiting subpages).

---

## 5. Dynamic Backoff & Rate Limit Handling (D-08)

### Mechanism
When Librus returns:
- HTTP 429 (Too Many Requests)
- HTTP 503 (Service Unavailable)
- Captcha or Cloudflare challenge detection in response HTML

The system triggers an automated backoff:
1. Set a backoff record in Firestore (`system/librus_sync_state`):
   ```json
   {
     "backoffUntil": "2026-09-18T10:30:00.000Z",
     "backoffReason": "HTTP 429: Too Many Requests",
     "updatedAt": "serverTimestamp"
   }
   ```
2. Duration: 20–30 minutes.
3. During backoff:
   - `scheduledLibrusSync` skips silently, logging `[Backoff Active]`.
   - `syncNow` endpoint checks backoff first and returns:
     ```json
     {
       "success": false,
       "rateLimited": true,
       "backoffUntil": "2026-09-18T10:30:00.000Z",
       "message": "Serwery Librus są chwilowo przeciążone. Korzystamy z pamięci podręcznej."
     }
     ```
   - Client does NOT encounter crashes; existing Firestore data is retained and served.

---

## 6. Client-Side Cooldown & UX (D-04)

### Flutter `sync_provider.dart` Architecture
In `lib/presentation/providers/sync_provider.dart`:
1. **Cooldown State**:
   - `DateTime? lastManualSyncTriggeredAt;`
   - `int get cooldownSecondsRemaining`: `120 - diffInSeconds` (capped at 0).
   - `bool get isCooldownActive => cooldownSecondsRemaining > 0;`
   - `bool get isNightSilence`: Checks if local time is between 22:30 and 06:30.
2. **On-Demand Click Protection**:
   - When user clicks manual sync in `app_header.dart` or `dashboard_screen.dart`:
   - If `isCooldownActive`:
     Update state: `statusMessage = 'Odczekaj jeszcze ${cooldownSecondsRemaining}s przed kolejnym odświeżeniem.'`
     Return early without calling the server.
   - If outside cooldown:
     Mark `lastManualSyncTriggeredAt = DateTime.now()`.
     Execute HTTP call to `/api/syncNow`.
     Timeout updated from 15s to 45s to allow human-paced scraper completion.
3. **UX Feedback**:
   - Floating SnackBar displaying:
     - Normal success: `"Zsynchronizowano z Librusem (przed chwilą)"`
     - Cooldown: `"Odczekaj chwilę przed kolejną synchronizacją (${seconds}s). Serwery Librus są chronione."`
     - Night time notice: `"Cisza nocna: serwery Librus odpoczywają do 06:30. Wyświetlamy aktualną kopię danych."`
     - Backoff: `"Serwery Librus odpoczywają (przeciążenie). Prezentujemy zapisane dane."`

---

## 7. Validation Architecture & Test Strategy

### Unit Tests (`functions/test/`)
Using Node.js built-in `node:test` and `node:assert`:
1. `test/sync_scheduler.test.js`:
   - Verify `isNightSilence()` for hours: 22:29 (false), 22:30 (true), 01:00 (true), 06:29 (true), 06:30 (false).
   - Verify weekend slot gating (Saturday 11:15 -> true; Saturday 14:00 -> false; Sunday 19:10 -> true).
   - Verify weekday intervals (school hours 07:00–16:30 -> 30–40 min; evening 16:30–22:30 -> 60 min).
   - Verify backoff suppression when `now < backoffUntil`.
2. `test/session_manager.test.js`:
   - Verify `tough-cookie` serialization to JSON and round-trip deserialization.
   - Verify cookie preservation across instances.
3. `test/librus_headers.test.js`:
   - Verify `MODERN_BROWSER_HEADERS` contains valid Chrome 133 headers, `Accept-Language`, `Sec-Ch-Ua`.
   - Verify sequential scraper helper with jitter delays.

### Flutter Verification
- `flutter analyze` ensuring zero linter warnings.
- Verification of `sync_provider.dart` cooldown logic.

---

## Implementation Work Breakdown (For Planner)

| Plan | Focus | Key Deliverables |
|------|-------|------------------|
| **11-01** | Backend Scraping Stealth & Sessions (D-05, D-06, D-07, D-08) | Modern headers (Chrome 133), `SessionManager` with Firestore cookie jar persistence, sequential `fetchAll` with 1.0–2.5s jitter, dynamic backoff detection (429/503), unit tests. |
| **11-02** | Cloud Scheduler & Gatekeeper Engine (D-01, D-02, D-03) | `sync_scheduler.js` with Warsaw timezone evaluation, night silence (22:30–06:30), school hours (30–40 min), evening (60 min), weekend slots (11:00 & 19:00), scheduler jitter, updated `scheduledLibrusSync`. |
| **11-03** | Client-Side Cooldown & Night-Time UX (D-04) | 2-minute cooldown in `sync_provider.dart`, 45s HTTP client timeout, cooldown countdown UI, night silence and backoff notifications in `app_header.dart` and `dashboard_screen.dart`. |

---

## RESEARCH COMPLETE
