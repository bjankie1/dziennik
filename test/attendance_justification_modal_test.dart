import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edusync/domain/models/justification_request.dart';
import 'package:edusync/presentation/screens/attendance/justification_modal.dart';
import 'package:edusync/presentation/screens/attendance/widgets/parent_approval_modal.dart';
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

      final approveButton = find.text('Zatwierdź z PIN-em');
      expect(approveButton, findsOneWidget);
      expect(find.text('Odrzuć wniosek'), findsOneWidget);

      await tester.tap(approveButton);
      await tester.pumpAndSettle();

      expect(approvedPin, equals('1234'));
    },
  );
}
