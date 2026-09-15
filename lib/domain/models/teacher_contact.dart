class TeacherContact {
  final String id;
  final String name;
  final String subjectName;
  final String role;
  final String initials;

  const TeacherContact({
    required this.id,
    required this.name,
    required this.subjectName,
    required this.role,
    required this.initials,
  });

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase().trim();
    return name.toLowerCase().contains(q) ||
        subjectName.toLowerCase().contains(q) ||
        role.toLowerCase().contains(q);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherContact && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
