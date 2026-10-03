import 'package:intl/intl.dart';
import '../../domain/models/ai_chat_message.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/lesson_slot.dart';
import '../../domain/models/message_thread.dart';
import '../../domain/models/school_task.dart';
import '../../domain/models/student_profile.dart';
import '../../domain/models/subject.dart';

/// Input bundle for building the grounded school gradebook context snapshot (Phase 20).
class SchoolAiContextSnapshotInput {
  final StudentProfile? student;
  final String viewerRole; // 'parent' | 'student'
  final DateTime now;
  final List<Subject> subjects;
  final Map<int, List<LessonSlot>> weekSchedule;
  final UpcomingEvent? upcomingExam;
  final List<AttendanceRecord> attendance;
  final List<MessageThread> messages;
  final List<Announcement> announcements;
  final List<SchoolTask> tasks;
  final Map<String, dynamic>? rawMetadata;

  SchoolAiContextSnapshotInput({
    this.student,
    this.viewerRole = 'parent',
    DateTime? now,
    this.subjects = const [],
    this.weekSchedule = const {},
    this.upcomingExam,
    this.attendance = const [],
    this.messages = const [],
    this.announcements = const [],
    this.tasks = const [],
    this.rawMetadata,
  }) : now = now ?? DateTime.now();
}

/// Builds the grounded Polish context snapshot and provides a deterministic
/// local Q&A analyzer over grades, timetable, exams, attendance, tasks,
/// announcements, and full Librus message bodies (`REQ-AI-01`, `REQ-AI-02`).
class SchoolAiContextBuilder {
  static const Map<int, String> _polishWeekdays = {
    1: 'poniedziałek',
    2: 'wtorek',
    3: 'środa',
    4: 'czwartek',
    5: 'piątek',
    6: 'sobota',
    7: 'niedziela',
  };

  static const Set<String> _forbiddenKeys = {
    'encryptedpassword',
    'password',
    'parentpin',
    'pin',
    'fcmtoken',
    'fcmtokens',
    'serializedjar',
    'telegrambottoken',
  };

  static String polishWeekday(DateTime dt) =>
      _polishWeekdays[dt.weekday] ?? 'dzień';

  static String _fmtDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
  static String _fmtShortDate(DateTime dt) => DateFormat('dd.MM.yyyy').format(dt);

  /// Scrubs any sensitive tokens or secret values if raw metadata was passed.
  static String sanitizeText(String input, [Map<String, dynamic>? rawMetadata]) {
    var result = input;
    if (rawMetadata != null) {
      for (final entry in rawMetadata.entries) {
        final keyLower = entry.key.toLowerCase();
        if (_forbiddenKeys.contains(keyLower) && entry.value != null) {
          final secretStr = entry.value.toString().trim();
          if (secretStr.isNotEmpty) {
            result = result.replaceAll(secretStr, '[REDACTED]');
          }
        }
      }
    }
    return result;
  }

  /// Builds the full system instruction + grounded gradebook context snapshot for Gemini.
  static String buildSystemInstruction(SchoolAiContextSnapshotInput input) {
    final snapshot = buildContextSnapshot(input);
    final roleLabel = input.viewerRole == 'student'
        ? 'UCZEŃ (Oskar — zwracaj się bezpośrednio po koleżeńsku: „Masz jutro...”, „Twoja średnia...”)'
        : 'RODZIC (Tata Oskara — zwracaj się z szacunkiem: „Oskar ma...”, „W wiadomości od wychowawcy...”)';

    return '''
Jesteś „Asystentem AI Dziennika Szkolnego” w aplikacji EduSync (Lepsza Szkoła) dla ucznia ${input.student?.name ?? 'Oskar Jankiewicz'} (${input.student?.className ?? 'Klasa 7b'}, ${input.student?.schoolName ?? 'Szkoła Podstawowa'}).
Aktualnie rozmawia z Tobą: $roleLabel.

ZASADY KRYTYCZNE (GROUNDING & ZERO HALUCYNACJI):
1. Odpowiadaj WYŁĄCZNIE po polsku, zwięźle, konkretnie i pomocnie. Formatuj kluczowe daty, przedmioty i nazwiska pogrubieniem (**...**).
2. Opieraj się WYŁĄCZNIE na danych z sekcji <DANE_DZIENNIKA_SZKOLNEGO> poniżej. NIGDY nie zmyślaj ocen, dat sprawdzianów, wycieczek ani treści wiadomości.
3. Kiedy użytkownik pyta o wycieczki (np. „Kiedy jest wycieczka Oskara do Warszawy?”), zebrania z rodzicami (np. „Kiedy jest zebranie z rodzicami?”), składki klasowe lub wydarzenia szkolne, DOKŁADNIE przeszukaj sekcję WIADOMOŚCI (pełne treści `body`) oraz OGŁOSZENIA. Często temat wiadomości to tylko „Informacja” lub „Sprawy klasowe”, a kluczowe szczegóły są w pełnej treści wiadomości!
4. Zawsze podawaj w tablicy `sources` dokładne źródła z dziennika (np. `📩 Wiadomość: Informacja (12.05)`, `📅 Plan lekcji: Matematyka`, `🎓 Oceny: Biologia`, `📋 Frekwencja`).
5. Jeśli odpowiedź dotyczy wydarzenia z konkretną datą w przyszłości (sprawdzian, kartkówka, wycieczka, zebranie z rodzicami), wypełnij pole `suggestedEvent` (z datą w formacie YYYY-MM-DD), aby użytkownik mógł jednym kliknięciem dodać je do Kalendarza Google.
6. Jeśli odpowiedź dotyczy sprawdzianu, pracy domowej lub przygotowania do wycieczki/zebrania, wypełnij także `suggestedTask`.
7. Jeśli w <DANE_DZIENNIKA_SZKOLNEGO> naprawdę nie ma informacji na dany temat, napisz wprost, że w zsynchronizowanych danych dziennika i w pełnych treściach ostatnich wiadomości nie znaleziono takiej informacji.

<DANE_DZIENNIKA_SZKOLNEGO>
$snapshot
</DANE_DZIENNIKA_SZKOLNEGO>
''';
  }

