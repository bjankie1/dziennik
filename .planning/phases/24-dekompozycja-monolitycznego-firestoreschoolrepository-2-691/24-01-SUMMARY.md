---
phase: 24-dekompozycja-monolitycznego-firestoreschoolrepository-2-691
plan: 01
subsystem: database
tags: [flutter, dart, firestore, repository, cache, shared_preferences, unit-testing]

# Dependency graph
requires:
  - phase: 23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni
    provides: Partial PIN approval (selectedRecordIds) and AttendanceRecord resolution in JustificationRequest
provides:
  - Instance-scoped SchoolDataCacheManager with 2-minute TTL memory cache, lazy FirebaseFirestore resolution, injectable http.Client, and isolated SharedPreferences override maps
  - FirestoreGradesDataSource for subjects and recent grades parsing
  - FirestoreAttendanceDataSource for attendance records, timetable slot enrichment, stats, and Librus e-Usprawiedliwienia
  - FirestoreJustificationsDataSource for student justification requests and full/partial parent PIN approval
  - Unit test suite in test/data/repositories/firestore_cache_and_attendance_test.dart
affects: [24-02-PLAN, firestore_school_repository, school_providers]

# Actuals (#2632)
actuals:
  tokens: 18423
  tasks: 2
  commits: 2
plan_head_before: 6dc0cc502b4d6ff4e04603c0c5c2e6feb1d6bb54

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Instance-scoped repository cache & overrides (SchoolDataCacheManager) eliminating static mutable maps"
    - "Lazy FirebaseFirestore getter and injectable http.Client for pure Dart unit testability without Firebase.initializeApp()"
    - "Domain-specific *DataSource decomposition in lib/data/repositories/firestore/"

key-files:
  created:
    - lib/data/repositories/firestore/school_data_cache_manager.dart
    - lib/data/repositories/firestore/firestore_grades_data_source.dart
    - lib/data/repositories/firestore/firestore_attendance_data_source.dart
    - lib/data/repositories/firestore/firestore_justifications_data_source.dart
    - test/data/repositories/firestore_cache_and_attendance_test.dart
  modified: []

key-decisions:
  - "Moved all 5 static override fields (_localReadOverrides, _readOverridesLoaded, _localJustificationOverrides, _justificationOverridesLoaded, _localDriveAttachmentsOverrides) and UniqueKey._c counter into instance-scoped fields on SchoolDataCacheManager to guarantee zero state leakage across repository instances and unit tests (REQ-ARCH-04)"
  - "Resolved FirebaseFirestore.instance lazily via getter and injected http.Client so domain data sources can be unit-tested in pure Dart with MockClient and seedMemoryCache without requiring Firebase.initializeApp()"

patterns-established:
  - "SchoolDataCacheManager: Shared instance-scoped cache & local override coordinator injected into all domain DataSources"
  - "Directed Acyclic Graph (DAG) between DataSources: FirestoreJustificationsDataSource depends on FirestoreAttendanceDataSource and SchoolDataCacheManager without cyclic repository references"

requirements-completed:
  - REQ-ARCH-03
  - REQ-ARCH-04

coverage:
  - id: D1
    description: "SchoolDataCacheManager encapsulates the 2-minute TTL _memoryCache, targetLogin resolution, lazy FirebaseFirestore access, injectable http.Client, and instance-scoped override maps with zero static mutable maps"
    requirement: REQ-ARCH-04
    verification:
      - kind: unit
        ref: "test/data/repositories/firestore_cache_and_attendance_test.dart#SchoolDataCacheManager — Instance-Scoped Cache & Overrides (REQ-ARCH-04)"
        status: pass
    human_judgment: false
  - id: D2
    description: "FirestoreGradesDataSource implements getSubjects() and getRecentGrades() with subject filtering, timetable teacher fallback lookup, grade percentage estimation, and Komentarz: tooltip parsing"
    requirement: REQ-ARCH-03
    verification:
      - kind: unit
        ref: "test/data/repositories/firestore_cache_and_attendance_test.dart#FirestoreGradesDataSource (REQ-ARCH-03)"
        status: pass
    human_judgment: false
  - id: D3
    description: "FirestoreAttendanceDataSource implements getAttendanceRecords(), getAttendanceStats(), submitJustification(), and cancelJustification() with timetable slot enrichment and instance-scoped justification overrides"
    requirement: REQ-ARCH-03
    verification:
      - kind: unit
        ref: "test/data/repositories/firestore_cache_and_attendance_test.dart#FirestoreAttendanceDataSource (REQ-ARCH-03, REQ-ARCH-04)"
        status: pass
    human_judgment: false
  - id: D4
    description: "FirestoreJustificationsDataSource implements requestJustification(), getJustificationRequests(), approveJustificationRequest(requestId, pin, {selectedRecordIds}), rejectJustificationRequest(), and respondJustificationRequest()"
    requirement: REQ-ARCH-03
    verification:
      - kind: unit
        ref: "test/data/repositories/firestore_cache_and_attendance_test.dart#FirestoreJustificationsDataSource — Full & Partial PIN Approval (REQ-ARCH-03)"
        status: pass
    human_judgment: false

