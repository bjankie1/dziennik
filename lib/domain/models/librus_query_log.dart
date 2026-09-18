import 'package:intl/intl.dart';

class LibrusQueryLog {
  final String id;
  final String url;
  final String endpoint;
  final String method;
  final int status;
  final String statusText;
  final int durationMs;
  final int responseSizeBytes;
  final String trigger; // 'cron' | 'manual'
  final String module; // 'Oceny', 'Plan lekcji', 'Frekwencja', itp.
  final DateTime timestamp;
  final String? error;
  final String? login;
  final String? syncRunId;

  const LibrusQueryLog({
    required this.id,
    required this.url,
    required this.endpoint,
    required this.method,
    required this.status,
    required this.statusText,
    required this.durationMs,
    required this.responseSizeBytes,
    required this.trigger,
    required this.module,
    required this.timestamp,
    this.error,
    this.login,
    this.syncRunId,
  });

  bool get isSuccess => status >= 200 && status < 400;
  bool get isRateLimited => status == 429;
  bool get isError => status >= 400;
  bool get isCacheHit => method == 'CACHE';
  bool get isCron => trigger.toLowerCase() == 'cron';

  String get formattedTime => DateFormat('HH:mm:ss').format(timestamp);
  String get formattedDateTime => DateFormat('dd.MM.yyyy HH:mm:ss').format(timestamp);

  String get durationText {
    if (durationMs < 1000) {
      return '$durationMs ms';
    }
    return '${(durationMs / 1000).toStringAsFixed(2)} s';
  }

  String get sizeText {
    if (responseSizeBytes <= 0) return '—';
    if (responseSizeBytes < 1024) return '$responseSizeBytes B';
    final kb = responseSizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }

  factory LibrusQueryLog.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime parsedTime;
    final rawTs = json['timestamp'];
    if (rawTs is String) {
      parsedTime = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else if (rawTs is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else {
      parsedTime = DateTime.now();
    }

    return LibrusQueryLog(
      id: id ?? json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      endpoint: json['endpoint']?.toString() ?? json['url']?.toString() ?? '',
      method: (json['method']?.toString() ?? 'GET').toUpperCase(),
      status: (json['status'] as num?)?.toInt() ?? 200,
      statusText: json['statusText']?.toString() ?? 'OK',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      responseSizeBytes: (json['responseSizeBytes'] as num?)?.toInt() ?? 0,
      trigger: json['trigger']?.toString() ?? 'manual',
      module: json['module']?.toString() ?? 'Inne',
      timestamp: parsedTime,
      error: json['error']?.toString(),
      login: json['login']?.toString(),
      syncRunId: json['syncRunId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'endpoint': endpoint,
      'method': method,
      'status': status,
      'statusText': statusText,
      'durationMs': durationMs,
      'responseSizeBytes': responseSizeBytes,
      'trigger': trigger,
      'module': module,
      'timestamp': timestamp.toIso8601String(),
      if (error != null) 'error': error,
      if (login != null) 'login': login,
      if (syncRunId != null) 'syncRunId': syncRunId,
    };
  }
}
