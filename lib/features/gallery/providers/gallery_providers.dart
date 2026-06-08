import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../data/gallery_repository.dart';

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepository(ref.watch(supabaseClientProvider));
});

final galleryPostsProvider = FutureProvider((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);
  final profile = ref.watch(currentProfileProvider).value;
  if (schoolId == null) return [];
  return ref
      .watch(galleryRepositoryProvider)
      .fetchPosts(schoolId, profile?.id);
});
