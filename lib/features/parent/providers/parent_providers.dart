import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/fee.dart';
import '../../auth/providers/auth_providers.dart';
import '../../assignments/data/assignments_repository.dart';
import '../../fees/data/fees_repository.dart';
import '../../student/data/student_repository.dart';
import '../data/parent_repository.dart';

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ParentRepository(
    client,
    StudentRepository(client),
    FeesRepository(client),
    AssignmentsRepository(client),
  );
});

final parentChildrenProvider = FutureProvider((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref.watch(parentRepositoryProvider).fetchChildren(profile.id);
});

class SelectedChildId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedChildIdProvider =
    NotifierProvider<SelectedChildId, String?>(SelectedChildId.new);

final selectedChildProvider = Provider((ref) {
  final children = ref.watch(parentChildrenProvider).value ?? [];
  final selectedId = ref.watch(selectedChildIdProvider);

  if (children.isEmpty) return null;

  return children.firstWhere(
    (child) => child.studentId == selectedId,
    orElse: () => children.first,
  );
});

final selectedChildAcademicsProvider = FutureProvider((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return null;
  return ref
      .watch(parentRepositoryProvider)
      .fetchChildAcademics(child.studentId);
});

final selectedChildFeesProvider = FutureProvider((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) {
    return const FeeSummary(
      totalDue: 0,
      totalPaid: 0,
      invoices: [],
      payments: [],
    );
  }
  return ref.watch(parentRepositoryProvider).fetchChildFees(child.studentId);
});

final selectedChildAssignmentsProvider = FutureProvider((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return [];
  return ref
      .watch(parentRepositoryProvider)
      .fetchChildAssignments(child.studentId);
});

final selectedChildSubmissionsProvider = FutureProvider((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return [];
  return ref
      .watch(parentRepositoryProvider)
      .fetchChildSubmissions(child.studentId);
});
