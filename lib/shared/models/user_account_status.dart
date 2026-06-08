enum UserAccountStatus {
  active,
  inactive,
  suspended;

  String get label => switch (this) {
        UserAccountStatus.active => 'Active',
        UserAccountStatus.inactive => 'Inactive',
        UserAccountStatus.suspended => 'Suspended',
      };

  String get dbValue => name;

  static UserAccountStatus fromDb(String? value) {
    return UserAccountStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => UserAccountStatus.active,
    );
  }
}
