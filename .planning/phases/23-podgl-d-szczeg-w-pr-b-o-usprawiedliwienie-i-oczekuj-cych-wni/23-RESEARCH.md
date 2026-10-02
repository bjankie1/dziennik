# Phase 23: Podgląd szczegółów próśb o usprawiedliwienie i oczekujących wniosków - Research

**Researched:** 2026-04-20
**Domain:** Flutter / Riverpod UI & State Management (`AttendanceScreen`, `ParentApprovalModal`, `ParentRejectionModal`, `DashboardScreen`) + Firestore Repository & Cloud Functions (`reviewJustificationRequest`)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### 1. Podgląd szczegółów prośby o usprawiedliwienie (Pulpit i Frekwencja)
- **D-01:** Kliknięcie w żółty baner prośby o usprawiedliwienie (zarówno na Pulpicie w `dashboard_mobile_view.dart` i `dashboard_metrics_column.dart`, jak i na ekranie Frekwencji w `attendance_screen.dart`) otwiera dedykowany modal szczegółów prośby (`ParentApprovalModal`) prezentujący szczegółową listę wszystkich objętych lekcji wraz z akcjami **Zatwierdź (PIN)** oraz **Odrzuć**.
- **D-02:** Na samym banerze prośby (obok liczby lekcji i powodu, np. `6 lekcji • Choroba`) dodana zostaje czytelna wskazówka wizualna (np. zakres dat / link `Zobacz szczegóły →`), aby użytkownik widział, że baner jest interaktywny i otwiera podgląd lekcji.
- **D-03:** Przy tworzeniu prośby o usprawiedliwienie (`requestJustification` w `firestore_school_repository.dart`) oraz przy wyświetlaniu banera należy używać imienia i nazwiska ucznia z profilu ucznia (`Oskar Jankiewicz`), a nie `appUser.displayName` zalogowanego konta Google rodzica (gdy rodzic testowo przełącza rolę na ucznia).

#### 2. Zakres szczegółów pojedynczej lekcji i częściowa akceptacja w modalu
- **D-04:** Modal szczegółów i autoryzacji prośby (`ParentApprovalModal`) rozwiązuje powiązane `recordIds` (oraz fallback po `date` + `lessonNumbers`) względem pełnej listy rekordów `AttendanceRecord` z `attendanceProvider`.
- **D-05:** Lekcje w modalu są pogrupowane dniami (z nagłówkiem dnia: **Data i dzień tygodnia**, np. *Wtorek, 29 Września 2026*), a każdy wiersz lekcji prezentuje:
  - **Nr lekcji + godziny** (np. `Lekcja 3 • 09:45–10:30`),
  - **Przedmiot** (np. `Język polski`),
  - **Nauczyciel** (oraz sala, jeśli dostępna),
  - **Powód / uzasadnienie ucznia** (oraz historię dialogu Q&A, jeśli prośba była wcześniej odrzucana/komentowana).
- **D-06:** Przy każdej lekcji w modalu `ParentApprovalModal` znajduje się checkbox (domyślnie wszystkie lekcje z prośby są zaznaczone). Rodzic może odznaczyć wybrane lekcje przed zatwierdzeniem PIN-em — wówczas do Librusa wysyłane są wyłącznie zaznaczone lekcje (częściowa akceptacja prośby), a przycisk zatwierdzania dynamicznie pokazuje liczbę wybranych lekcji (np. `Zatwierdź z PIN-em (5 z 6 lekcji)`).

#### 3. Podgląd i zarządzanie „X wnioski czekają na wychowawcę” (Frekwencja)
- **D-07:** Baner `X wnioski czekają na wychowawcę` w `AttendanceScreen` staje się rozwijany (akordeon / sekcja rozwijana po kliknięciu w baner lub przycisk `Pokaż szczegóły`). Po rozwinięciu wyświetla pogrupowaną dniami listę wszystkich lekcji ze statusem `JustificationStatus.requested` (Data i dzień tygodnia, Nr lekcji + godziny, Przedmiot, Nauczyciel, wysłany powód usprawiedliwienia).
- **D-08:** W rozwiniętej liście oczekujących wniosków użytkownik może cofnąć **pojedynczy wniosek** (przycisk `Cofnij` przy danej lekcji) lub **wszystkie oczekujące wnioski** naraz (`Cofnij wszystkie`).
- **D-09:** Na pasku filtrów w `AttendanceScreen` obok `Wszystkie`, `Do usprawiedliwienia (X)` oraz `Usprawiedliwione` dodana zostaje czwarta pigułka filtra: **`Oczekujące (Y)`** (gdzie `Y` to liczba lekcji ze statusem `JustificationStatus.requested`), pozwalająca jednym kliknięciem wyfiltrować główną listę frekwencji do samych oczekujących wniosków.

### the agent's Discretion
- Dokładna stylistyka mikro-animacji rozwijania banera `X wnioski czekają na wychowawcę` (`AnimatedCrossFade` / `AnimatedSize`) zgodnie z paletą `AppColors` i bursztynową kolorystyką statusu oczekującego (`#FFFBEB` / `#D97706`).
- Sposób przekazania zawężonej listy `selectedRecordIds` podczas częściowej akceptacji w `approveJustification` (aktualizacja `recordIds` na dokumencie prośby lub przekazanie wybranych ID do `approveJustificationRequest`).

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `REQ-ATT-01` | Podgląd szczegółów prośby o usprawiedliwienie z listy lekcji (dni, godziny, przedmioty, nauczyciel, powód) z poziomu banera oraz modali akceptacji/odrzucania na Pulpicie i we Frekwencji. | Covered by D-01..D-06: interactive banner cue (`Zobacz szczegóły →`) in `DashboardMobileView`, `DashboardMetricsColumn`, and `AttendanceScreen`; `AttendanceRecord` resolution + timetable teacher/classroom enrichment in `FirestoreSchoolRepository.getAttendanceRecords()`; day-grouped lesson cards with checkboxes and partial approval in `ParentApprovalModal`; day-grouped lesson summary in `ParentRejectionModal`; student profile name fix in `requestJustification` / `respondJustificationRequest` and banners. |
| `REQ-ATT-02` | Podgląd szczegółowej listy oczekujących wniosków o usprawiedliwienie („X wnioski czekają na wychowawcę”) z opcją cofnięcia pojedynczego lub wszystkich wniosków. | Covered by D-07..D-09: expandable accordion banner for `pendingList` (`JustificationStatus.requested`) in `AttendanceScreen` with day-grouped lessons, individual `Cofnij` (`cancelJustification([rec.id])`) and bulk `Cofnij wszystkie` (`cancelJustification(pendingList.map((r) => r.id).toList())`), plus 4th filter chip `Oczekujące (Y)` (`_activeFilter == 3`). |
</phase_requirements>

