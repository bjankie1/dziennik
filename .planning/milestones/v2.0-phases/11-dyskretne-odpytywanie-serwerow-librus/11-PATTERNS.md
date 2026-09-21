# Phase 11: Dyskretne odpytywanie serwerów Librus - Pattern Mapping

**Mapped:** 2026-09-18  
**Phase:** 11 - Dyskretne odpytywanie serwerów Librus (rate limiting, harmonogram nocny)  
**Status:** Complete  

---

## 1. File Inventory & Classification

| File | Status | Architectural Role | Data Flow & Responsibility | Closest Analog |
|---|---|---|---|---|
| `functions/src/librus_client.js` | **Modify** | HTTP Gateway / Scraper | Handles Librus Synergia OAuth authentication, cookie jar serialization/deserialization, realistic HTTP headers, session probing (`GET /uczen/index`), and sequential module fetching with randomized sleep jitter. | [librus_client.js](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/src/librus_client.js#L1-L97) |
| `functions/src/sync_service.js` | **Modify** | Application / Domain Service | Coordinates sync lifecycle: inspects global backoff lock (`system_status/librus_rate_limit`), retrieves cached session jar from `librus_sessions/{login}`, invokes `LibrusClient`, diffs changes, saves new notifications & student document, and triggers rate limit lock on 429/503. | [sync_service.js](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/src/sync_service.js#L1-L111) |
| `functions/src/schedule_evaluator.js` | **Create** | Pure Domain Logic / Policy | Evaluates Warsaw timezone windows (quiet hours 22:30–06:30, weekday school hours 07:00–16:30 with ~30m cadence, weekday evening 16:30–22:30 with 60m cadence, weekend 11:00/19:00 slots) and calculates random jitter delay. Fully decoupled for zero-side-effect unit testing. | New pure module (tested via Node test runner) |
| `functions/index.js` | **Modify** | Cloud Functions API / Infrastructure | Declares Cloud Scheduler (`scheduledLibrusSync`) running every 15 minutes with `timeoutSeconds: 300` and HTTP endpoints (`syncNow`, `getStudentData`). Integrates `schedule_evaluator` to decide whether to execute or safely skip. | [index.js](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/index.js#L15-L44) |
| `lib/presentation/providers/sync_provider.dart` | **Modify** | Presentation / State Management | Riverpod `Notifier<SyncState>` managing UI sync operations. Enforces a 120-second client-side cooldown between sync requests, presents informative status messages for quiet hours, and triggers endpoint `/api/syncNow`. | [sync_provider.dart](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/providers/sync_provider.dart#L7-L129) |
| `functions/test/schedule_decision.test.js` | **Create** | Backend Automated Tests | Unit tests verifying schedule decision windows (night quiet skip, weekday cadence, weekend 11:00/19:00 allowance, time calculation) using Node.js built-in `node:test` and `node:assert`. | Native Node.js test suite |
| `functions/test/stealth_client.test.js` | **Create** | Backend Automated Tests | Unit tests verifying cookie jar serialization/deserialization, sequential execution timing with jitter simulation, and backoff handling. | Native Node.js test suite |
| `test/presentation/providers/sync_provider_test.dart` | **Create** | Frontend Automated Tests | Flutter unit test verifying `SyncNotifier` cooldown enforcement (suppressing rapid clicks within 120 seconds and surfacing cooldown status message). | [dashboard_screen_test.dart](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/test/dashboard_screen_test.dart#L1-L50) |

---

## 2. Component Patterns & Analogs

### 2.1. Stealth HTTP Client & Cookie Persistence (`functions/src/librus_client.js`)

#### Role & Data Flow
Acts as the external scraping adapter. Injects modern browser impersonation headers, deserializes cached cookies if available, probes active session validity with `GET https://synergia.librus.pl/uczen/index` before performing expensive OAuth logins, and iterates sequentially over modules with randomized pause between calls.

#### Existing Analog: [librus_client.js:L1-L57](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/src/librus_client.js#L1-L57)
```javascript
// Existing initialization in librus_client.js
const axios = require("axios");
const { wrapper } = require("axios-cookiejar-support");
const { CookieJar } = require("tough-cookie");
const cheerio = require("cheerio");

class LibrusClient {
  constructor(login = process.env.LIBRUS_LOGIN, pass = process.env.LIBRUS_PASSWORD) {
    if (!login || !pass) {
      throw new Error("Brak danych logowania Librus. Ustaw zmienne LIBRUS_LOGIN i LIBRUS_PASSWORD.");
    }
    this.login = login;
    this.pass = pass;
    this.jar = new CookieJar();
    this.client = wrapper(axios.create({
      jar: this.jar,
      withCredentials: true,
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:10.0) Gecko/20100101 Firefox/10.0"
      },
      timeout: 25000
    }));
  }

  async authenticate() {
    await this.client.get("https://synergia.librus.pl/loguj/portalRodzina?v=1774820765");
    const authRes = await this.client.post(
      "https://api.librus.pl/OAuth/Authorization?client_id=46",
      new URLSearchParams({
        action: "login",
        login: this.login,
        pass: this.pass
      }).toString(),
      { headers: { "Content-Type": "application/x-www-form-urlencoded" } }
    );
...
```

#### Proposed Pattern & Modifications
1. **Modern Chrome Headers (D-06):**
```javascript
const MODERN_BROWSER_HEADERS = {
  "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
  "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
  "Accept-Language": "pl-PL,pl;q=0.9,en-US;q=0.8,en;q=0.7",
  "Sec-Ch-Ua": "\"Not(A:Brand\";v=\"99\", \"Google Chrome\";v=\"133\", \"Chromium\";v=\"133\"",
  "Sec-Ch-Ua-Mobile": "?0",
  "Sec-Ch-Ua-Platform": "\"Windows\"",
  "Sec-Fetch-Dest": "document",
  "Sec-Fetch-Mode": "navigate",
  "Sec-Fetch-Site": "same-origin",
  "Sec-Fetch-User": "?1",
  "Upgrade-Insecure-Requests": "1"
};
```

2. **Cookie Jar Serialization / Deserialization (D-07):**
```javascript
// Export & Import session state
async exportSession() {
  return await this.jar.serialize();
}

static async createWithSession(login, pass, serializedJar = null) {
  const client = new LibrusClient(login, pass);
  if (serializedJar) {
    try {
      client.jar = await CookieJar.deserialize(serializedJar);
      client._rebuildAxiosClient();
    } catch (e) {
      console.warn("Could not deserialize cookie jar, using fresh jar:", e.message);
    }
  }
  return client;
}

// Probe session validity before running full OAuth
async isSessionValid() {
  try {
    const res = await this.client.get("https://synergia.librus.pl/uczen/index", {
      maxRedirects: 3,
      validateStatus: (status) => status < 400
    });
    // If redirected to login page or response contains login form
    if (res.request?.path?.includes("loguj") || res.data?.includes("formularz-logowania")) {
      return false;
    }
    return true;
  } catch (err) {
    return false;
  }
}
```

3. **Sequential Module Fetching with Humanized Jitter (D-05):**
```javascript
const sleep = (minMs, maxMs) => new Promise(resolve => {
  const ms = Math.floor(Math.random() * (maxMs - minMs + 1)) + minMs;
  setTimeout(resolve, ms);
});

async fetchAll() {
  // 1. Session check or full authenticate
  const sessionOk = await this.isSessionValid();
  if (!sessionOk) {
    await this.authenticate();
  }

  // 2. Sequential execution imitating natural user browsing
  const infoData = await this.fetchStudentInfo();
  await sleep(1200, 2400);

  const annData = await this.fetchAnnouncements();
  await sleep(1000, 2200);

  const gradesData = await this.fetchGrades();
  await sleep(1500, 2500);

  const ttData = await this.fetchTimetable();
  await sleep(1200, 2000);

  const attData = await this.fetchAttendance();
  await sleep(1400, 2300);

  const msgData = await this.fetchMessages();
  await sleep(1000, 2000);

  const justData = await this.fetchJustifications();
  await sleep(1100, 2100);

  const terminarzData = await this.fetchTerminarz();

  // Return aggregated payload
  return { ... };
}
```

---

### 2.2. Synchronization Orchestration & Backoff Lock (`functions/src/sync_service.js`)

#### Role & Data Flow
Orchestrates the synchronization pipeline:
1. Queries `system_status/librus_rate_limit` in Firestore. If `lockedUntil > now`, immediately skips scraping and returns cached data.
2. Loads `librus_sessions/{login}`. Deserializes cookies into `LibrusClient`.
3. Calls `fetchAll()`. If HTTP 429 or 503 is caught, writes a 20-minute backoff lock to `system_status/librus_rate_limit`.
4. If successful, serializes the updated cookie jar back to `librus_sessions/{login}`.
5. Computes notifications diff and writes updates to `students/{login}`.

#### Existing Analog: [sync_service.js:L4-L20](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/src/sync_service.js#L4-L20)
```javascript
async function syncStudentData(login = process.env.LIBRUS_LOGIN, password = process.env.LIBRUS_PASSWORD) {
  if (!login || !password) {
    throw new Error("Brak danych logowania Librus. Ustaw zmienne LIBRUS_LOGIN i LIBRUS_PASSWORD.");
  }
  const db = admin.firestore();
  const client = new LibrusClient(login, password);

  console.log(`Starting sync for student: ${login}...`);
  const freshData = await client.fetchAll();

  const studentRef = db.collection("students").doc(login);
  const prevDoc = await studentRef.get();
  const prevData = prevDoc.exists ? prevDoc.data() : null;
...
```

#### Proposed Pattern & Modifications (D-07, D-08)
```javascript
const RATE_LIMIT_DOC = "system_status/librus_rate_limit";
const BACKOFF_DURATION_MS = 20 * 60 * 1000; // 20 minutes

async function checkRateLimitLock(db) {
  const doc = await db.doc(RATE_LIMIT_DOC).get();
  if (doc.exists) {
    const data = doc.data();
    if (data.isLocked && data.lockedUntil?.toDate() > new Date()) {
      return {
        locked: true,
        lockedUntil: data.lockedUntil.toDate(),
        reason: data.reason
      };
    }
  }
  return { locked: false };
}

async function setRateLimitLock(db, reason) {
  const lockedUntil = new Date(Date.now() + BACKOFF_DURATION_MS);
  await db.doc(RATE_LIMIT_DOC).set({
    isLocked: true,
    lockedUntil: admin.firestore.Timestamp.fromDate(lockedUntil),
    reason,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
}
```

---

### 2.3. Schedule Window Evaluator (`functions/src/schedule_evaluator.js`)

#### Role & Data Flow
Pure computation module without I/O or Firebase dependencies. Given a reference `Date` and optionally an execution minute cadence, it determines whether the scheduler should execute a sync run or skip it.
- **Night quiet period (22:30 – 06:30)**: Skip (D-01).
- **Weekdays (Pn–Pt)**:
  - 07:00 – 16:30: Run every ~30 minutes (i.e. every 2nd 15-minute invocation) with random jitter (0–5 min) (D-02).
  - 16:30 – 22:30: Run every ~60 minutes (i.e. once per hour, e.g. minute :00) (D-02).
- **Weekends (Sob–Nd)**: Only 2 slots: 11:00–11:15 and 19:00–19:15. All other times: skip (D-03).

#### Implementation Pattern
```javascript
/**
 * Evaluates whether a background sync should execute at the given Warsaw timestamp.
 * @param {Date} now Reference time
 * @returns {{ shouldRun: boolean, reason: string, jitterMs: number }}
 */
function evaluateScheduleDecision(now = new Date()) {
  const warsawStr = now.toLocaleString("en-US", { timeZone: "Europe/Warsaw" });
  const warsawDate = new Date(warsawStr);
  const day = warsawDate.getDay(); // 0 = Sun, 6 = Sat
  const hour = warsawDate.getHours();
  const minute = warsawDate.getMinutes();

  const isWeekend = (day === 0 || day === 6);

  // 1. Night Quiet Window: 22:30 - 06:30
  if ((hour === 22 && minute >= 30) || hour > 22 || hour < 6 || (hour === 6 && minute < 30)) {
    return { shouldRun: false, reason: "Cisza nocna (22:30 - 06:30)", jitterMs: 0 };
  }

  // 2. Weekend Policy (Saturday & Sunday): only 11:00-11:15 and 19:00-19:15
  if (isWeekend) {
    const isMorningSlot = (hour === 11 && minute < 15);
    const isEveningSlot = (hour === 19 && minute < 15);
    if (isMorningSlot || isEveningSlot) {
      const jitterMs = Math.floor(Math.random() * 180000); // 0-3m jitter
      return { shouldRun: true, reason: "Weekend sync slot", jitterMs };
    }
    return { shouldRun: false, reason: "Poza weekendowymi oknami (11:00 i 19:00)", jitterMs: 0 };
  }

  // 3. Weekday School Hours: 07:00 - 16:30 (Every 30m)
  if ((hour >= 7 && hour < 16) || (hour === 16 && minute <= 30)) {
    const isCadenceStep = (minute < 15 || (minute >= 30 && minute < 45));
    if (!isCadenceStep) {
      return { shouldRun: false, reason: "Pomiędzy 30-minutowymi cyklami szczytu szkolnego", jitterMs: 0 };
    }
    const jitterMs = Math.floor(Math.random() * 240000) + 60000;
    return { shouldRun: true, reason: "Szczyt szkolny (Pn-Pt 07:00-16:30)", jitterMs };
  }

  // 4. Weekday Evening Hours: 16:30 - 22:30 (Every 60m)
  if (minute < 15) {
    const jitterMs = Math.floor(Math.random() * 180000); // 0-3m jitter
    return { shouldRun: true, reason: "Popołudniowe okno (co 60 min)", jitterMs };
  }

  return { shouldRun: false, reason: "Pomiędzy 60-minutowymi cyklami wieczornymi", jitterMs: 0 };
}

module.exports = { evaluateScheduleDecision };
```

---

### 2.4. Cloud Functions Scheduling & Handlers (`functions/index.js`)

#### Role & Data Flow
Integrates `evaluateScheduleDecision` in `scheduledLibrusSync`.
Sets `schedule: "every 15 minutes"`, `timeZone: "Europe/Warsaw"`, `timeoutSeconds: 300` (to permit initial jitter sleep and sequential scraping).

#### Existing Analog: [index.js:L171-L194](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/index.js#L171-L194)
```javascript
exports.scheduledLibrusSync = onSchedule(
  {
    region: "europe-west3",
    schedule: "every 30 minutes",
    timeZone: "Europe/Warsaw",
    timeoutSeconds: 60,
    memory: "512MiB"
  },
  async (event) => {
    console.log("Starting scheduled 30-minute Librus sync job...");
    try {
      const login = process.env.LIBRUS_LOGIN;
      const pass = process.env.LIBRUS_PASSWORD;
      if (!login || !pass) {
        console.warn("scheduledLibrusSync: Brak skonfigurowanych zmiennych LIBRUS_LOGIN / LIBRUS_PASSWORD.");
        return;
      }
      const result = await syncStudentData(login, pass);
      console.log("Scheduled sync finished successfully:", result);
    } catch (error) {
      console.error("Scheduled sync error:", error);
    }
  }
);
```

#### Proposed Pattern & Modifications
```javascript
const { evaluateScheduleDecision } = require("./src/schedule_evaluator");

exports.scheduledLibrusSync = onSchedule(
  {
    region: "europe-west3",
    schedule: "every 15 minutes",
    timeZone: "Europe/Warsaw",
    timeoutSeconds: 300,
    memory: "512MiB"
  },
  async (event) => {
    const decision = evaluateScheduleDecision(new Date());
    if (!decision.shouldRun) {
      console.log(`[scheduledLibrusSync] Skipped: ${decision.reason}`);
      return;
    }

    if (decision.jitterMs > 0) {
      console.log(`[scheduledLibrusSync] Applying jitter of ${Math.round(decision.jitterMs / 1000)}s...`);
      await new Promise(res => setTimeout(res, decision.jitterMs));
    }

    const login = process.env.LIBRUS_LOGIN;
    const pass = process.env.LIBRUS_PASSWORD;
    if (!login || !pass) {
      console.warn("scheduledLibrusSync: Missing LIBRUS_LOGIN / LIBRUS_PASSWORD.");
      return;
    }

    const result = await syncStudentData(login, pass);
    console.log("Scheduled sync completed:", result);
  }
);
```

---

### 2.5. Frontend Sync Cooldown & Quiet Hours Feedback (`lib/presentation/providers/sync_provider.dart`)

#### Role & Data Flow
Manages UI sync triggering.
1. Checks `lastSyncTime`: If `now.difference(lastSyncTime) < 120 seconds` (2 minutes), refuses immediate dispatch, sets statusMessage with remaining seconds, and returns early without making HTTP calls (D-04).
2. Checks current time for quiet hours (22:30–06:30): If triggered manually during quiet hours, performs sync on-demand (D-04) but indicates quiet hours context in `statusMessage`.

#### Existing Analog: [sync_provider.dart:L76-L127](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/providers/sync_provider.dart#L76-L127)
```javascript
  Future<void> syncNow() async {
    if (state.isSyncing) return;
    state = state.copyWith(
      isSyncing: true,
      statusMessage: 'Synchronizacja z Librus Synergia w toku...',
    );

    try {
      // Trigger cloud synchronization endpoint
      final uri = Uri.parse('/api/syncNow');
      try {
        final res = await http.get(uri).timeout(const Duration(seconds: 15));
...
```

#### Proposed Pattern & Modifications
```dart
  static const int minCooldownSeconds = 120; // 2 minutes

  Future<void> syncNow() async {
    if (state.isSyncing) return;

    final now = DateTime.now();
    final elapsed = now.difference(state.lastSyncTime).inSeconds;
    if (elapsed < minCooldownSeconds && !state.isDemoMode) {
      final waitRemaining = minCooldownSeconds - elapsed;
      state = state.copyWith(
        statusMessage: 'Zbyt częste odświeżanie. Odczekaj jeszcze ${waitRemaining}s przed kolejną próbą.',
      );
      return;
    }

    final isQuietHour = (now.hour == 22 && now.minute >= 30) ||
        now.hour > 22 ||
        now.hour < 6 ||
        (now.hour == 6 && now.minute < 30);

    state = state.copyWith(
      isSyncing: true,
      statusMessage: isQuietHour
          ? 'Cisza nocna: serwery Librus odpoczywają do 06:30. Wywołano synchronizację na żądanie...'
          : 'Synchronizacja z Librus Synergia w toku...',
    );
...
```

---

## 3. Automated Test Suite Analogs & Patterns

### 3.1. Node.js Tests (`functions/test/schedule_decision.test.js`)
Uses native `node:test` and `node:assert`.

```javascript
const { test, describe } = require("node:test");
const assert = require("node:assert");
const { evaluateScheduleDecision } = require("../src/schedule_evaluator");

describe("Schedule Evaluator Time Windows", () => {
  test("Skips execution during night quiet window (03:15 Warsaw)", () => {
    // Construct ISO string corresponding to 03:15 in Warsaw
    const testDate = new Date("2026-09-18T01:15:00.000Z"); // UTC 01:15 -> Warsaw 03:15
    const decision = evaluateScheduleDecision(testDate);
    assert.strictEqual(decision.shouldRun, false);
    assert.match(decision.reason, /Cisza nocna/);
  });

  test("Runs during weekday school peak (Friday 10:00 Warsaw)", () => {
    const testDate = new Date("2026-09-18T08:00:00.000Z"); // UTC 08:00 -> Warsaw 10:00
    const decision = evaluateScheduleDecision(testDate);
    assert.strictEqual(decision.shouldRun, true);
    assert.ok(decision.jitterMs >= 0);
  });

  test("Skips outside weekend designated slots (Sunday 14:00 Warsaw)", () => {
    const testDate = new Date("2026-09-20T12:00:00.000Z"); // UTC 12:00 -> Warsaw 14:00
    const decision = evaluateScheduleDecision(testDate);
    assert.strictEqual(decision.shouldRun, false);
  });

  test("Runs during Sunday 11:00 slot (Sunday 11:05 Warsaw)", () => {
    const testDate = new Date("2026-09-20T09:05:00.000Z"); // UTC 09:05 -> Warsaw 11:05
    const decision = evaluateScheduleDecision(testDate);
    assert.strictEqual(decision.shouldRun, true);
  });
});
```

### 3.2. Flutter Provider Tests (`test/presentation/providers/sync_provider_test.dart`)
Uses `flutter_test` and `ProviderContainer`.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edusync/presentation/providers/sync_provider.dart';

void main() {
  test('SyncNotifier throttles rapid consecutive syncNow calls within 120s', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(syncProvider.notifier);
    final initialState = container.read(syncProvider);

    // Initial state check
    expect(initialState.isSyncing, false);

    // First call updates lastSyncTime
    await notifier.syncNow();
    final stateAfterFirst = container.read(syncProvider);

    // Immediate second call should be suppressed by cooldown
    await notifier.syncNow();
    final stateAfterSecond = container.read(syncProvider);

    expect(stateAfterSecond.isSyncing, false);
    expect(stateAfterSecond.statusMessage, contains('Odczekaj jeszcze'));
  });
}
```

---

## 4. Anti-Patterns to Avoid

| Anti-Pattern | Why It Fails / Risks | Approved Phase 11 Pattern |
|---|---|---|
| `Promise.all([fetchInfo, fetchAnn, fetchGrades, ...])` | Fires 8 parallel HTTP requests simultaneously. Impossible for human browsing, triggers rate limiting / bot protection. | Sequential loop with 1.0–2.5s jitter between requests (`D-05`). |
| Outdated User-Agent (`Firefox/10.0` from 2012) | Signals legacy automated scraper, trivial for Cloudflare/WAF to fingerprint and block. | Up-to-date Chrome 133 User-Agent with complete modern headers (`Accept`, `Sec-Ch-Ua`, `Sec-Fetch-*`) (`D-06`). |
| OAuth login on every execution | Re-authorizing via `api.librus.pl/OAuth/Authorization` every 15-30m floods auth endpoints. | Store serialized `CookieJar` in Firestore `librus_sessions/{login}`. Probe session via `GET /uczen/index` first (`D-07`). |
| Unconditional 24/7 cron | Scraping at 02:00 or 04:00 AM is suspicious and serves no purpose. | Quiet window (22:30–06:30) immediately terminates execution without touching Librus (`D-01`). |
| Immediate retry on HTTP 429/503 | Causes cascading IP bans and account lockout. | Persistent lock in `system_status/librus_rate_limit` backing off for 20 minutes across all tasks (`D-08`). |
| Unrestricted button clicks in Flutter UI | Users clicking "Odśwież" multiple times cause request bursts to Cloud Functions and Librus. | 120-second client-side cooldown preventing repeat requests with countdown display (`D-04`). |

---

## 5. Verification Checklist

- [ ] `functions/src/librus_client.js` uses `MODERN_BROWSER_HEADERS` and sequential fetching with randomized `sleep`.
- [ ] `functions/src/librus_client.js` provides `exportSession()` and `isSessionValid()` probing.
- [ ] `functions/src/sync_service.js` reads/writes `librus_sessions` and enforces `system_status/librus_rate_limit`.
- [ ] `functions/src/schedule_evaluator.js` encapsulates quiet hours and cadence calculation.
- [ ] `functions/index.js` schedules every 15 minutes with `timeoutSeconds: 300` and consults `evaluateScheduleDecision`.
- [ ] `lib/presentation/providers/sync_provider.dart` enforces 120s cooldown and reports quiet hours context.
- [ ] Tests pass via `npm test` in `functions/` and `flutter test` in root.

## PATTERN MAPPING COMPLETE
