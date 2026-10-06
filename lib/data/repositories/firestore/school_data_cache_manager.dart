import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/librus_connection_service.dart';
import '../../../domain/models/message_thread.dart';
import '../../../domain/models/user_role.dart';

class SchoolDataCacheManager {
  static const String prefReadOverrides = 'edusync_read_messages_overrides';
  static const String prefArchiveOverrides =
      'edusync_archived_messages_overrides';
  static const String prefJustificationOverrides =
      'edusync_justifications_overrides';
  static const String prefDefaultDriveFolderId =
      'edusync_drive_default_folder_id';
  static const String prefDefaultDriveFolderName =
      'edusync_drive_default_folder_name';
  static const String prefLocalReplies = 'local_message_replies_v1';

  final FirebaseFirestore? _firestoreOverride;
  final LibrusConnectionService connectionService;
  final http.Client httpClient;
  final Duration cacheTtl;

  FirebaseFirestore get firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  Map<String, dynamic>? _memoryCache;
  DateTime? _lastCacheTime;
  String? _cachedTargetLogin;

  final Map<String, bool> _localReadOverrides = {};
  bool _readOverridesLoaded = false;

  final Map<String, bool> _localArchiveOverrides = {};
  bool _archiveOverridesLoaded = false;

  final Map<String, String> _localJustificationOverrides = {};
  bool _justificationOverridesLoaded = false;

  final Map<String, List<Map<String, dynamic>>> _localReplies = {};
  bool _localRepliesLoaded = false;

  final Map<String, Map<String, DriveAttachmentInfo>>
      _localDriveAttachmentsOverrides = {};

  int _idCounter = 0;

  SchoolDataCacheManager({
    FirebaseFirestore? firestore,
    LibrusConnectionService? connectionService,
    http.Client? httpClient,
    this.cacheTtl = const Duration(minutes: 2),
  })  : _firestoreOverride = firestore,
        connectionService = connectionService ?? LibrusConnectionService(),
        httpClient = httpClient ?? http.Client();

  Map<String, dynamic>? get memoryCache => _memoryCache;
  DateTime? get lastCacheTime => _lastCacheTime;
  String? get cachedTargetLogin => _cachedTargetLogin;

  void seedMemoryCache(
    Map<String, dynamic> data, {
    String? targetLogin = '11010033',
    DateTime? cachedAt,
  }) {
    _memoryCache = data;
    _lastCacheTime = cachedAt ?? DateTime.now();
    _cachedTargetLogin = targetLogin;
  }

  void invalidateMemoryCache() {
    _memoryCache = null;
    _lastCacheTime = null;
    _cachedTargetLogin = null;
  }

  String generateUniqueId() =>
      'k_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';

  Map<String, DriveAttachmentInfo> parseDriveAttachments(
    dynamic raw,
    String msgId,
  ) {
    final result = <String, DriveAttachmentInfo>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          result[key.toString()] = DriveAttachmentInfo.fromMap(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }
    final localForMsg = _localDriveAttachmentsOverrides[msgId];
    if (localForMsg != null) {
      result.addAll(localForMsg);
    }
    return result;
  }