---

## Summary

Phase 23 closes two high-visibility UX and data-resolution gaps in the attendance and justification workflow across **Dashboard** and **AttendanceScreen**:

1. **Detailed Lesson Breakdown & Partial Approval on Student Justification Requests (`REQ-ATT-01`, D-01..D-06):**
   - Currently, the yellow banner (`"X prosi o usprawiedliwienie"`, `"6 lekcji • Choroba"`) in `DashboardMobileView`, `DashboardMetricsColumn`, and `AttendanceScreen` is non-interactive except for its small action buttons, and `ParentApprovalModal` / `ParentRejectionModal` only render raw `request.lessonNumbers.join(", ")` and `request.subjectNames.join(", ")` without resolving the underlying `AttendanceRecord` items (`date`, `timeSlot`, `subjectName`, `teacherName`, `classroom`).
   - Additionally, two root-cause data bugs were discovered during codebase inspection:
     1. **Student Name Bug (D-03):** `FirestoreSchoolRepository.requestJustification` (`lib/data/repositories/firestore_school_repository.dart:1525`) and `respondJustificationRequest` (`:1729`) write `'studentName': appUser?.displayName ?? 'Oskar Jankiewicz'`. When a parent tests the student view under their Google account (`Bartosz Jankiewicz`), the request stores `"Bartosz Jankiewicz"`, making the banner say `"Bartosz Jankiewicz prosi o usprawiedliwienie"`.
     2. **Teacher & Classroom Mapping Bug (D-05):** `functions/src/librus_client.js:585` scrapes the teacher into key `teacher`, whereas `FirestoreSchoolRepository.getAttendanceRecords()` (`lib/data/repositories/firestore_school_repository.dart:1076`) reads `item['teacherName'] as String?` (ignoring `item['teacher']`) and never cross-references `data['timetable']` for `classroom` or missing teacher names.
   - Furthermore, when a parent approves a multi-day or partially selected request (D-06), `FirestoreSchoolRepository.approveJustificationRequest` (`:1650`) and `functions/src/justification_service.js` (`:226-242`) currently do not accept a filtered `selectedRecordIds` / `hoursByDate` map nor update `_localJustificationOverrides` for the approved lessons.

2. **Expandable "X wnioski czekają na wychowawcę" Banner & `Oczekujące (Y)` Filter Pill (`REQ-ATT-02`, D-07..D-09):**
   - In `AttendanceScreen` (`lib/presentation/screens/attendance/attendance_screen.dart:216-261`), the amber banner showing `pendingList.length` lessons (`JustificationStatus.requested`) currently only offers a bulk `Cofnij` button without showing *which* days/lessons are waiting for the homeroom teacher.
   - Converting this banner into an expandable accordion (`_isPendingBannerExpanded`) grouped by day with individual `Cofnij` buttons (`cancelJustification([rec.id])`), a bulk `Cofnij wszystkie` button, and a 4th filter pill `Oczekujące (${pendingList.length})` (`_activeFilter == 3`) gives parents and students full visibility and control over pending justifications.

**Primary recommendation:** Fix data resolution at the repository layer first (student profile name in `requestJustification`, `teacher`/`classroom` enrichment in `getAttendanceRecords`, and `selectedRecordIds` + `_localJustificationOverrides` support in `approveJustificationRequest`), then upgrade `ParentApprovalModal`, `ParentRejectionModal`, the three justification request banners, and `AttendanceScreen`'s pending-requests banner + filter bar.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Student profile name resolution (`Oskar Jankiewicz`) on request creation & display (D-03) | Data / Repository (`FirestoreSchoolRepository`) | Presentation (`DashboardMobileView`, `DashboardMetricsColumn`, `AttendanceScreen`, `ParentApprovalModal`, `ParentRejectionModal`) | Repository must persist the student's actual profile name; UI must also guard against legacy Firestore docs that already saved the parent's `displayName`. |
| `AttendanceRecord` teacher & classroom resolution (D-05) | Data / Repository (`FirestoreSchoolRepository.getAttendanceRecords`) | Domain (`AttendanceRecord`) | `librus_client.js` stores `teacher` (not `teacherName`), and `timetable` holds `classroom` + `teacherName` by `(dayOfWeek, lessonNumber)`. Enriching in `getAttendanceRecords()` benefits all screens automatically. |
| Resolving `JustificationRequest.recordIds` to grouped `AttendanceRecord`s + checkboxes (D-04, D-05, D-06) | Presentation (`ParentApprovalModal`, `ParentRejectionModal`) | State (`attendanceProvider` in `school_providers.dart`) | Modal watches/reads `attendanceProvider` (with fallback to `request.lessonNumbers`/`subjectNames` when records are absent in isolated unit tests). |
| Partial approval (`selectedRecordIds`) & Librus payload (D-06) | Data / Repository (`SchoolRepository`, `FirestoreSchoolRepository`, `MockSchoolRepository`, `AttendanceNotifier`) | Backend (`functions/src/justification_service.js`) | Client passes `selectedRecordIds` (and computed `hoursByDate` / `selectedLessonNumbers`); repository marks only selected records as `JustificationStatus.requested` and removes only selected `recordIds` (or marks request `approved`). |
| Expandable "X wnioski czekają na wychowawcę" accordion & `Oczekujące (Y)` filter (D-07, D-08, D-09) | Presentation (`AttendanceScreen`) | State (`AttendanceNotifier.cancelJustification`) | `cancelJustification(List<String> recordIds)` already supports arbitrary single-item `[rec.id]` or multi-item lists! |

---

## Standard Stack

