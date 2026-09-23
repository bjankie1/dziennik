/// Types of family chat messages (REQ-CHAT-01, D-01, D-02).
enum ChatMessageType {
  text,
  justificationCard,
  systemInfo;

  String toFirestore() => switch (this) {
        ChatMessageType.text => 'text',
        ChatMessageType.justificationCard => 'justificationCard',
        ChatMessageType.systemInfo => 'systemInfo',
      };

  static ChatMessageType fromString(String? val) {
    if (val == null) return ChatMessageType.text;
    return switch (val.trim()) {
      'justificationCard' => ChatMessageType.justificationCard,
      'systemInfo' => ChatMessageType.systemInfo,
      _ => ChatMessageType.text,
    };
  }
}

/// Domain model representing a real-time family chat message between
/// parent and student (REQ-CHAT-01, D-01, D-04).
class ChatMessage {
  final String id;
  final String familyId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'student' | 'parent' | 'system'
  final String text;
  final DateTime createdAt;
  final ChatMessageType type;
  final Map<String, dynamic>? metadata;
  final bool isReadByStudent;
  final bool isReadByParent;

  const ChatMessage({
    required this.id,
    required this.familyId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.type = ChatMessageType.text,
    this.metadata,
    this.isReadByStudent = false,
    this.isReadByParent = false,
  });

  bool get isStudentSender => senderRole.toLowerCase() == 'student';
  bool get isParentSender => senderRole.toLowerCase() == 'parent';
  bool get isSystem => type == ChatMessageType.systemInfo || senderRole.toLowerCase() == 'system';
  bool get isJustificationCard => type == ChatMessageType.justificationCard;

  factory ChatMessage.fromJson(Map<String, dynamic> json, [String? id]) {
    DateTime parseDate(dynamic d) {
      if (d is DateTime) return d;
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : null;

    return ChatMessage(
      id: id ?? (json['id']?.toString() ?? ''),
      familyId: json['familyId']?.toString() ?? 'jankiewicz_family',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? 'parent',
      text: json['text']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      type: ChatMessageType.fromString(json['type']?.toString()),
      metadata: metadata,
      isReadByStudent: json['isReadByStudent'] == true,
      isReadByParent: json['isReadByParent'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'type': type.toFirestore(),
      if (metadata != null) 'metadata': metadata,
      'isReadByStudent': isReadByStudent,
      'isReadByParent': isReadByParent,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? familyId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? text,
    DateTime? createdAt,
    ChatMessageType? type,
    Map<String, dynamic>? metadata,
    bool? isReadByStudent,
    bool? isReadByParent,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      isReadByStudent: isReadByStudent ?? this.isReadByStudent,
      isReadByParent: isReadByParent ?? this.isReadByParent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ChatMessage(id: $id, sender: $senderName ($senderRole), type: ${type.name}, text: $text)';
}
