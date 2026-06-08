import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/providers/admin_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/announcements_repository.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  return AnnouncementsRepository(ref.watch(supabaseClientProvider));
});

final schoolIdProvider = FutureProvider<String?>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  final school = await ref.watch(schoolProvider.future);
  return ref.watch(announcementsRepositoryProvider).resolveSchoolId(
        profile?.schoolId ?? school?.id,
      );
});

final announcementsProvider = FutureProvider((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);
  if (schoolId == null) return [];
  return ref.watch(announcementsRepositoryProvider).fetchAnnouncements(schoolId);
});
