---
phase: 11-dyskretne-odpytywanie-serwerow-librus
plan: 01
subsystem: api
tags: [librus, scraping, stealth, rate-limiting, firestore, tough-cookie]

requires:
  - phase: 04-bezpieczny-autologin-i-trwale-powiazanie-profilu-librus
    provides: Firestore student profile and credentials persistence
provides:
  - Modern Chrome 133 browser profile with Client Hints and localized headers
  - Sequential human-paced scraping in fetchAll() with 1.0-2.5s jitter
  - CookieJar serialization and persistence in Firestore with isSessionAlive probe
  - Dynamic rate-limit backoff (20 min lock) on HTTP 429/503 and safe cache fallback
affects: [11-02-PLAN.md, functions/src/librus_client.js, functions/src/sync_service.js]

actuals:
  tokens: 1850
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns: [humanized-sequential-scraping, cookiejar-firestore-persistence, dynamic-backoff-lock]

key-files:
  created:
    - functions/test/librus_stealth.test.js
    - functions/test/librus_rate_limit.test.js
  modified:
    - functions/src/librus_client.js
    - functions/src/sync_service.js

key-decisions:
  - "Modernized User-Agent from Firefox 10 (2012) to Chrome 133 with Client Hints (D-06)"
  - "Eliminated parallel Promise.all in fetchAll() in favor of sequential calls with 1.0-2.5s random jitter (D-05)"
  - "Cached CookieJar session in Firestore librus_sessions/{login} and added isSessionAlive probe before running OAuth (D-07)"
  - "Implemented dynamic 20-min backoff lock in system_status/librus_rate_limit on 429/503 errors (D-08)"

patterns-established:
  - "Sequential humanized delay between HTTP scrapers"
  - "Session probe before re-authenticating with external portals"

requirements-completed:
  - REQ-STEALTH-01
  - REQ-STEALTH-02
  - REQ-STEALTH-03
  - REQ-STEALTH-04

coverage:
  - id: D1
    description: "Modern Chrome 133 headers and Client Hints"
    requirement: REQ-STEALTH-01
    verification:
      - kind: unit
        ref: "functions/test/librus_stealth.test.js"
        status: pass
    human_judgment: false
  - id: D2
    description: "Sequential module scraping with randomized jitter"
    requirement: REQ-STEALTH-02
    verification:
      - kind: unit
        ref: "functions/test/librus_stealth.test.js"
        status: pass
    human_judgment: false
  - id: D3
    description: "Persistent CookieJar in Firestore with isSessionAlive probe"
    requirement: REQ-STEALTH-03
    verification:
      - kind: unit
        ref: "functions/test/librus_stealth.test.js"
        status: pass
    human_judgment: false
  - id: D4
    description: "Dynamic rate-limit backoff on 429/503 with cache fallback"
    requirement: REQ-STEALTH-04
    verification:
      - kind: unit
        ref: "functions/test/librus_rate_limit.test.js"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-09-18
status: complete
---

# Phase 11: Plan 11-01 Summary

**Modern Chrome 133 stealth headers, humanized sequential request pacing with jitter, CookieJar session persistence in Firestore, and dynamic rate-limit backoff**

## Performance

- **Duration:** 8 min
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Replaced 14-year-old Firefox 10 User-Agent with Chrome 133 on Windows/macOS and full Client Hints (`Sec-Ch-Ua`, `Sec-Fetch-*`, `Accept-Language: pl-PL`).
- Replaced concurrent `Promise.all` in `fetchAll()` with sequential execution and 1.0–2.5s jitter between modules.
- Implemented `exportCookies()`, `importCookies()`, and lightweight `isSessionAlive()` probe to eliminate redundant OAuth logins.
- Added 20-minute backoff lock in `system_status/librus_rate_limit` upon receiving HTTP 429 or 503 errors, returning cached data.

## Task Commits

1. **Task 1 & 2: Modern stealth headers, cookie persistence, and sequential scraping** - `2949c1e` (feat)
2. **Task 3: Dynamic rate-limit backoff and session caching in sync_service** - `3ed592c` (feat)

## Files Created/Modified
- `functions/src/librus_client.js` - Added modern headers, `_initAxios()`, session export/import, session probe, and sequential `fetchAll()`.
- `functions/src/sync_service.js` - Integrated session restore/persist, rate-limit check, and 429/503 backoff with cache fallback.
- `functions/test/librus_stealth.test.js` - Unit tests for headers, session serialization, and probing.
- `functions/test/librus_rate_limit.test.js` - Unit tests for backoff lock evaluation and error pattern matching.

## Decisions Made
- Used `tough-cookie` built-in `serializeSync` / `deserializeSync` for zero-overhead JSON session storage.
- Preserved existing data schema so all frontend models continue deserializing without change.

## Deviations from Plan
None - plan executed exactly as specified.

## Next Phase Readiness
- Ready for Wave 2: Plan 11-02 (Adaptive Scheduler & Client Cooldown).
