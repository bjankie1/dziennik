import 'package:cloud_firestore/cloud_firestore.dart';

/// Priority levels for a family school task (REQ-TASK-01, D-02).
enum TaskPriority {
  high,
  medium,
  low;

  String toFirestore() => name;

  static TaskPriority fromString(String? val) =>
      switch (val?.trim().toLowerCase()) {
        'high' => TaskPriority.high,
        'low' => TaskPriority.low,
        _ => TaskPriority.medium,
      };

  String get label => switch (this) {
        TaskPriority.high => 'Wysoki',
        TaskPriority.medium => 'Normalny',
        TaskPriority.low => 'Niski',
      };

  int get sortWeight => switch (this) {
        TaskPriority.high => 0,
        TaskPriority.medium => 1,
        TaskPriority.low => 2,
      };
}

/// Target assignee for a family task (REQ-TASK-01, D-01).
enum TaskAssignee {
  student,
  parent,
  shared;

  String toFirestore() => name;

  static TaskAssignee fromString(String? val) =>
      switch (val?.trim().toLowerCase()) {
        'parent' => TaskAssignee.parent,
        'shared' => TaskAssignee.shared,
        _ => TaskAssignee.student,
      };

  String get label => switch (this) {
        TaskAssignee.student => 'Dla Oskara',
        TaskAssignee.parent => 'Dla Rodzica',
        TaskAssignee.shared => 'Wspólne',
      };
}

/// Origin source of a task, ready for Phase 16 smart suggestions (D-02).
enum TaskSource {
  manual,
  exam,
  message;

  String toFirestore() => name;

  static TaskSource fromString(String? val) =>
      switch (val?.trim().toLowerCase()) {
        'exam' => TaskSource.exam,
        'message' => TaskSource.message,
        _ => TaskSource.manual,
      };
}

/// Domain model representing a shared Parent ↔ Student task in Smart To-Do
/// (`family_tasks/{familyId}/tasks`, REQ-TASK-01, REQ-TASK-02, D-01, D-02, D-03).
class SchoolTask {
  final String id;
  final String familyId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskAssignee assignedTo;
  final String? subject;
  final bool isCompleted;
  final String createdByRole; // 'parent' | 'student'
  final String createdByName; // e.g. 'Tata', 'Rodzic', 'Oskar'
  final DateTime createdAt;
  final String? completedByRole;
  final String? completedByName;
  final DateTime? completedAt;
  final TaskSource source;
  final String? sourceId;
  final Map<String, dynamic>? metadata;

  const SchoolTask({
    required this.id,
    required this.familyId,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.assignedTo = TaskAssignee.student,
    this.subject,
    this.isCompleted = false,
    required this.createdByRole,
    required this.createdByName,
    required this.createdAt,
    this.completedByRole,
    this.completedByName,
    this.completedAt,
    this.source = TaskSource.manual,
    this.sourceId,
    this.metadata,
  });

