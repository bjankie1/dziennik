# Phase 14 Plan 03: Role Badge, Connect Screen Selection & Student Message Session Summary

**Plan ID:** 14-03  
**Phase:** 14 — Dostęp ucznia (rola student vs parent) i współdzielony cache danych  
**Status:** Completed  
**Completed Date:** 2026-09-22  

---

## 1. Executive Summary

Plan 14-03 completes Phase 14 by finalizing the visual identity and role selection mechanisms for the student account (REQ-ROLE-01, D-01, D-02) and integrating the independent student Librus session for outgoing messages:

1. **Automated Backend Test Scaffolding (`functions/test/student_messages.test.js` & `functions/src/message_service.js`):**
   - Unit tests covering session resolution: `role === 'student'` and `studentLogin` select the isolated student session key, while `role === 'parent'` resolves the parent session key.
   - Response metadata verification: ensures outgoing messages are explicitly attributed to *Oskar Jankiewicz (uczeń)* vs *Bartosz Jankiewicz (rodzic)* (T-14-05, T-14-06).

2. **Cloud Functions Backend Integration (`functions/index.js` `exports.sendMessage`):**
   - Reads `role` and `studentLogin` from requests.
   - Retrieves active session cookie jar from `librus_sessions/{sessionKey}`.
   - Dispatches message with the authenticated client or simulation mode attributed to the appropriate sender.

3. **Visual Role Badge in Desktop Header & Profile Sheet:**
   - Converted `AppDesktopHeader` to `ConsumerWidget` and added a prominent role badge chip (`🎓 Uczeń` vs `Rodzic`) in the desktop profile chip.
   - Updated `_showProfileSheet()` in `lib/presentation/screens/main_navigation_screen.dart` to display the active role, email, and clear permission description card.

4. **Account Role Selector in `LibrusConnectScreen`:**
   - Added `SegmentedButton<UserRole>` above the credentials form with `👨‍👩‍👦 Konto Rodzica` and `🎓 Konto Ucznia (Oskar)`.
   - Added dynamic subtitle card explaining the active permissions for the selected role.
   - Wired `_handleConnect` and `_handleUseDemo` to pass `_selectedRole` and update `AppUserNotifier`.

---

## 2. Tasks Completed

| Task ID | Description | Status |
|---|---|---|
| **14-03-01** | Backend test suite for student message session (`student_messages.test.js`, `message_service.js`) | Done |
| **14-03-02** | Visual role badge in `AppDesktopHeader` & Profile Sheet in `main_navigation_screen.dart` | Done |
| **14-03-03** | Account role selector `SegmentedButton<UserRole>` in `LibrusConnectScreen` | Done |
| **14-03-04** | Student message session support in `functions/index.js` `sendMessage` | Done |
| **14-03-05** | Full phase test suite execution and validation sign-off (`14-VALIDATION.md`) | Done |

---

## 3. Verification & Quality Gates

- **Backend Unit Tests:**  
  `npm test --prefix functions`  
  - 51 tests across 19 test suites passing cleanly.
- **Flutter Static Analysis:**  
  `flutter analyze`  
  - 0 issues found.
- **Validation Sign-Off:**  
  - `14-VALIDATION.md` signed off as approved and Nyquist-compliant.

---

## 4. Next Steps

With all 3 plans of Phase 14 (`14-01`, `14-02`, `14-03`) completed:
- Execute verification of Phase 14.
- Generate `14-SUMMARY.md`.
- Mark Phase 14 as complete in `.planning/STATE.md` and `.planning/ROADMAP.md`.
- Transition to Phase 15 (Smart To-Do & Bento Grid Widget).
