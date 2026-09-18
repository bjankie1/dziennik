---
phase: "11"
slug: "dyskretne-odpytywanie-serwerow-librus"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-18"
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest / Node built-in test & Flutter test |
| **Config file** | `functions/package.json` & `test/` |
| **Quick run command** | `cd functions && npm test` |
| **Full suite command** | `cd functions && npm test && flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd functions && npm test`
- **After every plan wave:** Run `cd functions && npm test && flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | REQ-STEALTH-01 | T-11-01 | Modern headers & stealth user-agent | unit | `npm test -- test/librus_stealth.test.js` | ❌ W0 | ⬜ pending |
| 11-01-02 | 01 | 1 | REQ-STEALTH-02 | T-11-02 | CookieJar session persistence & probe | unit | `npm test -- test/librus_session.test.js` | ❌ W0 | ⬜ pending |
| 11-01-03 | 01 | 1 | REQ-STEALTH-03 | T-11-03 | Sequential module scraping & backoff | unit | `npm test -- test/librus_rate_limit.test.js` | ❌ W0 | ⬜ pending |
| 11-02-01 | 02 | 2 | REQ-SCHED-01 | T-11-04 | Night silence & Warsaw time windowing | unit | `npm test -- test/schedule_window.test.js` | ❌ W0 | ⬜ pending |
| 11-02-02 | 02 | 2 | REQ-CLIENT-01 | T-11-05 | Client-side 2-min sync cooldown | unit | `flutter test test/presentation/providers/sync_provider_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `functions/test/schedule_window.test.js` — tests for Warsaw time windows, night silence, weekday vs weekend intervals
- [ ] `functions/test/librus_stealth.test.js` — tests for Chrome headers, cookie persistence, and sequential delay pacing
- [ ] `test/presentation/providers/sync_provider_test.dart` — tests for 120s cooldown in `SyncNotifier`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Librus on-demand sync | REQ-STEALTH-02 | Requires live credentials and network call to synergia.librus.pl | Trigger syncNow via app UI and verify logs in Cloud Functions console |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