  /// Normalized midnight timestamp for today (`00:00:00` local time).
  static DateTime get todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Normalized calendar date (`00:00:00` local time) of [dueDate], if set.
  DateTime? get normalizedDueDate {
    final d = dueDate;
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day);
  }

  /// True if the task is active and its calendar due date is strictly before today.
  bool get isOverdue {
    if (isCompleted) return false;
    final nd = normalizedDueDate;
    return nd != null && nd.isBefore(todayStart);
  }

  /// True if the task is active and its calendar due date is today.
  bool get isDueToday {
    if (isCompleted) return false;
    final nd = normalizedDueDate;
    return nd != null && nd.isAtSameMomentAs(todayStart);
  }

  /// True if the task is active and its calendar due date is strictly after today.
  bool get isUpcoming {
    if (isCompleted) return false;
    final nd = normalizedDueDate;
    return nd != null && nd.isAfter(todayStart);
  }

  /// True if the task is active and has no due date assigned.
  bool get hasNoDueDate => !isCompleted && dueDate == null;

  /// Human-readable attribution label for task cards (D-01).
  /// Example: `'Dodał: Tata • Ukończył: Oskar'` or `'Dodał: Tata'`.
  String get attributionLabel {
    final completedName = completedByName?.trim();
    if (isCompleted && completedName != null && completedName.isNotEmpty) {
      return 'Dodał: $createdByName • Ukończył: $completedName';
    }
    return 'Dodał: $createdByName';
  }

  /// Role-based deletion permission check (D-03).
  /// Student (`isStudent == true`) cannot delete a task created by Parent (`createdByRole == 'parent'`).
  bool canBeDeletedBy({required bool isStudent}) {
    if (isStudent && createdByRole.trim().toLowerCase() == 'parent') {
      return false;
    }
    return true;
  }

  /// Role relevance weight for sorting urgent tasks on the Dashboard (`0` = primary/shared, `1` = other role).
  int roleSortWeight({required bool isStudent}) {
    if (isStudent) {
      if (assignedTo == TaskAssignee.student ||
          assignedTo == TaskAssignee.shared) {
        return 0;
      }
      return 1;
    } else {
      if (assignedTo == TaskAssignee.parent ||
          assignedTo == TaskAssignee.shared) {
        return 0;
      }
      return 1;
    }
  }

  /// Sorts active tasks for the Dashboard „Zadania na dziś” Bento widget (D-08)
  /// and returns at most 5 most urgent items:
  /// 1. Overdue tasks (oldest dueDate first, then role relevance, then priority)
  /// 2. Due Today tasks (role relevance first, then priority)
  /// 3. Upcoming / undated tasks (role relevance first, then priority, then earliest dueDate)
  static List<SchoolTask> sortUrgentForDashboard(
    List<SchoolTask> tasks, {
    required bool isStudent,
    int maxItems = 5,
  }) {
    final active = tasks.where((t) => !t.isCompleted).toList();

    int urgencyBucket(SchoolTask t) {
      if (t.isOverdue) return 0;
      if (t.isDueToday) return 1;
      if (t.isUpcoming) return 2;
      return 3;
    }

    active.sort((a, b) {
      final bucketA = urgencyBucket(a);
      final bucketB = urgencyBucket(b);
      if (bucketA != bucketB) {
        return bucketA.compareTo(bucketB);
      }

      // Within overdue bucket, oldest due date comes first
      if (bucketA == 0) {
        final dateCompare = a.normalizedDueDate!.compareTo(b.normalizedDueDate!);
        if (dateCompare != 0) return dateCompare;
      }

      // Prioritize tasks relevant to the logged-in user's role + shared
      final roleWeightA = a.roleSortWeight(isStudent: isStudent);
      final roleWeightB = b.roleSortWeight(isStudent: isStudent);
      if (roleWeightA != roleWeightB) {
        return roleWeightA.compareTo(roleWeightB);
      }

      // Then sort by priority (high -> medium -> low)
      final priorityCompare = a.priority.sortWeight.compareTo(
        b.priority.sortWeight,
      );
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      // For upcoming tasks, earlier due date first
      if (a.normalizedDueDate != null && b.normalizedDueDate != null) {
        final dateCompare = a.normalizedDueDate!.compareTo(b.normalizedDueDate!);
        if (dateCompare != 0) return dateCompare;
      }

      return b.createdAt.compareTo(a.createdAt);
    });

    if (active.length <= maxItems) return active;
    return active.sublist(0, maxItems);
  }

  factory SchoolTask.fromJson(Map<String, dynamic> json, [String? id]) {
    DateTime? parseNullableDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      if (raw is Timestamp) return raw.toDate();
      if (raw is String && raw.trim().isNotEmpty) {
        return DateTime.tryParse(raw.trim());
      }
      return null;
    }

    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : null;

    final rawDescription = json['description']?.toString();
    final rawSubject = json['subject']?.toString();
    final rawCompletedByRole = json['completedByRole']?.toString();
    final rawCompletedByName = json['completedByName']?.toString();
    final rawSourceId = json['sourceId']?.toString();

    return SchoolTask(
      id: id ?? (json['id']?.toString() ?? ''),
      familyId: json['familyId']?.toString() ?? 'jankiewicz_family',
      title: json['title']?.toString() ?? '',
      description: (rawDescription != null && rawDescription.trim().isNotEmpty)
          ? rawDescription.trim()
          : null,
      dueDate: parseNullableDate(json['dueDate']),
      priority: TaskPriority.fromString(json['priority']?.toString()),
      assignedTo: TaskAssignee.fromString(json['assignedTo']?.toString()),
      subject: (rawSubject != null && rawSubject.trim().isNotEmpty)
          ? rawSubject.trim()
          : null,
      isCompleted: json['isCompleted'] == true,
      createdByRole: json['createdByRole']?.toString() ?? 'parent',
      createdByName: json['createdByName']?.toString() ?? 'Rodzic',
      createdAt: parseNullableDate(json['createdAt']) ?? DateTime.now(),
      completedByRole:
          (rawCompletedByRole != null && rawCompletedByRole.trim().isNotEmpty)
              ? rawCompletedByRole.trim()
              : null,
      completedByName:
          (rawCompletedByName != null && rawCompletedByName.trim().isNotEmpty)
              ? rawCompletedByName.trim()
              : null,
      completedAt: parseNullableDate(json['completedAt']),
      source: TaskSource.fromString(json['source']?.toString()),
      sourceId: (rawSourceId != null && rawSourceId.trim().isNotEmpty)
          ? rawSourceId.trim()
          : null,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.toFirestore(),
      'assignedTo': assignedTo.toFirestore(),
      'subject': subject,
      'isCompleted': isCompleted,
      'createdByRole': createdByRole,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'completedByRole': completedByRole,
      'completedByName': completedByName,
      'completedAt': completedAt?.toIso8601String(),
      'source': source.toFirestore(),
      if (sourceId != null) 'sourceId': sourceId,
      if (metadata != null) 'metadata': metadata,
    };
  }

  SchoolTask copyWith({
    String? id,
    String? familyId,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    TaskPriority? priority,
    TaskAssignee? assignedTo,
    String? subject,
    bool clearSubject = false,
    bool? isCompleted,
    String? createdByRole,
    String? createdByName,
    DateTime? createdAt,
    String? completedByRole,
    String? completedByName,
    DateTime? completedAt,
    bool clearCompletion = false,
    TaskSource? source,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) {
    return SchoolTask(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      subject: clearSubject ? null : (subject ?? this.subject),
      isCompleted: isCompleted ?? this.isCompleted,
      createdByRole: createdByRole ?? this.createdByRole,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      completedByRole:
          clearCompletion ? null : (completedByRole ?? this.completedByRole),
      completedByName:
          clearCompletion ? null : (completedByName ?? this.completedByName),
      completedAt: clearCompletion ? null : (completedAt ?? this.completedAt),
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolTask && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SchoolTask(id: $id, title: $title, priority: ${priority.name}, assignedTo: ${assignedTo.name}, isCompleted: $isCompleted)';
}
