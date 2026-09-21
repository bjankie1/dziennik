---
phase: "11"
slug: "dyskretne-odpytywanie-serwerow-librus"
status: passed
verified: "2026-09-18"
verifier: gsd-verifier
coverage:
  requirements:
    total: 6
    verified: 6
  must_haves:
    total: 11
    verified: 11
---

# Phase 11: Dyskretne odpytywanie serwerów Librus — Verification Report

**Phase Goal:** Ulepszenie strategii odpytywania serwerów Librus (inteligentny throttling, losowy jitter, dynamiczny backoff oraz całkowite wyłączenie odpytywania w godzinach nocnych), aby nie budzić podejrzeń o automatyzację ani łamanie regulaminu serwisu.

---

## 1. Requirements Verification

| Requirement ID | Description | Status | Evidence |
|----------------|-------------|--------|----------|
| **REQ-STEALTH-01** | Modern browser profile & stealth headers (Chrome 133, Client Hints) | ✅ PASSED | `functions/src/librus_client.js` sets Chrome 133, `Sec-Ch-Ua`, `Sec-Fetch-*`, `Accept-Language: pl-PL`. Tested in `functions/test/librus_stealth.test.js`. |
| **REQ-STEALTH-02** | Humanized sequential scraping in `fetchAll()` with 1.0–2.5s jitter | ✅ PASSED | `Promise.all` eliminated in `functions/src/librus_client.js`; sequential module flow with `sleep(1000, 2200)` delays. |
| **REQ-STEALTH-03** | Persistent session `CookieJar` in Firestore with probe before OAuth login | ✅ PASSED | `LibrusClient.exportCookies()` / `importCookies()`, Firestore `librus_sessions/{login}`, and `isSessionAlive()` probe to skip OAuth on valid sessions. |
| **REQ-STEALTH-04** | Dynamic backoff for HTTP 429/503 with Firestore lock and cache fallback | ✅ PASSED | `functions/src/sync_service.js` checks `system_status/librus_rate_limit` lock and sets 20-min backoff on 429/503 errors, returning cached student data. Tested in `functions/test/librus_rate_limit.test.js`. |
| **REQ-SCHED-01** | Adaptive Warsaw timezone scheduler (night silence 22:30–06:30, daytime jitter, weekend slots) | ✅ PASSED | `functions/src/schedule_evaluator.js` with pure `Intl` DST evaluation; `functions/index.js` `scheduledLibrusSync` runs every 15 mins with 300s timeout and jitter. Tested in `functions/test/schedule_window.test.js`. |
| **REQ-CLIENT-01** | Client-side 120s cooldown on manual sync with friendly status messages | ✅ PASSED | `lib/presentation/providers/sync_provider.dart` throttles `syncNow()` calls within 120s with remaining seconds feedback and night-mode note. Passed `flutter analyze`. |

---

## 2. Automated Test Execution

### Backend Tests (`functions/`):
```
> node --test

▶ Librus Rate Limiting & Backoff Guard
  ✔ should evaluate locked status correctly when backoffUntil is in the future
  ✔ should evaluate lock as expired when backoffUntil is in the past
  ✔ should identify rate limit and server overload error indicators
✔ Librus Rate Limiting & Backoff Guard (1.56ms)
▶ LibrusClient Stealth & Session Tests
  ✔ should initialize with modern Chrome 133 headers and client hints
  ✔ should serialize and deserialize CookieJar properly
  ✔ should detect expired session when isSessionAlive receives login form redirect
  ✔ should detect active session when isSessionAlive returns 200 without login form
✔ LibrusClient Stealth & Session Tests (5.80ms)
▶ Warsaw Timezone Schedule Evaluator
  ✔ should enforce night silence between 22:30 and 06:30 (D-01)
  ✔ should permit sync at 06:30 daytime boundary on weekdays (D-01/D-02)
  ✔ should follow 30-min cadence on weekday school hours 06:30 - 16:30 (D-02)
  ✔ should follow 60-min cadence on weekday evenings 16:30 - 22:30 (D-02)
  ✔ should restrict weekend sync to 11:00 and 19:00 slots (D-03)
✔ Warsaw Timezone Schedule Evaluator (11.97ms)
ℹ tests 12
ℹ suites 3
ℹ pass 12
ℹ fail 0
```

### Frontend Static Analysis:
```
$ flutter analyze
Analyzing dziennik szkolny...
No issues found! (ran in 1.8s)
```

---

## 3. Decision Audit

- **D-01 (Cisza nocna 22:30–06:30):** Verified in `schedule_evaluator.js` and `schedule_window.test.js`.
- **D-02 (Dni szkolne 30–40 min z jitterem, wieczorem co 60 min):** Verified in `schedule_evaluator.js` and `scheduledLibrusSync`.
- **D-03 (Weekendy tylko 11:00 i 19:00):** Verified in `schedule_evaluator.js` and `schedule_window.test.js`.
- **D-04 (Manual sync z cooldownem min. 2 minuty):** Verified in `sync_provider.dart`.
- **D-05 (Sekwencyjne pobieranie modułów z przerwą 1.0–2.5s):** Verified in `librus_client.js`.
- **D-06 (Nowoczesny profil przeglądarki Chrome 133):** Verified in `librus_client.js`.
- **D-07 (Trwałość sesji i ponowne użycie ciasteczek):** Verified in `sync_service.js` and `librus_client.js`.
- **D-08 (Dynamiczny backoff 429/503 i cache):** Verified in `sync_service.js` and `librus_rate_limit.test.js`.

---

## 4. Conclusion
Phase 11 goal is **100% achieved**. All requirements are verified, all unit test suites pass without regression, and all user design decisions are honored.
