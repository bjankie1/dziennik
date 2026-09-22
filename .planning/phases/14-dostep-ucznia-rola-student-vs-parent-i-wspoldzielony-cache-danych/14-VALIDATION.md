---
phase: "14"
slug: "dostep-ucznia-rola-student-vs-parent-i-wspoldzielony-cache-danych"
status: approved
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-22"
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js built-in test runner (`node --test`) & Flutter static analysis |
| **Config file** | `functions/package.json` |
| **Quick run command** | `npm test --prefix functions` |
| **Full suite command** | `npm test --prefix functions && flutter analyze` |
| **Estimated runtime** | ~4 seconds |

---

## Sampling Rate

- **After every task commit:** Run `npm test --prefix functions`
- **After every plan wave:** Run `npm test --prefix functions && flutter analyze`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | REQ-ROLE-01 | — | Obsługa ról `parent`/`student` w SharedPreferences i modelu AppUser | unit | `flutter analyze` | ✅ | ✅ green |
| 14-01-02 | 01 | 1 | REQ-ROLE-02 | T-14-01 | Endpointy `saveConnection` i `getConnection` obsługują rolę i studentLogin | unit | `node --test functions/test/user_roles.test.js` | ✅ | ✅ green |
| 14-01-03 | 01 | 1 | REQ-ROLE-03 | — | Pobieranie danych z `primaryLogin` w Firestore bez podwójnego scrapingu | unit | `node --test functions/test/shared_cache.test.js` | ✅ | ✅ green |
| 14-02-01 | 02 | 2 | REQ-ROLE-02 | — | Model i tworzenie dokumentu prośby o usprawiedliwienie w Firestore | unit | `node --test functions/test/justification_requests.test.js` | ✅ | ✅ green |
| 14-02-02 | 02 | 2 | REQ-ROLE-02 | T-14-02 | Weryfikacja PIN-u rodzica przy zatwierdzaniu prośby ucznia | unit | `node --test functions/test/justification_requests.test.js` | ✅ | ✅ green |
| 14-02-03 | 02 | 2 | REQ-ROLE-02 | — | Modal ucznia bez PIN-u oraz widżet powiadomień rodzica na Pulpicie | visual / unit | `flutter analyze` | ✅ | ✅ green |
| 14-03-01 | 03 | 3 | REQ-ROLE-01 | — | Badge roli w nagłówku i selektor profilu w logowaniu | visual | `flutter analyze` | ✅ | ✅ green |
| 14-03-02 | 03 | 3 | REQ-ROLE-01 | T-14-03 | Wysyłanie wiadomości z sesji Librus ucznia w sendMessage | unit | `node --test functions/test/student_messages.test.js` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `functions/test/user_roles.test.js` — testy endpointów powiązania i odczytu ról
- [x] `functions/test/shared_cache.test.js` — testy współdzielenia cache w Firestore
- [x] `functions/test/justification_requests.test.js` — testy maszyny stanów próśb o usprawiedliwienie i autoryzacji PIN
- [x] `functions/test/student_messages.test.js` — testy wyboru sesji ucznia przy wysyłce wiadomości

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Wygląd badge'a roli w nagłówku | REQ-ROLE-01 | Renderowanie w przeglądarce | Zaloguj się jako uczeń, sprawdź czy obok awatara widnieje fioletowa pigułka „Uczeń” |
| Obieg prośby o usprawiedliwienie | REQ-ROLE-02 | Interakcja dwuosobowa (uczeń → rodzic) | Złóż prośbę jako uczeń, przełącz na rodzica, zatwierdź PIN-em i sprawdź zmianę statusu na kafelku |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-09-22
