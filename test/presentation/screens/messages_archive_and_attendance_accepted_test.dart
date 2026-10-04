import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:edusync/data/repositories/mock_school_repository.dart';
import 'package:edusync/domain/models/attendance_record.dart';
import 'package:edusync/domain/models/justification_request.dart';
import 'package:edusync/domain/models/message_thread.dart';
import 'package:edusync/domain/models/student_profile.dart';
import 'package:edusync/domain/models/user_role.dart';
import 'package:edusync/presentation/providers/auth_providers.dart';
import 'package:edusync/presentation/providers/school_providers.dart';
import 'package:edusync/presentation/providers/tasks_provider.dart';
import 'package:edusync/presentation/screens/attendance/attendance_screen.dart';
import 'package:edusync/presentation/screens/attendance/widgets/accepted_justifications_summary_card.dart';
import 'package:edusync/presentation/screens/messages/messages_screen.dart';
import 'package:edusync/presentation/screens/messages/widgets/archive_box_icon.dart';

class _FakeParentNotifier extends AppUserNotifier {
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

class _ArchiveTestRepository extends MockSchoolRepository {
  List<MessageThread> threads;
  List<AttendanceRecord> records;

  _ArchiveTestRepository({
    required this.threads,
    required this.records,
  });

  @override
  Future<List<MessageThread>> getMessages() async {
    return List.unmodifiable(threads);
  }

  @override
  Future<void> archiveMessage(String id, {bool isArchived = true}) async {
    final index = threads.indexWhere((m) => m.id == id);
    if (index != -1) {
      threads[index] = threads[index].copyWith(
        isArchived: isArchived,
        isUnread: isArchived ? false : threads[index].isUnread,
      );
    }
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    return List.unmodifiable(records);
  }

  @override
  Future<List<JustificationRequest>> getJustificationRequests() async {
    return const [];
  }

  @override
  Future<StudentProfile> getStudentProfile() async {
    return const StudentProfile(
      id: '1234567u',
      name: 'Oskar Jankiewicz',
      className: '4 k Lic',
      schoolName: 'LO X Wrocław',
      avatarUrl: '',
      attendancePercentage: 95.0,
      overallAverage: 4.9,
      previousPeriodAverage: 4.8,
      classRank: 1,
      totalStudentsInClass: 28,
      unreadMessagesCount: 1,
      currentWeek: 'Tydzień A',
      luckyNumber: 15,
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pl_PL', null);
    await initializeDateFormatting('pl', null);
  });

