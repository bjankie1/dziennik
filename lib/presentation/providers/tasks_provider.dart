import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/school_task.dart';
import 'auth_providers.dart';

/// Repository for real-time Family Smart To-Do operations in Firestore
/// (`family_tasks/{familyId}/tasks`, REQ-TASK-01, REQ-TASK-02, D-01, D-02, D-03, D-08).
class TasksRepository {
  final FirebaseFirestore? _injectedFirestore;
  final StreamController<List<SchoolTask>> _localController =
      StreamController<List<SchoolTask>>.broadcast();

  TasksRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  /// Lazy, widget-test-safe Firestore instance getter preventing `[core/no-app]`
  /// crashes when `ProviderScope` runs without `Firebase.initializeApp()`.
  FirebaseFirestore? get _db {
    if (_injectedFirestore != null) return _injectedFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static List<SchoolTask> _buildInitialSeedTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return [
      SchoolTask(
        id: 'seed_task_1',
        familyId: 'jankiewicz_family',
        title: 'Powtórzyć dział „Układ krwionośny” przed sprawdzianem',
        description:
            'Przejrzeć notatki z zeszytu oraz schemat budowy serca (str. 84–92).',
        dueDate: today,
        priority: TaskPriority.high,
        assignedTo: TaskAssignee.student,
        subject: 'Biologia',
        isCompleted: false,
        createdByRole: 'parent',
        createdByName: 'Tata',
        createdAt: now.subtract(const Duration(hours: 5)),
        source: TaskSource.manual,
      ),
      SchoolTask(
        id: 'seed_task_2',
        familyId: 'jankiewicz_family',
        title: 'Rozwiązać zestaw zadań z funkcji kwadratowej (str. 114)',
        description: 'Zadania 1–6 z podręcznika na jutrzejszą matematykę.',
        dueDate: today,
        priority: TaskPriority.medium,
        assignedTo: TaskAssignee.student,
        subject: 'Matematyka',
        isCompleted: false,
        createdByRole: 'student',
        createdByName: 'Oskar',
        createdAt: now.subtract(const Duration(hours: 3)),
        source: TaskSource.manual,
      ),
      SchoolTask(
        id: 'seed_task_3',
        familyId: 'jankiewicz_family',
        title: 'Opłacić składkę na Radę Rodziców i wycieczkę klasową',
        description: 'Przelew na konto klasowe do końca tygodnia (85 zł).',
        dueDate: tomorrow,
        priority: TaskPriority.high,
        assignedTo: TaskAssignee.parent,
        subject: 'Opłata/Formalności',
        isCompleted: false,
        createdByRole: 'parent',
        createdByName: 'Tata',
        createdAt: now.subtract(const Duration(hours: 8)),
        source: TaskSource.manual,
      ),
      SchoolTask(
        id: 'seed_task_4',
        familyId: 'jankiewicz_family',
        title: 'Przygotować strój galowy na apel szkolny',
        description: 'Biała koszula i granatowe spodnie.',
        dueDate: today.subtract(const Duration(days: 1)),
        priority: TaskPriority.low,
        assignedTo: TaskAssignee.shared,
        subject: 'Szkoła',
        isCompleted: true,
        createdByRole: 'parent',
        createdByName: 'Tata',
        createdAt: now.subtract(const Duration(days: 2)),
        completedByRole: 'student',
        completedByName: 'Oskar',
        completedAt: now.subtract(const Duration(hours: 18)),
        source: TaskSource.manual,
      ),
    ];
  }

  final List<SchoolTask> _fallbackTasks = _buildInitialSeedTasks();

  List<SchoolTask> get currentFallbackTasks =>
      List<SchoolTask>.unmodifiable(_fallbackTasks);

  void _notifyFallbackListeners() {
    if (!_localController.isClosed) {
      _localController.add(List<SchoolTask>.unmodifiable(_fallbackTasks));
    }
  }