### Core (Existing Project Dependencies — No New Packages Required)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_riverpod` | `^2.5.1` | State management (`attendanceProvider`, `justificationRequestsProvider`, `studentProfileProvider`) | `[VERIFIED: pubspec.yaml:22]` `"flutter_riverpod: ^2.5.1"` — used across all screens and modals. |
| `google_fonts` | `^6.2.1` | Plus Jakarta Sans typography in modals, banners, and cards | `[VERIFIED: pubspec.yaml:27]` `"google_fonts: ^6.2.1"` — standard project typography. |
| `intl` | `^0.19.0` | Date formatting alongside project's custom Polish date formatters | `[VERIFIED: pubspec.yaml:28]` `"intl: ^0.19.0"`. |
| `node:test` / `flutter_test` | SDK built-in | Unit & widget test runners for Dart and Cloud Functions | `[VERIFIED: pubspec.yaml:36]` & `[VERIFIED: functions/package.json:9]`. |

**Installation:** None required. All changes use existing Flutter, Riverpod, and Node.js packages.

---

## Architecture Patterns

### System Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────────────┐
│ PRESENTATION LAYER                                                         │
│                                                                            │
│  ┌──────────────────────────────┐    ┌──────────────────────────────────┐  │
│  │ DashboardMobileView /        │    │ AttendanceScreen                 │  │
│  │ DashboardMetricsColumn       │    │ - Interactive Request Banner     │  │
│  │ - Interactive Request Banner │    │ - 4th Filter Pill: Oczekujące(Y) │  │
│  │ - "Zobacz szczegóły →" (D-02)│    │ - Expandable "X wnioski czekają" │  │
│  └──────────────┬───────────────┘    │   with per-lesson "Cofnij" (D-07)│  │
│                 │                    └────────────────┬─────────────────┘  │
│                 └──────────────────┬──────────────────┘                    │
│                                    ▼                                       │
│                 ┌─────────────────────────────────────┐                    │
│                 │ ParentApprovalModal (D-01, D-04..06)│                    │
│                 │ & ParentRejectionModal              │                    │
│                 │ - Resolves AttendanceRecord list    │                    │
│                 │ - Groups lessons by Date (PL header)│                    │
│                 │ - Checkboxes (partial selection)    │                    │
│                 │ - Action: Zatwierdź (PIN) / Odrzuć  │                    │
│                 └──────────────────┬──────────────────┘                    │
└────────────────────────────────────┼───────────────────────────────────────┘
                                     ▼
┌────────────────────────────────────────────────────────────────────────────┐
│ RIVERPOD / REPOSITORY / FUNCTIONS LAYER                                    │
│                                                                            │
│  AttendanceNotifier.approveJustification(reqId, pin, {selectedRecordIds})  │
│    └─► SchoolRepository.approveJustificationRequest(...)                   │
│          ├─► Updates _localJustificationOverrides for selectedRecordIds    │
│          ├─► POST /api/reviewJustificationRequest (selectedRecordIds,      │
│          │     lessonNumbers, hoursByDate)                                 │
│          └─► Cloud Function processParentReview -> Librus API              │
└────────────────────────────────────────────────────────────────────────────┘
```

### Pattern 1: Student Name Resolution in `requestJustification` & UI Banners (D-03)

**What happens today:**
In `lib/data/repositories/firestore_school_repository.dart:1523-1532`:
```dart
// [VERIFIED: lib/data/repositories/firestore_school_repository.dart:1523-1532]
      final requestData = <String, dynamic>{
        'studentId': '1',
        'studentName': appUser?.displayName ?? 'Oskar Jankiewicz',
        'date': dateStr,
        'lessonNumbers': lessonNumbers,
        'subjectNames': subjectNames,
        'reason': reason,
        'status': 'pending_parent',
        'recordIds': recordIds,
        'createdAt': FieldValue.serverTimestamp(),
```
And in `respondJustificationRequest` at `lib/data/repositories/firestore_school_repository.dart:1726-1731`:
```dart
// [VERIFIED: lib/data/repositories/firestore_school_repository.dart:1726-1731]
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/api/respondJustificationRequest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'requestId': requestId,
          'studentMessage': message,
          'studentName': appUser?.displayName ?? 'Oskar Jankiewicz',
        }),
      );
```
Because the parent switches roles in-app while logged into their own Google account (`Bartosz Jankiewicz`), `appUser?.displayName` is `"Bartosz Jankiewicz"`.

**Required Fix (Repository + Defensive UI):**
1. **Repository (`FirestoreSchoolRepository`):** Add a helper `_resolveStudentFullName()` that reads `(await getStudentProfile()).name` (returning `'Oskar Jankiewicz'` if empty or equal to `appUser?.displayName` when `appUser?.role == UserRole.parent`), and use it in `requestJustification` and `respondJustificationRequest`.
2. **UI Defensive Helper (`resolveStudentDisplayName`):** Because existing Firestore documents in `users/{uid}/justification_requests` may already have `studentName: "Bartosz Jankiewicz"` saved from earlier tests, add a helper method on `JustificationRequest` or in the UI:
   ```dart
   String effectiveStudentName({String? profileStudentName, String? currentParentName}) {
     final candidate = (profileStudentName != null && profileStudentName.trim().isNotEmpty)
         ? profileStudentName.trim()
         : 'Oskar Jankiewicz';
     if (studentName.trim().isEmpty) return candidate;
     if (currentParentName != null &&
         studentName.trim().toLowerCase() == currentParentName.trim().toLowerCase() &&
         candidate.toLowerCase() != currentParentName.trim().toLowerCase()) {
       return candidate;
     }
     return studentName;
   }
   ```
   Use this in:
   - `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart:320`
   - `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart:572`
   - `lib/presentation/screens/attendance/attendance_screen.dart:973`
   - `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart:166`
   - `lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart:205`

---

### Pattern 2: Enriching `AttendanceRecord` with `teacherName` and `classroom` (D-05)

**What happens today:**
In `functions/src/librus_client.js:579-590`, the Librus attendance scraper produces:
```javascript
// [VERIFIED: functions/src/librus_client.js:579-590]
          records.push({
            id: `att-${currentDate}-${lessonNum}-${shortType}`,
            date: currentDate,
            lessonNumber: lessonNum,
            subject: subjectMatch ? subjectMatch[1].trim() : "Lekcja",
            topic: topicMatch ? topicMatch[1].trim() : "",
            teacher: teacherMatch ? teacherMatch[1].trim() : "",
            type: mappedType,
            shortType,
            isExcused,
            isTrip: isTripMatch ? isTripMatch[1].trim() === "Tak" : false,
          });
