# Testing Strategy

**Analysis Date:** 2026-09-15
**Project:** EduSync

## Frameworks
- **Flutter Unit & Widget Tests:** `flutter_test` (built-in SDK).
- **Backend Node.js:** Node test runners & manual verification scripts in `functions/` and scratch directories.

## Test Types
1. **Static Analysis:**
   - `flutter analyze`: must pass with zero issues.
2. **Backend Handshake & Scraper Verification:**
   - Diagnostic scripts verifying OAuth flow, cookie persistence, and Synergia HTML selectors.
3. **Integration Verification:**
   - Cloud Functions invocation (`/api/syncNow`, `/api/studentData`).
   - Firestore write and read tests.
4. **End-to-End Web Verification:**
   - Web release builds (`flutter build web --release --pwa-strategy=none`).
   - Live smoke test on `https://lepsza-szkola.web.app`.

*Codebase analysis: 2026-09-15*
