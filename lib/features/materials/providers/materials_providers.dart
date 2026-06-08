import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/materials_repository.dart';

final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  return MaterialsRepository(ref.watch(supabaseClientProvider));
});

final teacherMaterialsProvider = FutureProvider((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref.watch(materialsRepositoryProvider).fetchByTeacher(profile.id);
});
