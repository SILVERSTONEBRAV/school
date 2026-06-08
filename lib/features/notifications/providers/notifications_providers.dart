import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(supabaseClientProvider));
});

final notificationsStreamProvider = StreamProvider((ref) async* {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref
      .watch(notificationsRepositoryProvider)
      .watchNotifications(profile.id);
});

final notificationsProvider = FutureProvider((ref) async {
  final stream = ref.watch(notificationsStreamProvider);
  return stream.value ?? [];
});

final unreadNotificationsCountProvider = Provider((ref) {
  final notifications = ref.watch(notificationsStreamProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
