import 'user_account_status.dart';
import 'user_role.dart';

class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.schoolId,
    this.status = UserAccountStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final UserRole role;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? schoolId;
  final UserAccountStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      role: UserRole.fromDb(json['role'] as String),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      schoolId: json['school_id'] as String?,
      status: UserAccountStatus.fromDb(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.dbValue,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'school_id': schoolId,
      'status': status.dbValue,
    };
  }
}
