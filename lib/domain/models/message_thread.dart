import 'package:intl/intl.dart';

class DriveAttachmentInfo {
  final String driveFileId;
  final String webViewLink;
  final String folderId;
  final String folderName;
  final DateTime savedAt;
  final String savedBy;

  const DriveAttachmentInfo({
    required this.driveFileId,
    required this.webViewLink,
    this.folderId = 'root',
    this.folderName = 'Mój dysk',
    required this.savedAt,
    this.savedBy = 'Rodzic',
  });

  factory DriveAttachmentInfo.fromMap(Map<String, dynamic> map) {
    final rawFolderId = (map['folderId'] ?? 'root').toString().trim();
    final rawFolderName = (map['folderName'] ?? 'Mój dysk').toString().trim();
    return DriveAttachmentInfo(
      driveFileId: (map['driveFileId'] ?? '').toString(),
      webViewLink: (map['webViewLink'] ?? '').toString(),
      folderId: rawFolderId.isEmpty ? 'root' : rawFolderId,
      folderName: rawFolderName.isEmpty ? 'Mój dysk' : rawFolderName,
      savedAt: DateTime.tryParse((map['savedAt'] ?? '').toString()) ?? DateTime.now(),
      savedBy: (map['savedBy'] ?? 'Rodzic').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'driveFileId': driveFileId,
        'webViewLink': webViewLink,
        'folderId': folderId,
        'folderName': folderName,
        'savedAt': savedAt.toIso8601String(),
        'savedBy': savedBy,
      };

  DriveAttachmentInfo copyWith({
    String? driveFileId,
    String? webViewLink,
    String? folderId,
    String? folderName,
    DateTime? savedAt,
    String? savedBy,
  }) {
    return DriveAttachmentInfo(
      driveFileId: driveFileId ?? this.driveFileId,
      webViewLink: webViewLink ?? this.webViewLink,
      folderId: folderId ?? this.folderId,
      folderName: folderName ?? this.folderName,
      savedAt: savedAt ?? this.savedAt,
      savedBy: savedBy ?? this.savedBy,
    );
  }
}

class DriveFolderOption {
  final String id;
  final String name;
  final String? webViewLink;

  const DriveFolderOption({
    required this.id,
    required this.name,
    this.webViewLink,
  });

  static const DriveFolderOption rootFolder = DriveFolderOption(
    id: 'root',
    name: 'Mój dysk',
  );

  factory DriveFolderOption.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? 'root').toString().trim();
    final name = (map['name'] ?? 'Mój dysk').toString().trim();
    return DriveFolderOption(
      id: id.isEmpty ? 'root' : id,
      name: name.isEmpty ? 'Mój dysk' : name,
      webViewLink: map['webViewLink']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        if (webViewLink != null) 'webViewLink': webViewLink,
      };
}

class MessageDetailsResult {
  final String body;
  final List<String> attachments;
  final Map<String, String> attachmentUrls;
  final bool hasAttachments;
  final Map<String, DriveAttachmentInfo> driveAttachments;

  const MessageDetailsResult({
    required this.body,
    this.attachments = const [],
    this.attachmentUrls = const {},
    this.hasAttachments = false,
    this.driveAttachments = const {},
  });
}

class MessageItem {
  final String id;
  final String senderName;
  final String senderRole;
  final String senderInitials;
  final DateTime timestamp;
  final String body;
  final bool isFromMe;
  final List<String> attachments;
  final Map<String, String> attachmentUrls;
  final bool hasAttachments;
  final Map<String, DriveAttachmentInfo> driveAttachments;

  const MessageItem({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.senderInitials,
    required this.timestamp,
    required this.body,
    this.isFromMe = false,
    this.attachments = const [],
    this.attachmentUrls = const {},
    this.hasAttachments = false,
    this.driveAttachments = const {},
  });