```
Meanwhile, `FirestoreSchoolRepository.getAttendanceRecords()` (`lib/data/repositories/firestore_school_repository.dart:1066-1077`) reads:
```dart
// [VERIFIED: lib/data/repositories/firestore_school_repository.dart:1066-1077]
        return AttendanceRecord(
          id: recordId,
          date: dt,
          lessonNumber: lessonNum,
          timeSlot: item['timeSlot'] as String? ?? defaultSlots[lessonNum] ?? '08:00 - 08:45',
          subjectName: (item['subjectName'] as String?) ?? (item['subject'] as String?) ?? 'Przedmiot',
          status: status,
          justificationStatus: justificationStatus,
          justificationReason: justificationReason,
          classroom: item['classroom'] as String?,
          teacherName: item['teacherName'] as String?,
        );
```
Notice two things:
1. `item['teacher']` is never checked when `item['teacherName']` is null!
2. `item['classroom']` is never present in Librus `/przegladaj_nb/uczen` tooltips, **but** `data['timetable']` in the exact same Firestore document (`schools/eksperymentalna/students/1`) has every lesson's `dayOfWeek`, `lessonNumber`, `teacherName` / `teacher`, and `classroom` / `room`!

**Required Fix in `FirestoreSchoolRepository.getAttendanceRecords()`:**
- Extract `(item['teacherName'] as String?) ?? (item['teacher'] as String?)`.
- Build a quick lookup map from `data['timetable']` keyed by `'${dayOfWeek}_${lessonNumber}'` (and fallback by subject name) to fill in `classroom` (`t['classroom'] ?? t['room']`) and `teacherName` (`t['teacherName'] ?? t['teacher']`) whenever the attendance item itself lacks them.
- Filter out empty strings (`""` -> `null`) so UI null checks (`record.teacherName != null`, `record.classroom != null`) work cleanly.

---

### Pattern 3: Resolving & Grouping Lessons in `ParentApprovalModal` & `ParentRejectionModal` (D-04, D-05, D-06)

**What happens today:**
`ParentApprovalModal` (`lib/presentation/screens/attendance/widgets/parent_approval_modal.dart:183-198`) only shows a flat summary box:
```dart
// [VERIFIED: lib/presentation/screens/attendance/widgets/parent_approval_modal.dart:183-198]
                Text(
                  request.lessonNumbers.isNotEmpty
                      ? 'Lekcje: ${request.lessonNumbers.join(", ")} (${request.subjectNames.join(", ")})'
                      : 'Powód: ${request.reason}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
```

**How Lesson Resolution Must Work (D-04):**
Create a shared helper (e.g. `resolveRequestAttendanceRecords(JustificationRequest req, List<AttendanceRecord> allRecords)`) used by the banners, `ParentApprovalModal`, and `ParentRejectionModal`:
1. Primary match: filter `allRecords` where `req.recordIds.contains(r.id)`.
2. Secondary match (fallback if primary is empty or incomplete): if `req.date != null`, match `allRecords` where `r.date.year == req.date!.year && r.date.month == req.date!.month && r.date.day == req.date!.day && (req.lessonNumbers.isEmpty || req.lessonNumbers.contains(r.lessonNumber))`.
3. Synthetic fallback (when `allRecords` is empty, e.g., in standalone widget tests where `attendanceProvider` is not seeded): synthesize `AttendanceRecord` items from `req.recordIds`, `req.lessonNumbers`, `req.subjectNames`, and `req.date ?? req.createdAt` so the modal always renders structured lesson rows with checkboxes even in unit tests.
4. Sort resolved records chronologically by `(date, lessonNumber)` and group them by calendar day (`yyyy-MM-dd`).

**Day Header & Lesson Card Layout (D-05, D-06):**
- **Day Header:** e.g. `Wtorek, 29 Września 2026` (reusing the Polish weekday + genitive month formatting pattern already in `AttendanceScreen._formatDayHeader(date)` at `lib/presentation/screens/attendance/attendance_screen.dart:1519-1547`).
- **Lesson Row with Checkbox (in `ParentApprovalModal`):**
  - `Checkbox` (checked by default; toggling updates `Set<String> _selectedRecordIds`).
  - Top line: `Lekcja ${r.lessonNumber} • ${r.timeSlot}` (badge/pill) + Status badge (`NB` / `SP`).
  - Subject title: `r.subjectName` (`fontWeight: FontWeight.w700`).
  - Teacher & Room subtitle: `${r.teacherName ?? 'Brak danych o nauczycielu'}${r.classroom != null && r.classroom!.isNotEmpty ? ' • Sala ${r.classroom}' : ''}`.
- **Reason & Q&A Dialog History Section (D-05):**
  - Student's justification reason box (`Powód ucznia: ${req.reason}`).
  - If `req.dialogHistory.isNotEmpty`, render the chronological Q&A bubbles (reusing the bubble style from `StudentResponseModal` at `lib/presentation/screens/attendance/widgets/student_response_modal.dart:192-265`).
- **Action Buttons in `ParentApprovalModal` (D-01, D-06):**
  - Because D-01 states that clicking the yellow banner opens `ParentApprovalModal` with both **Zatwierdź (PIN)** and **Odrzuć** actions, `ParentApprovalModal` should also accept an optional `VoidCallback? onReject` (or button `"Odrzuć / Zadaj pytanie"`) that closes `ParentApprovalModal` and opens `ParentRejectionModal` (when `onReject` is provided), alongside `"Anuluj"` and the primary `"Zatwierdź z PIN-em"` button!
  - Dynamic button label (D-06):
    - When all lessons are selected (`_selectedRecordIds.length == totalCount`): `'Zatwierdź z PIN-em ($totalCount z $totalCount lekcji)'` (note: contains substring `'Zatwierdź z PIN-em'`).
    - When a subset is selected (`0 < _selectedRecordIds.length < totalCount`): `'Zatwierdź z PIN-em (${_selectedRecordIds.length} z $totalCount lekcji)'`.
    - When `0` lessons are selected: disable the approve button (`onPressed: null`) and show `'Wybierz co najmniej 1 lekcję'`.
  - **Backward Compatibility Note for Existing Widget Test:** `test/attendance_justification_modal_test.dart:157` asserts `expect(find.text('Zatwierdź z PIN-em'), findsOneWidget);` when `recordIds: const ['att-1', 'att-2']` and `lessonNumbers: const [1, 2]`. Wait — let's check `test/attendance_justification_modal_test.dart:157`!
    ```dart
    // [VERIFIED: test/attendance_justification_modal_test.dart:157]
    expect(find.text('Zatwierdź z PIN-em'), findsOneWidget);
    ```
    Look at how `test/attendance_justification_modal_test.dart` tests `ParentApprovalModal`:
    - It mounts `ParentApprovalModal(request: sampleRequest, onApprove: (pin) async { ... })` directly inside a plain `MaterialApp` (**without** `ProviderScope`!) and looks for exact text `'Zatwierdź z PIN-em'` (or we can either keep button text `'Zatwierdź z PIN-em'` when all lessons are selected and show a separate counter pill `'Wybrano: X z Y lekcji'`, OR update `test/attendance_justification_modal_test.dart` alongside the new tests).
    - **Crucial:** If `ParentApprovalModal` accepts optional `List<AttendanceRecord>? availableRecords` (passed from `ref.read(attendanceProvider).valueOrNull` in `ParentApprovalModal.show(...)`), it doesn't even *require* `ProviderScope` when instantiated directly in unit tests! And if we update `test/attendance_justification_modal_test.dart` (or render `'Zatwierdź z PIN-em (${_selectedRecordIds.length} z $totalCount lekcji)'`), let's make sure all widget tests in `test/attendance_justification_modal_test.dart` pass.

---

### Pattern 4: End-to-End Partial Approval Flow (D-06)

**What happens today:**
1. `SchoolRepository.approveJustificationRequest(String requestId, String pin)` (`lib/data/repositories/school_repository.dart:26`) takes only `requestId` and `pin`.
2. `FirestoreSchoolRepository.approveJustificationRequest(String requestId, String pin)` (`lib/data/repositories/firestore_school_repository.dart:1650-1683`):
   - Sends `{ 'uid': uid, 'requestId': requestId, 'action': 'approve', 'pin': pin }` to `/api/reviewJustificationRequest`.
   - Calls `_mockFallback.approveJustificationRequest(requestId, pin)`, which does **not** update `_localJustificationOverrides` in `FirestoreSchoolRepository`!
3. `functions/src/justification_service.js:226-242` (`formatLibrusJustificationPayload`):
   ```javascript
   // [VERIFIED: functions/src/justification_service.js:226-242]
   function formatLibrusJustificationPayload(requestDoc) {
     const dateStr = requestDoc.date || new Date().toISOString().split("T")[0];
     const hours = Array.isArray(requestDoc.lessonNumbers) && requestDoc.lessonNumbers.length > 0
       ? requestDoc.lessonNumbers
       : [1];
     return {
       dateFrom: dateStr,
       dateTo: dateStr,
       hoursByDate: {
         [dateStr]: hours,
       },
       reason: requestDoc.reason || "Prośba o usprawiedliwienie nieobecności",
     };
   }
   ```
   Notice that if a request spans multiple dates (or `requestDoc.date` is null because lessons from 2 days were selected), `formatLibrusJustificationPayload` only sends a single date!

**Required End-to-End Upgrade for D-06:**
1. **Method Signatures:** Add optional `{List<String>? selectedRecordIds}` to:
   - `SchoolRepository.approveJustificationRequest(String requestId, String pin, {List<String>? selectedRecordIds})`
   - `FirestoreSchoolRepository.approveJustificationRequest(String requestId, String pin, {List<String>? selectedRecordIds})`
   - `MockSchoolRepository.approveJustificationRequest(String requestId, String pin, {List<String>? selectedRecordIds})`
   - `AttendanceNotifier.approveJustification(String requestId, String pin, {List<String>? selectedRecordIds})`
2. **In `FirestoreSchoolRepository.approveJustificationRequest`:**
   - Look up the request from `getJustificationRequests()` and the records from `getAttendanceRecords()`.
   - Determine `effectiveRecordIds = (selectedRecordIds != null && selectedRecordIds.isNotEmpty) ? selectedRecordIds : req.recordIds`.
   - Resolve the matching `AttendanceRecord` objects for `effectiveRecordIds`.
   - Build `hoursByDate` (`Map<String, List<int>>`), `dateFrom`, `dateTo`, and `selectedLessonNumbers` from the resolved records.
   - Include `'selectedRecordIds': effectiveRecordIds`, `'selectedLessonNumbers': selectedLessonNumbers`, `'hoursByDate': hoursByDate`, `'dateFrom': dateFrom`, `'dateTo': dateTo` in the JSON body sent to `/api/reviewJustificationRequest`.
   - Upon `response.statusCode == 200`, immediately persist `_localJustificationOverrides` for `effectiveRecordIds` with `status: 'requested'` and `reason: req.reason` (via `_saveLocalOverrides()`), so the approved lessons immediately transition to `JustificationStatus.requested` ("Oczekuje na wychowawcę"), while any **unchecked** lessons remain `JustificationStatus.none` ("Do usprawiedliwienia")!
3. **In `functions/src/justification_service.js` (`processParentReview` & `formatLibrusJustificationPayload`):**
   - In `processParentReview(existingData, reviewData)`: if `Array.isArray(reviewData.selectedRecordIds) && reviewData.selectedRecordIds.length > 0`, store `approvedRecordIds: reviewData.selectedRecordIds` and update `recordIds: reviewData.selectedRecordIds` (and `lessonNumbers: reviewData.selectedLessonNumbers` if provided, `hoursByDate: reviewData.hoursByDate`, `dateFrom: reviewData.dateFrom`, `dateTo: reviewData.dateTo`) on `updatedRequest`.
   - In `formatLibrusJustificationPayload(requestDoc)`: if `requestDoc.hoursByDate` is a non-empty object, use `requestDoc.hoursByDate`, `requestDoc.dateFrom`, and `requestDoc.dateTo` directly; otherwise fall back to the existing single-date behavior.

---

### Pattern 5: Interactive Request Banner on Dashboard & AttendanceScreen (D-01, D-02)

**Where the 3 banners live today:**
1. `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart:293-455` (`_buildPendingJustificationBanner`)
2. `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart:547-706` (`_buildPendingJustificationBanner`)
3. `lib/presentation/screens/attendance/attendance_screen.dart:936-1083` (`_buildParentRequestsBanner`)

**Required Changes across all 3 banners:**
- Resolve the matching `AttendanceRecord`s for each `req` using `resolveRequestAttendanceRecords(req, attendanceRecords)`.
- Compute a concise date/lesson summary string for the banner (D-02), e.g.:
  - Single day: `29.09 • 3 lekcje • ${req.reason}`
  - Multi-day: `28.09–29.09 • 6 lekcji • ${req.reason}`
- Display a clear visual link/pill on the banner: `Zobacz szczegóły →` (`AppColors.amber700` / `#B45309`, `FontWeight.w700`).
- Wrap the card in `Material` + `InkWell` (with `borderRadius: BorderRadius.circular(14)`) so clicking anywhere on the yellow banner opens `ParentApprovalModal.show(...)` (passing both `onApprove` and `onReject` so the user can either approve with PIN or switch to `ParentRejectionModal` right from the detail modal, per D-01).

---

### Pattern 6: Expandable "X wnioski czekają na wychowawcę" Accordion & 4th Filter Pill (D-07, D-08, D-09)

**What happens today in `AttendanceScreen` (`lib/presentation/screens/attendance/attendance_screen.dart:192-261`):**
```dart
// [VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:192-215]
    final filtered = _activeFilter == 0
        ? records
        : _activeFilter == 1
            ? unexcused
            : excusedList;
...
              FilterChipPill(
                label: 'Wszystkie',
                isSelected: _activeFilter == 0,
                onTap: () => setState(() => _activeFilter = 0),
              ),
              const SizedBox(width: 8),
              FilterChipPill(
                label: 'Do usprawiedliwienia (${unexcused.length})',
                isSelected: _activeFilter == 1,
                isAlert: unexcused.isNotEmpty,
                onTap: () => setState(() => _activeFilter = 1),
              ),
              const SizedBox(width: 8),
              FilterChipPill(
                label: 'Usprawiedliwione',
                isSelected: _activeFilter == 2,
                onTap: () => setState(() => _activeFilter = 2),
              ),
```
And lines `216-261` render the non-expandable `pendingList` banner with a single `Cofnij` button that cancels all `pendingList` items at once.

**Required Changes (D-07, D-08, D-09):**
1. **4th Filter Pill (`Oczekujące (Y)`, D-09):**
   - Update `filtered` computation:
     ```dart
     final filtered = _activeFilter == 0
         ? records
         : _activeFilter == 1
             ? unexcused
             : _activeFilter == 2
                 ? excusedList
                 : pendingList;
     ```
   - Add a 4th `FilterChipPill`:
     ```dart
     FilterChipPill(
       label: 'Oczekujące (${pendingList.length})',
       isSelected: _activeFilter == 3,
       onTap: () => setState(() => _activeFilter = 3),
     ),
     ```
2. **Expandable Accordion Banner (D-07, D-08):**
   - Add `bool _isPendingBannerExpanded = false;` to `_AttendanceScreenState`.
   - Replace the static `Container` at lines `216-261` with `_buildPendingTeacherBanner(BuildContext context, List<AttendanceRecord> pendingList)`:
     - **Collapsed / Header Row:**
       - Tapping the header row toggles `setState(() => _isPendingBannerExpanded = !_isPendingBannerExpanded)`.
       - Shows `Icons.hourglass_top_rounded`, count text `'${pendingList.length} ${pendingList.length == 1 ? "wniosek czeka" : "wnioski czekają"} na wychowawcę'`, interactive cue `'${_isPendingBannerExpanded ? "Ukryj szczegóły" : "Pokaż szczegóły"}'` with rotating/toggling chevron (`Icons.keyboard_arrow_down_rounded` / `Icons.keyboard_arrow_up_rounded`), and a bulk `'Cofnij wszystkie'` `TextButton` calling `ref.read(attendanceProvider.notifier).cancelJustification(pendingList.map((r) => r.id).toList())`.
     - **Expanded Details Body (`AnimatedCrossFade` or `AnimatedSize`):**
       - Groups `pendingList` by calendar day (`yyyy-MM-dd`), sorted newest-first, using `_formatDayHeader(date)` (e.g. `Wtorek, 29 Września 2026`).
       - Each lesson row displays:
         - `Lekcja ${rec.lessonNumber} • ${rec.timeSlot}`
         - `${rec.subjectName}` (`FontWeight.w700`)
         - `${rec.teacherName ?? "Nauczyciel"}${rec.classroom != null && rec.classroom!.isNotEmpty ? " • Sala ${rec.classroom}" : ""}`
         - Sent reason: `Powód: ${(rec.justificationReason != null && rec.justificationReason!.isNotEmpty) ? rec.justificationReason! : "Usprawiedliwienie wysłane do wychowawcy"}`
         - Individual `TextButton` / `OutlinedButton` **`Cofnij`** calling `ref.read(attendanceProvider.notifier).cancelJustification([rec.id])` (D-08).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cancelling a single pending justification vs. all pending justifications | A separate repository/API method for single-item cancellation | Existing `ref.read(attendanceProvider.notifier).cancelJustification(List<String> recordIds)` (`[VERIFIED: lib/presentation/providers/school_providers.dart:212-219]`) | Already accepts `List<String> recordIds` and works for both `[rec.id]` (single) and `pendingList.map((r) => r.id).toList()` (all). |
| Polish date header formatting (`Dzień tygodnia, DD Miesiąca RRRR`) | External locale date formatter that requires async `initializeDateFormatting` in tests | Existing `_formatDayHeader(DateTime date)` pattern from `AttendanceScreen` (`[VERIFIED: lib/presentation/screens/attendance/attendance_screen.dart:1519-1547]`) | Pure Dart, zero async initialization overhead, works identically in production and `flutter test`. |
| PIN verification dialog / input | A second custom PIN modal on top of `ParentApprovalModal` | Existing inline 4-digit PIN `TextField` + shake animation in `ParentApprovalModal` (`[VERIFIED: lib/presentation/screens/attendance/widgets/parent_approval_modal.dart:236-305]`) | Keeps approval to a single modal interaction: review/uncheck lessons -> enter 4-digit PIN -> click `Zatwierdź z PIN-em`. |

---

## Common Pitfalls

### Pitfall 1: Breaking `test/attendance_justification_modal_test.dart` When Adding `Riverpod` or Changing Button Labels
- **What goes wrong:** `test/attendance_justification_modal_test.dart` instantiates `ParentApprovalModal` inside a bare `MaterialApp` without a `ProviderScope` (`[VERIFIED: test/attendance_justification_modal_test.dart:129-145]`). If `ParentApprovalModal` unconditionally calls `ref.watch(attendanceProvider)` without a fallback or requires `ProviderScope`, the existing test will throw `Bad state: No ProviderScope found`.
- **How to avoid:** Pass `List<AttendanceRecord> records` as an optional parameter to `ParentApprovalModal` (populated automatically in `ParentApprovalModal.show(...)` or resolved safely), OR wrap `ProviderScope.containerOf(context)` in a try/catch so when `ParentApprovalModal` is pumped without a `ProviderScope`, it gracefully falls back to `widget.records ?? const []` and synthesizes lesson rows from `request.lessonNumbers` and `request.subjectNames`. Also check how `test/attendance_justification_modal_test.dart:157` matches the submit button text and update/align the test assertions accordingly.

### Pitfall 2: Legacy `studentName` Stored in Firestore Documents
- **What goes wrong:** Fixing `requestJustification` in `FirestoreSchoolRepository` only fixes *newly created* justification requests. Existing documents in `users/{uid}/justification_requests` created while testing under the parent's Google account already have `studentName: "Bartosz Jankiewicz"`.
- **How to avoid:** Apply the student profile name resolution both when creating/responding to a request **and** when rendering the banner/modal (`effectiveStudentName`), using `studentProfileProvider` (or fallback `'Oskar Jankiewicz'`) whenever `req.studentName` matches the parent's `displayName`.

### Pitfall 3: Partial Approval Leaving Unchecked Lessons in Limbo or Not Updating Local Overrides
- **What goes wrong:** When the parent unchecks 1 of 6 lessons in `ParentApprovalModal` and approves 5 lessons, if `FirestoreSchoolRepository.approveJustificationRequest` does not update `_localJustificationOverrides` with only the 5 `selectedRecordIds` (and if the Cloud Function keeps all 6 `recordIds` on the approved request document), then `getJustificationRequests` / `getAttendanceRecords` would either show all 6 lessons as `requested` or none of them.
- **How to avoid:**
  1. In `functions/src/justification_service.js` (`processParentReview`), overwrite `recordIds: reviewData.selectedRecordIds` (and `lessonNumbers: reviewData.selectedLessonNumbers`) when `selectedRecordIds` is provided.
  2. In `FirestoreSchoolRepository.approveJustificationRequest`, save `_localJustificationOverrides` only for `effectiveRecordIds` (`status: 'requested'`, `reason: req.reason`). That way, the 5 approved lessons immediately appear under `Oczekujące (5)` / `"5 wniosków czeka na wychowawcę"`, while the 1 unchecked lesson immediately returns to `Do usprawiedliwienia` (`JustificationStatus.none`).

### Pitfall 4: Missing Teacher Name Because of `teacher` vs `teacherName` Key Mismatch
- **What goes wrong:** `AttendanceRecord.teacherName` is always `null` for live Librus records because `librus_client.js:585` writes `teacher: ...` while `FirestoreSchoolRepository.getAttendanceRecords():1076` reads `item['teacherName']`.
- **How to avoid:** Read `(item['teacherName'] as String?) ?? (item['teacher'] as String?)`, treat empty strings as `null`, and fallback to matching `(dayOfWeek, lessonNumber)` in `data['timetable']` so both `teacherName` and `classroom` are populated.

---

## Code Examples

### 1. Resolving `AttendanceRecord`s for a `JustificationRequest` (D-04, D-05)
```dart
/// Resolves concrete [AttendanceRecord] items for [request] from [allRecords],
/// with fallback to date + lessonNumbers and synthetic fallback for isolated tests.
List<AttendanceRecord> resolveRequestRecords(
  JustificationRequest request,
  List<AttendanceRecord> allRecords,
) {
  final matched = <AttendanceRecord>[];
  final seenIds = <String>{};

  // 1. Match by explicit recordIds
  if (request.recordIds.isNotEmpty) {
    for (final r in allRecords) {
      if (request.recordIds.contains(r.id) && seenIds.add(r.id)) {
        matched.add(r);
      }
    }
  }

  // 2. Fallback match by date + lessonNumbers
  if (matched.isEmpty && request.date != null) {
    for (final r in allRecords) {
      final sameDay = r.date.year == request.date!.year &&
          r.date.month == request.date!.month &&
          r.date.day == request.date!.day;
      final matchesLesson = request.lessonNumbers.isEmpty ||
          request.lessonNumbers.contains(r.lessonNumber);
      if (sameDay && matchesLesson && seenIds.add(r.id)) {
        matched.add(r);
      }
    }
  }

  // 3. Synthetic fallback when allRecords is empty or doesn't contain the test IDs
  if (matched.isEmpty) {
    const defaultSlots = <int, String>{
      0: '07:10 - 07:55',
      1: '08:00 - 08:45',
      2: '08:55 - 09:40',
      3: '09:50 - 10:35',
      4: '10:45 - 11:30',
      5: '11:45 - 12:30',
      6: '12:45 - 13:30',
      7: '13:40 - 14:25',
      8: '14:35 - 15:20',
    };
    final count = request.recordIds.isNotEmpty
        ? request.recordIds.length
        : request.lessonNumbers.length;
    final baseDate = request.date ?? request.createdAt;
    for (var i = 0; i < count; i++) {
      final id = i < request.recordIds.length
          ? request.recordIds[i]
          : 'synthetic-${request.id}-$i';
      final lessonNum = i < request.lessonNumbers.length
          ? request.lessonNumbers[i]
          : (i + 1);
      final subject = i < request.subjectNames.length
          ? request.subjectNames[i]
          : (request.subjectNames.isNotEmpty ? request.subjectNames.first : 'Lekcja');
      matched.add(
        AttendanceRecord(
          id: id,
          date: baseDate,
          lessonNumber: lessonNum,
          timeSlot: defaultSlots[lessonNum] ?? '08:00 - 08:45',
          subjectName: subject,
          status: AttendanceStatus.absent,
          justificationStatus: JustificationStatus.pendingParent,
          justificationReason: request.reason,
        ),
      );
    }
  }

  matched.sort((a, b) {
    final dateCmp = a.date.compareTo(b.date);
    if (dateCmp != 0) return dateCmp;
    return a.lessonNumber.compareTo(b.lessonNumber);
  });
  return matched;
}
```

### 2. Grouping Resolved Records by Calendar Day (D-05, D-07)
```dart
Map<String, List<AttendanceRecord>> groupRecordsByDay(
  List<AttendanceRecord> records, {
  bool descendingDays = false,
}) {
  final sorted = List<AttendanceRecord>.from(records)
    ..sort((a, b) {
      final dA = DateTime(a.date.year, a.date.month, a.date.day);
      final dB = DateTime(b.date.year, b.date.month, b.date.day);
      final dayCmp = descendingDays ? dB.compareTo(dA) : dA.compareTo(dB);
      if (dayCmp != 0) return dayCmp;
      return a.lessonNumber.compareTo(b.lessonNumber);
    });

  final grouped = <String, List<AttendanceRecord>>{};
  for (final r in sorted) {
    final key =
        '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(key, () => []).add(r);
  }
  return grouped;
}
```

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter test` (Dart/Flutter UI & Repository) + `node --test` (Cloud Functions) |
| Config file | `pubspec.yaml` / `functions/package.json` |
| Quick run command | `flutter test test/attendance_justification_modal_test.dart && node --test functions/test/justification_requests.test.js` |
| Full suite command | `flutter test && npm --prefix functions test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| `REQ-ATT-01` (D-01..D-06) | `ParentApprovalModal` renders day-grouped lessons (lesson number, time slot, subject, teacher/classroom, reason, Q&A history), supports unchecking lessons for partial approval, and passes `selectedRecordIds` on PIN submit | Widget test | `flutter test test/attendance_justification_modal_test.dart` | ✅ Exists (needs new test cases for D-04..D-06) |
| `REQ-ATT-01` (D-06) | `processParentReview` & `formatLibrusJustificationPayload` support partial `selectedRecordIds` and multi-day `hoursByDate` | Unit test (Node) | `node --test functions/test/justification_requests.test.js` | ✅ Exists (needs new test cases for D-06) |
| `REQ-ATT-02` (D-07..D-09) | `AttendanceScreen` renders `Oczekujące (Y)` filter chip, expands `"X wnioski czekają na wychowawcę"` banner to show day-grouped pending lessons with teacher/reason, and supports individual `Cofnij` and bulk `Cofnij wszystkie` | Widget test | `flutter test test/attendance_pending_requests_test.dart` | ❌ Wave 0 / new test file to create in Phase 23 |

### Sampling Rate
- **Per task commit:** `flutter test test/attendance_justification_modal_test.dart && node --test functions/test/justification_requests.test.js`
- **Per wave merge:** `flutter test && npm --prefix functions test`
- **Phase gate:** Full suite green + `flutter analyze` with 0 errors before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/attendance_pending_requests_test.dart` — new widget test verifying `REQ-ATT-02` (D-07 expandable pending banner, D-08 single vs bulk `Cofnij`, D-09 `Oczekujące (Y)` filter pill) and `REQ-ATT-01` banner click on `AttendanceScreen`.
- [ ] Extend `test/attendance_justification_modal_test.dart` — add test cases for resolved `AttendanceRecord` day grouping (D-04, D-05) and checkbox partial selection (`selectedRecordIds`, D-06).
- [ ] Extend `functions/test/justification_requests.test.js` — add test cases for partial `selectedRecordIds` and multi-day `hoursByDate` in `processParentReview` and `formatLibrusJustificationPayload`.

---

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | Yes | 4-digit Parent PIN verification in `ParentApprovalModal` and server-side SHA-256 PIN verification in `verifyParentPinHash` (`[VERIFIED: functions/src/justification_service.js:24-39]`). |
| V4 Access Control | Yes | Approval/rejection actions in `AttendanceScreen`, `DashboardMobileView`, and `DashboardMetricsColumn` are gated by `isParent` (`activeRoleProvider == UserRole.parent`). |
| V5 Input Validation | Yes | `ParentApprovalModal` requires at least 1 selected lesson (`_selectedRecordIds.isNotEmpty`) and a 4-digit PIN before calling `onApprove`. Server validates `selectedRecordIds` is a non-empty array when provided. |

---

## Sources

### Primary (HIGH confidence — Verified In-Repo)
- `lib/presentation/screens/attendance/attendance_screen.dart` (`:175-261`, `:860-1085`, `:1519-1547`) — Filter pills, `"X wnioski czekają na wychowawcę"` banner, `_buildParentRequestsBanner`, and `_formatDayHeader`.
- `lib/presentation/screens/attendance/widgets/parent_approval_modal.dart` (`:1-401`) — Current PIN approval modal implementation.
- `lib/presentation/screens/attendance/widgets/parent_rejection_modal.dart` (`:1-393`) — Current rejection / Q&A dialog modal implementation.
- `lib/presentation/screens/dashboard/widgets/dashboard_mobile_view.dart` (`:293-455`) & `lib/presentation/screens/dashboard/widgets/dashboard_metrics_column.dart` (`:547-706`) — Dashboard pending justification banners.
- `lib/data/repositories/firestore_school_repository.dart` (`:991-1083`, `:1510-1740`) — `getAttendanceRecords`, `requestJustification`, `approveJustificationRequest`, `rejectJustificationRequest`, `respondJustificationRequest`.
- `lib/presentation/providers/school_providers.dart` (`:184-322`) — `AttendanceNotifier` and `justificationRequestsProvider`.
- `functions/src/justification_service.js` (`:1-252`) & `functions/src/librus_client.js` (`:579-590`) — Backend justification review logic and Librus attendance scraper format.
- `test/attendance_justification_modal_test.dart` (`:1-168`) & `functions/test/justification_requests.test.js` (`:1-209`) — Existing automated test suites.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — 100% existing Flutter/Riverpod/Node stack verified in `pubspec.yaml` and `functions/package.json`.
- Architecture: HIGH — Every file, line number, provider, and Cloud Function endpoint was inspected directly.
- Pitfalls: HIGH — Root causes of both the student name bug (`appUser.displayName`) and missing teacher/classroom (`item['teacher']` vs `item['teacherName']`) were confirmed directly in the source code.

**Research date:** 2026-04-20
**Valid until:** 2026-05-20
