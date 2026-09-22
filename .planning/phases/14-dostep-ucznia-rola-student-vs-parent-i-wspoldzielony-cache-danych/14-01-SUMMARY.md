# Phase 14 Plan 01: Data Layer & Backend Roles & Shared Cache Summary

**Plan ID:** 14-01  
**Phase:** 14 — Dostęp ucznia (rola student vs parent) i współdzielony cache danych  
**Status:** Completed  
**Completed Date:** 2026-09-22  

---

## 1. Executive Summary

Plan 14-01 successfully established the foundational multi-user role model (`UserRole.parent` vs `UserRole.student`), persistent state management in `AppUser`, and the Single Source of Truth shared data cache for EduSync:

1. **Automated Backend Tests (`functions/test/user_roles.test.js` & `functions/test/shared_cache.test.js`):**
   - Verified role parsing (`parent` default vs `student`), payload formatting in `saveConnection`, and rejection of direct parental e-justifications when attempted with a `student` role.
   - Verified document key resolution routing student data requests directly to `primaryLogin` without triggering secondary Librus scraping jobs.
2. **Domain & State Layer (`UserRole` & `AppUser`):**
   - Introduced `UserRole` enum (`parent`, `student`) with helpers `isParent`, `isStudent`, `displayName`, and safe parser `fromString`.
   - Extended `AppUser` and `AppUserNotifier` with `role`, `studentLogin`, `primaryLogin`, `familyId`, and backed by `SharedPreferences` for zero-latency UI rehydration on page reload.
3. **Cloud Functions Backend Endpoints (`functions/index.js` & `functions/src/sync_service.js`):**
   - Updated `saveConnection` to capture and persist `role`, `studentLogin`, `primaryLogin`, and `familyId` into `users/{userId}` in Firestore (`{ merge: true }`).
   - Updated `getConnection` to return role metadata along with connection state.
   - Updated `getStudentData` and `syncStudentData` to serve directly from the central cache (`students/{primaryLogin}`) for student accounts, eliminating redundant web scraping.
4. **Data Layer Integration (`LibrusConnectionService` & `FirestoreSchoolRepository`):**
   - Updated `LibrusConnectionService` to cache and parse role metadata and provide `getSavedAppUser()`.
   - Updated `FirestoreSchoolRepository._getStudentData()` to route student queries to `appUser.primaryLogin`, maintaining full parity across both accounts with zero duplicate scraping.

---

## 2. Tasks Completed

| Task ID | Description | Commits | Status |
|---|---|---|---|
| **14-01-01** | Scaffolding automated backend test suites for roles and shared cache (`user_roles.test.js`, `shared_cache.test.js`) | `d7a0b5a` | Done |
| **14-01-02** | Domain model `UserRole` and `AppUser` state with SharedPreferences persistence | `5abef14` | Done |
| **14-01-03** | Cloud Functions backend role support in `saveConnection`, `getConnection`, and `sync_service` | `2f6336f` | Done |
| **14-01-04** | Integration in `LibrusConnectionService` & `FirestoreSchoolRepository` (Single Source of Truth) | `3f8dd2f` | Done |

---

## 3. Verification & Quality Gates

- **Backend Unit Tests:**  
  `npm test --prefix functions`  
  - 33 tests across 12 test suites passing cleanly (duration: ~200ms).
- **Flutter Static Analysis:**  
  `flutter analyze`  
  - No issues found (0 warnings, 0 errors).

---

## 4. Key Files Created / Modified

- [`functions/test/user_roles.test.js`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/test/user_roles.test.js) — Unit tests for role parsing, connection payloads, and parental PIN authorization.
- [`functions/test/shared_cache.test.js`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/test/shared_cache.test.js) — Unit tests for shared cache doc resolution and scraping prevention.
- [`lib/domain/models/user_role.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/domain/models/user_role.dart) — `UserRole` enum (`parent`, `student`) with helpers.
- [`lib/presentation/providers/auth_providers.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/providers/auth_providers.dart) — Extended `AppUser` and `AppUserNotifier` with role persistence.
- [`functions/index.js`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/index.js) — Role parameters in `saveConnection`, `getConnection`, `getStudentData`, and `syncNow`.
- [`functions/src/sync_service.js`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/src/sync_service.js) — Helpers `resolveCacheDocumentId`, `shouldDispatchLibrusScrape`, and student cache guard.
- [`lib/data/services/librus_connection_service.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/data/services/librus_connection_service.dart) — SharedPreferences role persistence and `getSavedAppUser()`.
- [`lib/data/repositories/firestore_school_repository.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/data/repositories/firestore_school_repository.dart) — Single Source of Truth routing to `primaryLogin`.
