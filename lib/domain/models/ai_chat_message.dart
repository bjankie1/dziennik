import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/calendar_export_service.dart';

/// Gemini model tier selector for Phase 20 AI Assistant (D-03b).
enum AiModelTier {
  flash38(
    modelId: 'gemini-3.8-flash',
    fallbackModelIds: ['gemini-flash-latest', 'gemini-2.5-flash'],
    shortLabel: '⚡ 3.8 Flash',
    fullLabel: '⚡ Gemini 3.8 Flash',
    subtitle: 'Szybki — zalecany na co dzień',
  ),
  pro31(
    modelId: 'gemini-3.1-pro-preview',
    fallbackModelIds: ['gemini-2.5-pro', 'gemini-flash-latest'],
    shortLabel: '🧠 3.1 Pro',
    fullLabel: '🧠 Gemini 3.1 Pro',
    subtitle: 'Głęboka analiza — trudne pytania',
  );

  final String modelId;
  final List<String> fallbackModelIds;
  final String shortLabel;
  final String fullLabel;
  final String subtitle;

  const AiModelTier({
    required this.modelId,
    required this.fallbackModelIds,
    required this.shortLabel,
    required this.fullLabel,
    required this.subtitle,
  });

  static AiModelTier fromModelId(String? raw) {
    if (raw != null && raw.contains('pro')) {
      return AiModelTier.pro31;
    }
    return AiModelTier.flash38;
  }
}

/// Clickable source citation pill attached to an AI Assistant answer (D-06).
class AiSourceCitation {
  final String type; // 'message' | 'timetable' | 'exam' | 'grade' | 'attendance' | 'announcement' | 'task'
  final String label;
  final String route;
  final String? targetId;

  const AiSourceCitation({
    required this.type,
    required this.label,
    required this.route,
    this.targetId,
  });

  /// Normalizes routes so LLM outputs like `/plan` or `/ogloszenia` map to valid GoRouter paths.
  String get normalizedRoute {
    final clean = route.trim();
    if (clean == '/plan' || clean.startsWith('/plan?')) {
      return clean.replaceFirst('/plan', '/plan-lekcji');
    }
    if (clean == '/ogloszenia') {
      return '/wiadomosci';
    }
    if (clean.isEmpty || !clean.startsWith('/')) {
      switch (type) {
        case 'message':
        case 'announcement':
          return '/wiadomosci';
        case 'timetable':
        case 'exam':
          return '/plan-lekcji';
        case 'grade':
          return '/oceny';
        case 'attendance':
          return '/frekwencja';
        case 'task':
          return '/zadania';
        default:
          return '/pulpit';
      }
    }
    return clean;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'label': label,
      'route': normalizedRoute,
      if (targetId != null) 'targetId': targetId,
    };
  }

  factory AiSourceCitation.fromMap(Map<String, dynamic> map) {
    final type = (map['type'] as String? ?? 'message').trim();
    final rawRoute = (map['route'] as String? ?? '').trim();
    return AiSourceCitation(
      type: type,
      label: (map['label'] as String? ?? 'Źródło w dzienniku').trim(),
      route: rawRoute,
      targetId: map['targetId'] as String?,
    );
  }
}

/// Optional calendar event extracted by the AI Assistant for 1-click Google Calendar export (D-06).
class AiSuggestedEvent {
  final String title;
  final String date; // YYYY-MM-DD
  final String? startTime; // HH:MM
  final String description;

  const AiSuggestedEvent({
    required this.title,
    required this.date,
    this.startTime,
    required this.description,
  });

  DateTime? get parsedDate {
    try {
      final parts = date.trim().split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      return DateTime.tryParse(date);
    } catch (_) {
      return null;
    }
  }

  CalendarExamEvent toCalendarExamEvent() {
    final dt = parsedDate ?? DateTime.now().add(const Duration(days: 1));
    return CalendarExamEvent(
      subject: title,
      eventType: 'Wydarzenie szkolne',
      scope: description,
      date: dt,
      startTime: (startTime != null && startTime!.trim().isNotEmpty)
          ? startTime!.trim()
          : '08:00',
    );
  }

  Uri buildGoogleCalendarUri() {
    return Uri.parse(
      CalendarExportService.buildGoogleCalendarUrl(toCalendarExamEvent()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      if (startTime != null) 'startTime': startTime,
      'description': description,
    };
  }

  factory AiSuggestedEvent.fromMap(Map<String, dynamic> map) {
    return AiSuggestedEvent(
      title: (map['title'] as String? ?? '').trim(),
      date: (map['date'] as String? ?? '').trim(),
      startTime: map['startTime'] as String?,
      description: (map['description'] as String? ?? '').trim(),
    );
  }
}

/// Optional Smart To-Do task suggested by the AI Assistant (D-06).
class AiSuggestedTask {
  final String title;
  final String? dueDate; // YYYY-MM-DD
  final String category; // 'exam' | 'homework' | 'trip' | 'other'

  const AiSuggestedTask({
    required this.title,
    this.dueDate,
    this.category = 'other',
  });

  DateTime? get parsedDueDate {
    if (dueDate == null || dueDate!.trim().isEmpty) return null;
    try {
      final parts = dueDate!.trim().split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      return DateTime.tryParse(dueDate!);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      if (dueDate != null) 'dueDate': dueDate,
      'category': category,
    };
  }

