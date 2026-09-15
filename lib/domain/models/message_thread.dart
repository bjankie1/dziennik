class MessageItem {
  final String id;
  final String senderName;
  final String senderRole;
  final String senderInitials;
  final DateTime timestamp;
  final String body;
  final bool isFromMe;
  final List<String> attachments;

  const MessageItem({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.senderInitials,
    required this.timestamp,
    required this.body,
    this.isFromMe = false,
    this.attachments = const [],
  });
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
  final List<String> attachments;
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
    this.attachments = const [],
    List<MessageItem>? messages,
  }) : messages = messages ??
            [
              MessageItem(
                id: '${id}_0',
                senderName: senderName,
                senderRole: senderRole,
                senderInitials: senderInitials,
                timestamp: timestamp,
                body: body,
                attachments: attachments,
                isFromMe: false,
              ),
            ];

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
    List<String>? attachments,
    List<MessageItem>? messages,
  }) {
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
      attachments: attachments ?? this.attachments,
      messages: messages ?? this.messages,
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