  testWidgets(
    'MessagesScreen hides archived messages by default, toggles Pokaż zarchiwizowane chip, matches 30px button heights, and supports manual archiving with Undo',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _ArchiveTestRepository(
        threads: [
          MessageThread(
            id: 'msg_active_1',
            senderName: 'mgr Krzysztof Wiśniewski',
            senderInitials: 'KW',
            senderRole: 'Wychowawca',
            subject: 'Wycieczka klasowa w Karkonosze',
            preview: 'Przypominam o wpłacie zaliczki.',
            body: 'Przypominam o wpłacie zaliczki.',
            timestamp: DateTime(2026, 10, 3, 10, 30),
            isUnread: true,
            isArchived: false,
          ),
          MessageThread(
            id: 'msg_archived_1',
            senderName: 'e-Usprawiedliwienia',
            senderInitials: 'EU',
            senderRole: 'System Librus',
            subject: 'Potwierdzenie usprawiedliwienia nieobecności',
            preview: 'Usprawiedliwienie nieobecności ucznia zostało zaakceptowane.',
            body: 'Usprawiedliwienie nieobecności ucznia zostało zaakceptowane.',
            timestamp: DateTime(2026, 10, 1, 14, 0),
            isUnread: false,
            isArchived: true,
            isAutoArchived: true,
          ),
        ],
        records: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolRepositoryProvider.overrideWithValue(repo),
            announcementsProvider.overrideWith((ref) async => const []),
            tasksStreamProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: const MaterialApp(
            home: MessagesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // By default, active message is visible and auto-archived message is hidden
      expect(find.text('Wycieczka klasowa w Karkonosze'), findsOneWidget);
      expect(
        find.text('Potwierdzenie usprawiedliwienia nieobecności'),
        findsNothing,
      );

      // Filter chip shows count of archived messages and vector ArchiveBoxIcon inline with search bar
      final archiveFilterChip = find.byKey(
        const ValueKey('messages_archive_filter_chip'),
      );
      expect(archiveFilterChip, findsOneWidget);
      expect(find.text('Pokaż zarchiwizowane (1)'), findsOneWidget);
      expect(
        find.descendant(
          of: archiveFilterChip,
          matching: find.byType(ArchiveBoxIcon),
        ),
        findsOneWidget,
      );
      final searchCenterY = tester.getCenter(find.byType(TextField)).dy;
      final filterChipCenterY = tester.getCenter(archiveFilterChip).dy;
      expect((searchCenterY - filterChipCenterY).abs(), lessThan(4.0));

      // Tap filter chip to reveal archived messages
      await tester.tap(archiveFilterChip);
      await tester.pumpAndSettle();

      expect(
        find.text('Potwierdzenie usprawiedliwienia nieobecności'),
        findsOneWidget,
      );
      expect(find.text('Auto-archiwum'), findsOneWidget);

      // Hide archived again and verify equal 30px height on task and archive buttons
      await tester.tap(archiveFilterChip);
      await tester.pumpAndSettle();
      expect(
        find.text('Potwierdzenie usprawiedliwienia nieobecności'),
        findsNothing,
      );

      final taskActionBtn = find.byKey(
        const ValueKey('task_action_msg_active_1'),
      );
      final archiveActionBtn = find.byKey(
        const ValueKey('archive_message_msg_active_1'),
      );
      expect(taskActionBtn, findsOneWidget);
      expect(archiveActionBtn, findsOneWidget);
      expect(
        find.descendant(
          of: archiveActionBtn,
          matching: find.byType(ArchiveBoxIcon),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(archiveActionBtn).height, equals(30.0));
      expect(
        tester.getSize(archiveActionBtn).height,
        equals(tester.getSize(taskActionBtn).height),
      );
      await tester.tap(archiveActionBtn);
      await tester.pumpAndSettle();

      // Now both messages are archived, so active view shows empty state and chip shows (2)
      expect(find.text('Wycieczka klasowa w Karkonosze'), findsNothing);
      expect(find.text('Pokaż zarchiwizowane (2)'), findsOneWidget);
      expect(find.text('Wiadomość przeniesiona do archiwum'), findsOneWidget);

      // Tap Cofnij on SnackBar to restore the message
      await tester.tap(find.text('Cofnij'));
      await tester.pumpAndSettle();

      expect(find.text('Wycieczka klasowa w Karkonosze'), findsOneWidget);
      expect(find.text('Pokaż zarchiwizowane (1)'), findsOneWidget);

      // Verify compact icon+badge toggle on narrow viewport (< 600px)
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.text('Pokaż zarchiwizowane (1)'), findsNothing);
      expect(
        find.descendant(
          of: archiveFilterChip,
          matching: find.byType(ArchiveBoxIcon),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: archiveFilterChip,
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AttendanceScreen shows Usprawiedliwione (X) count, AcceptedJustificationsSummaryCard, and teacher approval badges on excused lessons',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      expect(AcceptedJustificationsSummaryCard.formatLessonsCount(1), '1 lekcja');
      expect(AcceptedJustificationsSummaryCard.formatLessonsCount(2), '2 lekcje');
      expect(AcceptedJustificationsSummaryCard.formatLessonsCount(5), '5 lekcji');
      expect(AcceptedJustificationsSummaryCard.formatLessonsCount(12), '12 lekcji');
      expect(AcceptedJustificationsSummaryCard.formatLessonsCount(22), '22 lekcje');
      expect(AcceptedJustificationsSummaryCard.formatLessonsCount(25), '25 lekcji');

      final repo = _ArchiveTestRepository(
        threads: const [],
        records: [
          AttendanceRecord(
            id: 'att_exc_1',
            date: DateTime(2026, 10, 2),
            lessonNumber: 2,
            subjectName: 'Matematyka',
            classroom: '204',
            teacherName: 'dr A. Nowak',
            type: AttendanceType.excused,
            timeSlot: '08:50 — 09:35',
            justificationStatus: JustificationStatus.approved,
            justificationReason: 'Wizyta lekarska',
          ),
          AttendanceRecord(
            id: 'att_exc_2',
            date: DateTime(2026, 10, 2),
            lessonNumber: 3,
            subjectName: 'Fizyka',
            classroom: '14',
            teacherName: 'mgr J. Wiśniewski',
            type: AttendanceType.excused,
            timeSlot: '09:45 — 10:30',
            justificationStatus: JustificationStatus.approved,
            justificationReason: 'Wizyta lekarska',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolRepositoryProvider.overrideWithValue(repo),
            appUserProvider.overrideWith(_FakeParentNotifier.new),
          ],
          child: const MaterialApp(
            home: AttendanceScreen(initialFilter: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Filter chip shows count: Usprawiedliwione (2)
      expect(find.text('Usprawiedliwione (2)'), findsOneWidget);

      // Summary card is visible when Usprawiedliwione filter is active
      final summaryCard = find.byKey(
        const ValueKey('accepted_justifications_summary_card'),
      );
      expect(summaryCard, findsOneWidget);
      expect(
        find.textContaining('Zaakceptowane usprawiedliwienia (2 lekcje • 1 dzień)'),
        findsOneWidget,
      );

      // Lesson rows display explicit teacher approval status and reason
      expect(
        find.text(
          'Usprawiedliwiona • Zaakceptowano przez wychowawcę (Wizyta lekarska)',
        ),
        findsNWidgets(2),
      );

      // Expand the summary card to see day breakdown
      await tester.tap(
        find.byKey(const ValueKey('accepted_justifications_banner_toggle')),
      );
      await tester.pumpAndSettle();

      expect(find.text('L2 Matematyka, L3 Fizyka'), findsOneWidget);
      expect(find.text('Powód: Wizyta lekarska'), findsOneWidget);
    },
  );

  testWidgets(
    'Announcement.formatContent preserves line breaks and restores structure for flattened bullet and numbered announcements in MessagesScreen',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const rawAuditions =
          'We wtorek 6 października 2026 roku w auli szkolnej odbędą się przesłuchania do „Utalentowanej Dziesiątki" – zajęć pozalekcyjnych. '
          'Szczegóły organizacyjne: • Czas: Zapraszamy na 6. godzinę lekcyjną (w razie potrzeby przesłuchania zostaną przedłużone na 7. godzinę). '
          '• Zgłoszenia: Zaraz przy wejściu na aulę będzie znajdował się stolik z listą chętnych. '
          '• Wokaliści: Osoby śpiewające do podkładu muzycznego proszone są o zabranie go ze sobą. '
          'W przypadku dodatkowych pytań przed przesłuchaniami, zapraszamy do kontaktu w gabinecie C202 – pedagog Anita Piechnik.';

      final formattedAuditions = Announcement.formatContent(rawAuditions);
      expect(
        formattedAuditions,
        contains('\n\nSzczegóły organizacyjne:\n• Czas: Zapraszamy na 6. godzinę lekcyjną'),
      );
      expect(formattedAuditions, contains('\n• Zgłoszenia: Zaraz przy wejściu'));
      expect(
        formattedAuditions,
        contains('\n\nW przypadku dodatkowych pytań przed przesłuchaniami'),
      );

      const rawRules =
          'REGULAMIN SZKOLNEGO KONKURSU: „Jesieniara" 1. Postanowienia ogólne '
          '• Organizatorem konkursu jest Biblioteka Szkolna LO nr X we Wrocławiu. '
          '2. Cele konkursu • Promowanie czytelnictwa. '
          '5. Terminy • Konkurs trwa od dnia 28.09.2026 r. do dnia 5.10.2026 r. '
          '• Rozstrzygnięcie konkursu nastąpi 9.10.2026 r. 6. Ocena prac i nagrody '
          '• Laureaci otrzymają nagrody. Nauczyciele bibliotekarze: Marta Kruk Magdalena Wilkocka';

      final formattedRules = Announcement.formatContent(rawRules);
      expect(formattedRules, contains('\n\n1. Postanowienia ogólne\n• Organizatorem'));
      expect(formattedRules, contains('\n\n2. Cele konkursu\n• Promowanie'));
      expect(formattedRules, contains('od dnia 28.09.2026 r. do dnia 5.10.2026 r.'));
      expect(formattedRules, contains('\n\n6. Ocena prac i nagrody\n• Laureaci'));
      expect(formattedRules, contains('\n\nNauczyciele bibliotekarze: Marta Kruk'));

      final repo = _ArchiveTestRepository(threads: const [], records: const []);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolRepositoryProvider.overrideWithValue(repo),
            announcementsProvider.overrideWith(
              (ref) async => [
                Announcement(
                  id: 'ann_1',
                  title: "Przesłuchania 'Utalentowana X\"",
                  author: 'Anita Piechnik',
                  authorRole: 'Nauczyciel / Dyrekcja',
                  publishedDate: DateTime(2026, 9, 29),
                  content: rawAuditions,
                  tags: const ['Ogłoszenie szkolne', 'Ważne'],
                ),
              ],
            ),
            tasksStreamProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: const MaterialApp(
            home: MessagesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ogłoszenia'));
      await tester.pumpAndSettle();

      final selectable = tester.widget<SelectableText>(
        find.byType(SelectableText).first,
      );
      final renderedText = selectable.textSpan!.toPlainText();
      expect(renderedText, contains('\n• Czas:'));
      expect(renderedText, contains('\n• Zgłoszenia:'));
    },
  );
}
