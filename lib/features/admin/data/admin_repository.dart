import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/auth_redirect_config.dart';
import '../../../shared/models/at_risk_student.dart';
import '../../../shared/models/audit_log_entry.dart';
import '../../../shared/models/parent_profile_details.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/models/school.dart';
import '../../../shared/models/staff_profile_details.dart';
import '../../../shared/models/student_profile_details.dart';
import '../../../shared/models/user_account_status.dart';
import '../../../shared/models/user_role.dart';

export 'admin_user_service.dart';

class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  Future<School?> fetchSchool() async {
    final data = await _client
        .from('schools')
        .select()
        .order('created_at')
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return School.fromJson(data);
  }

  Future<School> saveSchool(School school) async {
    if (school.id.isEmpty) {
      final data = await _client
          .from('schools')
          .insert(school.toJson())
          .select()
          .single();
      return School.fromJson(data);
    }

    final data = await _client
        .from('schools')
        .update(school.toJson())
        .eq('id', school.id)
        .select()
        .single();
    return School.fromJson(data);
  }

  Future<List<Profile>> fetchProfiles() async {
    final data = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map((item) => Profile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Profile> updateProfile(Profile profile) async {
    final data = await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .select()
        .single();

    return Profile.fromJson(data);
  }

  Future<StudentProfileDetails?> fetchStudentDetails(String profileId) async {
    final data = await _client
        .from('student_profiles')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();
    if (data == null) return null;
    return StudentProfileDetails.fromJson(data);
  }

  Future<ParentProfileDetails?> fetchParentDetails(String profileId) async {
    final data = await _client
        .from('parent_profiles')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();
    if (data == null) return null;
    return ParentProfileDetails.fromJson(data);
  }

  Future<StaffProfileDetails?> fetchStaffDetails(String profileId) async {
    final data = await _client
        .from('staff_profiles')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();
    if (data == null) return null;
    return StaffProfileDetails.fromJson(data);
  }

  Future<void> upsertStudentDetails(StudentProfileDetails details) async {
    await _client.from('student_profiles').upsert(details.toJson());
  }

  Future<void> upsertParentDetails(ParentProfileDetails details) async {
    await _client.from('parent_profiles').upsert(details.toJson());
  }

  Future<void> upsertStaffDetails(StaffProfileDetails details) async {
    await _client.from('staff_profiles').upsert(details.toJson());
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: AuthRedirectConfig.emailRedirectTo,
    );
  }

  Future<void> logAudit({
    required String actorId,
    required String action,
    String? targetUserId,
    Map<String, dynamic>? details,
  }) async {
    await _client.from('admin_audit_log').insert({
      'actor_id': actorId,
      'action': action,
      'target_user_id': targetUserId,
      'details': details ?? {},
    });
  }

  Future<List<AuditLogEntry>> fetchAuditLog({int limit = 50}) async {
    final data = await _client
        .from('admin_audit_log')
        .select('*, actor:profiles!actor_id(first_name, last_name)')
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AtRiskStudent>> fetchAtRiskStudents() async {
    final data = await _client.from('at_risk_students').select();
    return (data as List)
        .map((e) => AtRiskStudent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> countProfilesByRole(UserRole role) async {
    final data = await _client
        .from('profiles')
        .select('id')
        .eq('role', role.dbValue);

    return (data as List).length;
  }

  Future<int> countByStatus(UserAccountStatus status) async {
    final data = await _client
        .from('profiles')
        .select('id')
        .eq('status', status.dbValue);
    return (data as List).length;
  }

  Future<Map<String, dynamic>> createStaffInvite({
    required String email,
    required UserRole role,
    String? schoolId,
    String? invitedBy,
  }) async {
    if (!UserRole.inviteOnlyRoles.contains(role)) {
      throw ArgumentError('Only staff roles can be invited through this flow.');
    }

    final data = await _client
        .from('staff_invites')
        .insert({
          'email': email.trim(),
          'role': role.dbValue,
          ...? (schoolId != null ? {'school_id': schoolId} : null),
          ...? (invitedBy != null ? {'invited_by': invitedBy} : null),
        })
        .select()
        .single();

    return data;
  }

  Future<void> linkParentStudent({
    required String parentId,
    required String studentId,
    String? relationship,
  }) async {
    await _client.from('student_parents').upsert({
      'parent_id': parentId,
      'student_id': studentId,
      'relationship': relationship,
    });
  }
}
