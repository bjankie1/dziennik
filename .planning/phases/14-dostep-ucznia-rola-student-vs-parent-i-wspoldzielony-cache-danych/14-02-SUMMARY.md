# Phase 14 Plan 02: Student Justification Request Flow & Parent PIN Approval Summary

**Plan ID:** 14-02  
**Phase:** 14 — Dostęp ucznia (rola student vs parent) i współdzielony cache danych  
**Status:** Completed  
**Completed Date:** 2026-09-22  

---

## 1. Executive Summary

Plan 14-02 successfully delivers the complete end-to-end two-sided parental excuse approval workflow (REQ-ROLE-02, D-03, D-04, T-14-03, T-14-04):

1. **Automated Backend Test Scaffolding (`functions/test/justification_requests.test.js`):**
   - Unit tests covering student request sanitization (max reason length 250, recordIds non-empty validation, lesson numbers filtering).
   - State machine transitions: initial `pending_parent_approval` -> PIN verified approval (`"1234"`) -> `approved`, parental rejection -> `rejected`, wrong PIN preservation of pending state, and prevention of duplicate approvals (T-14-04).
   - Tested formatting into payload suitable for external `LibrusClient.submitJustification` dispatch.

2. **Domain & Data Layer:**
   - Created `JustificationRequestStatus` enum (`pendingParentApproval`, `approved`, `rejected`) and `JustificationRequest` model (`lib/domain/models/justification_request.dart`) with full JSON and Firestore serialization.
   - Extended `SchoolRepository`, `MockSchoolRepository`, and `FirestoreSchoolRepository` with `requestJustification`, `getJustificationRequests`, `approveJustificationRequest`, and `rejectJustificationRequest`.
   - Exposed `justificationRequestsProvider` and updated `AttendanceNotifier` with reactive notification invalidation and instant local UI reconciliation.

3. **Cloud Functions Backend Endpoints (`functions/index.js` & `functions/src/justification_service.js`):**
   - `createJustificationRequest`: Validates student requests and stores in `justification_requests` collection with `pending_parent_approval` status.
   - `reviewJustificationRequest`: Validates parental 4-digit PIN (`1234`), guards against double submissions, updates status to `approved` or `rejected`, and dispatches official e-Justification to Librus Synergia.
   - `getJustificationRequests`: Returns requests filtered by `familyId`, `primaryLogin`, or `studentLogin`.

4. **UI Modals & Presentation Integration:**
   - Created `StudentJustificationModal`: streamlined student bottom sheet without any PIN entry, providing quick reason chips, custom note input, and informative disclaimer.
   - Created `ParentApprovalModal`: parent bottom sheet displaying student name, requested hours, subjects, reason, and 4-digit PIN authorization (`1234`) with approve/reject actions.
   - Integrated into `AttendanceScreen`: student view displays „Poproś rodzica o usprawiedliwienie” action and amber `Oczekuje na akceptację rodzica` badges; parent view shows a prominent top alert banner with direct PIN approval action.
   - Integrated into `DashboardScreen` (Desktop Bento Grid and Mobile View): parents receive real-time highlighted notification cards with quick `[Zatwierdź (PIN)]` shortcuts; students receive direct quick action shortcuts to `StudentJustificationModal`.

---

## 2. Tasks Completed

| Task ID | Description | Commits | Status |
|---|---|---|---|
| **14-02-01** | Backend test suite for justification requests & state transitions (`justification_requests.test.js`, `justification_service.js`) | `d88fe68` | Done |
| **14-02-02** | Domain model `JustificationRequest` and enum `JustificationRequestStatus` | `524bfa4` | Done |
| **14-02-03** | Cloud Functions backend endpoints `createJustificationRequest`, `reviewJustificationRequest`, `getJustificationRequests` | `a41ec38` | Done |
| **14-02-04** | Repository and Riverpod state integration across abstract, mock, and Firestore repositories | `d39e54b` | Done |
| **14-02-05** | UI Modals: `StudentJustificationModal` (no PIN) & `ParentApprovalModal` (PIN authorization) | `163492c` | Done |
| **14-02-06** | UI integration in `AttendanceScreen` & `DashboardScreen` (Desktop Bento Grid & Mobile) | `d71f4b0` | Done |

---

## 3. Verification & Quality Gates

- **Backend Unit Tests:**  
  `npm test --prefix functions`  
  - 44 tests across 16 test suites passing cleanly (duration: ~210ms).
- **Flutter Static Analysis:**  
  `flutter analyze`  
  - No issues found (0 warnings, 0 errors).

---

## 4. Key Files Created / Modified

- [`functions/src/justification_service.js`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/src/justification_service.js) — Request sanitization, PIN validation, state transition logic, and Librus payload formatting.
- [`functions/test/justification_requests.test.js`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/test/justification_requests.test.js) — Unit tests for state transitions and input validation.
- [`lib/domain/models/justification_request.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/domain/models/justification_request.dart) — Domain model and status enum.
- [`functions/index.js`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/functions/index.js) — Cloud Functions endpoints for creating, reviewing, and listing requests.
- [`lib/data/repositories/school_repository.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/data/repositories/school_repository.dart) — Abstract methods for justification requests.
- [`lib/data/repositories/mock_school_repository.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/data/repositories/mock_school_repository.dart) — In-memory state and mock simulation.
- [`lib/data/repositories/firestore_school_repository.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/data/repositories/firestore_school_repository.dart) — Firestore querying and Cloud Functions invocation.
- [`lib/presentation/providers/school_providers.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/providers/school_providers.dart) — `justificationRequestsProvider` and `AttendanceNotifier` methods.
- [`lib/presentation/screens/attendance/widgets/student_justification_modal.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/attendance/widgets/student_justification_modal.dart) — Bottom sheet for student view (no PIN).
- [`lib/presentation/screens/attendance/widgets/parent_approval_modal.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/attendance/widgets/parent_approval_modal.dart) — Bottom sheet for parent view (4-digit PIN entry).
- [`lib/presentation/screens/attendance/attendance_screen.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/attendance/attendance_screen.dart) — Student dock, amber badges, and parent alert banner.
- [`lib/presentation/screens/dashboard/dashboard_screen.dart`](file:///Users/bjankiewicz/Projects/dziennik%20szkolny/lib/presentation/screens/dashboard/dashboard_screen.dart) — Bento Grid Attendance Card, Quick Actions shortcut tile, and Mobile Dashboard alert card.