  MessageItem copyWith({
    String? id,
    String? senderName,
    String? senderRole,
    String? senderInitials,
    DateTime? timestamp,
    String? body,
    bool? isFromMe,
    List<String>? attachments,
    Map<String, String>? attachmentUrls,
    bool? hasAttachments,
    Map<String, DriveAttachmentInfo>? driveAttachments,
  }) {
    final nextAttachments = attachments ?? this.attachments;
    return MessageItem(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      senderInitials: senderInitials ?? this.senderInitials,
      timestamp: timestamp ?? this.timestamp,
      body: body ?? this.body,
      isFromMe: isFromMe ?? this.isFromMe,
      attachments: nextAttachments,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      hasAttachments: hasAttachments ?? (nextAttachments.isNotEmpty || this.hasAttachments),
      driveAttachments: driveAttachments ?? this.driveAttachments,
    );
  }
}

class MessageThread {
  final String id;
  final String senderName;
  final String senderInitials;
  final String senderRole; // "Wychowawca", "Dyrekcja", "Nauczyciel chemii"
  final String subject;
  final String preview;
  final String body;
  final DateTime timestamp;
  final bool isUnread;
  final bool isImportant;
  final bool isArchived;
  final bool isAutoArchived;
  final List<String> attachments;
  final Map<String, String> attachmentUrls;
  final bool hasAttachments;
  final Map<String, DriveAttachmentInfo> driveAttachments;
  final List<MessageItem> messages;

  MessageThread({
    required this.id,
    required this.senderName,
    required this.senderInitials,
    required this.senderRole,
    required this.subject,
    required this.preview,
    required this.body,
    required this.timestamp,
    this.isUnread = false,
    this.isImportant = false,
    this.isArchived = false,
    this.isAutoArchived = false,
    this.attachments = const [],
    this.attachmentUrls = const {},
    bool? hasAttachments,
    this.driveAttachments = const {},
    List<MessageItem>? messages,
  })  : hasAttachments = hasAttachments ?? attachments.isNotEmpty,
        messages = messages ??
            [
              MessageItem(
                id: '${id}_0',
                senderName: senderName,
                senderRole: senderRole,
                senderInitials: senderInitials,
                timestamp: timestamp,
                body: body,
                attachments: attachments,
                attachmentUrls: attachmentUrls,
                hasAttachments: hasAttachments ?? attachments.isNotEmpty,
                driveAttachments: driveAttachments,
                isFromMe: false,
              ),
            ];

  /// Detects Librus system justification confirmation messages (D-03, REQ-MSG-ARCH-02).
  static bool isSystemJustificationConfirmation({
    required String sender,
    required String subject,
    String body = '',
  }) {
    final s = sender.toLowerCase();
    final subj = subject.toLowerCase();
    final b = body.toLowerCase();

    final isSystemJustificationSender =
        s.contains('usprawiedliwieni') || s.contains('system librus');
    final hasAcceptancePhrase = subj.contains('zaakceptowano usprawiedliwienie') ||
        subj.contains('usprawiedliwienie zostało zaakceptowane') ||
        subj.contains('potwierdzenie usprawiedliwienia') ||
        subj.contains('usprawiedliwienie nieobecności') ||
        b.contains('zaakceptowano usprawiedliwienie') ||
        b.contains('usprawiedliwienie zostało zaakceptowane') ||
        b.contains('potwierdzenie usprawiedliwienia');

    if (s.contains('usprawiedliwieni')) return true;
    if (isSystemJustificationSender &&
        (hasAcceptancePhrase || subj.contains('usprawiedliwieni'))) {
      return true;
    }
    return hasAcceptancePhrase;
  }

