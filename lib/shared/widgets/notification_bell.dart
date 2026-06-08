import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../features/notifications/providers/notifications_providers.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return IconButton(
      onPressed: () => _showNotifications(context, ref, notificationsAsync),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: 'Notifications',
    );
  }

  Future<void> _showNotifications(
    BuildContext context,
    WidgetRef ref,
    AsyncValue notificationsAsync,
  ) async {
    final notifications = notificationsAsync.value ?? [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final profile =
                            await ref.read(currentProfileProvider.future);
                        if (profile == null) return;
                        await ref
                            .read(notificationsRepositoryProvider)
                            .markAllAsRead(profile.id);
                      },
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: notificationsAsync.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : notifications.isEmpty
                        ? const Center(child: Text('No notifications'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final item = notifications[index];
                              return ListTile(
                                leading: Icon(
                                  item.isRead
                                      ? Icons.notifications_none
                                      : Icons.notifications_active,
                                ),
                                title: Text(item.title),
                                subtitle:
                                    item.body != null ? Text(item.body!) : null,
                                trailing: Text(
                                  _formatDate(item.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                onTap: () async {
                                  if (!item.isRead) {
                                    await ref
                                        .read(notificationsRepositoryProvider)
                                        .markAsRead(item.id);
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