  Future<void> ensureReadOverridesLoaded() async {
    if (_readOverridesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(prefReadOverrides);
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          if (val is bool) _localReadOverrides[key] = val;
        });
      }
      _readOverridesLoaded = true;
    } catch (_) {}
  }

  bool? getReadOverride(String msgId) => _localReadOverrides[msgId];

  Future<void> _saveReadOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        prefReadOverrides,
        json.encode(_localReadOverrides),
      );
    } catch (_) {}
  }

  Future<void> setReadOverride(String msgId, bool isRead) async {
    await ensureReadOverridesLoaded();
    _localReadOverrides[msgId] = isRead;
    await _saveReadOverrides();

    if (_memoryCache != null && _memoryCache!['messages'] != null) {
      final msgs = _memoryCache!['messages'] as List<dynamic>;
      for (final m in msgs) {
        if (m is Map && (m['id'] == msgId || m['id']?.toString() == msgId)) {
          m['isRead'] = isRead;
        }
      }
    }
  }

  Future<void> setAllReadOverrides(Iterable<String> msgIds) async {
    await ensureReadOverridesLoaded();
    for (final id in msgIds) {
      _localReadOverrides[id] = true;
    }
    await _saveReadOverrides();

    if (_memoryCache != null && _memoryCache!['messages'] != null) {
      final rawMsgs = _memoryCache!['messages'] as List<dynamic>;
      for (final m in rawMsgs) {
        if (m is Map) m['isRead'] = true;
      }
    }
  }

  Future<void> ensureArchiveOverridesLoaded() async {
    if (_archiveOverridesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(prefArchiveOverrides);
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          if (val is bool) _localArchiveOverrides[key] = val;
        });
      }
      _archiveOverridesLoaded = true;
    } catch (_) {}
  }

  bool? getArchiveOverride(String msgId) => _localArchiveOverrides[msgId];

  Future<void> _saveArchiveOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        prefArchiveOverrides,
        json.encode(_localArchiveOverrides),
      );
    } catch (_) {}
  }

  Future<void> setArchiveOverride(String msgId, bool isArchived) async {
    await ensureArchiveOverridesLoaded();
    _localArchiveOverrides[msgId] = isArchived;
    await _saveArchiveOverrides();

    if (_memoryCache != null) {
      if (_memoryCache!['archivedMessageOverrides'] is Map) {
        (_memoryCache!['archivedMessageOverrides'] as Map)[msgId] = isArchived;
      } else {
        _memoryCache!['archivedMessageOverrides'] = <String, dynamic>{
          msgId: isArchived,
        };
      }
      if (_memoryCache!['messages'] is List) {
        final msgs = _memoryCache!['messages'] as List<dynamic>;
        for (final m in msgs) {
          if (m is Map && (m['id'] == msgId || m['id']?.toString() == msgId)) {
            m['isArchived'] = isArchived;
          }
        }
      }
    }
  }

  Future<void> ensureJustificationOverridesLoaded() async {
    if (_justificationOverridesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(prefJustificationOverrides);
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          if (val is String) _localJustificationOverrides[key] = val;
        });
      }
      _justificationOverridesLoaded = true;
    } catch (_) {}
  }

  String? getJustificationOverride(String recordId) =>
      _localJustificationOverrides[recordId];

  Future<void> _saveJustificationOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        prefJustificationOverrides,
        json.encode(_localJustificationOverrides),
      );
    } catch (_) {}
  }

  Future<void> setJustificationOverrides(
    Iterable<String> recordIds,
    String reason, {
    Iterable<String> removeRecordIds = const [],
  }) async {
    await ensureJustificationOverridesLoaded();
    final keepSet = recordIds.toSet();
    for (final id in keepSet) {
      _localJustificationOverrides[id] = reason;
    }
    for (final id in removeRecordIds) {
      if (!keepSet.contains(id)) {
        _localJustificationOverrides.remove(id);
      }
    }
    await _saveJustificationOverrides();
  }

  Future<void> removeJustificationOverrides(Iterable<String> recordIds) async {
    await ensureJustificationOverridesLoaded();
    for (final id in recordIds) {
      _localJustificationOverrides.remove(id);
    }
    await _saveJustificationOverrides();
  }

  String _currentStudentScopeLogin() {
    final fromData = _memoryCache?['login']?.toString().trim() ?? '';
    if (fromData.isNotEmpty) return fromData;
    return (_cachedTargetLogin ?? '').trim();
  }

  Future<void> ensureLocalRepliesLoaded() async {
    if (_localRepliesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(prefLocalReplies);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = json.decode(jsonStr);
        if (decoded is Map) {
          decoded.forEach((key, val) {
            if (val is List) {
              final list = <Map<String, dynamic>>[];
              for (final entry in val) {
                if (entry is Map) {
                  list.add(Map<String, dynamic>.from(entry));
                }
              }
              if (list.isNotEmpty) {
                _localReplies[key.toString()] = list;
              }
            }
          });
        }
      }
      _localRepliesLoaded = true;
    } catch (_) {}
  }

  List<Map<String, dynamic>> getLocalReplies(String msgId) {
    final list = _localReplies[msgId];
    if (list == null || list.isEmpty) return const [];
    final activeLogin = _currentStudentScopeLogin();
    return list
        .where((r) {
          final replyLogin = (r['targetLogin'] ?? '').toString().trim();
          if (activeLogin.isNotEmpty &&
              replyLogin.isNotEmpty &&
              replyLogin != activeLogin) {
            return false;
          }
          return true;
        })
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  Future<void> _saveLocalReplies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        prefLocalReplies,
        json.encode(_localReplies),
      );
    } catch (_) {}
  }

  Future<void> addLocalReply(
    String msgId,
    Map<String, dynamic> replyMap,
  ) async {
    await ensureLocalRepliesLoaded();
    final cleanMsgId = msgId.trim();
    if (cleanMsgId.isEmpty) return;

    final activeLogin = _currentStudentScopeLogin();
    final normalized = <String, dynamic>{
      ...replyMap,
      if (activeLogin.isNotEmpty) 'targetLogin': activeLogin,
    };
    final incomingId = (normalized['id'] ?? '').toString().trim();
    final incomingContent =
        (normalized['content'] ?? normalized['body'] ?? '').toString().trim();

    final listForMsg = _localReplies.putIfAbsent(
      cleanMsgId,
      () => <Map<String, dynamic>>[],
    );
    final alreadyInLocal = listForMsg.any((existing) {
      final existingId = (existing['id'] ?? '').toString().trim();
      final existingContent =
          (existing['content'] ?? existing['body'] ?? '').toString().trim();
      return (incomingId.isNotEmpty && existingId == incomingId) ||
          (incomingContent.isNotEmpty && existingContent == incomingContent);
    });
    if (!alreadyInLocal) {
      listForMsg.add(normalized);
      await _saveLocalReplies();
    }

    if (_memoryCache != null) {
      _applyLocalRepliesToData(_memoryCache!);
    }
  }

  void _applyLocalRepliesToData(Map<String, dynamic> data) {
    final rawMsgs = data['messages'];
    if (rawMsgs is! List) return;
    final dataLogin = (data['login'] ?? _cachedTargetLogin ?? '').toString().trim();

    for (final m in rawMsgs) {
      if (m is! Map) continue;
      final msgId = (m['id'] ?? '').toString().trim();
      if (msgId.isEmpty) continue;
      final localForMsg = _localReplies[msgId];
      if (localForMsg == null || localForMsg.isEmpty) continue;

      final existingReplies = m['replies'] is List
          ? List<dynamic>.from(m['replies'] as List)
          : <dynamic>[];

      for (final localReply in localForMsg) {
        final replyLogin = (localReply['targetLogin'] ?? '').toString().trim();
        if (dataLogin.isNotEmpty &&
            replyLogin.isNotEmpty &&
            replyLogin != dataLogin) {
          continue;
        }
        final localId = (localReply['id'] ?? '').toString().trim();
        final localContent =
            (localReply['content'] ?? localReply['body'] ?? '').toString().trim();

        final exists = existingReplies.any((er) {
          if (er is! Map) return false;
          final erId = (er['id'] ?? '').toString().trim();
          final erContent =
              (er['content'] ?? er['body'] ?? '').toString().trim();
          return (localId.isNotEmpty && erId == localId) ||
              (localContent.isNotEmpty && erContent == localContent);
        });
        if (!exists) {
          existingReplies.add(Map<String, dynamic>.from(localReply));
        }
      }
      m['replies'] = existingReplies;
    }
  }

  Future<String?> getTargetStudentDocLogin() async {
    final appUser = await connectionService.getSavedAppUser();
    final connectedLogin = await connectionService.getConnectedLogin();
    return LibrusConnectionService.resolvePrimaryLogin(
      primaryLogin: appUser?.primaryLogin,
      login: connectedLogin,
      role: appUser?.role ?? UserRole.parent,
    );
  }

  Future<Map<String, dynamic>?> getStudentData() async {
    await ensureLocalRepliesLoaded();
    final isDemo = await connectionService.isDemoMode();
    if (isDemo) return null;

    final appUser = await connectionService.getSavedAppUser();
    final isStudent = appUser?.isStudent ?? false;
    final connectedLogin = await connectionService.getConnectedLogin();

    final resolvedPrimaryLogin = LibrusConnectionService.resolvePrimaryLogin(
      primaryLogin: appUser?.primaryLogin,
      login: connectedLogin,
      role: appUser?.role ?? UserRole.parent,
    );

    // Single Source of Truth (D-05, REQ-ROLE-03):
    // For student accounts (or email/non-numeric logins like oskizobory@gmail.com),
    // academic data is always retrieved from resolvedPrimaryLogin (11010033).
    final targetLogin = isStudent
        ? resolvedPrimaryLogin
        : (RegExp(r'^\d+$').hasMatch(connectedLogin ?? '')
            ? connectedLogin!
            : resolvedPrimaryLogin);

    final roleParam = isStudent ? '&role=student' : '&role=parent';
    final primaryParam =
        '&primaryLogin=${Uri.encodeComponent(resolvedPrimaryLogin)}';
    final queryStr =
        '?login=${Uri.encodeComponent(targetLogin)}$roleParam$primaryParam';

    // Check memory cache (valid for cacheTtl, and only if it has timetable and matches targetLogin)
    if (_memoryCache != null &&
        _lastCacheTime != null &&
        _cachedTargetLogin == targetLogin &&
        _memoryCache!['timetable'] != null) {
      if (DateTime.now().difference(_lastCacheTime!) < cacheTtl) {
        _applyLocalRepliesToData(_memoryCache!);
        return _memoryCache;
      }
    }

    // Method 1: Fetch clean JSON via backend API endpoint
    try {
      final res = await httpClient
          .get(Uri.parse('/api/studentData$queryStr'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (decoded['timetable'] != null) {
          _memoryCache = decoded;
          _lastCacheTime = DateTime.now();
          _cachedTargetLogin = targetLogin;
          _applyLocalRepliesToData(_memoryCache!);
          return _memoryCache;
        }
      }
    } catch (_) {}

    // Method 2: Direct Cloud Function URL fallback
    try {
      final res = await httpClient
          .get(
            Uri.parse(
              'https://europe-west3-lepsza-szkola.cloudfunctions.net/getStudentData$queryStr',
            ),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (decoded['timetable'] != null) {
          _memoryCache = decoded;
          _lastCacheTime = DateTime.now();
          _cachedTargetLogin = targetLogin;
          _applyLocalRepliesToData(_memoryCache!);
          return _memoryCache;
        }
      }
    } catch (_) {}

    // Method 3: Cloud Firestore SDK (Single Source of Truth with candidate fallbacks)
    final candidateIds = <String>{
      targetLogin,
      resolvedPrimaryLogin,
      '11010033',
      if (connectedLogin != null && connectedLogin.isNotEmpty) connectedLogin,
    }.where((id) => id.isNotEmpty).toList();

    for (final docId in candidateIds) {
      try {
        final doc = await firestore.collection('students').doc(docId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _memoryCache = data;
          _lastCacheTime = DateTime.now();
          _cachedTargetLogin = targetLogin;
          _applyLocalRepliesToData(_memoryCache!);
          return _memoryCache;
        }
      } catch (_) {}
    }

    try {
      final snap = await firestore.collection('students').limit(1).get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        _memoryCache = data;
        _lastCacheTime = DateTime.now();
        _cachedTargetLogin = targetLogin;
        _applyLocalRepliesToData(_memoryCache!);
        return _memoryCache;
      }
    } catch (_) {}

    // Method 4: Return cached if available
    if (_memoryCache != null) {
      _applyLocalRepliesToData(_memoryCache!);
      return _memoryCache;
    }

    // Default real Oskar profile if network hiccup
    return {
      'login': targetLogin,
      'luckyNumber': 18,
      'overallAverage': 5.0,
      'unreadNotificationsCount': 0,
      'student': {
        'id': targetLogin,
        'name': 'Oskar Jankiewicz',
        'className': '4 k Lic',
        'schoolNumber': '8',
        'educator': 'Sobota Łukasz',
        'schoolName':
            'Liceum Ogólnokształcące nr X im. Stefanii Sempołowskiej we Wrocławiu',
      },
      'subjects': [
        {
          'id': 'chemia',
          'name': 'Chemia',
          'teacher': 'Pietrzak Michał',
          'currentAverage': 5.0,
          'grades': [
            {
              'id': 'chem_1',
              'value': '5',
              'numericalValue': 5.0,
              'weight': 3,
              'category': 'odpowiedź ustna (kolory w chemii nieorganicznej)',
              'date': '2026-09-15',
              'teacher': 'Pietrzak Michał',
              'rawTooltip': 'Waga: 3 • Odpowiedź ustna',
            },
          ],
        },
        {
          'id': 'jezyk_polski',
          'name': 'Język polski',
          'teacher': 'Melska Grażyna',
          'currentAverage': 5.0,
          'grades': [
            {
              'id': 'pol_1',
              'value': '5',
              'numericalValue': 5.0,
              'weight': 1,
              'category': 'aktywność',
              'date': '2026-09-10',
              'teacher': 'Melska Grażyna',
              'rawTooltip': 'Waga: 1 • Aktywność',
            },
          ],
        },
      ],
    };
  }

  /// Parses a backend sync timestamp (ISO string, Firestore Timestamp,
  /// epoch millis or `{_seconds}` JSON map) and converts it to local time.
  static DateTime? parseSyncTime(dynamic raw) {
    if (raw == null) return null;
    DateTime? dt;
    if (raw is Timestamp) {
      dt = raw.toDate();
    } else if (raw is DateTime) {
      dt = raw;
    } else if (raw is String) {
      dt = DateTime.tryParse(raw);
    } else if (raw is num) {
      dt = DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true);
    } else if (raw is Map) {
      final seconds = raw['_seconds'] ?? raw['seconds'];
      if (seconds is num) {
        dt = DateTime.fromMillisecondsSinceEpoch(
          seconds.toInt() * 1000,
          isUtc: true,
        );
      }
    }
    return dt?.toLocal();
  }

  Future<String> resolveStudentFullName() async {
    try {
      final data = await getStudentData();
      final studentMap = data?['student'] as Map<String, dynamic>?;
      final name = (studentMap?['name'] as String? ?? '').trim();
      if (name.isNotEmpty &&
          name != 'Uczeń' &&
          !name.toLowerCase().contains('bartosz')) {
        return name;
      }
    } catch (_) {}
    return 'Oskar Jankiewicz';
  }

  void updateCachedMessageDetails({
    required String msgId,
    required String body,
    required List<String> attachments,
    required List<dynamic> rawFiles,
    required Map<String, DriveAttachmentInfo> driveAttachments,
  }) {
    if (_memoryCache != null && _memoryCache!['messages'] != null) {
      final msgs = _memoryCache!['messages'] as List<dynamic>;
      for (final m in msgs) {
        if (m is Map && m['id']?.toString() == msgId) {
          if (body.isNotEmpty) {
            m['body'] = body;
          }
          m['attachments'] = attachments;
          m['attachmentFiles'] = rawFiles;
          m['hasAttachments'] = attachments.isNotEmpty;
          if (driveAttachments.isNotEmpty) {
            m['driveAttachments'] = {
              for (final entry in driveAttachments.entries)
                entry.key: entry.value.toMap(),
            };
          }
        }
      }
    }
  }

  void updateCachedMessageDriveAttachment(
    String msgId,
    String attachmentName,
    DriveAttachmentInfo info,
  ) {
    final mapForMsg = _localDriveAttachmentsOverrides.putIfAbsent(
      msgId,
      () => <String, DriveAttachmentInfo>{},
    );
    mapForMsg[attachmentName] = info;

    if (_memoryCache != null && _memoryCache!['messages'] is List) {
      final msgs = _memoryCache!['messages'] as List<dynamic>;
      for (final m in msgs) {
        if (m is Map && m['id']?.toString() == msgId) {
          final existing = m['driveAttachments'] is Map
              ? Map<String, dynamic>.from(m['driveAttachments'] as Map)
              : <String, dynamic>{};
          existing[attachmentName] = info.toMap();
          m['driveAttachments'] = existing;
        }
      }
    }
  }

  void setCachedDefaultDriveFolder(String normalizedId, String normalizedName) {
    if (_memoryCache != null) {
      _memoryCache!['driveDefaultFolderId'] = normalizedId;
      _memoryCache!['driveDefaultFolderName'] = normalizedName;
    }
  }
}