  MessageThread copyWith({
    String? id,
    String? senderName,
    String? senderInitials,
    String? senderRole,
    String? subject,
    String? preview,
    String? body,
    DateTime? timestamp,
    bool? isUnread,
    bool? isImportant,
    bool? isArchived,
    bool? isAutoArchived,
    List<String>? attachments,
    Map<String, String>? attachmentUrls,
    bool? hasAttachments,
    Map<String, DriveAttachmentInfo>? driveAttachments,
    List<MessageItem>? messages,
  }) {
    final nextAttachments = attachments ?? this.attachments;
    final nextAttachmentUrls = attachmentUrls ?? this.attachmentUrls;
    final nextHasAttachments =
        hasAttachments ?? (nextAttachments.isNotEmpty || this.hasAttachments);
    final nextDriveAttachments = driveAttachments ?? this.driveAttachments;

    List<MessageItem> nextMessages;
    if (messages != null) {
      nextMessages = messages;
    } else if (this.messages.isNotEmpty) {
      nextMessages = [
        this.messages.first.copyWith(
          body: body ?? this.messages.first.body,
          attachments: attachments ?? this.messages.first.attachments,
          attachmentUrls: attachmentUrls ?? this.messages.first.attachmentUrls,
          hasAttachments: hasAttachments ?? this.messages.first.hasAttachments,
          driveAttachments: driveAttachments ?? this.messages.first.driveAttachments,
        ),
        ...this.messages.skip(1),
      ];
    } else {
      nextMessages = this.messages;
    }

    return MessageThread(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      senderInitials: senderInitials ?? this.senderInitials,
      senderRole: senderRole ?? this.senderRole,
      subject: subject ?? this.subject,
      preview: preview ?? this.preview,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isUnread: isUnread ?? this.isUnread,
      isImportant: isImportant ?? this.isImportant,
      isArchived: isArchived ?? this.isArchived,
      isAutoArchived: isAutoArchived ?? this.isAutoArchived,
      attachments: nextAttachments,
      attachmentUrls: nextAttachmentUrls,
      hasAttachments: nextHasAttachments,
      driveAttachments: nextDriveAttachments,
      messages: nextMessages,
    );
  }

