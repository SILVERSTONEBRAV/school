import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/audit_log_entry.dart';
import '../../../shared/models/at_risk_student.dart';
import '../../../shared/models/school.dart';
import '../../../shared/models/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

final adminUserServiceProvider = Provider<AdminUserService>((ref) {
  return AdminUserService(ref.watch(supabaseClientProvider));
});

final schoolProvider = FutureProvider<School?>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchSchool();
});

final profilesProvider = FutureProvider((ref) async {
  return ref.watch(adminRepositoryProvider).fetchProfiles();
});

final adminStatsProvider = FutureProvider<Map<UserRole, int>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final counts = <UserRole, int>{};

  for (final role in UserRole.values) {
    counts[role] = await repository.countProfilesByRole(role);
  }

  return counts;
});

final auditLogProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchAuditLog();
});

final atRiskStudentsProvider = FutureProvider<List<AtRiskStudent>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchAtRiskStudents();
});