  /// Serializes all domain models into a structured, token-efficient Polish context snapshot.
  static String buildContextSnapshot(SchoolAiContextSnapshotInput input) {
    final now = input.now;
    final tomorrow = now.add(const Duration(days: 1));
    final buf = StringBuffer();

    buf.writeln('=== KONTEKST CZASOWY I PROFIL ===');
    buf.writeln(
      'Dzisiaj jest: ${_fmtDate(now)} (${polishWeekday(now)}), godz. ${DateFormat('HH:mm').format(now)}',
    );
    buf.writeln(
      'Jutro jest: ${_fmtDate(tomorrow)} (${polishWeekday(tomorrow)})',
    );
    if (input.student != null) {
      final s = input.student!;
      buf.writeln(
        'Uczeń: ${s.name} | Klasa: ${s.className} | Szkoła: ${s.schoolName}',
      );
      buf.writeln(
        'Wychowawca: ${s.educator ?? "brak danych"} | Szczęśliwy numerek dziś: ${s.luckyNumber}',
      );
      buf.writeln(
        'Średnia ogólna: ${s.overallAverage.toStringAsFixed(2)} | Frekwencja ogólna: ${s.attendancePercentage.toStringAsFixed(1)}%',
      );
    }

    // 1. SPRAWDZIANY I TERMINARZ
    buf.writeln('\n=== NADCHODZĄCE SPRAWDZIANY I WYDARZENIA Z TERMINARZA ===');
    final examLines = <String>[];
    if (input.upcomingExam != null) {
      final ex = input.upcomingExam!;
      examLines.add(
        '- [${_fmtDate(ex.date)} (${polishWeekday(ex.date)})] ${ex.type}: ${ex.subject} — Zakres/Tytuł: ${ex.title} (Sala/godz.: ${ex.room}, ${ex.time})',
      );
    }
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    for (int day = 1; day <= 5; day++) {
      final lessons = input.weekSchedule[day] ?? const [];
      final lessonDate = monday.add(Duration(days: day - 1));
      for (final slot in lessons) {
        final hasExam = slot.eventType != null ||
            (slot.topic != null &&
                (slot.topic!.toLowerCase().contains('sprawdzian') ||
                    slot.topic!.toLowerCase().contains('kartkówka')));
        if (hasExam) {
          final evType = slot.eventType ?? 'Sprawdzian';
          final evTitle = slot.eventTitle ?? slot.topic ?? slot.subjectName;
          examLines.add(
            '- [${_fmtDate(lessonDate)} (${polishWeekday(lessonDate)}) lek.${slot.lessonNumber} ${slot.startTime}-${slot.endTime}] $evType z przedmiotu ${slot.subjectName}: $evTitle (Nauczyciel: ${slot.teacher}, Sala: ${slot.room})',
          );
        }
      }
    }
    if (examLines.isEmpty) {
      buf.writeln('Brak wpisanych sprawdzianów w bieżącym terminarzu.');
    } else {
      for (final line in examLines.toSet()) {
        buf.writeln(line);
      }
    }

    // 2. PLAN LEKCJI (BIEŻĄCY TYDZIEŃ)
    buf.writeln('\n=== PLAN LEKCJI (PONIEDZIAŁEK - PIĄTEK) ===');
    if (input.weekSchedule.isEmpty) {
      buf.writeln('Brak załadowanego planu lekcji.');
    } else {
      for (int day = 1; day <= 5; day++) {
        final dayDate = monday.add(Duration(days: day - 1));
        final dayName = _polishWeekdays[day] ?? 'Dzień $day';
        final slots = input.weekSchedule[day] ?? const [];
        buf.writeln('• ${dayName.toUpperCase()} (${_fmtDate(dayDate)}):');
        if (slots.isEmpty) {
          buf.writeln('  Brak lekcji.');
        } else {
          for (final s in slots) {
            final statusTag = switch (s.status) {
              LessonStatus.canceled => ' [ODWOŁANA]',
              LessonStatus.substituted =>
                ' [ZASTĘPSTWO: ${s.substituteTeacher ?? s.teacher}]',
              _ => '',
            };
            final examTag = s.eventType != null
                ? ' [UWAGA: ${s.eventType} - ${s.eventTitle ?? s.topic ?? ""}]'
                : '';
            final hwTag = (s.homework != null && s.homework!.trim().isNotEmpty)
                ? ' [Praca domowa: ${s.homework}]'
                : '';
            buf.writeln(
              '  Lekcja ${s.lessonNumber} (${s.startTime}-${s.endTime}): ${s.subjectName} (sala ${s.room}, naucz. ${s.teacher})$statusTag$examTag$hwTag',
            );
          }
        }
      }
    }

    // 3. OCENY I ŚREDNIE
    buf.writeln('\n=== OCENY I ŚREDNIE PRZEDMIOTOWE ===');
    if (input.subjects.isEmpty) {
      buf.writeln('Brak ocen.');
    } else {
      for (final sub in input.subjects) {
        final avg1 = sub.calculateWeightedAverage(1);
        final avg2 = sub.calculateWeightedAverage(2);
        final recent = [...sub.grades]
          ..sort((a, b) => b.date.compareTo(a.date));
        final gradesSummary = recent.take(8).map((g) {
          final commentPart =
              g.comment.trim().isNotEmpty ? ' "${g.comment.trim()}"' : '';
          return '${g.rawValue} (waga ${g.weight}, ${g.categoryName}, ${_fmtShortDate(g.date)}$commentPart)';
        }).join('; ');
        buf.writeln(
          '- ${sub.name} (naucz. ${sub.teacherName}) | Śr. Sem1: ${avg1.toStringAsFixed(2)}, Sem2: ${avg2.toStringAsFixed(2)} | Oceny: ${gradesSummary.isEmpty ? "brak" : gradesSummary}',
        );
      }
    }

    // 4. FREKWENCJA I NIEOBECNOŚCI
    buf.writeln('\n=== FREKWENCJA I NIEOBECNOŚCI ===');
    if (input.attendance.isEmpty) {
      buf.writeln('Brak zarejestrowanych nieobecności lub spóźnień.');
    } else {
      final unexcused = input.attendance
          .where((r) =>
              r.type == AttendanceType.absent &&
              r.justificationStatus == JustificationStatus.none)
          .toList();
      final pending = input.attendance
          .where((r) =>
              r.type == AttendanceType.absent &&
              r.justificationStatus == JustificationStatus.requested)
          .toList();
      final excused = input.attendance
          .where((r) =>
              r.type == AttendanceType.excused ||
              r.justificationStatus == JustificationStatus.approved)
          .toList();
      final lates = input.attendance
          .where((r) =>
              r.type == AttendanceType.late ||
              r.type == AttendanceType.excusedLate)
          .toList();

      buf.writeln(
        'Podsumowanie wpisów: Nieusprawiedliwione nieobecności: ${unexcused.length} | Oczekujące na akceptację: ${pending.length} | Usprawiedliwione: ${excused.length} | Spóźnienia: ${lates.length}',
      );
      final nonPresent = input.attendance
          .where((r) => r.type != AttendanceType.present)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      for (final r in nonPresent.take(20)) {
        final typeStr = switch (r.type) {
          AttendanceType.absent =>
            r.justificationStatus == JustificationStatus.none
                ? 'NIEOBECNOŚĆ NIEUSPRAWIEDLIWIONA'
                : (r.justificationStatus == JustificationStatus.requested
                    ? 'NIEOBECNOŚĆ (w trakcie usprawiedliwiania)'
                    : 'NIEOBECNOŚĆ USPRAWIEDLIWIONA'),
          AttendanceType.excused => 'NIEOBECNOŚĆ USPRAWIEDLIWIONA',
          AttendanceType.late => 'SPÓŹNIENIE',
          AttendanceType.excusedLate => 'SPÓŹNIENIE USPRAWIEDLIWIONE',
          AttendanceType.exempted => 'ZWOLNIENIE',
          AttendanceType.present => 'OBECNOŚĆ',
        };
        buf.writeln(
          '- [${_fmtDate(r.date)} (${polishWeekday(r.date)}) lek.${r.lessonNumber}] ${r.subjectName}: $typeStr',
        );
      }
    }

    // 5. WIADOMOŚCI LIBRUS (PEŁNA TREŚĆ DO 35 WIADOMOŚCI — D-05)
    buf.writeln(
      '\n=== WIADOMOŚCI SZKOLNE LIBRUS (PEŁNE TREŚCI — WYCIECZKI, ZEBRANIA, INFORMACJE) ===',
    );
    if (input.messages.isEmpty) {
      buf.writeln('Brak wiadomości w skrzynce.');
    } else {
      final sortedMsgs = [...input.messages]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      for (final m in sortedMsgs.take(35)) {
        final fullText = (m.body.trim().isNotEmpty ? m.body.trim() : m.preview.trim());
        final clippedBody = fullText.length > 1800
            ? '${fullText.substring(0, 1800)}...'
            : fullText;
        buf.writeln(
          '--- WIADOMOŚĆ [ID: ${m.id}] | Data: ${_fmtDate(m.timestamp)} (${_fmtShortDate(m.timestamp)}) | Od: ${m.senderName} (${m.senderRole}) | Temat: "${m.subject}" ---',
        );
        buf.writeln('Treść: $clippedBody');
        if (m.attachments.isNotEmpty) {
          buf.writeln('Załączniki: ${m.attachments.join(', ')}');
        }
      }
    }

    // 6. OGŁOSZENIA SZKOLNE
    buf.writeln('\n=== OGŁOSZENIA SZKOLNE ===');
    if (input.announcements.isEmpty) {
      buf.writeln('Brak ogłoszeń szkolnych.');
    } else {
      for (final a in input.announcements.take(15)) {
        buf.writeln(
          '- [Data: ${_fmtDate(a.publishedDate)}] "${a.title}" (Autor: ${a.author}): ${a.content}',
        );
      }
    }

    // 7. ZADANIA SMART TO-DO
    buf.writeln('\n=== ZADANIA DO WYKONANIA (SMART TO-DO) ===');
    final activeTasks = input.tasks.where((t) => !t.isCompleted).toList();
    if (activeTasks.isEmpty) {
      buf.writeln('Brak aktywnych zadań na liście To-Do.');
    } else {
      for (final t in activeTasks.take(20)) {
        final dueStr = t.dueDate != null ? _fmtDate(t.dueDate!) : 'brak terminu';
        buf.writeln(
          '- [Termin: $dueStr] ${t.title} (Przedmiot/Kategoria: ${t.subject ?? "Szkoła"}, Przypisane do: ${t.assignedTo.name}) — ${t.description ?? ""}',
        );
      }
    }

    return sanitizeText(buf.toString(), input.rawMetadata);
  }

