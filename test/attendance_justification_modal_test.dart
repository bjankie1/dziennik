import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edusync/domain/models/attendance_record.dart';
import 'package:edusync/domain/models/justification_request.dart';
import 'package:edusync/presentation/screens/attendance/justification_modal.dart';
import 'package:edusync/presentation/screens/attendance/widgets/parent_approval_modal.dart';
import 'package:edusync/presentation/screens/attendance/widgets/parent_rejection_modal.dart';
import 'package:edusync/presentation/screens/attendance/widgets/student_justification_modal.dart';

void main() {
  testWidgets(
    'StudentJustificationModal keeps Wyślij prośbę do rodzica button visible and tappable on compact mobile screen (360x640)',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? submittedReason;
      DateTime? submittedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    StudentJustificationModal.show(
                      context,
                      ['rec_1', 'rec_2', 'rec_3'],
                      initialDate: DateTime(2026, 9, 29),
                      onConfirm: (reason, selectedDate) {
                        submittedReason = reason;
                        submittedDate = selectedDate;
                      },
                    );
                  },
                  child: const Text('Otwórz modal ucznia'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Otwórz modal ucznia'));
      await tester.pumpAndSettle();

      // Verify modal title and submit button are visible without scrolling
      expect(find.text('Poproś rodzica o usprawiedliwienie'), findsOneWidget);
      final submitButton = find.text('Wyślij prośbę do rodzica');
      expect(submitButton, findsOneWidget);
      expect(find.text('Anuluj'), findsOneWidget);

      // Select quick reason chip and tap submit directly
      await tester.tap(find.text('Złe samopoczucie'));
      await tester.pump();

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(submittedReason, equals('Złe samopoczucie'));
      expect(submittedDate, equals(DateTime(2026, 9, 29)));
    },
  );

  testWidgets(
    'JustificationModal keeps Zatwierdź i wyślij usprawiedliwienie button visible on compact mobile screen (360x640)',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? submittedPin;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    JustificationModal.show(
                      context,
                      ['rec_1'],
                      'Wizyta lekarska',
                      (reason, pin, selectedDate) {
                        submittedPin = pin;
                      },
                    );
                  },
                  child: const Text('Otwórz modal rodzica'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Otwórz modal rodzica'));
      await tester.pumpAndSettle();

      final submitButton = find.text('Zatwierdź i wyślij usprawiedliwienie');
      expect(submitButton, findsOneWidget);

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(submittedPin, equals('1234'));
    },
  );

  testWidgets(
    'ParentApprovalModal keeps Zatwierdź z PIN-em button visible on compact mobile screen (360x640)',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? approvedPin;
      final request = JustificationRequest(
        id: 'req_1',
        studentLogin: 'oskar_login',
        studentName: 'Oskar',
        recordIds: const ['rec_1', 'rec_2'],
        lessonNumbers: const [1, 2],
        subjectNames: const ['Matematyka', 'Język polski', 'Fizyka', 'Chemia'],
        date: DateTime(2026, 9, 29),
        reason: 'Bardzo długi powód nieobecności wpisany przez ucznia na telefonie komórkowym',
        status: JustificationRequestStatus.pendingParentApproval,
        requestedAt: DateTime(2026, 9, 29, 10, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    ParentApprovalModal.show(
                      context,
                      request,
                      onApprove: (pin) async {
                        approvedPin = pin;
                        return true;
                      },
                      onReject: (_) async => true,
                    );
                  },
                  child: const Text('Otwórz akceptację'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Otwórz akceptację'));
      await tester.pumpAndSettle();

      final approveButton = find.textContaining('Zatwierdź z PIN-em');
      expect(approveButton, findsOneWidget);
      expect(find.text('Odrzuć wniosek'), findsOneWidget);

      await tester.tap(approveButton);
      await tester.pumpAndSettle();

      expect(approvedPin, equals('1234'));
    },
  );

  testWidgets(
    'ParentApprovalModal renders day-grouped lesson details with Polish day headers, hours, subject, teacher, classroom, and Q&A history (D-04, D-05)',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final availableRecords = <AttendanceRecord>[
        AttendanceRecord(
          id: 'att-2026-09-28-1',
          date: DateTime(2026, 9, 28),
          lessonNumber: 1,
          subjectName: 'Język polski',
          type: AttendanceType.absent,
          timeSlot: '08:00 - 08:45',
          teacherName: 'Melska Grażyna',
          classroom: '204',
        ),
        AttendanceRecord(
          id: 'att-2026-09-29-3',
          date: DateTime(2026, 9, 29),
          lessonNumber: 3,
          subjectName: 'Matematyka',
          type: AttendanceType.absent,
          timeSlot: '09:50 - 10:35',
          teacherName: 'Kowalski Jan',
          classroom: '105',
        ),
      ];

      final request = JustificationRequest(
        id: 'req_details',
        studentLogin: '11010033',
        studentName: 'Bartosz Jankiewicz', // legacy parent name should resolve to Oskar Jankiewicz
        recordIds: const ['att-2026-09-28-1', 'att-2026-09-29-3'],
        lessonNumbers: const [1, 3],
        subjectNames: const ['Język polski', 'Matematyka'],
        date: DateTime(2026, 9, 28),
        reason: 'Choroba i wizyta u lekarza',
        status: JustificationRequestStatus.pendingParentApproval,
        requestedAt: DateTime(2026, 9, 29, 12, 0),
        dialogHistory: [
          JustificationDialogEntry(
            senderRole: 'parent',
            senderName: 'Bartosz Jankiewicz',
            message: 'Dlaczego opuściłeś te lekcje?',
            timestamp: DateTime(2026, 9, 29, 11, 0),
          ),
          JustificationDialogEntry(
            senderRole: 'student',
            senderName: 'Oskar Jankiewicz',
            message: 'Byłem u lekarza z gorączką',
            timestamp: DateTime(2026, 9, 29, 11, 30),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    ParentApprovalModal.show(
                      context,
                      request,
                      availableRecords: availableRecords,
                      onApprove: (_) async => true,
                      onReject: (_) async => true,
                    );
                  },
                  child: const Text('Otwórz szczegóły'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Otwórz szczegóły'));
      await tester.pumpAndSettle();

      // Effective student name (D-03)
      expect(find.text('Wniosek od: Oskar Jankiewicz'), findsOneWidget);

      // Day headers (D-05)
      expect(find.text('Poniedziałek, 28 Września 2026'), findsOneWidget);
      expect(find.text('Wtorek, 29 Września 2026'), findsOneWidget);

      // Lesson number + hours, subject, teacher + classroom (D-05)
      expect(find.text('Lekcja 1 • 08:00 - 08:45'), findsOneWidget);
      expect(find.text('Język polski'), findsOneWidget);
      expect(find.text('Melska Grażyna • Sala 204'), findsOneWidget);

      expect(find.text('Lekcja 3 • 09:50 - 10:35'), findsOneWidget);
      expect(find.text('Matematyka'), findsOneWidget);
      expect(find.text('Kowalski Jan • Sala 105'), findsOneWidget);

      // Reason and Q&A history (D-05)
      expect(find.text('"Choroba i wizyta u lekarza"'), findsOneWidget);
      expect(find.text('Historia rozmowy z uczniem:'), findsOneWidget);
      expect(find.text('Dlaczego opuściłeś te lekcje?'), findsOneWidget);
      expect(find.text('Byłem u lekarza z gorączką'), findsOneWidget);
    },
  );

  testWidgets(
    'ParentApprovalModal supports per-lesson checkboxes and partial approval via onApproveSelected (D-06)',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? approvedPin;
      List<String>? approvedRecordIds;

      final availableRecords = <AttendanceRecord>[
        AttendanceRecord(
          id: 'att-2026-09-29-1',
          date: DateTime(2026, 9, 29),
          lessonNumber: 1,
          subjectName: 'Język polski',
          type: AttendanceType.absent,
          timeSlot: '08:00 - 08:45',
          teacherName: 'Melska Grażyna',
        ),
        AttendanceRecord(
          id: 'att-2026-09-29-2',
          date: DateTime(2026, 9, 29),
          lessonNumber: 2,
          subjectName: 'Matematyka',
          type: AttendanceType.absent,
          timeSlot: '08:55 - 09:40',
          teacherName: 'Kowalski Jan',
        ),
        AttendanceRecord(
          id: 'att-2026-09-29-3',
          date: DateTime(2026, 9, 29),
          lessonNumber: 3,
          subjectName: 'Fizyka',
          type: AttendanceType.absent,
          timeSlot: '09:50 - 10:35',
          teacherName: 'Nowak Piotr',
        ),
      ];

      final request = JustificationRequest(
        id: 'req_partial',
        studentLogin: '11010033',
        studentName: 'Oskar Jankiewicz',
        recordIds: const [
          'att-2026-09-29-1',
          'att-2026-09-29-2',
          'att-2026-09-29-3',
        ],
        lessonNumbers: const [1, 2, 3],
        subjectNames: const ['Język polski', 'Matematyka', 'Fizyka'],
        date: DateTime(2026, 9, 29),
        reason: 'Choroba',
        status: JustificationRequestStatus.pendingParentApproval,
        requestedAt: DateTime(2026, 9, 29, 10, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    ParentApprovalModal.show(
                      context,
                      request,
                      availableRecords: availableRecords,
                      onApprove: (_) async => true,
                      onApproveSelected: (pin, selectedIds) async {
                        approvedPin = pin;
                        approvedRecordIds = selectedIds;
                        return true;
                      },
                      onReject: (_) async => true,
                    );
                  },
                  child: const Text('Otwórz częściową akceptację'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Otwórz częściową akceptację'));
      await tester.pumpAndSettle();

      // Initially all 3 lessons are checked
      expect(find.text('Zatwierdź z PIN-em (3 z 3 lekcji)'), findsOneWidget);

      // Uncheck the second lesson (Matematyka)
      final checkboxFinder = find.byKey(const ValueKey('approval_checkbox_att-2026-09-29-2'));
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxFinder);
      await tester.pump();

      expect(find.text('Zatwierdź z PIN-em (2 z 3 lekcji)'), findsOneWidget);

      // Submit partial approval
      await tester.tap(find.text('Zatwierdź z PIN-em (2 z 3 lekcji)'));
      await tester.pumpAndSettle();

      expect(approvedPin, equals('1234'));
      expect(approvedRecordIds, equals(['att-2026-09-29-1', 'att-2026-09-29-3']));
    },
  );

  testWidgets(
    'ParentRejectionModal renders dynamic studentName in subtitle, label, and submit button, plus multi-day date range summary',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? rejectedReason;
      final availableRecords = <AttendanceRecord>[
        AttendanceRecord(
          id: 'att-2026-09-28-1',
          date: DateTime(2026, 9, 28),
          lessonNumber: 1,
          subjectName: 'Język polski',
          type: AttendanceType.absent,
          timeSlot: '08:00 - 08:45',
        ),
        AttendanceRecord(
          id: 'att-2026-09-29-3',
          date: DateTime(2026, 9, 29),
          lessonNumber: 3,
          subjectName: 'Matematyka',
          type: AttendanceType.absent,
          timeSlot: '09:50 - 10:35',
        ),
      ];

      final request = JustificationRequest(
        id: 'req_reject_multi',
        studentLogin: '11010033',
        studentName: 'Bartosz Jankiewicz', // legacy parent name resolves to Oskar Jankiewicz
        recordIds: const ['att-2026-09-28-1', 'att-2026-09-29-3'],
        lessonNumbers: const [1, 3],
        subjectNames: const ['Język polski', 'Matematyka'],
        date: DateTime(2026, 9, 28),
        reason: 'Wyjazd',
        status: JustificationRequestStatus.pendingParentApproval,
        requestedAt: DateTime(2026, 9, 29, 12, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    ParentRejectionModal.show(
                      context,
                      request,
                      availableRecords: availableRecords,
                      onReject: (reason) async {
                        rejectedReason = reason;
                        return true;
                      },
                    );
                  },
                  child: const Text('Otwórz odrzucenie'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Otwórz odrzucenie'));
      await tester.pumpAndSettle();

      // Dynamic studentName instead of hardcoded Oskarowi
      expect(
        find.text(
          'Wyjaśnij uczniowi (Oskar Jankiewicz) powód odmowy lub zadaj pytanie',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Komentarz rodzica (widoczny dla: Oskar Jankiewicz)'),
        findsOneWidget,
      );
      expect(
        find.text('Przekaż odmowę (Oskar Jankiewicz)'),
        findsOneWidget,
      );

      // Multi-day date range summary (28.09–29.09)
      expect(find.text('28.09–29.09'), findsOneWidget);

      await tester.tap(find.text('Przekaż odmowę (Oskar Jankiewicz)'));
      await tester.pumpAndSettle();

      expect(rejectedReason, isNotNull);
    },
  );
}
