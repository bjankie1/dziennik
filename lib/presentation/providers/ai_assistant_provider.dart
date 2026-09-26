import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/school_ai_assistant_service.dart';
import '../../core/services/school_ai_context_builder.dart';
import '../../domain/models/ai_chat_message.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/lesson_slot.dart';
import '../../domain/models/message_thread.dart';
import '../../domain/models/student_profile.dart';
import '../../domain/models/subject.dart';
import 'auth_providers.dart';
import 'school_providers.dart';
import 'tasks_provider.dart';

/// Dual-mode workspace selector for the floating chat panel and `/czat` screen (D-02).
enum ChatWorkspaceMode {
  family,
  aiAssistant,
}

class ActiveChatModeNotifier extends Notifier<ChatWorkspaceMode> {
  @override
  ChatWorkspaceMode build() => ChatWorkspaceMode.family;

  void setMode(ChatWorkspaceMode mode) => state = mode;
  void toggle() {
    state = state == ChatWorkspaceMode.family
        ? ChatWorkspaceMode.aiAssistant
        : ChatWorkspaceMode.family;
  }
}

final activeChatModeProvider =
    NotifierProvider<ActiveChatModeNotifier, ChatWorkspaceMode>(
  ActiveChatModeNotifier.new,
);

/// Controls whether the desktop floating chat panel (`FloatingChatPanel`) is open (D-01).
class FloatingChatOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void open({ChatWorkspaceMode? mode}) {
    if (mode != null) {
      ref.read(activeChatModeProvider.notifier).setMode(mode);
    }
    state = true;
  }

  void close() => state = false;
  void toggle() => state = !state;
}

final isFloatingChatOpenProvider =
    NotifierProvider<FloatingChatOpenNotifier, bool>(
  FloatingChatOpenNotifier.new,
);

/// Active Gemini model tier (`⚡ Gemini 3.8 Flash` default vs `🧠 Gemini 3.1 Pro`, D-03b).
class SelectedAiModelNotifier extends Notifier<AiModelTier> {
  @override
  AiModelTier build() => AiModelTier.flash38;

  void selectModel(AiModelTier tier) => state = tier;
}

final selectedAiModelProvider =
    NotifierProvider<SelectedAiModelNotifier, AiModelTier>(
  SelectedAiModelNotifier.new,
);

/// Tracks whether the AI Assistant is currently generating a response.
class AiAssistantLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool loading) => state = loading;
}

final aiAssistantLoadingProvider =
    NotifierProvider<AiAssistantLoadingNotifier, bool>(
  AiAssistantLoadingNotifier.new,
);

final schoolAiAssistantServiceProvider = Provider<SchoolAiAssistantService>((ref) {
  return const SchoolAiAssistantService();
});

/// Repository managing per-role AI conversation history in Firestore
/// (`students/{studentId}/ai_chats/{role}/messages`, D-07).
class AiChatRepository {
  final FirebaseFirestore? _injectedFirestore;
  final Map<String, List<AiChatMessage>> _localHistoryByRole = {
    'parent': <AiChatMessage>[],
    'student': <AiChatMessage>[],
  };
  final Map<String, StreamController<List<AiChatMessage>>> _controllersByRole = {
    'parent': StreamController<List<AiChatMessage>>.broadcast(),
    'student': StreamController<List<AiChatMessage>>.broadcast(),
  };

  AiChatRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore? get _db {
    if (_injectedFirestore != null) return _injectedFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  List<AiChatMessage> _getLocalList(String roleKey) {
    return _localHistoryByRole.putIfAbsent(roleKey, () => <AiChatMessage>[]);
  }

  void _emitLocal(String roleKey) {
    final controller = _controllersByRole[roleKey];
    if (controller != null && !controller.isClosed) {
      controller.add(List<AiChatMessage>.unmodifiable(_getLocalList(roleKey)));
    }
  }

  Stream<List<AiChatMessage>> watchHistory({
    required String studentId,
    required String roleKey,
  }) {
    final controller = StreamController<List<AiChatMessage>>();
    final localSub = _controllersByRole[roleKey]?.stream.listen((items) {
      if (!controller.isClosed) {
        controller.add(items);
      }
    });

    // Emit current local snapshot immediately
    controller.add(List<AiChatMessage>.unmodifiable(_getLocalList(roleKey)));

    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? firestoreSub;
    final db = _db;
    if (db != null) {
      try {
        firestoreSub = db
            .collection('students')
            .doc(studentId)
            .collection('ai_chats')
            .doc(roleKey)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .limit(60)
            .snapshots()
            .listen(
          (snap) {
            final docs = snap.docs
                .map((d) => AiChatMessage.fromMap(d.data(), docId: d.id))
                .toList();
            _localHistoryByRole[roleKey] = docs;
            if (!controller.isClosed) {
              controller.add(List<AiChatMessage>.unmodifiable(docs));
            }
          },
          onError: (Object err) {
            debugPrint('[AiChatRepository] Firestore stream error: $err');
            if (!controller.isClosed) {
              controller.add(
                List<AiChatMessage>.unmodifiable(_getLocalList(roleKey)),
              );
            }
          },
        );
      } catch (e) {
        debugPrint('[AiChatRepository] watchHistory setup error: $e');
      }
    }

    controller.onCancel = () {
      localSub?.cancel();
      firestoreSub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> saveMessage({
    required String studentId,
    required String roleKey,
    required AiChatMessage message,
  }) async {
    final list = _getLocalList(roleKey);
    list.removeWhere((m) => m.id == message.id);
    list.add(message);
    _emitLocal(roleKey);

    final db = _db;
    if (db != null) {
      try {
        await db
            .collection('students')
            .doc(studentId)
            .collection('ai_chats')
            .doc(roleKey)
            .collection('messages')
            .doc(message.id)
            .set(message.toMap());
      } catch (e) {
        debugPrint('[AiChatRepository] saveMessage error: $e');
      }
    }
  }

  Future<void> clearHistory({
    required String studentId,
    required String roleKey,
  }) async {
    _localHistoryByRole[roleKey] = <AiChatMessage>[];
    _emitLocal(roleKey);

    final db = _db;
    if (db != null) {
      try {
        final col = db
            .collection('students')
            .doc(studentId)
            .collection('ai_chats')
            .doc(roleKey)
            .collection('messages');
        final snap = await col.limit(100).get();
        if (snap.docs.isNotEmpty) {
          final batch = db.batch();
          for (final doc in snap.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('[AiChatRepository] clearHistory error: $e');
      }
    }
  }
}

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  return AiChatRepository();
});

/// Resolves the primary `studentId` (`11010033`) used for Firestore AI chat storage.
final activeAiStudentIdProvider = Provider<String>((ref) {
  final student = ref.watch(studentProfileProvider).value;
  if (student != null && student.id.trim().isNotEmpty) {
    return student.id.trim().replaceFirst(RegExp(r'u$', caseSensitive: false), '');
  }
  final user = ref.watch(appUserProvider);
  final rawLogin = user?.studentLogin?.trim() ?? '';
  if (rawLogin.isNotEmpty) {
    return rawLogin.replaceFirst(RegExp(r'u$', caseSensitive: false), '');
  }
  return '11010033';
});

/// Resolves the current viewer role key (`'student'` or `'parent'`, D-07).
final activeAiViewerRoleKeyProvider = Provider<String>((ref) {
  final user = ref.watch(appUserProvider);
  return (user?.isStudent ?? false) ? 'student' : 'parent';
});

/// Live stream of AI chat messages isolated per viewer role (`parent` vs `student`).
final aiChatMessagesProvider = StreamProvider<List<AiChatMessage>>((ref) {
  final studentId = ref.watch(activeAiStudentIdProvider);
  final roleKey = ref.watch(activeAiViewerRoleKeyProvider);
  final repo = ref.watch(aiChatRepositoryProvider);
  return repo.watchHistory(studentId: studentId, roleKey: roleKey);
});

/// Controller handling user questions, context gathering, and history clearing.
class AiChatActions {
  final Ref _ref;

  const AiChatActions(this._ref);

  Future<void> askQuestion(String rawQuestion) async {
    final question = rawQuestion.trim();
    if (question.isEmpty) return;
    if (_ref.read(aiAssistantLoadingProvider)) return;

    final studentId = _ref.read(activeAiStudentIdProvider);
    final roleKey = _ref.read(activeAiViewerRoleKeyProvider);
    final selectedModel = _ref.read(selectedAiModelProvider);
    final chatRepo = _ref.read(aiChatRepositoryProvider);
    final currentHistory =
        List<AiChatMessage>.from(_ref.read(aiChatMessagesProvider).value ?? const []);

    final userMsg = AiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      text: question,
      timestamp: DateTime.now(),
      viewerRole: roleKey,
    );

    await chatRepo.saveMessage(
      studentId: studentId,
      roleKey: roleKey,
      message: userMsg,
    );

    _ref.read(aiAssistantLoadingProvider.notifier).setLoading(true);
    try {
      final schoolRepo = _ref.read(schoolRepositoryProvider);

      StudentProfile? student = _ref.read(studentProfileProvider).value;
      student ??= await schoolRepo.getStudentProfile();

      List<Subject>? subjects = _ref.read(subjectsProvider).value;
      subjects ??= await schoolRepo.getSubjects();

      Map<int, List<LessonSlot>>? weekSchedule =
          _ref.read(weekScheduleProvider).value;
      weekSchedule ??= await schoolRepo.getWeekSchedule();

      UpcomingEvent? upcomingExam = _ref.read(upcomingExamProvider).value;
      upcomingExam ??= await schoolRepo.getUpcomingExam();

      List<AttendanceRecord>? attendance = _ref.read(attendanceProvider).value;
      attendance ??= await schoolRepo.getAttendanceRecords();

      List<MessageThread>? messages = _ref.read(messagesProvider).value;
      messages ??= await schoolRepo.getMessages();

      List<Announcement>? announcements =
          _ref.read(announcementsProvider).value;
      announcements ??= await schoolRepo.getAnnouncements();

      final tasks = _ref.read(tasksStreamProvider).value ?? const [];

      final contextInput = SchoolAiContextSnapshotInput(
        student: student,
        viewerRole: roleKey,
        subjects: subjects,
        weekSchedule: weekSchedule,
        upcomingExam: upcomingExam,
        attendance: attendance,
        messages: messages,
        announcements: announcements,
        tasks: tasks,
      );

      final aiService = _ref.read(schoolAiAssistantServiceProvider);
      final reply = await aiService.askQuestion(
        question: question,
        contextInput: contextInput,
        selectedModel: selectedModel,
        history: currentHistory,
      );

      await chatRepo.saveMessage(
        studentId: studentId,
        roleKey: roleKey,
        message: reply,
      );
    } catch (e) {
      debugPrint('[AiChatActions] askQuestion error: $e');
      final errMsg = AiChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        text:
            'Wystąpił chwilowy błąd podczas łączenia z Asystentem AI. Spróbuj ponownie za chwilę.',
        timestamp: DateTime.now(),
        viewerRole: roleKey,
        modelUsed: selectedModel.modelId,
        isError: true,
      );
      await chatRepo.saveMessage(
        studentId: studentId,
        roleKey: roleKey,
        message: errMsg,
      );
    } finally {
      _ref.read(aiAssistantLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> clearHistory() async {
    final studentId = _ref.read(activeAiStudentIdProvider);
    final roleKey = _ref.read(activeAiViewerRoleKeyProvider);
    await _ref.read(aiChatRepositoryProvider).clearHistory(
          studentId: studentId,
          roleKey: roleKey,
        );
  }
}

final aiChatActionsProvider = Provider<AiChatActions>((ref) {
  return AiChatActions(ref);
});
