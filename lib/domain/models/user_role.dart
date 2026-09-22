/// Role of the user in EduSync family model.
///
/// [parent] represents a parent with full administrative rights (PIN authorization,
/// submitting official e-justifications to school).
/// [student] represents the student with access to timetable, grades, attendance,
/// and requesting justifications through parents.
enum UserRole {
  parent,
  student;

  bool get isParent => this == UserRole.parent;
  bool get isStudent => this == UserRole.student;

  String get displayName => switch (this) {
        UserRole.parent => 'Rodzic',
        UserRole.student => 'Uczeń',
      };

  static UserRole fromString(String? role) {
    if (role?.trim().toLowerCase() == 'student') return UserRole.student;
    return UserRole.parent;
  }
}