  /// Watches family tasks in real time from `family_tasks/{familyId}/tasks`,
  /// emitting starter fallback tasks immediately and whenever Firestore is
  /// empty or unavailable in widget tests.
  Stream<List<SchoolTask>> watchTasks(String familyId) {
    late final StreamController<List<SchoolTask>> controller;
    StreamSubscription<List<SchoolTask>>? localSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? firestoreSub;

    controller = StreamController<List<SchoolTask>>(
      onListen: () {
        // 1. Emit optimistic/fallback starter tasks immediately
        controller.add(List<SchoolTask>.unmodifiable(_fallbackTasks));

        // 2. Forward local mutations (optimistic UI & widget test mode)
        localSub = _localController.stream.listen((tasks) {
          if (!controller.isClosed) {
            controller.add(tasks);
          }
        });

        // 3. Subscribe to Cloud Firestore if initialized
        final db = _db;
        if (db != null) {
          try {
            firestoreSub = db
                .collection('family_tasks')
                .doc(familyId)
                .collection('tasks')
                .orderBy('createdAt', descending: true)
                .limit(200)
                .snapshots()
                .listen(
              (snapshot) {
                if (controller.isClosed) return;
                if (snapshot.docs.isEmpty) {
                  controller.add(List<SchoolTask>.unmodifiable(_fallbackTasks));
                } else {
                  final remoteTasks = snapshot.docs
                      .map((doc) => SchoolTask.fromJson(doc.data(), doc.id))
                      .toList();
                  _fallbackTasks
                    ..clear()
                    ..addAll(remoteTasks);
                  controller.add(List<SchoolTask>.unmodifiable(remoteTasks));
                }
              },
              onError: (Object error) {
                debugPrint('[TasksRepository] watchTasks stream error: $error');
                if (!controller.isClosed) {
                  controller.add(List<SchoolTask>.unmodifiable(_fallbackTasks));
                }
              },
            );
          } catch (e) {
            debugPrint('[TasksRepository] watchTasks setup error: $e');
          }
        }
      },
      onCancel: () async {
        await localSub?.cancel();
        await firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Creates a new task in `family_tasks/{familyId}/tasks` and updates local state immediately.
  Future<SchoolTask> addTask({
    required String familyId,
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    TaskAssignee assignedTo = TaskAssignee.student,
    String? subject,
    required String createdByRole,
    required String createdByName,
    TaskSource source = TaskSource.manual,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedDesc = description?.trim();
    final trimmedSubject = subject?.trim();

    final taskId = 'task_${DateTime.now().millisecondsSinceEpoch}';
    final newTask = SchoolTask(
      id: taskId,
      familyId: familyId,
      title: trimmedTitle,
      description:
          (trimmedDesc != null && trimmedDesc.isNotEmpty) ? trimmedDesc : null,
      dueDate: dueDate,
      priority: priority,
      assignedTo: assignedTo,
      subject: (trimmedSubject != null && trimmedSubject.isNotEmpty)
          ? trimmedSubject
          : null,
      isCompleted: false,
      createdByRole: createdByRole,
      createdByName: createdByName,
      createdAt: DateTime.now(),
      source: source,
      sourceId: sourceId,
      metadata: metadata,
    );

    // Optimistic local insert at top of list
    _fallbackTasks.insert(0, newTask);
    _notifyFallbackListeners();

    final db = _db;
    if (db != null) {
      try {
        await db
            .collection('family_tasks')
            .doc(familyId)
            .collection('tasks')
            .doc(taskId)
            .set(newTask.toJson());
      } catch (e) {
        debugPrint('[TasksRepository] addTask Firestore error: $e');
      }
    }

    return newTask;
  }

  /// Updates an existing task in `family_tasks/{familyId}/tasks`.
  Future<void> updateTask(String familyId, SchoolTask updatedTask) async {
    final index = _fallbackTasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _fallbackTasks[index] = updatedTask;
    } else {
      _fallbackTasks.insert(0, updatedTask);
    }
    _notifyFallbackListeners();

    final db = _db;
    if (db != null) {
      try {
        await db
            .collection('family_tasks')
            .doc(familyId)
            .collection('tasks')
            .doc(updatedTask.id)
            .set(updatedTask.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('[TasksRepository] updateTask Firestore error: $e');
      }
    }
  }

  /// Toggles task completion status with full attribution (`D-01`, `D-08`).
  Future<void> toggleTaskCompletion(
    String familyId,
    SchoolTask task, {
    required bool isCompleted,
    required String actorRole,
    required String actorName,
  }) async {
    final now = DateTime.now();
    final updatedTask = isCompleted
        ? task.copyWith(
            isCompleted: true,
            completedByRole: actorRole,
            completedByName: actorName,
            completedAt: now,
          )
        : task.copyWith(
            isCompleted: false,
            clearCompletion: true,
          );

    await updateTask(familyId, updatedTask);
  }

  /// Deletes a task from `family_tasks/{familyId}/tasks` if permitted by `D-03`.
  /// Returns `false` if a student attempts to delete a parent-created task.
  Future<bool> deleteTask(
    String familyId,
    SchoolTask task, {
    required bool isStudent,
  }) async {
    if (!task.canBeDeletedBy(isStudent: isStudent)) {
      return false;
    }

    _fallbackTasks.removeWhere((t) => t.id == task.id);
    _notifyFallbackListeners();

    final db = _db;
    if (db != null) {
      try {
        await db
            .collection('family_tasks')
            .doc(familyId)
            .collection('tasks')
            .doc(task.id)
            .delete();
      } catch (e) {
        debugPrint('[TasksRepository] deleteTask Firestore error: $e');
      }
    }

    return true;
  }
}

/// Provider for [TasksRepository].
final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository();
});

/// Real-time stream of family tasks for the active user's `familyId` (`D-01`).
final tasksStreamProvider = StreamProvider<List<SchoolTask>>((ref) {
  final user = ref.watch(appUserProvider);
  final familyId = user?.familyId ?? 'jankiewicz_family';
  return ref.watch(tasksRepositoryProvider).watchTasks(familyId);
});

/// Top 5 most urgent active tasks sorted for the Dashboard „Zadania na dziś” Bento widget (`D-08`).
final urgentTasksProvider = Provider<List<SchoolTask>>((ref) {
  final tasks = ref.watch(tasksStreamProvider).value ?? const [];
  final isStudent = ref.watch(appUserProvider)?.isStudent ?? false;
  return SchoolTask.sortUrgentForDashboard(tasks, isStudent: isStudent);
});

/// Count of active tasks that are either overdue or due today, used for navigation badges (`D-09`).
final activeTasksBadgeCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(tasksStreamProvider).value ?? const [];
  return tasks.where((t) => !t.isCompleted && (t.isOverdue || t.isDueToday)).length;
});

/// Total count of all uncompleted tasks in the family list (`D-04`, `D-08`).
final totalActiveTasksCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(tasksStreamProvider).value ?? const [];
  return tasks.where((t) => !t.isCompleted).length;
});
