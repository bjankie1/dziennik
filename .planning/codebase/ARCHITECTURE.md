# Architecture Overview

**Analysis Date:** 2026-09-15
**Project:** EduSync

## Architectural Pattern
- **Frontend:** Clean Architecture with Riverpod Notifiers (Presentation -> Providers -> Domain -> Data).
- **Backend:** Serverless Microservice architecture with Firebase Cloud Functions v2 and Firestore Document Store.

## Key Layers
1. **Presentation Layer (`lib/presentation/`):**
   - **Screens:** `DashboardScreen`, `ScheduleScreen`, `GradesScreen`, `AttendanceScreen`, `MessagesScreen`, `AuthGate`, `LoginScreen`, `LibrusConnectScreen`.
   - **Widgets:** `AppHeader`, interactive modals (`GradeDetailsModal`, `AverageSimulatorModal`, `JustificationModal`).
   - **Theme:** Academic Precision design tokens (`lib/core/theme/app_colors.dart`, `app_theme.dart`).

2. **State / Provider Layer (`lib/presentation/providers/`):**
   - `school_providers.dart`: reactive `FutureProvider` & `AsyncNotifier` for student profile, schedule, grades, attendance, announcements, and navigation index.
   - `sync_provider.dart`: `SyncNotifier` managing synchronization lifecycle, status timestamps, and on-demand trigger.
   - `auth_providers.dart`: Firebase Auth and Librus connection state.

3. **Domain Layer (`lib/domain/models/`):**
   - Immutables: `StudentProfile`, `Subject`, `Grade`, `LessonSlot`, `UpcomingEvent`, `AttendanceRecord`, `MessageThread`, `Announcement`.

4. **Data Layer (`lib/data/`):**
   - `SchoolRepository`: abstract contract.
   - `FirestoreSchoolRepository`: production implementation querying `/api/studentData` (Firestore cache) with in-memory caching and graceful fallback.
   - `MockSchoolRepository`: development/demo fallback data.
   - `LibrusConnectionService`: manages connection persistence across Firestore and local storage.

5. **Cloud Backend (`functions/`):**
   - `librus_client.js`: Authenticates with Synergia and scrapes data modules.
   - `sync_service.js`: Manages Firestore persistence, detects differences (diffing engine), generates notification documents.
   - `index.js`: Exports Cloud Functions v2 and Cloud Scheduler hooks.

*Codebase analysis: 2026-09-15*
