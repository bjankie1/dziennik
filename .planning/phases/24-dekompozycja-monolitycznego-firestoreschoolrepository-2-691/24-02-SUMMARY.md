---
phase: 24-dekompozycja-monolitycznego-firestoreschoolrepository-2-691
plan: 02
subsystem: database
tags: [flutter, dart, firestore, repository, facade, messages, google-drive, schedule, unit-testing]

# Dependency graph
requires:
  - phase: 24-01
    provides: Instance-scoped SchoolDataCacheManager, FirestoreGradesDataSource, FirestoreAttendanceDataSource, and FirestoreJustificationsDataSource
provides:
  - FirestoreMessagesDataSource for message threads, sender/role/signature parsing, parseMessageDate, read overrides, message details, and all 6 Google Drive folder/attachment methods
  - FirestoreScheduleDataSource for student profile, upcoming exams, timetable parsing, Warsaw trip week logic, announcements, and teacher aggregation
  - Clean 242 LOC FirestoreSchoolRepository facade implementing all 30 SchoolRepository methods with zero static mutable maps
  - Unit test suite in test/data/repositories/firestore_messages_and_schedule_test.dart
affects: [firestore_school_repository, school_providers, messages_screen, schedule_screen]

# Actuals (#2632)
actuals:
  tokens: 20794
  tasks: 2
  commits: 2
plan_head_before: 6213dcff58ea81b3cb797ffc3fa4482d21526f4f

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure delegating repository facade (< 250 LOC) wiring an instance-scoped SchoolDataCacheManager across 5 domain DataSources in a 4-level DAG"
    - "Static forwarder preservation (FirestoreSchoolRepository.parseMessageDate -> FirestoreMessagesDataSource.parseMessageDate) for zero-breaking-change compatibility"

key-files:
  created:
    - lib/data/repositories/firestore/firestore_messages_data_source.dart
    - lib/data/repositories/firestore/firestore_schedule_data_source.dart
    - test/data/repositories/firestore_messages_and_schedule_test.dart
  modified:
    - lib/data/repositories/firestore_school_repository.dart

key-decisions:
  - "Reduced FirestoreSchoolRepository from 2,691 LOC to a 242 LOC facade that instantiates a shared instance-scoped SchoolDataCacheManager and wires it into the 5 domain DataSources while accepting optional overrides for every dependency"
  - "Preserved FirestoreSchoolRepository.parseMessageDate as a static forwarder to FirestoreMessagesDataSource.parseMessageDate so existing callers and tests pass with zero modifications"

patterns-established:
  - "4-level Directed Acyclic Graph (DAG) in lib/data/repositories/firestore/: Level 0 SchoolDataCacheManager -> Level 1 FirestoreGradesDataSource, FirestoreAttendanceDataSource, FirestoreMessagesDataSource -> Level 2 FirestoreJustificationsDataSource, FirestoreScheduleDataSource -> Level 3 FirestoreSchoolRepository facade"

requirements-completed:
  - REQ-ARCH-03
  - REQ-ARCH-04

coverage:
  - id: D1
    description: "FirestoreMessagesDataSource implements getMessages(), static parseMessageDate(), sendMessage(), getMessageBody(), getMessageDetails(), markMessageAsRead(), markAllMessagesAsRead(), and all 6 Google Drive folder/attachment methods using SchoolDataCacheManager"
    requirement: REQ-ARCH-03
    verification:
      - kind: unit
        ref: "test/data/repositories/firestore_messages_and_schedule_test.dart#FirestoreMessagesDataSource (REQ-ARCH-03, REQ-ARCH-04)"
        status: pass
    human_judgment: false
  - id: D2
    description: "FirestoreScheduleDataSource implements getStudentProfile(), getUpcomingExam(), getTodaySchedule(), getScheduleForDay(), getWeekSchedule(), getAnnouncements(), and getTeachers() along with cleanEventSubjectName, extractAllEvents, and parseTimetableForDay"
    requirement: REQ-ARCH-03
    verification:
      - kind: unit
        ref: "test/data/repositories/firestore_messages_and_schedule_test.dart#FirestoreScheduleDataSource (REQ-ARCH-03)"
        status: pass
    human_judgment: false
  - id: D3
    description: "FirestoreSchoolRepository is reduced from 2,691 LOC to 242 LOC (< 250 LOC) as a clean facade delegating all 30 SchoolRepository methods to the 5 domain DataSources with zero static mutable maps and full instance isolation"
    requirement: REQ-ARCH-04
    verification:
      - kind: unit
        ref: "test/data/repositories/firestore_messages_and_schedule_test.dart#FirestoreSchoolRepository Facade & Isolation (REQ-ARCH-03, REQ-ARCH-04)"
        status: pass
    human_judgment: false

# Metrics
duration: 9 min
completed: 2026-10-03
status: complete
---

