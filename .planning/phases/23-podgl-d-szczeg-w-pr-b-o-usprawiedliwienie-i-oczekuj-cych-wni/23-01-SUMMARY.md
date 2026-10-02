---
phase: 23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni
plan: 01
subsystem: api
tags: [flutter, riverpod, firestore, cloud-functions, attendance, justifications, librus]

requires:
  - phase: 14.1-czat-rodzinny-i-dwukierunkowy-dialog-usprawiedliwie
    provides: Student justification requests, PIN parental review, and two-way Q&A dialogue
provides:
  - Partial lesson approval (selectedRecordIds, selectedLessonNumbers, hoursByDate, dateFrom, dateTo) in Cloud Functions processParentReview and formatLibrusJustificationPayload
  - JustificationRequest helpers (effectiveStudentName, resolveAttendanceRecords, groupRecordsByDay, formatPolishDayHeader, formatDateRangeSummary)
  - Student profile name attribution ('Oskar Jankiewicz') in FirestoreSchoolRepository.requestJustification and respondJustificationRequest
  - AttendanceRecord teacherName and classroom enrichment from item['teacher'] and timetable lookup in FirestoreSchoolRepository.getAttendanceRecords
  - Optional selectedRecordIds parameter across SchoolRepository, FirestoreSchoolRepository, MockSchoolRepository, and AttendanceNotifier.approveJustification
affects:
  - 23-02 (Wave 2 UI modals and banners for detailed justification requests and pending teacher applications)

actuals:
  tokens: 8108
  tasks: 2
  commits: 2
  plan_head_before: e3287b765bfbe1c3f79c581abf37c22abbde3159

tech-stack:
  added: []
  patterns:
    - "Domain-level AttendanceRecord resolution with three-tier fallback (explicit recordIds -> date + lessonNumbers -> synthetic test records)"
    - "Timetable cross-referencing in getAttendanceRecords by (dayOfWeek, lessonNumber) and subject name for teacherName and classroom enrichment"
    - "Partial approval state synchronization via _localJustificationOverrides for selectedRecordIds and deselected ID cleanup"

key-files:
  created: []
  modified:
    - functions/src/justification_service.js
    - functions/index.js
    - functions/test/justification_requests.test.js
    - lib/domain/models/justification_request.dart
    - lib/data/repositories/school_repository.dart
    - lib/data/repositories/firestore_school_repository.dart
    - lib/data/repositories/mock_school_repository.dart
    - lib/presentation/providers/school_providers.dart

key-decisions:
  - "Resolved studentName from getStudentProfile() ('Oskar Jankiewicz') when creating or responding to justification requests and added effectiveStudentName() on JustificationRequest to guard against legacy Firestore documents that saved the parent's Google displayName."
  - "Enriched AttendanceRecord in FirestoreSchoolRepository.getAttendanceRecords() by reading item['teacherName'] ?? item['teacher'] and cross-referencing data['timetable'] for missing teacherName, classroom, and subjectName."
  - "Extended processParentReview and formatLibrusJustificationPayload to accept selectedRecordIds, selectedLessonNumbers, hoursByDate, dateFrom, and dateTo so partial parental approval sends only selected lessons to Librus."

patterns-established:
  - "Three-tier lesson resolution on JustificationRequest.resolveAttendanceRecords for consistent rendering across live data, legacy date-based requests, and isolated widget tests"

requirements-completed:
  - REQ-ATT-01
  - REQ-ATT-02

coverage:
  - id: D1
    description: "Cloud Functions processParentReview and formatLibrusJustificationPayload support partial selectedRecordIds approval, empty selection rejection (400), and multi-day hoursByDate payloads"
    requirement: REQ-ATT-01
    verification:
      - kind: unit
        ref: "functions/test/justification_requests.test.js#should update recordIds, approvedRecordIds, lessonNumbers, and hoursByDate on partial approval (D-06)"
        status: pass
      - kind: unit
        ref: "functions/test/justification_requests.test.js#should preserve multi-day hoursByDate, dateFrom, and dateTo when present on requestDoc (D-06)"
        status: pass
    human_judgment: false
  - id: D2
    description: "JustificationRequest domain helpers, student profile name attribution, timetable teacher/classroom enrichment, and selectedRecordIds repository/notifier plumbing"
    requirement: REQ-ATT-02
    verification:
      - kind: unit
        ref: "flutter analyze && flutter test test/attendance_justification_modal_test.dart"
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-10-02
status: complete
---

# Phase 23 Plan 01: Backend & Repository Justification Detail Support Summary

