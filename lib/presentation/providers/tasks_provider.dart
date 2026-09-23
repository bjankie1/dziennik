import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/school_task.dart';
import 'auth_providers.dart';

/// Repository for real-time Family Smart To-Do operations in Firestore
/// (`family_tasks/{familyId}/tasks`, REQ-TASK-01, REQ-TASK-02, REQ-TASK-03, REQ-TASK-04).
class TasksRepository {
  static const _cacheKey = 'cached_family_tasks_v1';

  final FirebaseFirestore? _injectedFirestore;
  final SharedPreferences? _prefs;
  final StreamController<List<SchoolTask>> _localController =
      StreamController<List<SchoolTask>>.broadcast();
  final Set<String> _deletedTaskIds = <String>{};

  TasksRepository({
    FirebaseFirestore? firestore,
    SharedPreferences? prefs,
  })  : _injectedFirestore = firestore,
        _prefs = prefs {
    _loadFromLocalCache();
  }

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

  void _loadFromLocalCache() {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty) {
          final loaded = decoded
              .whereType<Map>()
              .map((m) => SchoolTask.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          if (loaded.isNotEmpty) {
            _fallbackTasks
              ..clear()
              ..addAll(loaded);
          }
        }
      }
    } catch (e) {
      debugPrint('[TasksRepository] _loadFromLocalCache error: $e');
    }
  }

  void _saveToLocalCache() {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final encoded = jsonEncode(_fallbackTasks.map((t) => t.toJson()).toList());
      prefs.setString(_cacheKey, encoded);
    } catch (e) {
      debugPrint('[TasksRepository] _saveToLocalCache error: $e');
    }
  }

  List<SchoolTask> get currentFallbackTasks =>
      List<SchoolTask>.unmodifiable(_fallbackTasks);

  void _notifyFallbackListeners() {
    _saveToLocalCache();
    if (!_localController.isClosed) {
      _localController.add(List<SchoolTask>.unmodifiable(_fallbackTasks));
    }
  }

  /// Watches family tasks in real time from `family_tasks/{familyId}/tasks`,
  /// emitting cached/starter tasks immediately and keeping Firestore + local cache synchronized.
  Stream<List<SchoolTask>> watchTasks(String familyId) {
    late final StreamController<List<SchoolTask>> controller;
    StreamSubscription<List<SchoolTask>>? localSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? firestoreSub;

    controller = StreamController<List<SchoolTask>>(
      onListen: () {
        // 1. Emit cached/optimistic tasks immediately on first frame
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
                  // Push any locally cached non-seed tasks to Firestore so both stay in sync
                  for (final localTask in _fallbackTasks) {
                    if (!localTask.id.startsWith('seed_')) {
                      db
                          .collection('family_tasks')
                          .doc(familyId)
                          .collection('tasks')
                          .doc(localTask.id)
                          .set(localTask.toJson(), SetOptions(merge: true))
                          .catchError((_) {});
                    }
                  }
                  controller.add(List<SchoolTask>.unmodifiable(_fallbackTasks));
                } else {
                  final remoteTasks = snapshot.docs
                      .map((doc) => SchoolTask.fromJson(doc.data(), doc.id))
                      .where((t) => !_deletedTaskIds.contains(t.id))
                      .toList();

                  final remoteIds = remoteTasks.map((t) => t.id).toSet();
                  final remoteSourceIds = remoteTasks
                      .map((t) => t.sourceId)
                      .whereType<String>()
                      .toSet();

                  // Keep any locally added user tasks not yet reflected in remote snapshot
                  final unsyncedLocal = _fallbackTasks.where((t) {
                    if (t.id.startsWith('seed_') || _deletedTaskIds.contains(t.id)) {
                      return false;
                    }
                    if (remoteIds.contains(t.id)) return false;
                    if (t.sourceId != null && remoteSourceIds.contains(t.sourceId)) {
                      return false;
                    }
                    return true;
                  }).toList();

                  for (final localTask in unsyncedLocal) {
                    db
                        .collection('family_tasks')
                        .doc(familyId)
                        .collection('tasks')
                        .doc(localTask.id)
                        .set(localTask.toJson(), SetOptions(merge: true))
                        .catchError((_) {});
                  }

                  final merged = <SchoolTask>[
                    ...unsyncedLocal,
                    ...remoteTasks,
                  ];
                  _fallbackTasks
                    ..clear()
                    ..addAll(merged);
                  _saveToLocalCache();
                  controller.add(List<SchoolTask>.unmodifiable(_fallbackTasks));
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
  /// If `sourceId` is provided, uses a deterministic ID and deduplicates against existing tasks.
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
    final trimmedSourceId =
        (sourceId != null && sourceId.trim().isNotEmpty) ? sourceId.trim() : null;

    // Check if a task with the same sourceId already exists to prevent duplicates
    if (trimmedSourceId != null) {
      final existingIdx = _fallbackTasks.indexWhere(
        (t) =>
            t.sourceId == trimmedSourceId ||
            SchoolTask.normalizeSlug(t.sourceId) ==
                SchoolTask.normalizeSlug(trimmedSourceId),
      );
      if (existingIdx != -1) {
        final existing = _fallbackTasks[existingIdx];
        final updated = existing.copyWith(
          title: trimmedTitle,
          description:
              (trimmedDesc != null && trimmedDesc.isNotEmpty) ? trimmedDesc : null,
          dueDate: dueDate,
          priority: priority,
          assignedTo: assignedTo,
          subject: (trimmedSubject != null && trimmedSubject.isNotEmpty)
              ? trimmedSubject
              : existing.subject,
          source: source,
          sourceId: trimmedSourceId,
          metadata: metadata ?? existing.metadata,
        );
        await updateTask(familyId, updated);
        return updated;
      }
    }

    final taskId = trimmedSourceId != null
        ? 'task_${SchoolTask.normalizeSlug(trimmedSourceId)}'
        : 'task_${DateTime.now().millisecondsSinceEpoch}';

    _deletedTaskIds.remove(taskId);

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
      sourceId: trimmedSourceId,
      metadata: metadata,
    );

    // Optimistic local insert at top of list
    _fallbackTasks.removeWhere((t) => t.id == taskId);
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
            .set(newTask.toJson(), SetOptions(merge: true));
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

    _deletedTaskIds.add(task.id);
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
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {}
  return TasksRepository(prefs: prefs);
});

/// Real-time stream of family tasks for the active user's `familyId` (`D-01`).
final tasksStreamProvider = StreamProvider<List<SchoolTask>>((ref) {
  final user = ref.watch(appUserProvider);
  final rawFamilyId = user?.familyId?.trim();
  final familyId = (rawFamilyId != null && rawFamilyId.isNotEmpty)
      ? rawFamilyId
      : 'jankiewicz_family';
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
