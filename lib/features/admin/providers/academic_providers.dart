import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/academic_year.dart';
import '../../../shared/models/school_class.dart';
import '../../../shared/models/subject.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/academic_repository.dart';
import 'admin_providers.dart';

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  return AcademicRepository(ref.watch(supabaseClientProvider));
});

final academicYearsProvider = FutureProvider<List<AcademicYear>>((ref) async {
  final school = await ref.watch(schoolProvider.future);
  if (school == null) return [];
  return ref.watch(academicRepositoryProvider).fetchAcademicYears(school.id);
});

final classesProvider = FutureProvider<List<SchoolClass>>((ref) async {
  final school = await ref.watch(schoolProvider.future);
  if (school == null) return [];
  return ref.watch(academicRepositoryProvider).fetchClasses(school.id);
});

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final school = await ref.watch(schoolProvider.future);
  if (school == null) return [];
  return ref.watch(academicRepositoryProvider).fetchSubjects(school.id);
});

final teachersProvider = FutureProvider((ref) {
  return ref.watch(academicRepositoryProvider).fetchTeachers();
});

final studentsProvider = FutureProvider((ref) {
  return ref.watch(academicRepositoryProvider).fetchStudents();
});