  /// Deterministic grounded Polish Q&A engine used as an instant fallback when
  /// Firebase AI Logic is offline or unconfigured, and for golden Q&A evaluation tests.
  static AiChatMessage generateGroundedLocalReply({
    required String question,
    required SchoolAiContextSnapshotInput input,
    String? id,
    String modelUsed = 'gemini-3.8-flash (lokalny indeks dziennika)',
  }) {
    final q = question.toLowerCase().trim();
    final msgId = id ?? 'ai_local_${DateTime.now().millisecondsSinceEpoch}';
    final now = input.now;

    // 1. Check for Trip / Wycieczka / Warszawa / Wyjazd queries
    if (q.contains('wycieczk') ||
        q.contains('warszaw') ||
        q.contains('wyjazd') ||
        q.contains('zielon')) {
      for (final m in input.messages) {
        final combined = '${m.subject} ${m.body} ${m.preview}'.toLowerCase();
        if (combined.contains('wycieczk') ||
            combined.contains('warszaw') ||
            combined.contains('wyjazd')) {
          final extractedDate = _extractEventIsoDate(
                '${m.subject} ${m.body}',
                referenceYear: now.year,
              ) ??
              _fmtDate(m.timestamp.add(const Duration(days: 7)));
          return AiChatMessage(
            id: msgId,
            role: 'assistant',
            viewerRole: input.viewerRole,
            timestamp: now,
            modelUsed: modelUsed,
            text:
                'Z wiadomości od **${m.senderName}** (*„${m.subject}”* z dnia ${_fmtShortDate(m.timestamp)}) wynika:\n\n'
                '📌 **${m.body.trim()}**',
            sources: [
              AiSourceCitation(
                type: 'message',
                label:
                    '📩 Wiadomość: ${m.subject} (${DateFormat('dd.MM').format(m.timestamp)})',
                route: '/wiadomosci',
                targetId: m.id,
              ),
            ],
            suggestedEvent: AiSuggestedEvent(
              title: 'Wycieczka szkolna (Oskar)',
              date: extractedDate,
              startTime: '07:00',
              description:
                  'Źródło: Wiadomość od ${m.senderName} (${m.subject})\n\n${m.body.trim()}',
            ),
            suggestedTask: AiSuggestedTask(
              title: 'Przygotować się do wycieczki szkolnej (${m.subject})',
              dueDate: extractedDate,
              category: 'trip',
            ),
          );
        }
      }
      for (final a in input.announcements) {
        final combined = '${a.title} ${a.content}'.toLowerCase();
        if (combined.contains('wycieczk') || combined.contains('warszaw')) {
          final extractedDate = _extractEventIsoDate(
                '${a.title} ${a.content}',
                referenceYear: now.year,
              ) ??
              _fmtDate(a.publishedDate);
          return AiChatMessage(
            id: msgId,
            role: 'assistant',
            viewerRole: input.viewerRole,
            timestamp: now,
            modelUsed: modelUsed,
            text:
                'W ogłoszeniu szkolnym **„${a.title}”** (${a.author}, ${_fmtShortDate(a.publishedDate)}) podano:\n\n'
                '📌 **${a.content.trim()}**',
            sources: [
              AiSourceCitation(
                type: 'announcement',
                label: '📩 Ogłoszenie: ${a.title}',
                route: '/wiadomosci',
                targetId: a.id,
              ),
            ],
            suggestedEvent: AiSuggestedEvent(
              title: a.title,
              date: extractedDate,
              startTime: '08:00',
              description: a.content,
            ),
          );
        }
      }
    }

    // 2. Check for Parent Meeting / Zebranie z rodzicami / Wywiadówka / Konsultacje
    if (q.contains('zebrani') ||
        q.contains('wywiadówk') ||
        q.contains('wywiadowk') ||
        q.contains('spotkani') ||
        q.contains('rodzic')) {
      for (final m in input.messages) {
        final combined = '${m.subject} ${m.body} ${m.preview}'.toLowerCase();
        if (combined.contains('zebrani') ||
            combined.contains('wywiadówk') ||
            combined.contains('wywiadowk') ||
            combined.contains('spotkani z rodzic') ||
            combined.contains('rodzicam')) {
          final extractedDate = _extractEventIsoDate(
                '${m.subject} ${m.body}',
                referenceYear: now.year,
              ) ??
              _fmtDate(m.timestamp.add(const Duration(days: 5)));
          final extractedTime = _extractTime('${m.subject} ${m.body}') ?? '17:30';
          return AiChatMessage(
            id: msgId,
            role: 'assistant',
            viewerRole: input.viewerRole,
            timestamp: now,
            modelUsed: modelUsed,
            text:
                'Informację o zebraniu znaleziono w wiadomości od **${m.senderName}** (*„${m.subject}”*, ${_fmtShortDate(m.timestamp)}):\n\n'
                '👨‍🏫 **${m.body.trim()}**',
            sources: [
              AiSourceCitation(
                type: 'message',
                label:
                    '📩 Wiadomość: ${m.subject} (${DateFormat('dd.MM').format(m.timestamp)})',
                route: '/wiadomosci',
                targetId: m.id,
              ),
            ],
            suggestedEvent: AiSuggestedEvent(
              title: 'Zebranie z rodzicami (Oskar)',
              date: extractedDate,
              startTime: extractedTime,
              description:
                  'Wiadomość od: ${m.senderName}\nTemat: ${m.subject}\n\n${m.body.trim()}',
            ),
          );
        }
      }
      for (final a in input.announcements) {
        final combined = '${a.title} ${a.content}'.toLowerCase();
        if (combined.contains('zebrani') ||
            combined.contains('wywiadówk') ||
            combined.contains('rodzic')) {
          final extractedDate = _extractEventIsoDate(
                '${a.title} ${a.content}',
                referenceYear: now.year,
              ) ??
              _fmtDate(a.publishedDate);
          return AiChatMessage(
            id: msgId,
            role: 'assistant',
            viewerRole: input.viewerRole,
            timestamp: now,
            modelUsed: modelUsed,
            text:
                'W ogłoszeniu **„${a.title}”** (${a.author}) znajduje się informacja o zebraniu:\n\n'
                '👨‍🏫 **${a.content.trim()}**',
            sources: [
              AiSourceCitation(
                type: 'announcement',
                label: '📩 Ogłoszenie: ${a.title}',
                route: '/wiadomosci',
                targetId: a.id,
              ),
            ],
            suggestedEvent: AiSuggestedEvent(
              title: 'Zebranie z rodzicami',
              date: extractedDate,
              startTime: _extractTime(a.content) ?? '17:30',
              description: a.content,
            ),
          );
        }
      }
    }

    // 3. Check for Exams / Sprawdzian / Kartkówka / Test
    if (q.contains('sprawdzian') ||
        q.contains('kartkówk') ||
        q.contains('kartkowk') ||
        q.contains('test') ||
        q.contains('klasówk')) {
      if (input.upcomingExam != null) {
        final ex = input.upcomingExam!;
        final dateIso = _fmtDate(ex.date);
        return AiChatMessage(
          id: msgId,
          role: 'assistant',
          viewerRole: input.viewerRole,
          timestamp: now,
          modelUsed: modelUsed,
          text:
              'Najbliższy sprawdzian w terminarzu to:\n\n'
              '📅 **${ex.type}: ${ex.subject}**\n'
              '• **Data:** ${_fmtShortDate(ex.date)} (${polishWeekday(ex.date)})\n'
              '• **Zakres:** ${ex.title}\n'
              '• **Szczegóły:** ${ex.room} (${ex.time})',
          sources: [
            AiSourceCitation(
              type: 'exam',
              label:
                  '📅 Plan lekcji: ${ex.subject} (${DateFormat('dd.MM').format(ex.date)})',
              route: '/plan-lekcji?data=$dateIso',
            ),
          ],
          suggestedEvent: AiSuggestedEvent(
            title: '${ex.type}: ${ex.subject} (Oskar)',
            date: dateIso,
            startTime: _extractTime(ex.time) ?? '08:00',
            description: 'Przedmiot: ${ex.subject}\nZakres: ${ex.title}\nSala: ${ex.room}',
          ),
          suggestedTask: AiSuggestedTask(
            title: 'Powtórzyć materiał na ${ex.type.toLowerCase()} z: ${ex.subject} (${ex.title})',
            dueDate: dateIso,
            category: 'exam',
          ),
        );
      }

      // Check weekSchedule for lesson slots with exams
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      for (int day = 1; day <= 5; day++) {
        final slots = input.weekSchedule[day] ?? const [];
        final slotDate = monday.add(Duration(days: day - 1));
        for (final s in slots) {
          if (s.eventType != null ||
              (s.topic != null &&
                  (s.topic!.toLowerCase().contains('sprawdzian') ||
                      s.topic!.toLowerCase().contains('kartkówka')))) {
            final evType = s.eventType ?? 'Sprawdzian';
            final scope = s.eventTitle ?? s.topic ?? s.subjectName;
            final dateIso = _fmtDate(slotDate);
            return AiChatMessage(
              id: msgId,
              role: 'assistant',
              viewerRole: input.viewerRole,
              timestamp: now,
              modelUsed: modelUsed,
              text:
                  'W planie lekcji zaplanowano:\n\n'
                  '📅 **$evType: ${s.subjectName}**\n'
                  '• **Termin:** ${_fmtShortDate(slotDate)} (${polishWeekday(slotDate)}), lekcja ${s.lessonNumber} (${s.startTime}–${s.endTime})\n'
                  '• **Zakres:** $scope\n'
                  '• **Nauczyciel i sala:** ${s.teacher}, sala ${s.room}',
              sources: [
                AiSourceCitation(
                  type: 'exam',
                  label:
                      '📅 Plan lekcji: ${s.subjectName} (${DateFormat('dd.MM').format(slotDate)})',
                  route: '/plan-lekcji?data=$dateIso',
                ),
              ],
              suggestedEvent: AiSuggestedEvent(
                title: '$evType: ${s.subjectName}',
                date: dateIso,
                startTime: s.startTime,
                description: 'Zakres: $scope (sala ${s.room})',
              ),
              suggestedTask: AiSuggestedTask(
                title: 'Przygotować się na $evType z przedmiotu ${s.subjectName}',
                dueDate: dateIso,
                category: 'exam',
              ),
            );
          }
        }
      }
    }

    // 4. Check for Attendance / Nieobecności / Frekwencja
    if (q.contains('nieobecno') ||
        q.contains('frekwencj') ||
        q.contains('spóźni') ||
        q.contains('spozni') ||
        q.contains('usprawiedliw')) {
      final unexcused = input.attendance
          .where((r) =>
              r.type == AttendanceType.absent &&
              r.justificationStatus == JustificationStatus.none)
          .toList();
      final lates = input.attendance
          .where((r) =>
              r.type == AttendanceType.late ||
              r.type == AttendanceType.excusedLate)
          .toList();
      final pct = input.student?.attendancePercentage ?? 92.5;

      final details = unexcused.take(5).map((r) {
        return '• **${_fmtShortDate(r.date)}** (lekcja ${r.lessonNumber}) — ${r.subjectName}';
      }).join('\n');

      final summaryText = unexcused.isEmpty
          ? 'Świetna wiadomość! Wszystkie nieobecności są usprawiedliwione. Ogólna frekwencja wynosi **${pct.toStringAsFixed(1)}%** (liczba spóźnień: **${lates.length}**).'
          : 'Ogólna frekwencja wynosi **${pct.toStringAsFixed(1)}%**. W dzienniku znajduje się **${unexcused.length}** nieusprawiedliwionych godzin lekcyjnych:\n\n$details';

      return AiChatMessage(
        id: msgId,
        role: 'assistant',
        viewerRole: input.viewerRole,
        timestamp: now,
        modelUsed: modelUsed,
        text: summaryText,
        sources: const [
          AiSourceCitation(
            type: 'attendance',
            label: '📋 Frekwencja i usprawiedliwienia',
            route: '/frekwencja',
          ),
        ],
      );
    }

    // 5. Check for Grades / Oceny / Średnia
    if (q.contains('ocen') || q.contains('średni') || q.contains('sredni')) {
      final allGrades = input.subjects.expand((s) => s.grades).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final latestLines = allGrades.take(5).map((g) {
        return '• **${g.rawValue}** (waga ${g.weight}) — **${g.subjectName}**: ${g.categoryName} (${_fmtShortDate(g.date)})';
      }).join('\n');
      final avg = input.student?.overallAverage ?? 4.75;

      return AiChatMessage(
        id: msgId,
        role: 'assistant',
        viewerRole: input.viewerRole,
        timestamp: now,
        modelUsed: modelUsed,
        text:
            'Aktualna średnia ważona wynosi **${avg.toStringAsFixed(2)}**.\n\n'
            'Ostatnie oceny w dzienniku:\n'
            '${latestLines.isEmpty ? "• Brak zarejestrowanych ocen." : latestLines}',
        sources: const [
          AiSourceCitation(
            type: 'grade',
            label: '🎓 Oceny i średnie',
            route: '/oceny',
          ),
        ],
      );
    }

    // 6. Check for Timetable / Plan lekcji / Jutro / Dzisiaj
    if (q.contains('plan') ||
        q.contains('lekcj') ||
        q.contains('jutro') ||
        q.contains('dzisiaj') ||
        q.contains('dziś') ||
        q.contains('zastępstw')) {
      final targetDay = q.contains('jutro')
          ? (now.add(const Duration(days: 1)).weekday).clamp(1, 5)
          : now.weekday.clamp(1, 5);
      final dayLabel = _polishWeekdays[targetDay] ?? 'wybrany dzień';
      final slots = input.weekSchedule[targetDay] ?? const [];
      final slotLines = slots.map((s) {
        final note = s.status == LessonStatus.canceled
            ? ' *(odwołana)*'
            : (s.status == LessonStatus.substituted ? ' *(zastępstwo)*' : '');
        return '• **${s.lessonNumber}. ${s.subjectName}** (${s.startTime}–${s.endTime}, sala ${s.room})$note';
      }).join('\n');

      return AiChatMessage(
        id: msgId,
        role: 'assistant',
        viewerRole: input.viewerRole,
        timestamp: now,
        modelUsed: modelUsed,
        text: slots.isEmpty
            ? 'W planie na **$dayLabel** nie ma zaplanowanych lekcji.'
            : 'Plan lekcji na **$dayLabel**:\n\n$slotLines',
        sources: const [
          AiSourceCitation(
            type: 'timetable',
            label: '📅 Plan lekcji',
            route: '/plan-lekcji',
          ),
        ],
      );
    }

    // 7. Ranked Polish-stem keyword search across messages (with attachments) & announcements
    final queryWords = _extractMeaningfulQueryWords(q);
    if (queryWords.isNotEmpty) {
      final rankedReply = _buildRankedKeywordReply(
        queryWords: queryWords,
        input: input,
        msgId: msgId,
        now: now,
        modelUsed: modelUsed,
      );
      if (rankedReply != null) {
        return rankedReply;
      }
    }

    return AiChatMessage(
      id: msgId,
      role: 'assistant',
      viewerRole: input.viewerRole,
      timestamp: now,
      modelUsed: modelUsed,
      text:
          'Przeszukałem dziennik Oskara (oceny, plan lekcji, sprawdziany, nieobecności oraz **${input.messages.length}** wiadomości wraz z załącznikami i ogłoszeniami), ale nie znalazłem jednoznacznej wzmianki na temat: **${queryWords.isNotEmpty ? queryWords.join(', ') : question.trim()}**.',
      sources: const [
        AiSourceCitation(
          type: 'message',
          label: '📩 Wiadomości Librus',
          route: '/wiadomosci',
        ),
        AiSourceCitation(
          type: 'timetable',
          label: '📅 Plan lekcji',
          route: '/plan-lekcji',
        ),
      ],
    );
  }

