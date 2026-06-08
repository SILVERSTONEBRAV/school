import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/user_account_status.dart';
import '../../../shared/models/user_role.dart';

class AdminUserService {
  AdminUserService(this._client);

  final SupabaseClient _client;

  Future<String> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
    String? phoneNumber,
    String? schoolId,
    UserAccountStatus status = UserAccountStatus.active,
    String? rollNumber,
    String? dateOfBirth,
    String? address,
    String? occupation,
    String? employeeId,
    String? jobTitle,
    String? department,
  }) async {
    final response = await _client.functions.invoke(
      'admin-users',
      body: {
        'action': 'create_user',
        'email': email.trim(),
        'password': password,
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'role': role.dbValue,
        'phone_number': phoneNumber?.trim(),
        'school_id': schoolId,
        'status': status.dbValue,
        'roll_number': rollNumber,
        'date_of_birth': dateOfBirth,
        'address': address,
        'occupation': occupation,
        'employee_id': employeeId,
        'job_title': jobTitle,
        'department': department,
      },
    );

    if (response.status != 200) {
      final error = response.data is Map ? response.data['error'] : response.data;
      throw Exception(error ?? 'Failed to create user');
    }

    final data = response.data as Map<String, dynamic>;
    return data['user_id'] as String;
  }

  Future<void> updatePassword({
    required String userId,
    required String password,
  }) async {
    final response = await _client.functions.invoke(
      'admin-users',
      body: {
        'action': 'update_password',
        'user_id': userId,
        'password': password,
      },
    );

    if (response.status != 200) {
      final error = response.data is Map ? response.data['error'] : response.data;
      throw Exception(error ?? 'Failed to update password');
    }
  }

  Future<void> deleteUser(String userId) async {
    final response = await _client.functions.invoke(
      'admin-users',
      body: {
        'action': 'delete_user',
        'user_id': userId,
      },
    );

    if (response.status != 200) {
      final error = response.data is Map ? response.data['error'] : response.data;
      throw Exception(error ?? 'Failed to delete user');
    }
  }
}
