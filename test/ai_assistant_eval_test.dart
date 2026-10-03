import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:edusync/core/services/school_ai_context_builder.dart';
import 'package:edusync/domain/models/ai_chat_message.dart';
import 'package:edusync/domain/models/attendance_record.dart';
import 'package:edusync/domain/models/grade.dart';
import 'package:edusync/domain/models/lesson_slot.dart';
import 'package:edusync/domain/models/message_thread.dart';
import 'package:edusync/domain/models/school_task.dart';
import 'package:edusync/domain/models/student_profile.dart';
import 'package:edusync/domain/models/subject.dart';

void main() {
  late SchoolAiContextSnapshotInput sampleInput;

  setUp(() {
    final now = DateTime(2026, 5, 11, 16, 30); // Poniedziałek 11.05.2026
    sampleInput = SchoolAiContextSnapshotInput(
      now: now,
      viewerRole: 'parent',
      student: const StudentProfile(
        id: '11010033',
        name: 'Oskar Jankiewicz',
        className: 'Klasa 7b',
        schoolName: 'SP nr 14 w Warszawie',
        avatarUrl: '',
        attendancePercentage: 94.2,
        overallAverage: 4.85,
        previousPeriodAverage: 4.70,
        classRank: 3,
        totalStudentsInClass: 26,
        unreadMessagesCount: 2,
        currentWeek: 'Tydzień A',
        luckyNumber: 17,
        educator: 'mgr Anna Nowak',
      ),
      upcomingExam: UpcomingEvent(
        title: 'Równania i wyrażenia algebraiczne — dział 5',
        subject: 'Matematyka',
        date: DateTime(2026, 5, 14),
        time: '08:55 - 09:40',
        room: 'Sala 201',
        type: 'Sprawdzian',
        daysRemaining: 3,
      ),
      subjects: [
        Subject(
          id: 'mat',
          name: 'Matematyka',
          teacherName: 'mgr Jan Kowalski',
          grades: [
            Grade(
              id: 'g1',
              subjectName: 'Matematyka',
              rawValue: '5',
              numericValue: 5.0,
              weight: 3,
              category: GradeCategory.exam,
              categoryName: 'Sprawdzian',
              comment: 'Wielomiany',
              teacher: 'mgr Jan Kowalski',
              date: DateTime(2026, 5, 8),
              term: 2,
            ),
          ],
        ),
      ],
      weekSchedule: {
        1: const [
          LessonSlot(
            lessonNumber: 1,
            subjectName: 'Język polski',
            startTime: '08:00',
            endTime: '08:45',
            room: '104',
            teacher: 'mgr Anna Nowak',
            status: LessonStatus.normal,
          ),
        ],
      },
      attendance: [
        AttendanceRecord(
          id: 'att1',
          date: DateTime(2026, 5, 7),
          lessonNumber: 2,
          subjectName: 'Geografia',
          type: AttendanceType.absent,
          timeSlot: '08:55 - 09:40',
          justificationStatus: JustificationStatus.none,
        ),
      ],
      messages: [
        // Message with generic subject "Informacja" where trip details are inside full body
        MessageThread(
          id: 'msg_warsaw_1',
          senderName: 'Anna Nowak',
          senderInitials: 'AN',
          senderRole: 'Wychowawca',
          subject: 'Informacja',
          preview: 'Informacja',
          body:
              'Szanowni Państwo, przypominam, że trzydniowa wycieczka klasy Oskara do Warszawy odbędzie się w dniach 18-20 maja 2026 r. Zbiórka przed szkołą o godz. 06:45.',
          timestamp: DateTime(2026, 5, 9, 14, 20),
          isUnread: true,
        ),
        // Message about parent meeting
        MessageThread(
          id: 'msg_meeting_2',
          senderName: 'Dyrekcja Szkoły',
          senderInitials: 'DS',
          senderRole: 'Dyrekcja',
          subject: 'Organizacja maja',
          preview: 'Organizacja maja',
          body:
              'Informujemy, że obowiązkowe zebranie z rodzicami podsumowujące oceny proponowane odbędzie się 28 maja 2026 o godz. 17:30 w sali 204.',
          timestamp: DateTime(2026, 5, 6, 10, 0),
          isUnread: false,
        ),
      ],
      tasks: [
        SchoolTask(
          id: 't1',
          familyId: 'jankiewicz_family',
          title: 'Wpłacić zaliczkę na wycieczkę',
          dueDate: DateTime(2026, 5, 15),
          priority: TaskPriority.high,
          assignedTo: TaskAssignee.parent,
          subject: 'Wycieczka',
          isCompleted: false,
          createdByRole: 'parent',
          createdByName: 'Tata',
          createdAt: DateTime(2026, 5, 5),
          source: TaskSource.manual,
        ),
      ],
      rawMetadata: const {
        'encryptedPassword': 'SUPER_SECRET_LIBRUS_PASSWORD_123',
        'parentPin': '9876',
        'fcmToken': 'SECRET_FCM_TOKEN_ABC',
      },
    );
  });

  test('SchoolAiContextBuilder includes full message bodies, Polish dates, and strips secrets', () {
    final snapshot = SchoolAiContextBuilder.buildContextSnapshot(sampleInput);

    // Temporal grounding
    expect(snapshot, contains('2026-05-11 (poniedziałek)'));
    expect(snapshot, contains('2026-05-12 (wtorek)'));

    // Full message bodies must be included even when subject is generic "Informacja"
    expect(snapshot, contains('wycieczka klasy Oskara do Warszawy odbędzie się w dniach 18-20 maja 2026'));
    expect(snapshot, contains('zebranie z rodzicami podsumowujące oceny proponowane odbędzie się 28 maja 2026 o godz. 17:30'));

    // Upcoming exam & grades
    expect(snapshot, contains('Równania i wyrażenia algebraiczne'));
    expect(snapshot, contains('Wielomiany'));

    // Security check: no secret values can appear in snapshot
    expect(snapshot, isNot(contains('SUPER_SECRET_LIBRUS_PASSWORD_123')));
    expect(snapshot, isNot(contains('SECRET_FCM_TOKEN_ABC')));

    final scrubbed = SchoolAiContextBuilder.sanitizeText(
      'Hasło to SUPER_SECRET_LIBRUS_PASSWORD_123 a PIN to 9876',
      sampleInput.rawMetadata,
    );
    expect(scrubbed, isNot(contains('SUPER_SECRET_LIBRUS_PASSWORD_123')));
    expect(scrubbed, isNot(contains('9876')));
  });

  test('AiChatMessage parses Gemini structured JSON output with citations, suggestedEvent, and suggestedTask', () {
    final geminiJson = jsonEncode({
      'answer': 'Najbliższy sprawdzian z **Matematyki** odbędzie się **14.05.2026**.',
      'sources': [
        {
          'type': 'exam',
          'label': '📅 Plan lekcji: Matematyka (14.05)',
          'route': '/plan',
          'targetId': 'exam_mat_1',
        }
      ],
      'suggestedEvent': {
        'title': 'Sprawdzian: Matematyka',
        'date': '2026-05-14',
        'startTime': '08:55',
        'description': 'Dział 5: Równania i wyrażenia algebraiczne',
      },
      'suggestedTask': {
        'title': 'Powtórzyć równania przed sprawdzianem',
        'dueDate': '2026-05-13',
        'category': 'exam',
      },
    });

    final message = AiChatMessage.fromGeminiStructuredJson(
      id: 'msg_test_1',
      rawJson: geminiJson,
      viewerRole: 'parent',
      modelUsed: 'gemini-3.8-flash',
    );

    expect(message.text, contains('Matematyki'));
    expect(message.sources.length, 1);
    // /plan should normalize to /plan-lekcji for GoRouter compatibility
    expect(message.sources.first.normalizedRoute, '/plan-lekcji');
    expect(message.suggestedEvent, isNotNull);
    expect(message.suggestedEvent!.date, '2026-05-14');
    expect(
      message.suggestedEvent!.buildGoogleCalendarUri().toString(),
      contains('calendar.google.com'),
    );
    expect(message.suggestedTask, isNotNull);
    expect(message.suggestedTask!.title, contains('Powtórzyć równania'));
  });

  test('Golden Polish Q&A evaluation: answers exam, Warsaw trip, and parent meeting queries with citations', () {
    // 1. "Kiedy jest następny sprawdzian?"
    final examReply = SchoolAiContextBuilder.generateGroundedLocalReply(
      question: 'Kiedy jest następny sprawdzian?',
      input: sampleInput,
    );
    expect(examReply.text, contains('Matematyka'));
    expect(examReply.text, contains('14.05.2026'));
    expect(examReply.sources.any((s) => s.normalizedRoute.startsWith('/plan-lekcji')), isTrue);
    expect(examReply.suggestedEvent?.date, '2026-05-14');

    // 2. "Kiedy jest wycieczka Oskara do Warszawy?"
    final tripReply = SchoolAiContextBuilder.generateGroundedLocalReply(
      question: 'Kiedy jest wycieczka Oskara do Warszawy?',
      input: sampleInput,
    );
    expect(tripReply.text, contains('18-20 maja 2026'));
    expect(tripReply.text, contains('Anna Nowak'));
    expect(tripReply.sources.first.normalizedRoute, '/wiadomosci');
    expect(tripReply.sources.first.targetId, 'msg_warsaw_1');
    expect(tripReply.suggestedEvent?.date, '2026-05-18');

    // 3. "Kiedy jest zebranie z rodzicami?"
    final meetingReply = SchoolAiContextBuilder.generateGroundedLocalReply(
      question: 'Kiedy jest zebranie z rodzicami?',
      input: sampleInput,
    );
    expect(meetingReply.text, contains('28 maja 2026'));
    expect(meetingReply.text, contains('17:30'));
    expect(meetingReply.sources.first.targetId, 'msg_meeting_2');
    expect(meetingReply.suggestedEvent?.date, '2026-05-28');
    expect(meetingReply.suggestedEvent?.startTime, '17:30');
  });

  test('Regression: stop-words ("informacje", "temat") do not match NNW insurance message; Polish stem matches matura message & attachments', () {
    final inputWithInsuranceAndMatura = SchoolAiContextSnapshotInput(
      now: DateTime(2026, 10, 3, 19, 30),
      viewerRole: 'parent',
      messages: [
        MessageThread(
          id: '2149280',
          senderName: 'Piwnik Ewa',
          senderInitials: 'PE',
          senderRole: 'Nauczyciel',
          subject: 'Informacje o ubezpieczeniu na rok szkolny 2026/2027',
          preview: 'Informacje o ubezpieczeniu na rok szkolny 2026/2027',
          body:
              'Drodzy Rodzice, Wzorem lat ubiegłych załączeniu przesyłamy wynegocjowaną dedykowaną ofertę ubezpieczenia NNW dla dzieci i młodzieży.',
          timestamp: DateTime(2026, 9, 29, 12, 0),
          isUnread: false,
        ),
        MessageThread(
          id: '2027508',
          senderName: 'Sobota Łukasz',
          senderInitials: 'SŁ',
          senderRole: 'Nauczyciel',
          subject: 'Informacje na temat egzaminu maturalnego',
          preview: 'Informacje na temat egzaminu maturalnego',
          body:
              'Dzień dobry, przesyłam Państwu obiecaną prezentację. Pozdrawiam, Łukasz Sobota',
          timestamp: DateTime(2026, 9, 10, 14, 0),
          isUnread: false,
          attachments: const [
            'matura2027_wrzesien2026_R_U.pdf',
            'matura2027_wrzesien2026_R_U.pptx',
          ],
          hasAttachments: true,
        ),
      ],
    );

    final snapshot =
        SchoolAiContextBuilder.buildContextSnapshot(inputWithInsuranceAndMatura);
    expect(snapshot, contains('matura2027_wrzesien2026_R_U.pdf'));

    final reply = SchoolAiContextBuilder.generateGroundedLocalReply(
      question: 'Czy były jakieś informacje na temat matury próbnej z Operon?',
      input: inputWithInsuranceAndMatura,
    );

    // Must NOT return the unrelated NNW insurance message
    expect(reply.text, isNot(contains('Piwnik Ewa')));
    expect(reply.text, isNot(contains('ubezpieczenia NNW')));

    // Must return the matura message from Sobota Łukasz, list attachments, and note missing 'operon'
    expect(reply.text, contains('Sobota Łukasz'));
    expect(reply.text, contains('Informacje na temat egzaminu maturalnego'));
    expect(reply.text, contains('matura2027_wrzesien2026_R_U.pdf'));
    expect(reply.text, contains('operon'));
    expect(reply.sources.first.targetId, '2027508');
  });
}