**Partial lesson approval with multi-day `hoursByDate` in Cloud Functions, timetable teacher/classroom enrichment on `AttendanceRecord`, student profile name attribution (`Oskar Jankiewicz`), and `JustificationRequest` day-grouping helpers**

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-02T08:28:45Z
- **Completed:** 2026-10-02T08:37:30Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Extended `processParentReview` and `formatLibrusJustificationPayload` in `functions/src/justification_service.js` (and `exports.reviewJustificationRequest` in `functions/index.js`) to support partial lesson selection (`selectedRecordIds`, `selectedLessonNumbers`, `hoursByDate`, `dateFrom`, `dateTo`) and reject empty `selectedRecordIds` arrays with HTTP 400.
- Added `effectiveStudentName`, `resolveAttendanceRecords`, `groupRecordsByDay`, `formatPolishDayHeader`, and `formatDateRangeSummary` helpers to `JustificationRequest` in `lib/domain/models/justification_request.dart`.
- Fixed student name attribution in `FirestoreSchoolRepository.requestJustification` and `respondJustificationRequest` via `_resolveStudentFullName()` so requests initiated while testing under a parent's Google account use `'Oskar Jankiewicz'`.
- Enriched `AttendanceRecord` in `FirestoreSchoolRepository.getAttendanceRecords()` by reading `item['teacher']` alongside `item['teacherName']` and cross-referencing `data['timetable']` by `(dayOfWeek, lessonNumber)` and subject name to populate missing `teacherName` and `classroom` fields.
- Threaded optional `{List<String>? selectedRecordIds}` through `SchoolRepository`, `FirestoreSchoolRepository`, `MockSchoolRepository`, and `AttendanceNotifier.approveJustification`, updating `_localJustificationOverrides` only for selected lessons while reverting deselected lessons to `JustificationStatus.none`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Upgrade Cloud Functions justification_service.js and reviewJustificationRequest for Partial Lesson Approval and Multi-Day hoursByDate (D-06)** - `205e155` (feat)
2. **Task 2: Add JustificationRequest Lesson Resolution Helpers, Fix Student Profile Name Attribution, Enrich AttendanceRecord Teacher/Classroom & Thread selectedRecordIds Through Repositories and AttendanceNotifier** - `0001c3b` (feat)

## Files Created/Modified
- `functions/src/justification_service.js` - Partial `selectedRecordIds` validation/updates in `processParentReview` and multi-day `hoursByDate` formatting in `formatLibrusJustificationPayload`
- `functions/index.js` - Forwards partial selection fields in `reviewJustificationRequest` and passes `reviewResult.updatedRequest` to `formatLibrusJustificationPayload`
- `functions/test/justification_requests.test.js` - Unit tests for partial `selectedRecordIds` approval, empty selection 400 rejection, and multi-day `hoursByDate` Librus payload formatting
- `lib/domain/models/justification_request.dart` - `effectiveStudentName`, `resolveAttendanceRecords`, `groupRecordsByDay`, `formatPolishDayHeader`, and `formatDateRangeSummary` helpers
- `lib/data/repositories/school_repository.dart` - Added optional `{List<String>? selectedRecordIds}` to `approveJustificationRequest`
- `lib/data/repositories/firestore_school_repository.dart` - Added `_resolveStudentFullName()`, timetable teacher/classroom enrichment in `getAttendanceRecords()`, and `selectedRecordIds` + `_localJustificationOverrides` handling in `approveJustificationRequest`
- `lib/data/repositories/mock_school_repository.dart` - Partial `selectedRecordIds` approval with deselected lesson cancellation in `approveJustificationRequest`
- `lib/presentation/providers/school_providers.dart` - Forwarded `{List<String>? selectedRecordIds}` in `AttendanceNotifier.approveJustification`

## Decisions Made
- Resolved `studentName` from `getStudentProfile()` (`'Oskar Jankiewicz'`) in `FirestoreSchoolRepository` and added `JustificationRequest.effectiveStudentName()` so both new and legacy Firestore documents display the student's actual name instead of the parent's Google `displayName`.
- Enriched `AttendanceRecord` directly in `FirestoreSchoolRepository.getAttendanceRecords()` using `item['teacher']` and `data['timetable']` slot lookup so all downstream screens and modals automatically receive `teacherName` and `classroom`.
- Built `hoursByDate`, `dateFrom`, `dateTo`, and `selectedLessonNumbers` from resolved `AttendanceRecord`s in `FirestoreSchoolRepository.approveJustificationRequest` before calling `/api/reviewJustificationRequest`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Ready for `23-02-PLAN.md` (Wave 2 UI upgrades for `ParentApprovalModal`, `ParentRejectionModal`, Dashboard/Attendance interactive banners, expandable `"X wnioski czekają na wychowawcę"` accordion, and `Oczekujące (Y)` filter chip).

## Self-Check: PASSED

---
*Phase: 23-podgl-d-szczeg-w-pr-b-o-usprawiedliwienie-i-oczekuj-cych-wni*
*Completed: 2026-10-02*
