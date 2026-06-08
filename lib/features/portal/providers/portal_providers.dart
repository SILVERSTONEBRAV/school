import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/portal_models.dart';
import '../../auth/providers/auth_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../data/portal_repository.dart';

final portalRepositoryProvider = Provider<PortalRepository>((ref) {
  return PortalRepository(ref.watch(supabaseClientProvider));
});

final portalSchoolProvider = FutureProvider((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);
  if (schoolId == null) return null;
  return ref.watch(portalRepositoryProvider).fetchSchoolPortal(schoolId);
});

final portalFaqsProvider = FutureProvider((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);
  if (schoolId == null) return [];
  return ref.watch(portalRepositoryProvider).fetchFaqs(schoolId);
});

final portalDownloadsProvider = FutureProvider((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);
  if (schoolId == null) return [];
  return ref.watch(portalRepositoryProvider).fetchDownloads(schoolId);
});

final portalContactsProvider = FutureProvider((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);
  if (schoolId == null) return [];
  return ref.watch(portalRepositoryProvider).fetchContacts(schoolId);
});

final portalStoriesProvider = FutureProvider((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);
  if (schoolId == null) return [];
  return ref.watch(portalRepositoryProvider).fetchStories(schoolId);
});

final portalReviewsProvider = FutureProvider((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);
  if (schoolId == null) return [];
  return ref.watch(portalRepositoryProvider).fetchReviews(schoolId);
});

final portalHelpProvider = FutureProvider((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);
  if (schoolId == null) return [];
  return ref.watch(portalRepositoryProvider).fetchHelp(schoolId);
});

final portalAppReleasesProvider = FutureProvider((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);
  if (schoolId == null) return <PortalAppRelease>[];
  return ref.watch(portalRepositoryProvider).fetchAppReleases(schoolId);
});
