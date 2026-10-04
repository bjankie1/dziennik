---
phase: "26"
slug: "pe-na-tre-wiadomo-ci-i-og-osze-oraz-linki-do-za-cznik-w-w-po"
status: ready
nyquist_compliant: true
wave_0_complete: false
created: "2026-10-04"
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js built-in test runner (`node:test` + `node:assert/strict`) |
| **Config file** | `functions/package.json` (`"scripts": { "test": "node --test" }`) |
| **Quick run command** | `node --test functions/test/telegram_notifications.test.js functions/test/justification_notifications.test.js functions/test/message_body_indexing.test.js` |
| **Full suite command** | `npm --prefix functions test` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `node --test functions/test/telegram_notifications.test.js functions/test/justification_notifications.test.js functions/test/message_body_indexing.test.js`
- **After every plan wave:** Run `npm --prefix functions test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-01-01 | 01 | 1 | REQ-NOTIF-TG-MSG-01, REQ-NOTIF-TG-ANN-01, REQ-NOTIF-TG-ATT-01 | T-26-01, T-26-03 | Pre-hydration of message details & multiline extraction without breaking `maxIncrementalFetch` | unit | `node --test functions/test/message_body_indexing.test.js functions/test/justification_notifications.test.js` | ✅ | ⬜ pending |
| 26-01-02 | 01 | 1 | REQ-NOTIF-TG-MSG-01, REQ-NOTIF-TG-ANN-01, REQ-NOTIF-TG-ATT-01 | T-26-01, T-26-02 | Escapes `<`, `>`, `&` after plain-text truncation, formats `/api/downloadAttachment` links, keeps total HTML <= 4096 chars | unit | `node --test functions/test/telegram_notifications.test.js functions/test/justification_notifications.test.js functions/test/message_body_indexing.test.js` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `functions/test/telegram_notifications.test.js` — unit tests for `REQ-NOTIF-TG-MSG-01`, `REQ-NOTIF-TG-ANN-01`, `REQ-NOTIF-TG-ATT-01`, HTML escaping, truncation within 4096 chars, and `LibrusClient` multiline message extraction

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