# Phase 24 Plan 02: Extract FirestoreMessagesDataSource & FirestoreScheduleDataSource and Refactor FirestoreSchoolRepository Facade Summary

**Extracted `FirestoreMessagesDataSource` and `FirestoreScheduleDataSource` into `lib/data/repositories/firestore/`, reduced `FirestoreSchoolRepository` from 2,691 LOC to a 242 LOC facade with zero static mutable maps, and added unit tests verifying message/Drive operations, schedule/exam resolution, and repository instance isolation**

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-03T17:30:09Z
- **Completed:** 2026-10-03T17:39:48Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Created `FirestoreMessagesDataSource` implementing `getMessages()`, `parseMessageDate()`, `sendMessage()`, `getMessageBody()`, `getMessageDetails()`, `markMessageAsRead()`, `markAllMessagesAsRead()`, and all 6 Google Drive folder/attachment methods (`getDefaultDriveFolder`, `setDefaultDriveFolder`, `saveAttachmentToDrive`, `listDriveFolders`, `createDriveFolder`, `moveDriveAttachment`) backed by `SchoolDataCacheManager` (`REQ-ARCH-03`, `REQ-ARCH-04`).
- Created `FirestoreScheduleDataSource` implementing `getStudentProfile()`, `cleanEventSubjectName()`, `getUpcomingExam()`, `getTodaySchedule()`, `getScheduleForDay()`, `getWeekSchedule()`, `getAnnouncements()`, and `getTeachers()` with Warsaw school trip week (`2026-09-14`) handling, Terminarz exam/quiz enrichment, and attendance overlay on `LessonSlot` (`REQ-ARCH-03`).
- Refactored `lib/data/repositories/firestore_school_repository.dart` from 2,691 LOC down to 242 LOC (`< 250 LOC`) as a clean facade implementing all 30 `SchoolRepository` methods, removing all `static final Map` fields and the top-level `UniqueKey` class while retaining `FirestoreSchoolRepository.parseMessageDate` (`REQ-ARCH-03`, `REQ-ARCH-04`).
- Added 9 unit tests in `test/data/repositories/firestore_messages_and_schedule_test.dart` and verified that all 42 tests across `test/data/repositories/`, `test/presentation/screens/messages_timestamp_test.dart`, `test/attendance_pending_requests_test.dart`, and `test/message_attachments_test.dart` pass alongside `flutter analyze` with 0 issues.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create FirestoreMessagesDataSource & FirestoreScheduleDataSource** - `cba718e` (`feat`)
2. **Task 2: Refactor FirestoreSchoolRepository to < 250 LOC Facade & Add Unit Tests** - `92737ec` (`refactor`)

## Files Created/Modified

- `lib/data/repositories/firestore/firestore_messages_data_source.dart` - Domain data source for messages, read overrides, details, and Google Drive integration (859 LOC)
- `lib/data/repositories/firestore/firestore_schedule_data_source.dart` - Domain data source for student profile, upcoming exams, timetable, announcements, and teachers (732 LOC)
- `lib/data/repositories/firestore_school_repository.dart` - Clean delegating `SchoolRepository` facade (242 LOC, reduced from 2,691 LOC)
- `test/data/repositories/firestore_messages_and_schedule_test.dart` - Unit tests for messages data source, schedule data source, and repository facade isolation (582 LOC)

## Decisions Made

- Wired a single instance-scoped `SchoolDataCacheManager` inside `FirestoreSchoolRepository`'s constructor and passed it into all 5 domain `*DataSource` instances so in-memory cache mutations (`markMessageAsRead`, `saveAttachmentToDrive`, `submitJustification`, `approveJustificationRequest`) remain immediately visible across domain services within a repository instance without any `static` state.
- Kept `FirestoreSchoolRepository.parseMessageDate` as a one-line static forwarder to `FirestoreMessagesDataSource.parseMessageDate` so `test/presentation/screens/messages_timestamp_test.dart` and any external callers require zero modifications.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 24 (`REQ-ARCH-03`, `REQ-ARCH-04`) is 100% complete: `FirestoreSchoolRepository` is decomposed into `SchoolDataCacheManager` + 5 domain `*DataSource` classes behind a `< 250 LOC` facade with zero static mutable maps and full unit test coverage.
- Ready for Phase 19 (Raporty tygodniowe) or `/gsd-verify-work`.

## Self-Check: PASSED

- FOUND: `lib/data/repositories/firestore/firestore_messages_data_source.dart`
- FOUND: `lib/data/repositories/firestore/firestore_schedule_data_source.dart`
- FOUND: `lib/data/repositories/firestore_school_repository.dart` (242 LOC < 250 LOC)
- FOUND: `test/data/repositories/firestore_messages_and_schedule_test.dart`
- FOUND: commit `cba718e`
- FOUND: commit `92737ec`

---
*Phase: 24-dekompozycja-monolitycznego-firestoreschoolrepository-2-691*
*Completed: 2026-10-03*
