import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edusync/data/repositories/mock_school_repository.dart';
import 'package:edusync/domain/models/attendance_record.dart';
import 'package:edusync/domain/models/justification_request.dart';
import 'package:edusync/domain/models/student_profile.dart';
import 'package:edusync/domain/models/user_role.dart';
import 'package:edusync/presentation/providers/auth_providers.dart';
import 'package:edusync/presentation/providers/school_providers.dart';
import 'package:edusync/presentation/screens/attendance/attendance_screen.dart';
import 'package:edusync/presentation/screens/attendance/widgets/parent_approval_modal.dart';

class _ConfigurableSchoolRepository extends MockSchoolRepository {
  List<AttendanceRecord> records;
  List<JustificationRequest> requests;
  final List<List<String>> cancelledBatches = [];
  List<String>? lastApprovedSelectedIds;

  _ConfigurableSchoolRepository({
    required this.records,
    required this.requests,
  });

  @override
  Future<StudentProfile> getStudentProfile() async {
    return const StudentProfile(
      id: '1234567u',
      name: 'Oskar Jankiewicz',
      className: '4 k Lic',
      schoolName: 'LO X Wrocław',
      avatarUrl: '',
      attendancePercentage: 94.2,
      overallAverage: 4.8,
      previousPeriodAverage: 4.7,
      classRank: 2,
      totalStudentsInClass: 28,
      unreadMessagesCount: 0,
      currentWeek: 'Tydzień A',
      luckyNumber: 12,
    );
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    return List.unmodifiable(records);
  }

  @override
  Future<List<JustificationRequest>> getJustificationRequests() async {
    return List.unmodifiable(requests);
  }

  @override
  Future<void> cancelJustification(List<String> recordIds) async {
    cancelledBatches.add(List.from(recordIds));
    records = records.map((rec) {
      if (recordIds.contains(rec.id)) {
        return AttendanceRecord(
          id: rec.id,
          date: rec.date,
          lessonNumber: rec.lessonNumber,
          subjectName: rec.subjectName,
          type: AttendanceType.absent,
          timeSlot: rec.timeSlot,
          justificationStatus: JustificationStatus.none,
          justificationReason: null,
          classroom: rec.classroom,
          teacherName: rec.teacherName,
        );
      }
      return rec;
    }).toList();
  }

  @override
  Future<void> submitJustification(
    List<String> recordIds,
    String reason, {
    DateTime? date,
  }) async {
    records = records.map((rec) {
      final matchesDate = date != null &&
          rec.date.year == date.year &&
          rec.date.month == date.month &&
          rec.date.day == date.day;
      if (recordIds.contains(rec.id) || matchesDate) {
        return AttendanceRecord(
          id: rec.id,
          date: rec.date,
          lessonNumber: rec.lessonNumber,
          subjectName: rec.subjectName,
          type: rec.type,
          timeSlot: rec.timeSlot,
          justificationStatus: JustificationStatus.requested,
          justificationReason: reason,
          classroom: rec.classroom,
          teacherName: rec.teacherName,
        );
      }
      return rec;
    }).toList();
  }

  @override
  Future<bool> approveJustificationRequest(
    String requestId,
    String pin, {
    List<String>? selectedRecordIds,
  }) async {
    if (pin != '1234') return false;
    lastApprovedSelectedIds = selectedRecordIds;
    final idx = requests.indexWhere((r) => r.id == requestId);
    if (idx == -1) return false;
    final existing = requests[idx];
    final hasExplicit =
        selectedRecordIds != null && selectedRecordIds.isNotEmpty;
    final effectiveIds =
        hasExplicit ? selectedRecordIds : existing.recordIds;
    final deselected = existing.recordIds
        .where((id) => !effectiveIds.contains(id))
        .toList();
    if (deselected.isNotEmpty) {
      await cancelJustification(deselected);
    }
    requests[idx] = existing.copyWith(
      status: JustificationRequestStatus.approved,
      recordIds: effectiveIds,
      reviewedBy: 'parent',
      reviewedAt: DateTime(2026, 9, 23, 19, 0),
    );
    await submitJustification(
      effectiveIds,
      existing.reason,
      date: hasExplicit ? null : existing.date,
    );
    return true;
  }
}

class _FixedParentUserNotifier extends AppUserNotifier {
  @override
  AppUser? build() {
    return const AppUser(
      displayName: 'Bartosz Jankiewicz',
      email: 'parent@example.com',
      role: UserRole.parent,
      studentLogin: '1234567u',
      primaryLogin: '7654321r',
      familyId: 'jankiewicz_family',
    );
  }
}

