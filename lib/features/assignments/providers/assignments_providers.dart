import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/assignments_repository.dart';

final assignmentsRepositoryProvider = Provider<AssignmentsRepository>((ref) {
  return AssignmentsRepository(ref.watch(supabaseClientProvider));
});

final teacherAssignmentsProvider = FutureProvider((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref
      .watch(assignmentsRepositoryProvider)
      .fetchTeacherAssignments(profile.id);
});

final studentAssignmentsProvider = FutureProvider((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref
      .watch(assignmentsRepositoryProvider)
      .fetchStudentAssignments(profile.id);
});

final studentSubmissionsProvider = FutureProvider((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref
      .watch(assignmentsRepositoryProvider)
      .fetchStudentSubmissions(profile.id);
});
