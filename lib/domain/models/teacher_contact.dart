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
    final q = _norm(query);
    return _norm(name).contains(q) ||
        _norm(subjectName).contains(q) ||
        _norm(role).contains(q);
  }

  static String _norm(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll('ą', 'a')
        .replaceAll('ć', 'c')
        .replaceAll('ę', 'e')
        .replaceAll('ł', 'l')
        .replaceAll('ń', 'n')
        .replaceAll('ó', 'o')
        .replaceAll('ś', 's')
        .replaceAll('ź', 'z')
        .replaceAll('ż', 'z');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherContact && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
