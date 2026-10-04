import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/models/message_thread.dart';
import '../mock_school_repository.dart';
import 'school_data_cache_manager.dart';

class FirestoreMessagesDataSource {
  final SchoolDataCacheManager cacheManager;
  final MockSchoolRepository mockFallback;
  final http.Client? _httpClientOverride;

  FirestoreMessagesDataSource({
    required this.cacheManager,
    MockSchoolRepository? mockFallback,
    http.Client? httpClient,
  })  : mockFallback = mockFallback ?? MockSchoolRepository(),
        _httpClientOverride = httpClient;

  http.Client get _httpClient => _httpClientOverride ?? cacheManager.httpClient;
  FirebaseFirestore get _firestore => cacheManager.firestore;

  Future<List<MessageThread>> getMessages() async {
    await cacheManager.ensureReadOverridesLoaded();
    await cacheManager.ensureArchiveOverridesLoaded();
    final data = await cacheManager.getStudentData();
    if (data == null || data['messages'] == null) {
      final mockList = await mockFallback.getMessages();
      return mockList.map((m) {
        final readOverride = cacheManager.getReadOverride(m.id);
        final archiveOverride = cacheManager.getArchiveOverride(m.id);
        final isAutoArch = m.isAutoArchived ||
            MessageThread.isSystemJustificationConfirmation(
              sender: '${m.senderName} ${m.senderRole}',
              subject: m.subject,
              body: m.body,
            );
        final effectiveArchived = archiveOverride ?? (m.isArchived || isAutoArch);
        final effectiveUnread = readOverride != null
            ? !readOverride
            : (isAutoArch && effectiveArchived ? false : m.isUnread);
        return m.copyWith(
          isUnread: effectiveUnread,
          isArchived: effectiveArchived,
          isAutoArchived: isAutoArch,
        );
      }).toList();
    }

    final rawList = data['messages'] as List<dynamic>? ?? [];
    if (rawList.isEmpty) return [];

    final remoteArchiveMap = data['archivedMessageOverrides'];

    return rawList.map((item) {
      final senderRaw = (item['sender'] as String? ?? 'Nauczyciel').trim();
      final subject = item['subject'] as String? ?? 'Wiadomość';
      final bodyText =
          item['body'] as String? ?? item['preview'] as String? ?? subject;

      final bracketMatch = RegExp(r'\[(.*?)\]').firstMatch(senderRaw);
      final bracketRole = bracketMatch?.group(1)?.trim() ?? '';

      String role = 'Nauczyciel';
      final lowerSender = senderRaw.toLowerCase();
      if (lowerSender.contains('dyrektor')) {
        role = 'Dyrektor Szkoły';
      } else if (lowerSender.contains('wychowawc')) {
        role = 'Wychowawca';
      } else if (lowerSender.contains('administrator')) {
        role = 'Administrator szkoły';
      } else if (lowerSender.contains('sekretariat')) {
        role = 'Sekretariat';
      } else if (lowerSender.contains('pedagog')) {
        role = 'Pedagog szkolny';
      } else if (lowerSender.contains('psycholog')) {
        role = 'Psycholog szkolny';
      } else if (lowerSender.contains('usprawiedliwieni')) {
        role = 'System Librus';
      } else if (bracketRole.isNotEmpty) {
        role = bracketRole;
      }

      // Clean sender name without losing bracket-only senders like "[Administrator szkoły]"
      String cleanName = senderRaw.replaceAll(RegExp(r'\[.*?\]'), '').trim();
      if (cleanName.isEmpty) {
        // Check if the message body has a signature (e.g. "Pozdrawiam\nKamila Buczek - szkolna Rada Rodziców")
        final sigMatch = RegExp(
          r'(?:Pozdrawiam|Z\s+poważaniem)[,:\s]*\r?\n+\s*([^\r\n\-]{3,70}(?:-[^\r\n]{2,50})?)',
          caseSensitive: false,
        ).firstMatch(bodyText);
        final signedBy = sigMatch?.group(1)?.trim() ?? '';
        final baseSender = bracketRole.isNotEmpty
            ? bracketRole
            : (senderRaw.isNotEmpty ? senderRaw : role);
        if (signedBy.isNotEmpty &&
            !signedBy.toLowerCase().contains('kopia powyższej')) {
          cleanName = '$signedBy ($baseSender)';
        } else {
          cleanName = baseSender;
        }
      }

      final words = cleanName
          .replaceAll(RegExp(r'[()\[\]]'), '')
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      String initials = 'L';
      if (words.length >= 2) {
        initials = '${words[0][0]}${words[1][0]}'.toUpperCase();
      } else if (words.isNotEmpty && words[0].isNotEmpty) {
        initials = words[0][0].toUpperCase();
      }

      final isImportant = subject.toUpperCase().contains('PILNE') ||
          subject.toUpperCase().contains('WAŻNE');

      final dt = parseMessageDate(item['date'] ?? item['timestamp']);

      final id = item['id']?.toString() ?? cacheManager.generateUniqueId();
      final localOverride = cacheManager.getReadOverride(id);
      final isAutoArchived = item['isAutoArchived'] == true ||
          MessageThread.isSystemJustificationConfirmation(
            sender: '$senderRaw $role',
            subject: subject,
            body: bodyText,
          );
      bool? remoteArchiveOverride;
      if (remoteArchiveMap is Map && remoteArchiveMap[id] is bool) {
        remoteArchiveOverride = remoteArchiveMap[id] as bool;
      } else if (item['isArchived'] is bool) {
        remoteArchiveOverride = item['isArchived'] as bool;
      }
      final archiveOverride =
          cacheManager.getArchiveOverride(id) ?? remoteArchiveOverride;
      final bool isArchived = archiveOverride ?? isAutoArchived;

      final now = DateTime.now();
      final isToday =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;

      bool isUnread;
      if (localOverride != null) {
        // User explicit action inside EduSync (read / unread toggle) has highest authority
        isUnread = !localOverride;
      } else if (isAutoArchived && isArchived) {
        // D-03: Auto-archived justification confirmations are automatically marked as read
        isUnread = false;
      } else {
        final backendIsRead = item['isRead'] == true && item['unread'] != true;
        if (!backendIsRead) {
          isUnread = true;
        } else if (isToday) {
          // If a message was received today and user hasn't opened it in EduSync yet,
          // highlight it as unread so user sees the indicator/badge
          isUnread = true;
        } else {
          isUnread = false;
        }
      }

      final attachments = <String>[];
      final attachmentUrls = <String, String>{};

      final rawAttachmentFiles =
          item['attachmentFiles'] as List<dynamic>? ?? const [];
      for (final f in rawAttachmentFiles) {
        if (f is Map) {
          final name = (f['name'] ?? '').toString().trim();
          final path = (f['path'] ?? '').toString().trim();
          if (name.isNotEmpty) {
            if (!attachments.contains(name)) {
              attachments.add(name);
            }
            if (path.isNotEmpty) {
              attachmentUrls[name] = path;
            }
          }
        }
      }

      final rawAttachments = item['attachments'] as List<dynamic>? ?? const [];
      for (final a in rawAttachments) {
        if (a is String && a.trim().isNotEmpty) {
          final name = a.trim();
          if (!attachments.contains(name)) {
            attachments.add(name);
          }
        } else if (a is Map) {
          final name = (a['name'] ?? '').toString().trim();
          final path = (a['path'] ?? '').toString().trim();
          if (name.isNotEmpty) {
            if (!attachments.contains(name)) {
              attachments.add(name);
            }
            if (path.isNotEmpty) {
              attachmentUrls[name] = path;
            }
          }
        }
      }

      final hasAttachments =
          item['hasAttachments'] == true || attachments.isNotEmpty;
      final driveAttachments =
          cacheManager.parseDriveAttachments(item['driveAttachments'], id);

      return MessageThread(
        id: id,
        senderName: cleanName,
        senderInitials: initials,
        senderRole: role,
        subject: subject,
        preview: item['preview'] as String? ?? subject,
        body: bodyText,
        timestamp: dt,
        isUnread: isUnread,
        isImportant: isImportant,
        isArchived: isArchived,
        isAutoArchived: isAutoArchived,
        attachments: attachments,
        attachmentUrls: attachmentUrls,
        hasAttachments: hasAttachments,
        driveAttachments: driveAttachments,
      );
    }).toList();
  }

