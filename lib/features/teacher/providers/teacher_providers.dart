import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/class_subject.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/teacher_repository.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository(ref.watch(supabaseClientProvider));
});

final teacherClassesProvider = FutureProvider((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref.watch(teacherRepositoryProvider).fetchMyClasses(profile.id);
});

final teacherClassSubjectsProvider = FutureProvider<List<ClassSubject>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref.watch(teacherRepositoryProvider).fetchMyClassSubjects(profile.id);
});

final teacherTermsProvider = FutureProvider((ref) {
  return ref.watch(teacherRepositoryProvider).fetchAllTerms();
});