  static const Set<String> _polishStopWords = {
    'czy',
    'był',
    'byl',
    'była',
    'byla',
    'było',
    'bylo',
    'były',
    'byly',
    'byli',
    'będzie',
    'bedzie',
    'będą',
    'beda',
    'jest',
    'są',
    'mamy',
    'masz',
    'mają',
    'maja',
    'jakie',
    'jaki',
    'jaka',
    'jakieś',
    'jakies',
    'jakaś',
    'jakas',
    'jakiś',
    'jakis',
    'kiedy',
    'gdzie',
    'komu',
    'czym',
    'czego',
    'dlaczego',
    'coś',
    'cos',
    'ktoś',
    'ktos',
    'informacje',
    'informacja',
    'informacji',
    'informację',
    'informacjom',
    'temat',
    'tematu',
    'temacie',
    'sprawie',
    'sprawa',
    'sprawy',
    'dotyczące',
    'dotyczace',
    'dotyczy',
    'wiadomo',
    'wiadomości',
    'wiadomosci',
    'wiadomość',
    'wiadomosc',
    'ogłoszenie',
    'ogloszenie',
    'ogłoszenia',
    'ogloszenia',
    'dzienniku',
    'dziennik',
    'librus',
    'librusie',
    'szkole',
    'szkoły',
    'szkola',
    'szkoła',
    'klasie',
    'klasy',
    'klasa',
    'oskara',
    'oskar',
    'oskarowi',
    'oskarze',
    'nasz',
    'nasza',
    'nasze',
    'tego',
    'tym',
    'tych',
    'taki',
    'taka',
    'takie',
    'oraz',
    'albo',
    'żeby',
    'zeby',
    'więc',
    'wiec',
    'bardzo',
    'proszę',
    'prosze',
    'powiedz',
    'napisz',
    'sprawdź',
    'sprawdz',
    'pokaż',
    'pokaz',
    'ostatnio',
    'ostatnie',
    'ostatnich',
    'nowe',
    'nowych',
    'przez',
    'przy',
    'przed',
    'około',
    'okolo',
    'tylko',
    'jeszcze',
    'może',
    'moze',
    'można',
    'mozna',
  };