  factory AiSuggestedTask.fromMap(Map<String, dynamic> map) {
    return AiSuggestedTask(
      title: (map['title'] as String? ?? '').trim(),
      dueDate: map['dueDate'] as String?,
      category: (map['category'] as String? ?? 'other').trim(),
    );
  }
}

/// Single message turn in the AI Assistant conversation (`students/{id}/ai_chats/{role}/messages/{msgId}`).
class AiChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime timestamp;
  final String viewerRole; // 'parent' | 'student'
  final String? modelUsed;
  final List<AiSourceCitation> sources;
  final AiSuggestedEvent? suggestedEvent;
  final AiSuggestedTask? suggestedTask;
  final bool isError;

  const AiChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    required this.viewerRole,
    this.modelUsed,
    this.sources = const [],
    this.suggestedEvent,
    this.suggestedTask,
    this.isError = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAtIso': timestamp.toIso8601String(),
      'viewerRole': viewerRole,
      if (modelUsed != null) 'modelUsed': modelUsed,
      'sources': sources.map((s) => s.toMap()).toList(),
      if (suggestedEvent != null) 'suggestedEvent': suggestedEvent!.toMap(),
      if (suggestedTask != null) 'suggestedTask': suggestedTask!.toMap(),
      'isError': isError,
    };
  }

  factory AiChatMessage.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parsedTime = DateTime.now();
    final rawTs = map['timestamp'];
    if (rawTs is Timestamp) {
      parsedTime = rawTs.toDate();
    } else if (rawTs is String) {
      parsedTime = DateTime.tryParse(rawTs) ?? parsedTime;
    } else if (map['createdAtIso'] is String) {
      parsedTime = DateTime.tryParse(map['createdAtIso'] as String) ?? parsedTime;
    }

    final rawSources = map['sources'];
    final parsedSources = <AiSourceCitation>[];
    if (rawSources is List) {
      for (final item in rawSources) {
        if (item is Map) {
          parsedSources.add(
            AiSourceCitation.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    AiSuggestedEvent? parsedEvent;
    if (map['suggestedEvent'] is Map) {
      final ev = AiSuggestedEvent.fromMap(
        Map<String, dynamic>.from(map['suggestedEvent'] as Map),
      );
      if (ev.title.isNotEmpty && ev.date.isNotEmpty) {
        parsedEvent = ev;
      }
    }

    AiSuggestedTask? parsedTask;
    if (map['suggestedTask'] is Map) {
      final t = AiSuggestedTask.fromMap(
        Map<String, dynamic>.from(map['suggestedTask'] as Map),
      );
      if (t.title.isNotEmpty) {
        parsedTask = t;
      }
    }

    return AiChatMessage(
      id: docId ?? (map['id'] as String? ?? ''),
      role: (map['role'] as String? ?? 'assistant').trim(),
      text: (map['text'] as String? ?? '').trim(),
      timestamp: parsedTime,
      viewerRole: (map['viewerRole'] as String? ?? 'parent').trim(),
      modelUsed: map['modelUsed'] as String?,
      sources: parsedSources,
      suggestedEvent: parsedEvent,
      suggestedTask: parsedTask,
      isError: map['isError'] == true,
    );
  }

  /// Parses the structured JSON string returned by Gemini (`responseSchema`) into an [AiChatMessage].
  factory AiChatMessage.fromGeminiStructuredJson({
    required String id,
    required String rawJson,
    required String viewerRole,
    required String modelUsed,
    DateTime? timestamp,
  }) {
    final ts = timestamp ?? DateTime.now();
    try {
      String cleaned = rawJson.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
            .replaceFirst(RegExp(r'\s*```$'), '')
            .trim();
      }
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        final answer = (decoded['answer'] as String? ?? '').trim();
        final rawSources = decoded['sources'];
        final sources = <AiSourceCitation>[];
        if (rawSources is List) {
          for (final item in rawSources) {
            if (item is Map) {
              sources.add(
                AiSourceCitation.fromMap(Map<String, dynamic>.from(item)),
              );
            }
          }
        }

        AiSuggestedEvent? suggestedEvent;
        if (decoded['suggestedEvent'] is Map) {
          final ev = AiSuggestedEvent.fromMap(
            Map<String, dynamic>.from(decoded['suggestedEvent'] as Map),
          );
          if (ev.title.isNotEmpty && ev.date.isNotEmpty) {
            suggestedEvent = ev;
          }
        }

        AiSuggestedTask? suggestedTask;
        if (decoded['suggestedTask'] is Map) {
          final task = AiSuggestedTask.fromMap(
            Map<String, dynamic>.from(decoded['suggestedTask'] as Map),
          );
          if (task.title.isNotEmpty) {
            suggestedTask = task;
          }
        }

        return AiChatMessage(
          id: id,
          role: 'assistant',
          text: answer.isNotEmpty ? answer : cleaned,
          timestamp: ts,
          viewerRole: viewerRole,
          modelUsed: modelUsed,
          sources: sources,
          suggestedEvent: suggestedEvent,
          suggestedTask: suggestedTask,
        );
      }
    } catch (_) {
      // Fall back to plain text if JSON parsing fails
    }

    return AiChatMessage(
      id: id,
      role: 'assistant',
      text: rawJson.trim(),
      timestamp: ts,
      viewerRole: viewerRole,
      modelUsed: modelUsed,
    );
  }
}
