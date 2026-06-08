import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/offline_cache_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/student_repository.dart';

final offlineCacheProvider = Provider((ref) => OfflineCacheService());

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(supabaseClientProvider));
});

final studentAcademicsProvider = FutureProvider((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) {
    return const StudentAcademics(
      subjects: [],
      grades: [],
      attendance: [],
    );
  }

  final repo = ref.watch(studentRepositoryProvider);
  final cache = ref.watch(offlineCacheProvider);
  final cacheKey = 'student_academics_${profile.id}';

  try {
    final result = await repo.fetchAcademics(profile.id);
    await cache.save(cacheKey, result.toCacheJson());
    return result;
  } catch (_) {
    final cached = await cache.load(cacheKey);
    if (cached != null) return StudentAcademics.fromCache(cached);
    rethrow;
  }
});