  static String formatTimestamp(DateTime timestamp, {DateTime? now}) {
    final dt = timestamp.toLocal();
    final refNow = (now ?? DateTime.now()).toLocal();
    final today = DateTime(refNow.year, refNow.month, refNow.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final dayDiff = today.difference(msgDay).inDays;
    final hasTime = dt.hour != 0 || dt.minute != 0 || dt.second != 0;

    if (dayDiff == 0) {
      return hasTime
          ? 'Dzisiaj, ${DateFormat('HH:mm', 'pl_PL').format(dt)}'
          : 'Dzisiaj';
    }
    if (dayDiff == 1) {
      return hasTime
          ? 'Wczoraj, ${DateFormat('HH:mm', 'pl_PL').format(dt)}'
          : 'Wczoraj';
    }
    if (dt.year == refNow.year) {
      return hasTime
          ? DateFormat('d MMM, HH:mm', 'pl_PL').format(dt)
          : DateFormat('d MMM', 'pl_PL').format(dt);
    }
    return hasTime
        ? DateFormat('d MMM yyyy, HH:mm', 'pl_PL').format(dt)
        : DateFormat('d MMM yyyy', 'pl_PL').format(dt);
  }

  String get formattedTimestamp => formatTimestamp(timestamp);

  String resolveSenderName({String? overrideBody}) {
    final existing = senderName.trim();
    if (existing.isNotEmpty) return existing;

    final bodyText = overrideBody ??
        (body.trim().isNotEmpty
            ? body
            : (messages.isNotEmpty ? messages.first.body : preview));
    final sigMatch = RegExp(
      r'(?:Pozdrawiam|Z\s+poważaniem)[,:\s]*\r?\n+\s*([^\r\n\-]{3,70}(?:-[^\r\n]{2,50})?)',
      caseSensitive: false,
    ).firstMatch(bodyText);
    final signedBy = sigMatch?.group(1)?.trim() ?? '';
    final baseRole =
        senderRole.trim().isNotEmpty ? senderRole.trim() : 'Administrator szkoły';
    if (signedBy.isNotEmpty &&
        !signedBy.toLowerCase().contains('kopia powyższej')) {
      return '$signedBy ($baseRole)';
    }
    return baseRole;
  }

  String? extractCcTeacherFromBody([String? overrideBody]) {
    final bodyText = overrideBody ??
        (body.trim().isNotEmpty
            ? body
            : (messages.isNotEmpty ? messages.first.body : preview));
    final ccMatch = RegExp(
      r'Kopia powyższej wiadomości została wysłana do nauczyciela:\s*([^\r\n]+)',
      caseSensitive: false,
    ).firstMatch(bodyText);
    final ccName = ccMatch?.group(1)?.trim();
    if (ccName != null && ccName.isNotEmpty) return ccName;
    return null;
  }

  static bool looksLikeMessageWithAttachment(String text) {
    final lower = text.toLowerCase();
    return lower.contains('załącz') ||
        lower.contains('prezentacj') ||
        lower.contains('przesyłam') ||
        lower.contains('plik') ||
        lower.contains('formularz') ||
        lower.contains('regulamin') ||
        lower.contains('dokument');
  }

  bool get needsDetailsFetch {
    final firstMsg = messages.firstOrNull;
    final isBodyMissingOrSameAsSubject = firstMsg == null ||
        firstMsg.body.trim().isEmpty ||
        firstMsg.body.trim() == subject.trim();
    final needsAttachmentDetails = (hasAttachments &&
            (attachments.isEmpty || attachmentUrls.isEmpty)) ||
        (attachments.isEmpty &&
            looksLikeMessageWithAttachment(firstMsg?.body ?? body));
    return isBodyMissingOrSameAsSubject || needsAttachmentDetails;
  }

  List<String> unsavedAttachmentsFor(MessageItem message) {
    final effectiveDrive = {...driveAttachments, ...message.driveAttachments};
    return message.attachments
        .where((f) => !effectiveDrive.containsKey(f))
        .toList();
  }

  MessageThread withNormalizedSenderName() {
    final resolvedSender = resolveSenderName();
    if (senderName.trim().isNotEmpty) return this;
    final fixedMessages = messages.map((m) {
      if (!m.isFromMe && m.senderName.trim().isEmpty) {
        return m.copyWith(senderName: resolvedSender);
      }
      return m;
    }).toList();
    return copyWith(senderName: resolvedSender, messages: fixedMessages);
  }

  MessageThread withMergedDetails(MessageDetailsResult details) {
    final firstMsg = messages.firstOrNull;
    final fullBody = details.body.trim().isNotEmpty
        ? details.body
        : (firstMsg?.body ?? body);
    final mergedAttachments =
        details.attachments.isNotEmpty ? details.attachments : attachments;
    final mergedUrls =
        details.attachmentUrls.isNotEmpty ? details.attachmentUrls : attachmentUrls;
    final mergedHasAttachments =
        details.hasAttachments || mergedAttachments.isNotEmpty || hasAttachments;
    final mergedDriveAttachments = {
      ...driveAttachments,
      ...details.driveAttachments,
    };
    final resolvedSender = resolveSenderName(overrideBody: fullBody);
    final updatedMessages = messages.map((m) {
      if (m == messages.first) {
        return m.copyWith(
          senderName: m.senderName.trim().isNotEmpty ? m.senderName : resolvedSender,
          body: fullBody,
          attachments: mergedAttachments,
          attachmentUrls: mergedUrls,
          hasAttachments: mergedHasAttachments,
          driveAttachments: {...m.driveAttachments, ...mergedDriveAttachments},
        );
      }
      return m;
    }).toList();

    return copyWith(
      senderName: resolvedSender,
      body: fullBody,
      preview: fullBody.length > 90 ? '${fullBody.substring(0, 90)}...' : fullBody,
      attachments: mergedAttachments,
      attachmentUrls: mergedUrls,
      hasAttachments: mergedHasAttachments,
      driveAttachments: mergedDriveAttachments,
      messages: updatedMessages,
    );
  }

  MessageThread withSavedDriveAttachments(
    String messageId,
    Map<String, DriveAttachmentInfo> newEntries,
  ) {
    final mergedThreadDrive = {...driveAttachments, ...newEntries};
    final updatedMessages = messages.map((m) {
      if (m.id == messageId || m == messages.first) {
        return m.copyWith(driveAttachments: {...m.driveAttachments, ...newEntries});
      }
      return m;
    }).toList();
    return copyWith(
      driveAttachments: mergedThreadDrive,
      messages: updatedMessages,
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String author;
  final String authorRole;
  final String content;
  final DateTime publishedDate;
  final List<String> tags;
  final bool isRead;

  const Announcement({
    required this.id,
    required this.title,
    required this.author,
    required this.authorRole,
    required this.content,
    required this.publishedDate,
    required this.tags,
    this.isRead = false,
  });
}
