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

  const MessageThread({
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
  });
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
