/// Status of a student justification request in the parental approval pipeline.
enum JustificationRequestStatus {
  pendingParentApproval,
  approved,
  rejected;

  bool get isPending => this == JustificationRequestStatus.pendingParentApproval;
  bool get isApproved => this == JustificationRequestStatus.approved;
  bool get isRejected => this == JustificationRequestStatus.rejected;

  String get displayName => switch (this) {
        JustificationRequestStatus.pendingParentApproval => 'Oczekuje na akceptację rodzica',
        JustificationRequestStatus.approved => 'Zatwierdzone',
        JustificationRequestStatus.rejected => 'Odrzucone',
      };

  String toFirestore() => switch (this) {
        JustificationRequestStatus.pendingParentApproval => 'pending_parent_approval',
        JustificationRequestStatus.approved => 'approved',
        JustificationRequestStatus.rejected => 'rejected',
      };

  static JustificationRequestStatus fromString(String? val) {
    if (val == null) return JustificationRequestStatus.pendingParentApproval;
    return switch (val.trim().toLowerCase()) {
      'approved' => JustificationRequestStatus.approved,
      'rejected' => JustificationRequestStatus.rejected,
      _ => JustificationRequestStatus.pendingParentApproval,
    };
  }
}

/// Domain model representing an excuse request initiated by a student
/// and awaiting parent approval via 4-digit PIN (REQ-ROLE-02, D-03, D-04).
class JustificationRequest {
  final String id;
  final String studentLogin;
  final String studentName;
  final String familyId;
  final String primaryLogin;
  final List<String> recordIds;
  final List<int> lessonNumbers;
  final List<String> subjectNames;
  final DateTime? date;
  final String reason;
  final JustificationRequestStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  const JustificationRequest({
    required this.id,
    required this.studentLogin,
    this.studentName = 'Oskar Jankiewicz',
    this.familyId = 'jankiewicz_family',
    this.primaryLogin = '7654321r',
    required this.recordIds,
    this.lessonNumbers = const [],
    this.subjectNames = const [],
    this.date,
    required this.reason,
    this.status = JustificationRequestStatus.pendingParentApproval,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  factory JustificationRequest.fromJson(Map<String, dynamic> json, [String? id]) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      if (d is String) return DateTime.tryParse(d);
      return null;
    }

    final rawLessonNumbers = json['lessonNumbers'];
    final lessonNumbers = rawLessonNumbers is List
        ? rawLessonNumbers.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList()
        : <int>[];

    final rawSubjects = json['subjectNames'];
    final subjectNames = rawSubjects is List
        ? rawSubjects.map((e) => e.toString()).toList()
        : <String>[];

    final rawRecordIds = json['recordIds'];
    final recordIds = rawRecordIds is List
        ? rawRecordIds.map((e) => e.toString()).toList()
        : <String>[];

    return JustificationRequest(
      id: id ?? (json['id']?.toString() ?? ''),
      studentLogin: json['studentLogin']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? 'Oskar Jankiewicz',
      familyId: json['familyId']?.toString() ?? 'jankiewicz_family',
      primaryLogin: json['primaryLogin']?.toString() ?? '7654321r',
      recordIds: recordIds,
      lessonNumbers: lessonNumbers,
      subjectNames: subjectNames,
      date: parseDate(json['date']),
      reason: json['reason']?.toString() ?? '',
      status: JustificationRequestStatus.fromString(json['status']?.toString()),
      requestedAt: parseDate(json['requestedAt']) ?? DateTime.now(),
      reviewedAt: parseDate(json['reviewedAt']),
      reviewedBy: json['reviewedBy']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentLogin': studentLogin,
      'studentName': studentName,
      'familyId': familyId,
      'primaryLogin': primaryLogin,
      'recordIds': recordIds,
      'lessonNumbers': lessonNumbers,
      'subjectNames': subjectNames,
      'date': date?.toIso8601String().split('T').first,
      'reason': reason,
      'status': status.toFirestore(),
      'requestedAt': requestedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  JustificationRequest copyWith({
    String? id,
    String? studentLogin,
    String? studentName,
    String? familyId,
    String? primaryLogin,
    List<String>? recordIds,
    List<int>? lessonNumbers,
    List<String>? subjectNames,
    DateTime? date,
    String? reason,
    JustificationRequestStatus? status,
    DateTime? requestedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return JustificationRequest(
      id: id ?? this.id,
      studentLogin: studentLogin ?? this.studentLogin,
      studentName: studentName ?? this.studentName,
      familyId: familyId ?? this.familyId,
      primaryLogin: primaryLogin ?? this.primaryLogin,
      recordIds: recordIds ?? this.recordIds,
      lessonNumbers: lessonNumbers ?? this.lessonNumbers,
      subjectNames: subjectNames ?? this.subjectNames,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JustificationRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ status.hashCode;

  @override
  String toString() =>
      'JustificationRequest(id: $id, student: $studentName, status: ${status.name}, reason: $reason)';
}