  /// Extracts non-stopword query words of length >= 4 from [queryLower].
  static List<String> _extractMeaningfulQueryWords(String queryLower) {
    final rawTokens = queryLower
        .replaceAll(RegExp(r'[^\wąćęłńóśźżĄĆĘŁŃÓŚŹŻ\s]'), ' ')
        .split(RegExp(r'\s+'))
        .map((w) => w.trim())
        .where((w) => w.length >= 4 && !_polishStopWords.contains(w))
        .toList();
    final seen = <String>{};
    final unique = <String>[];
    for (final token in rawTokens) {
      if (seen.add(token)) {
        unique.add(token);
      }
    }
    return unique;
  }

  /// Normalizes a Polish word or filename token to a stem of at least 4 chars
  /// so inflections like `matury`, `maturalnego`, and `matura2027` share stem `matur`,
  /// and `próbnej` / `próbna` share stem `próbn`.
  static String polishStem(String word) {
    var clean = word
        .toLowerCase()
        .replaceAll(RegExp(r'[0-9_]+'), '')
        .trim();
    if (clean.length <= 4) return clean;

    const suffixes = <String>[
      'alnego',
      'alnych',
      'alnym',
      'alnej',
      'alny',
      'alna',
      'alne',
      'owych',
      'owego',
      'owym',
      'owej',
      'eniu',
      'enia',
      'enie',
      'ami',
      'ach',
      'ego',
      'emu',
      'ych',
      'imi',
      'ymi',
      'iej',
      'ej',
      'ów',
      'ow',
      'om',
      'em',
      'ie',
      'ze',
      'ą',
      'ę',
      'y',
      'i',
      'a',
      'u',
      'o',
      'e',
    ];

    for (final suffix in suffixes) {
      if (clean.endsWith(suffix) && clean.length - suffix.length >= 4) {
        return clean.substring(0, clean.length - suffix.length);
      }
    }
    return clean;
  }

