enum UserRole {
  admin,
  teacher,
  student,
  parent,
  staff,
  accountant;

  /// Roles users may pick during public self-registration.
  static const selfRegistrationRoles = [UserRole.student, UserRole.parent];

  /// Roles assigned only through admin invite links.
  static const inviteOnlyRoles = [
    UserRole.admin,
    UserRole.teacher,
    UserRole.staff,
    UserRole.accountant,
  ];

  static bool isSelfRegistrationRole(UserRole role) =>
      selfRegistrationRoles.contains(role);

  String get label => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.teacher => 'Teacher',
        UserRole.student => 'Student',
        UserRole.parent => 'Parent',
        UserRole.staff => 'Staff',
        UserRole.accountant => 'Accountant',
      };

  String get dbValue => name;

  static UserRole fromDb(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.student,
    );
  }

  String get homeRoute => switch (this) {
        UserRole.admin => '/admin',
        UserRole.teacher => '/teacher',
        UserRole.student => '/student',
        UserRole.parent => '/parent',
        UserRole.staff => '/staff',
        UserRole.accountant => '/accountant',
      };
}