  /// Resiliently parses a message or announcement date from Librus / Firestore
  /// (`YYYY-MM-DD HH:MM:SS`, `YYYY-MM-DD`, `DD.MM.YYYY HH:MM`, multiline strings,
  /// Firestore `Timestamp`, `{_seconds}` maps, or epoch milliseconds).
  static DateTime parseMessageDate(dynamic raw, {DateTime? fallback}) {
    if (raw == null) return fallback ?? DateTime.now();
    if (raw is Timestamp) {
      return raw.toDate().toLocal();
    }
    if (raw is DateTime) {
      return raw.toLocal();
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true)
          .toLocal();
    }
    if (raw is Map) {
      final seconds = raw['_seconds'] ?? raw['seconds'];
      if (seconds is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds.toInt() * 1000,
          isUtc: true,
        ).toLocal();
      }
    }
    try {
      // Handle arbitrary Timestamp-like objects with .toDate()
      final dynamic maybeDate = (raw as dynamic).toDate();
      if (maybeDate is DateTime) {
        return maybeDate.toLocal();
      }
    } catch (_) {}

    if (raw is String) {
      final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (cleaned.isEmpty) return fallback ?? DateTime.now();

      final parsed = DateTime.tryParse(cleaned);
      if (parsed != null) {
        return parsed.isUtc ? parsed.toLocal() : parsed;
      }

      final dmyMatch = RegExp(
        r'^(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
      ).firstMatch(cleaned);
      if (dmyMatch != null) {
        final day = int.parse(dmyMatch.group(1)!);
        final month = int.parse(dmyMatch.group(2)!);
        final year = int.parse(dmyMatch.group(3)!);
        final hour =
            dmyMatch.group(4) != null ? int.parse(dmyMatch.group(4)!) : 0;
        final minute =
            dmyMatch.group(5) != null ? int.parse(dmyMatch.group(5)!) : 0;
        final second =
            dmyMatch.group(6) != null ? int.parse(dmyMatch.group(6)!) : 0;
        return DateTime(year, month, day, hour, minute, second);
      }

      final isoEmbedded = RegExp(
        r'(\d{4}-\d{2}-\d{2}(?:[T\s]\d{2}:\d{2}(?::\d{2})?)?)',
      ).firstMatch(cleaned);
      if (isoEmbedded != null) {
        final embeddedParsed = DateTime.tryParse(isoEmbedded.group(1)!);
        if (embeddedParsed != null) {
          return embeddedParsed.isUtc
              ? embeddedParsed.toLocal()
              : embeddedParsed;
        }
      }
    }

    return fallback ?? DateTime.now();
  }

  Future<void> sendMessage({
    required List<String> recipientNames,
    required String subject,
    required String body,
    String? replyToId,
  }) async {
    final connectedLogin =
        await cacheManager.connectionService.getConnectedLogin();
    try {
      await _httpClient
          .post(
            Uri.parse('/api/sendMessage'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'login': connectedLogin ?? '',
              'recipients': recipientNames,
              'subject': subject,
              'body': body,
              'replyToId': replyToId,
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    await mockFallback.sendMessage(
      recipientNames: recipientNames,
      subject: subject,
      body: body,
      replyToId: replyToId,
    );
  }

  Future<String?> getMessageBody(String msgId, {String? url}) async {
    final details = await getMessageDetails(msgId, url: url);
    return details?.body;
  }

  Future<MessageDetailsResult?> getMessageDetails(
    String msgId, {
    String? url,
  }) async {
    final isDemo = await cacheManager.connectionService.isDemoMode();
    if (isDemo) return mockFallback.getMessageDetails(msgId, url: url);

    final connectedLogin =
        await cacheManager.connectionService.getConnectedLogin();
    final query = (connectedLogin != null && connectedLogin.isNotEmpty)
        ? '&login=$connectedLogin'
        : '';
    final urlParam = (url != null && url.isNotEmpty)
        ? '&url=${Uri.encodeComponent(url)}'
        : '';

    try {
      final res = await _httpClient
          .get(Uri.parse('/api/messageDetails?msgId=$msgId$query$urlParam'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data =
            json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final body = (data['body'] as String? ?? '').trim();
        final attachments = <String>[];
        final attachmentUrls = <String, String>{};

        final rawFiles = data['attachmentFiles'] as List<dynamic>? ?? const [];
        for (final f in rawFiles) {
          if (f is Map) {
            final name = (f['name'] ?? '').toString().trim();
            final path = (f['path'] ?? '').toString().trim();
            if (name.isNotEmpty) {
              if (!attachments.contains(name)) attachments.add(name);
              if (path.isNotEmpty) attachmentUrls[name] = path;
            }
          }
        }

        final rawAtt = data['attachments'] as List<dynamic>? ?? const [];
        for (final a in rawAtt) {
          if (a is String &&
              a.trim().isNotEmpty &&
              !attachments.contains(a.trim())) {
            attachments.add(a.trim());
          }
        }

        final driveAttachments =
            cacheManager.parseDriveAttachments(data['driveAttachments'], msgId);

        // Update in-memory cache so navigating back & forth retains attachments
        cacheManager.updateCachedMessageDetails(
          msgId: msgId,
          body: body,
          attachments: attachments,
          rawFiles: rawFiles,
          driveAttachments: driveAttachments,
        );

        return MessageDetailsResult(
          body: body,
          attachments: attachments,
          attachmentUrls: attachmentUrls,
          hasAttachments:
              attachments.isNotEmpty || data['hasAttachments'] == true,
          driveAttachments: driveAttachments,
        );
      }
    } catch (_) {}

    return null;
  }

  Future<void> markMessageAsRead(String msgId, {bool isRead = true}) async {
    await cacheManager.setReadOverride(msgId, isRead);
    await mockFallback.markMessageAsRead(msgId, isRead: isRead);

    // Persist to Firestore document asynchronously
    try {
      final targetLogin = await cacheManager.getTargetStudentDocLogin();
      if (targetLogin != null && targetLogin.isNotEmpty) {
        final docRef = _firestore.collection('students').doc(targetLogin);
        final doc = await docRef.get();
        if (doc.exists) {
          final msgs = List<dynamic>.from(doc.data()?['messages'] ?? []);
          var changed = false;
          for (final m in msgs) {
            if (m is Map && (m['id'] == msgId || m['id'].toString() == msgId)) {
              m['isRead'] = isRead;
              changed = true;
            }
          }
          if (changed) {
            await docRef.update({'messages': msgs});
          }
        }
      }
    } catch (_) {}
  }

  Future<void> markAllMessagesAsRead() async {
    final msgs = await getMessages();
    await cacheManager.setAllReadOverrides(msgs.map((m) => m.id));
    await mockFallback.markAllMessagesAsRead();

    try {
      final targetLogin = await cacheManager.getTargetStudentDocLogin();
      if (targetLogin != null && targetLogin.isNotEmpty) {
        final docRef = _firestore.collection('students').doc(targetLogin);
        final doc = await docRef.get();
        if (doc.exists) {
          final rawMsgs = List<dynamic>.from(doc.data()?['messages'] ?? []);
          for (final m in rawMsgs) {
            if (m is Map) m['isRead'] = true;
          }
          await docRef.update({'messages': rawMsgs});
        }
      }
    } catch (_) {}
  }

  Future<void> archiveMessage(String msgId, {bool isArchived = true}) async {
    await cacheManager.setArchiveOverride(msgId, isArchived);
    await mockFallback.archiveMessage(msgId, isArchived: isArchived);

    try {
      final targetLogin = await cacheManager.getTargetStudentDocLogin();
      if (targetLogin != null && targetLogin.isNotEmpty) {
        final docRef = _firestore.collection('students').doc(targetLogin);
        final doc = await docRef.get();
        if (doc.exists) {
          final docData = doc.data() ?? {};
          final rawMsgs = List<dynamic>.from(docData['messages'] ?? []);
          for (final m in rawMsgs) {
            if (m is Map && (m['id'] == msgId || m['id']?.toString() == msgId)) {
              m['isArchived'] = isArchived;
            }
          }
          final overrides = Map<String, dynamic>.from(
            (docData['archivedMessageOverrides'] as Map?) ?? const {},
          );
          overrides[msgId] = isArchived;
          await docRef.update({
            'messages': rawMsgs,
            'archivedMessageOverrides': overrides,
          });
        }
      }
    } catch (_) {}
  }

  Future<DriveFolderOption> getDefaultDriveFolder() async {
    final isDemo = await cacheManager.connectionService.isDemoMode();
    if (isDemo) {
      return mockFallback.getDefaultDriveFolder();
    }

    String? localId;
    String? localName;
    try {
      final prefs = await SharedPreferences.getInstance();
      localId = prefs
          .getString(SchoolDataCacheManager.prefDefaultDriveFolderId)
          ?.trim();
      localName = prefs
          .getString(SchoolDataCacheManager.prefDefaultDriveFolderName)
          ?.trim();
    } catch (_) {}

    final mem = cacheManager.memoryCache;
    if (mem != null) {
      final cachedId = (mem['driveDefaultFolderId'] ?? '').toString().trim();
      final cachedName =
          (mem['driveDefaultFolderName'] ?? '').toString().trim();
      if (cachedId.isNotEmpty) {
        return DriveFolderOption(
          id: cachedId,
          name: cachedName.isNotEmpty
              ? cachedName
              : (cachedId == 'root' ? 'Mój dysk' : 'Folder Google Drive'),
        );
      }
    }

    try {
      final targetLogin = await cacheManager.getTargetStudentDocLogin();
      if (targetLogin != null && targetLogin.isNotEmpty) {
        final doc =
            await _firestore.collection('students').doc(targetLogin).get();
        if (doc.exists && doc.data() != null) {
          final d = doc.data()!;
          final fsId = (d['driveDefaultFolderId'] ?? '').toString().trim();
          final fsName = (d['driveDefaultFolderName'] ?? '').toString().trim();
          if (fsId.isNotEmpty) {
            final resolvedName = fsName.isNotEmpty
                ? fsName
                : (fsId == 'root' ? 'Mój dysk' : 'Folder Google Drive');
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                SchoolDataCacheManager.prefDefaultDriveFolderId,
                fsId,
              );
              await prefs.setString(
                SchoolDataCacheManager.prefDefaultDriveFolderName,
                resolvedName,
              );
            } catch (_) {}
            return DriveFolderOption(id: fsId, name: resolvedName);
          }
        }
      }
    } catch (_) {}

    if (localId != null && localId.isNotEmpty) {
      return DriveFolderOption(
        id: localId,
        name: (localName != null && localName.isNotEmpty)
            ? localName
            : (localId == 'root' ? 'Mój dysk' : 'Folder Google Drive'),
      );
    }

    return DriveFolderOption.rootFolder;
  }

  Future<void> setDefaultDriveFolder(DriveFolderOption folder) async {
    final normalizedId = folder.id.trim().isEmpty ? 'root' : folder.id.trim();
    final normalizedName = folder.name.trim().isEmpty
        ? (normalizedId == 'root' ? 'Mój dysk' : 'Folder Google Drive')
        : folder.name.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        SchoolDataCacheManager.prefDefaultDriveFolderId,
        normalizedId,
      );
      await prefs.setString(
        SchoolDataCacheManager.prefDefaultDriveFolderName,
        normalizedName,
      );
    } catch (_) {}

    cacheManager.setCachedDefaultDriveFolder(normalizedId, normalizedName);

    final isDemo = await cacheManager.connectionService.isDemoMode();
    if (isDemo) {
      await mockFallback.setDefaultDriveFolder(
        DriveFolderOption(
          id: normalizedId,
          name: normalizedName,
          webViewLink: folder.webViewLink,
        ),
      );
      return;
    }

    try {
      final targetLogin = await cacheManager.getTargetStudentDocLogin();
      if (targetLogin != null && targetLogin.isNotEmpty) {
        await _firestore.collection('students').doc(targetLogin).set({
          'driveDefaultFolderId': normalizedId,
          'driveDefaultFolderName': normalizedName,
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<DriveAttachmentInfo> saveAttachmentToDrive({
    required String msgId,
    required String attachmentName,
    required String downloadPath,
    required String accessToken,
    String? folderId,
    String? folderName,
    String? savedBy,
  }) async {
    final isDemo = await cacheManager.connectionService.isDemoMode();
    if (isDemo) {
      return mockFallback.saveAttachmentToDrive(
        msgId: msgId,
        attachmentName: attachmentName,
        downloadPath: downloadPath,
        accessToken: accessToken,
        folderId: folderId,
        folderName: folderName,
        savedBy: savedBy,
      );
    }

    final defaultFolder = await getDefaultDriveFolder();
    final effectiveFolderId = (folderId != null && folderId.trim().isNotEmpty)
        ? folderId.trim()
        : defaultFolder.id;
    final effectiveFolderName =
        (folderName != null && folderName.trim().isNotEmpty)
            ? folderName.trim()
            : defaultFolder.name;

    final targetLogin =
        await cacheManager.getTargetStudentDocLogin() ?? '11010033';
    final appUser = await cacheManager.connectionService.getSavedAppUser();
    final effectiveSavedBy = savedBy ??
        appUser?.displayName ??
        ((appUser?.isStudent ?? false) ? 'Uczeń' : 'Rodzic');

    final payload = jsonEncode({
      'studentId': targetLogin,
      'login': targetLogin,
      'msgId': msgId,
      'attachmentName': attachmentName,
      'downloadPath': downloadPath,
      'accessToken': accessToken,
      'folderId': effectiveFolderId,
      'folderName': effectiveFolderName,
      'savedBy': effectiveSavedBy,
    });

    http.Response res;
    try {
      res = await _httpClient
          .post(
            Uri.parse('/api/saveAttachmentToDrive'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      res = await _httpClient
          .post(
            Uri.parse(
              'https://europe-west3-lepsza-szkola.cloudfunctions.net/saveAttachmentToDrive',
            ),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 45));
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('UNAUTHENTICATED_DRIVE: Sesja Google Drive wygasła.');
    }

    final decoded =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200 || decoded['driveAttachment'] == null) {
      throw Exception(
        decoded['error']?.toString() ??
            'Nie udało się zapisać załącznika na Dysku Google.',
      );
    }

    final info = DriveAttachmentInfo.fromMap(
      Map<String, dynamic>.from(decoded['driveAttachment'] as Map),
    );
    cacheManager.updateCachedMessageDriveAttachment(
      msgId,
      attachmentName,
      info,
    );
    return info;
  }

  Future<List<DriveFolderOption>> listDriveFolders({
    required String accessToken,
  }) async {
    final isDemo = await cacheManager.connectionService.isDemoMode();
    if (isDemo) {
      return mockFallback.listDriveFolders(accessToken: accessToken);
    }

    final payload = jsonEncode({
      'action': 'list',
      'accessToken': accessToken,
    });

    http.Response res;
    try {
      res = await _httpClient
          .post(
            Uri.parse('/api/driveFolder?action=list'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      res = await _httpClient
          .post(
            Uri.parse(
              'https://europe-west3-lepsza-szkola.cloudfunctions.net/manageDriveFolders?action=list',
            ),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 20));
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('UNAUTHENTICATED_DRIVE: Sesja Google Drive wygasła.');
    }

    if (res.statusCode != 200) {
      return const <DriveFolderOption>[];
    }

    final decoded =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final rawList = decoded['folders'] as List<dynamic>? ?? const [];
    return rawList
        .whereType<Map>()
        .map((f) => DriveFolderOption.fromMap(Map<String, dynamic>.from(f)))
        .where((f) => f.id.isNotEmpty && f.id != 'root')
        .toList();
  }

  Future<DriveFolderOption> createDriveFolder({
    required String accessToken,
    required String folderName,
    bool setAsDefault = false,
  }) async {
    final isDemo = await cacheManager.connectionService.isDemoMode();
    if (isDemo) {
      return mockFallback.createDriveFolder(
        accessToken: accessToken,
        folderName: folderName,
        setAsDefault: setAsDefault,
      );
    }

    final targetLogin =
        await cacheManager.getTargetStudentDocLogin() ?? '11010033';
    final payload = jsonEncode({
      'action': 'create',
      'accessToken': accessToken,
      'folderName': folderName.trim(),
      'studentId': targetLogin,
      'setAsDefault': setAsDefault,
    });

    http.Response res;
    try {
      res = await _httpClient
          .post(
            Uri.parse('/api/driveFolder?action=create'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      res = await _httpClient
          .post(
            Uri.parse(
              'https://europe-west3-lepsza-szkola.cloudfunctions.net/manageDriveFolders?action=create',
            ),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 20));
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('UNAUTHENTICATED_DRIVE: Sesja Google Drive wygasła.');
    }

    final decoded =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200 || decoded['folder'] == null) {
      throw Exception(
        decoded['error']?.toString() ??
            'Nie udało się utworzyć folderu na Dysku Google.',
      );
    }

    final created = DriveFolderOption.fromMap(
      Map<String, dynamic>.from(decoded['folder'] as Map),
    );
    if (setAsDefault) {
      await setDefaultDriveFolder(created);
    }
    return created;
  }

  Future<void> moveDriveAttachment({
    required String accessToken,
    required String msgId,
    required List<String> attachmentNames,
    required Map<String, DriveAttachmentInfo> currentDriveAttachments,
    required String targetFolderId,
    required String targetFolderName,
    bool setAsDefault = true,
  }) async {
    final isDemo = await cacheManager.connectionService.isDemoMode();
    if (isDemo) {
      await mockFallback.moveDriveAttachment(
        accessToken: accessToken,
        msgId: msgId,
        attachmentNames: attachmentNames,
        currentDriveAttachments: currentDriveAttachments,
        targetFolderId: targetFolderId,
        targetFolderName: targetFolderName,
        setAsDefault: setAsDefault,
      );
      return;
    }

    final targetLogin =
        await cacheManager.getTargetStudentDocLogin() ?? '11010033';
    final items = <Map<String, dynamic>>[];
    for (final name in attachmentNames) {
      final info = currentDriveAttachments[name];
      if (info != null && info.driveFileId.isNotEmpty) {
        items.add({
          'attachmentName': name,
          'fileId': info.driveFileId,
          'previousFolderId': info.folderId,
        });
      }
    }

    final payload = jsonEncode({
      'action': 'move',
      'accessToken': accessToken,
      'studentId': targetLogin,
      'msgId': msgId,
      'items': items,
      'targetFolderId': targetFolderId,
      'targetFolderName': targetFolderName,
      'setAsDefault': setAsDefault,
    });

    http.Response res;
    try {
      res = await _httpClient
          .post(
            Uri.parse('/api/driveFolder?action=move'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      res = await _httpClient
          .post(
            Uri.parse(
              'https://europe-west3-lepsza-szkola.cloudfunctions.net/manageDriveFolders?action=move',
            ),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 25));
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('UNAUTHENTICATED_DRIVE: Sesja Google Drive wygasła.');
    }

    if (res.statusCode != 200) {
      final decoded =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      throw Exception(
        decoded['error']?.toString() ??
            'Nie udało się przenieść załącznika do wybranego folderu.',
      );
    }

    for (final name in attachmentNames) {
      final info = currentDriveAttachments[name];
      if (info != null) {
        final updated = info.copyWith(
          folderId: targetFolderId,
          folderName: targetFolderName,
        );
        cacheManager.updateCachedMessageDriveAttachment(msgId, name, updated);
      }
    }

    if (setAsDefault) {
      await setDefaultDriveFolder(
        DriveFolderOption(id: targetFolderId, name: targetFolderName),
      );
    }
  }
}