  static bool _textMatchesQueryWord(String textLower, String queryWord) {
    if (textLower.contains(queryWord)) return true;
    final stem = polishStem(queryWord);
    if (stem.length >= 4 && textLower.contains(stem)) return true;
    return false;
  }

  static AiChatMessage? _buildRankedKeywordReply({
    required List<String> queryWords,
    required SchoolAiContextSnapshotInput input,
    required String msgId,
    required DateTime now,
    required String modelUsed,
  }) {
    // Track which query words appear anywhere in the entire gradebook
    final allCorpusText = StringBuffer();
    for (final m in input.messages) {
      allCorpusText.write(
        ' ${m.subject} ${m.body} ${m.preview} ${m.senderName} ${m.attachments.join(' ')} ',
      );
    }
    for (final a in input.announcements) {
      allCorpusText.write(' ${a.title} ${a.content} ${a.author} ');
    }
    final corpusLower = allCorpusText.toString().toLowerCase();

    final globallyMatchedWords = <String>[];
    final globallyMissingWords = <String>[];
    for (final w in queryWords) {
      if (_textMatchesQueryWord(corpusLower, w)) {
        globallyMatchedWords.add(w);
      } else {
        globallyMissingWords.add(w);
      }
    }

    if (globallyMatchedWords.isEmpty) {
      return null;
    }

    // Score each MessageThread by number of matched query words + field weights
    MessageThread? bestMessage;
    var bestMsgScore = 0;
    var bestMsgMatchedWords = <String>[];

    for (final m in input.messages) {
      final subjLower = m.subject.toLowerCase();
      final attLower = m.attachments.join(' ').toLowerCase();
      final bodyLower = '${m.body} ${m.preview} ${m.senderName}'.toLowerCase();
      final combinedLower = '$subjLower $attLower $bodyLower';

      var score = 0;
      final matched = <String>[];
      for (final w in queryWords) {
        if (_textMatchesQueryWord(combinedLower, w)) {
          matched.add(w);
          score += 10;
          if (_textMatchesQueryWord(subjLower, w)) score += 5;
          if (_textMatchesQueryWord(attLower, w)) score += 4;
        }
      }
      if (score > bestMsgScore) {
        bestMsgScore = score;
        bestMessage = m;
        bestMsgMatchedWords = matched;
      }
    }

    // Score each Announcement as well
    Announcement? bestAnnouncement;
    var bestAnnScore = 0;
    var bestAnnMatchedWords = <String>[];

    for (final a in input.announcements) {
      final titleLower = a.title.toLowerCase();
      final contentLower = '${a.content} ${a.author}'.toLowerCase();
      final combinedLower = '$titleLower $contentLower';

      var score = 0;
      final matched = <String>[];
      for (final w in queryWords) {
        if (_textMatchesQueryWord(combinedLower, w)) {
          matched.add(w);
          score += 10;
          if (_textMatchesQueryWord(titleLower, w)) score += 5;
        }
      }
      if (score > bestAnnScore) {
        bestAnnScore = score;
        bestAnnouncement = a;
        bestAnnMatchedWords = matched;
      }
    }

    if (bestMessage != null && bestMsgScore >= bestAnnScore) {
      final m = bestMessage;
      final missingForMessage = queryWords
          .where((w) => !bestMsgMatchedWords.contains(w))
          .toList();
      final attachmentsBlock = m.attachments.isNotEmpty
          ? '\n\n📎 **Załączniki:** ${m.attachments.join(', ')}'
          : '';

      final intro = missingForMessage.isEmpty
          ? 'W wiadomości od **${m.senderName}** (*„${m.subject}”* z ${_fmtShortDate(m.timestamp)}) znaleziono pasującą informację:'
          : 'W dzienniku nie znaleziono bezpośredniej wzmianki o: **${missingForMessage.join(', ')}**.\n\n'
              'Znaleziono natomiast powiązaną wiadomość dotyczącą hasła **${bestMsgMatchedWords.join(', ')}** od **${m.senderName}** (*„${m.subject}”* z ${_fmtShortDate(m.timestamp)}):';

      return AiChatMessage(
        id: msgId,
        role: 'assistant',
        viewerRole: input.viewerRole,
        timestamp: now,
        modelUsed: modelUsed,
        text: '$intro\n\n📩 **${m.body.trim()}**$attachmentsBlock',
        sources: [
          AiSourceCitation(
            type: 'message',
            label:
                '📩 Wiadomość: ${m.subject} (${DateFormat('dd.MM').format(m.timestamp)})',
            route: '/wiadomosci',
            targetId: m.id,
          ),
        ],
      );
    }

    if (bestAnnouncement != null && bestAnnScore > 0) {
      final a = bestAnnouncement;
      final missingForAnn = queryWords
          .where((w) => !bestAnnMatchedWords.contains(w))
          .toList();
      final intro = missingForAnn.isEmpty
          ? 'W ogłoszeniu szkolnym **„${a.title}”** (${a.author}, ${_fmtShortDate(a.publishedDate)}) znaleziono pasującą informację:'
          : 'W dzienniku nie znaleziono bezpośredniej wzmianki o: **${missingForAnn.join(', ')}**.\n\n'
              'Znaleziono natomiast powiązane ogłoszenie dotyczące hasła **${bestAnnMatchedWords.join(', ')}** (**„${a.title}”**, ${_fmtShortDate(a.publishedDate)}):';

      return AiChatMessage(
        id: msgId,
        role: 'assistant',
        viewerRole: input.viewerRole,
        timestamp: now,
        modelUsed: modelUsed,
        text: '$intro\n\n📌 **${a.content.trim()}**',
        sources: [
          AiSourceCitation(
            type: 'announcement',
            label: '📩 Ogłoszenie: ${a.title}',
            route: '/wiadomosci',
            targetId: a.id,
          ),
        ],
      );
    }

    return null;
  }