void main() {
  Widget buildTestScreen(_ConfigurableSchoolRepository repo) {
    return ProviderScope(
      overrides: [
        schoolRepositoryProvider.overrideWithValue(repo),
        appUserProvider.overrideWith(_FixedParentUserNotifier.new),
      ],
      child: const MaterialApp(
        home: AttendanceScreen(),
      ),
    );
  }

  testWidgets(
      'Interactive parent justification banner displays effectiveStudentName, date summary, and supports partial approval',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final records = [
      AttendanceRecord(
        id: 'att_003',
        date: DateTime(2026, 9, 22),
        lessonNumber: 3,
        subjectName: 'Historia',
        type: AttendanceType.absent,
        timeSlot: '09:50 - 10:35',
        justificationStatus: JustificationStatus.requested,
        justificationReason: 'Wizyta u lekarza specjalisty',
        teacherName: 'Jan Nowak',
        classroom: '104',
      ),
      AttendanceRecord(
        id: 'att_004',
        date: DateTime(2026, 9, 22),
        lessonNumber: 4,
        subjectName: 'Geografia',
        type: AttendanceType.absent,
        timeSlot: '10:45 - 11:30',
        justificationStatus: JustificationStatus.requested,
        justificationReason: 'Wizyta u lekarza specjalisty',
        teacherName: 'Maria Kowal',
        classroom: '208',
      ),
    ];

    final requests = [
      JustificationRequest(
        id: 'req_parent_01',
        studentLogin: '1234567u',
        // Legacy corrupted parent name on request document (D-02)
        studentName: 'Bartosz Jankiewicz',
        familyId: 'jankiewicz_family',
        primaryLogin: '7654321r',
        recordIds: const ['att_003', 'att_004'],
        lessonNumbers: const [3, 4],
        subjectNames: const ['Historia', 'Geografia'],
        date: DateTime(2026, 9, 22),
        reason: 'Wizyta u lekarza specjalisty',
        status: JustificationRequestStatus.pendingParentApproval,
        requestedAt: DateTime(2026, 9, 22, 16, 0),
      ),
    ];

    final repo = _ConfigurableSchoolRepository(
      records: records,
      requests: requests,
    );

    await tester.pumpWidget(buildTestScreen(repo));
    await tester.pumpAndSettle();

    // Verify D-01, D-02: Banner resolves child name 'Oskar Jankiewicz', date range, and 'Zobacz szczegóły →'
    final bannerFinder =
        find.byKey(const ValueKey('parent_pending_request_banner'));
    expect(bannerFinder, findsOneWidget);
    expect(
      find.text('Oskar Jankiewicz prosi o usprawiedliwienie'),
      findsOneWidget,
    );
    expect(
      find.text('Bartosz Jankiewicz prosi o usprawiedliwienie'),
      findsNothing,
    );
    expect(find.textContaining('22.09'), findsOneWidget);
    expect(find.text('Zobacz szczegóły →'), findsOneWidget);

    // Tap the banner body to open ParentApprovalModal
    await tester.tap(find.text('Zobacz szczegóły →'));
    await tester.pumpAndSettle();

    expect(find.byType(ParentApprovalModal), findsOneWidget);
    expect(find.text('Wtorek, 22 Września 2026'), findsOneWidget);
    expect(find.text('Zatwierdź z PIN-em (2 z 2 lekcji)'), findsOneWidget);

    // Deselect att_004 checkbox (D-06 partial approval)
    final checkbox4 = find.byKey(const ValueKey('approval_checkbox_att_004'));
    await tester.ensureVisible(checkbox4);
    await tester.tap(checkbox4);
    await tester.pump();

    expect(find.text('Zatwierdź z PIN-em (1 z 2 lekcji)'), findsOneWidget);

    // Enter PIN '1234' and approve
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    final submitBtn = find.text('Zatwierdź z PIN-em (1 z 2 lekcji)');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(repo.lastApprovedSelectedIds, equals(['att_003']));
    expect(repo.cancelledBatches, isNotEmpty);
    expect(repo.cancelledBatches.first, equals(['att_004']));

    final att3 = repo.records.firstWhere((r) => r.id == 'att_003');
    final att4 = repo.records.firstWhere((r) => r.id == 'att_004');
    expect(att3.justificationStatus, JustificationStatus.requested);
    expect(att4.justificationStatus, JustificationStatus.none);
  });

  testWidgets(
      'Expandable pending teacher banner shows day-grouped requested lessons and supports per-lesson and bulk Cofnij',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final records = [
      AttendanceRecord(
        id: 'att_req_1',
        date: DateTime(2026, 9, 21),
        lessonNumber: 1,
        subjectName: 'Matematyka',
        type: AttendanceType.absent,
        timeSlot: '08:00 - 08:45',
        justificationStatus: JustificationStatus.requested,
        justificationReason: 'Wizyta lekarska',
        teacherName: 'Anna Wiśniewska',
        classroom: '201',
      ),
      AttendanceRecord(
        id: 'att_req_2',
        date: DateTime(2026, 9, 21),
        lessonNumber: 2,
        subjectName: 'Język polski',
        type: AttendanceType.absent,
        timeSlot: '08:55 - 09:40',
        justificationStatus: JustificationStatus.requested,
        justificationReason: 'Wizyta lekarska',
        teacherName: 'Piotr Zieliński',
        classroom: '105',
      ),
    ];

    final repo = _ConfigurableSchoolRepository(
      records: records,
      requests: const [],
    );

    await tester.pumpWidget(buildTestScreen(repo));
    await tester.pumpAndSettle();

    // Verify D-07 collapsed state
    expect(find.text('2 wnioski czekają na wychowawcę'), findsOneWidget);
    expect(find.text('Pokaż szczegóły'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cancel_all_pending_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cancel_pending_att_req_1')),
      findsNothing,
    );

    // Tap accordion toggle to expand
    await tester.tap(find.byKey(const ValueKey('pending_teacher_banner_toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Ukryj szczegóły'), findsOneWidget);
    expect(find.text('Lekcja 1 • 08:00 - 08:45'), findsOneWidget);
    expect(find.text('Lekcja 2 • 08:55 - 09:40'), findsOneWidget);
    expect(find.textContaining('Anna Wiśniewska'), findsWidgets);
    expect(find.text('Powód: Wizyta lekarska'), findsNWidgets(2));

    // Tap per-lesson 'Cofnij' for att_req_1 (D-08)
    await tester.tap(find.byKey(const ValueKey('cancel_pending_att_req_1')));
    await tester.pumpAndSettle();

    expect(repo.cancelledBatches.last, equals(['att_req_1']));
    expect(find.text('1 wniosek czeka na wychowawcę'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cancel_pending_att_req_1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('cancel_pending_att_req_2')),
      findsOneWidget,
    );

    // Tap 'Cofnij wszystkie' for remaining pending lesson
    await tester.tap(find.byKey(const ValueKey('cancel_all_pending_button')));
    await tester.pumpAndSettle();

    expect(repo.cancelledBatches.last, equals(['att_req_2']));
    expect(find.textContaining('czeka na wychowawcę'), findsNothing);
    expect(find.textContaining('czekają na wychowawcę'), findsNothing);
  });

  testWidgets(
      '4th filter pill Oczekujące (Y) filters main attendance list to JustificationStatus.requested lessons',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final records = [
      AttendanceRecord(
        id: 'att_none_1',
        date: DateTime(2026, 9, 21),
        lessonNumber: 1,
        subjectName: 'Chemia',
        type: AttendanceType.absent,
        timeSlot: '08:00 - 08:45',
        justificationStatus: JustificationStatus.none,
      ),
      AttendanceRecord(
        id: 'att_req_1',
        date: DateTime(2026, 9, 22),
        lessonNumber: 2,
        subjectName: 'Biologia',
        type: AttendanceType.absent,
        timeSlot: '08:55 - 09:40',
        justificationStatus: JustificationStatus.requested,
        justificationReason: 'Choroba',
      ),
      AttendanceRecord(
        id: 'att_exc_1',
        date: DateTime(2026, 9, 23),
        lessonNumber: 3,
        subjectName: 'Fizyka',
        type: AttendanceType.excused,
        timeSlot: '09:50 - 10:35',
        justificationStatus: JustificationStatus.approved,
      ),
    ];

    final repo = _ConfigurableSchoolRepository(
      records: records,
      requests: const [],
    );

    await tester.pumpWidget(buildTestScreen(repo));
    await tester.pumpAndSettle();

    // Verify 4th filter pill 'Oczekujące (1)' is rendered (D-09)
    final pendingFilterChip = find.text('Oczekujące (1)');
    expect(pendingFilterChip, findsOneWidget);

    // Tap 'Oczekujące (1)' filter pill
    await tester.tap(pendingFilterChip);
    await tester.pumpAndSettle();

    // Only Biologia (JustificationStatus.requested) should be shown in the attendance list
    expect(find.text('Lekcja 2: Biologia'), findsOneWidget);
    expect(find.text('Lekcja 1: Chemia'), findsNothing);
    expect(find.text('Lekcja 3: Fizyka'), findsNothing);
  });
}
