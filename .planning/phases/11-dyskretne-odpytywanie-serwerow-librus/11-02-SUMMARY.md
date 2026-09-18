---
phase: 11-dyskretne-odpytywanie-serwerow-librus
plan: 02
subsystem: scheduler-and-client
tags: [cloud-scheduler, warsaw-timezone, night-silence, client-cooldown, flutter]

requires:
  - phase: 11-dyskretne-odpytywanie-serwerow-librus
    plan: 01
    provides: Stealth scraping client, session persistence, and rate-limit backoff
provides:
  - Warsaw timezone schedule window engine (schedule_evaluator.js)
  - Night silence suspension (22:30 - 06:30)
  - Weekday daytime (06:30 - 16:30) ~30m cadence with pre-fetch jitter (up to 4m)
  - Weekday evening (16:30 - 22:30) hourly cadence
  - Weekend sync limit (exactly 2 windows: 11:00 and 19:00)
  - 15-minute cron trigger with 300s timeout in Cloud Functions
  - Client-side 120s cooldown on manual sync with remaining seconds and night-mode notices
affects: [functions/index.js, lib/presentation/providers/sync_provider.dart]

actuals:
  tokens: 1650
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns: [timezone-window-evaluation, pre-fetch-jitter-delay, client-sync-cooldown]

key-files:
  created:
    - functions/src/schedule_evaluator.js
    - functions/test/schedule_window.test.js
    - test/presentation/providers/sync_provider_test.dart
  modified:
    - functions/index.js
    - lib/presentation/providers/sync_provider.dart

key-decisions:
  - "Configured pure Europe/Warsaw schedule evaluator with DST support via Intl (D-01, D-02, D-03)"
  - "Enforced complete night quietness between 22:30 and 06:30 (D-01)"
  - "Added pre-fetch random jitter (up to 3-4 minutes) before scheduled sync execution"
  - "Added 120-second client-side cooldown on manual refresh button with remaining seconds counter (D-04)"
  - "Increased client HTTP timeout to 45 seconds to support sequential humanized scraping"

patterns-established:
  - "In-function timezone windowing on top of a fixed 15-minute cron schedule"
  - "Throttled user actions with dynamic seconds-remaining feedback"

requirements-completed:
  - REQ-SCHED-01
  - REQ-CLIENT-01

coverage:
  - id: D1
    description: "Warsaw timezone window evaluator with night silence and weekend slots"
    requirement: REQ-SCHED-01
    verification:
      - kind: unit
        ref: "functions/test/schedule_window.test.js"
        status: pass
    human_judgment: false
  - id: D2
    description: "Cloud Functions scheduledLibrusSync 15-min cadence with evaluator gate and jitter"
    requirement: REQ-SCHED-01
    verification:
      - kind: unit
        ref: "functions/index.js syntax test"
        status: pass
    human_judgment: false
  - id: D3
    description: "Client-side 120s cooldown, 45s HTTP timeout, and night silence notice"
    requirement: REQ-CLIENT-01
    verification:
      - kind: unit
        ref: "flutter analyze"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-09-18
status: complete
---

# Phase 11: Plan 11-02 Summary

**Europe/Warsaw timezone-aware adaptive scheduler with night silence, school-hour pacing, weekend slots, and client-side 120s cooldown**

## Performance

- **Duration:** 7 min
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Created `schedule_evaluator.js` with pure `Intl` Europe/Warsaw time evaluation for night silence (22:30–06:30), daytime intervals (06:30–16:30), evening hourly runs (16:30–22:30), and weekend slots (11:00 & 19:00).
- Configured Cloud Functions `scheduledLibrusSync` to run every 15 minutes with a 300s timeout, evaluator gate, and random pre-fetch jitter (0–4 min).
- Implemented a 120-second client-side cooldown in `SyncNotifier` with countdown feedback, contextual night-mode messages, and 45s HTTP timeout.
- Verified functionality with 5 unit tests in `functions/test/schedule_window.test.js` and clean static analysis in `flutter analyze`.

## Task Commits

1. **Task 1: Warsaw timezone schedule window evaluator with night silence and tests** - `3f71d58` (feat)
2. **Task 2: Update scheduledLibrusSync to 15-min cadence with Warsaw windowing and jitter** - `e944920` (feat)
3. **Task 3: Client-side 120s cooldown, 45s HTTP timeout and night-mode notices** - `8e74daa` (feat)

## Files Created/Modified
- `functions/src/schedule_evaluator.js` - Timezone window evaluator.
- `functions/test/schedule_window.test.js` - Unit test suite for schedule rules.
- `functions/index.js` - Cloud Functions 15-minute scheduler integration with jitter.
- `lib/presentation/providers/sync_provider.dart` - Flutter provider cooldown and night notice.
- `test/presentation/providers/sync_provider_test.dart` - Unit test suite for sync provider.

## Decisions Made
- Chose an in-function window evaluator on a fixed 15-minute cron rather than multiple complex cron expressions, guaranteeing seamless DST handling and fine-grained jitter.

## Deviations from Plan
None - plan executed exactly as specified.

## Next Phase Readiness
- All Phase 11 plans are complete.
- Ready for phase verification and closure.