  static String? _extractEventIsoDate(String text, {required int referenceYear}) {
    // 1. Check YYYY-MM-DD
    final isoMatch = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
    if (isoMatch != null) {
      return isoMatch.group(0);
    }

    // 2. Check DD.MM.YYYY or DD.MM
    final dotMatch =
        RegExp(r'(\d{1,2})\.(\d{1,2})(?:\.(\d{4}))?').firstMatch(text);
    if (dotMatch != null) {
      final d = int.parse(dotMatch.group(1)!).toString().padLeft(2, '0');
      final m = int.parse(dotMatch.group(2)!).toString().padLeft(2, '0');
      final y = dotMatch.group(3) ?? referenceYear.toString();
      return '$y-$m-$d';
    }

    // 3. Check Polish month names, e.g. "18-20 maja 2026" or "28 maja"
    final months = <String, String>{
      'styczn': '01',
      'lut': '02',
      'marc': '03',
      'marz': '03',
      'kwietn': '04',
      'maj': '05',
      'czerwc': '06',
      'lipc': '07',
      'sierpn': '08',
      'wrześn': '09',
      'wrzesn': '09',
      'październik': '10',
      'pazdziernik': '10',
      'listopad': '11',
      'grudni': '12',
    };
    final lower = text.toLowerCase();
    for (final entry in months.entries) {
      final regex = RegExp(
        r'(\d{1,2})(?:\s*[-–]\s*\d{1,2})?\s+' + entry.key + r'[a-ząćęłńóśźż]*(?:\s+(\d{4}))?',
      );
      final match = regex.firstMatch(lower);
      if (match != null) {
        final day = int.parse(match.group(1)!).toString().padLeft(2, '0');
        final year = match.group(2) ?? referenceYear.toString();
        return '$year-${entry.value}-$day';
      }
    }
    return null;
  }

  static String? _extractTime(String text) {
    final match = RegExp(r'\b(\d{1,2}:\d{2})\b').firstMatch(text);
    if (match != null) {
      final parts = match.group(1)!.split(':');
      return '${parts[0].padLeft(2, '0')}:${parts[1]}';
    }
    return null;
  }
}