# Metrics
duration: 6 min
completed: 2026-10-03
status: complete
---

# Phase 24 Plan 01: Extract SchoolDataCacheManager & Academic/Attendance/Justification DataSources Summary

**Extracted instance-scoped `SchoolDataCacheManager` and domain data sources (`FirestoreGradesDataSource`, `FirestoreAttendanceDataSource`, `FirestoreJustificationsDataSource`) into `lib/data/repositories/firestore/` with unit tests proving cache isolation and partial/full PIN approval**

## Performance

- **Duration:** 6 min
- **Started:** 2026-10-03T17:21:31Z
- **Completed:** 2026-10-03T17:27:54Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Created `SchoolDataCacheManager` encapsulating the 2-minute TTL `_memoryCache`, `targetLogin` resolution, lazy `FirebaseFirestore` access, injectable `http.Client`, and instance-scoped override maps (`_localReadOverrides`, `_localJustificationOverrides`, `_localDriveAttachmentsOverrides`, and `_idCounter`) with zero static mutable maps (`REQ-ARCH-04`).
- Created `FirestoreGradesDataSource` implementing `getSubjects()` and `getRecentGrades()` with invalid-row filtering, timetable teacher fallback lookup, grade percentage estimation, and `Komentarz:` tooltip extraction (`REQ-ARCH-03`).
- Created `FirestoreAttendanceDataSource` implementing `getAttendanceRecords()`, `getAttendanceStats()`, `submitJustification()`, and `cancelJustification()` with 3-tier timetable slot enrichment and instance-scoped justification overrides (`REQ-ARCH-03`, `REQ-ARCH-04`).
- Created `FirestoreJustificationsDataSource` implementing `requestJustification()`, `getJustificationRequests()`, `approveJustificationRequest(requestId, pin, {selectedRecordIds})`, `rejectJustificationRequest()`, and `respondJustificationRequest()` (`REQ-ARCH-03`).
- Added 7 unit tests in `test/data/repositories/firestore_cache_and_attendance_test.dart` verifying instance-scoped cache/override isolation across instances and `SharedPreferences` resets, TTL cache hits/invalidation, grades parsing, attendance timetable enrichment, and full/partial PIN justification approval.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create SchoolDataCacheManager & FirestoreGradesDataSource** - `a680e0f` (`feat`)
2. **Task 2: Create FirestoreAttendanceDataSource, FirestoreJustificationsDataSource & Unit Tests** - `69d85be` (`feat`)

## Files Created/Modified

- `lib/data/repositories/firestore/school_data_cache_manager.dart` - Instance-scoped student document cache and `SharedPreferences` override manager (437 LOC)
- `lib/data/repositories/firestore/firestore_grades_data_source.dart` - Domain data source for subjects, grades, and recent grades (209 LOC)
- `lib/data/repositories/firestore/firestore_attendance_data_source.dart` - Domain data source for attendance records, timetable enrichment, stats, and Librus e-Usprawiedliwienia (428 LOC)
- `lib/data/repositories/firestore/firestore_justifications_data_source.dart` - Domain data source for student justification requests and parent PIN approval/rejection/Q&A (388 LOC)
- `test/data/repositories/firestore_cache_and_attendance_test.dart` - Unit tests for cache isolation, TTL behavior, grades, attendance, and justifications data sources (602 LOC)

## Decisions Made

- Replaced all `static` mutable override maps and boolean flags with instance fields on `SchoolDataCacheManager` so each repository/cache manager instance has isolated state in memory and reloads cleanly when `SharedPreferences` is reset in unit tests.
- Used lazy `FirebaseFirestore` resolution (`_firestoreOverride ?? FirebaseFirestore.instance`) and injectable `http.Client` across `SchoolDataCacheManager` and the domain data sources so unit tests execute purely in Dart without `Firebase.initializeApp()`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for `24-02-PLAN.md`: extract `FirestoreMessagesDataSource` and `FirestoreScheduleDataSource`, and refactor `FirestoreSchoolRepository` into a `< 250 LOC` facade delegating all 30 `SchoolRepository` methods to `SchoolDataCacheManager` and the 5 domain `*DataSource` classes.

## Self-Check: PASSED

- FOUND: `lib/data/repositories/firestore/school_data_cache_manager.dart`
- FOUND: `lib/data/repositories/firestore/firestore_grades_data_source.dart`
- FOUND: `lib/data/repositories/firestore/firestore_attendance_data_source.dart`
- FOUND: `lib/data/repositories/firestore/firestore_justifications_data_source.dart`
- FOUND: `test/data/repositories/firestore_cache_and_attendance_test.dart`
- FOUND: commit `a680e0f`
- FOUND: commit `69d85be`

---
*Phase: 24-dekompozycja-monolitycznego-firestoreschoolrepository-2-691*
*Completed: 2026-10-03*
