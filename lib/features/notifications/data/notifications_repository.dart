import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/notification_item.dart';

class NotificationsRepository {
  NotificationsRepository(this._client);

  final SupabaseClient _client;

  Stream<List<NotificationItem>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .map(
          (data) => data
              .map((item) => NotificationItem.fromJson(item))
              .toList(),
        );
  }

  Future<List<NotificationItem>> fetchNotifications(String userId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List)
        .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> fetchUnreadCount(String userId) async {
    final data = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (data as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> notifyUsers({
    required List<String> userIds,
    required String title,
    String? body,
    required String type,
    String? referenceId,
  }) async {
    if (userIds.isEmpty) return;

    final rows = userIds
        .map(
          (userId) => {
            'user_id': userId,
            'title': title,
            'body': body,
            'type': type,
            'reference_id': referenceId,
          },
        )
        .toList();

    await _client.from('notifications').insert(rows);
  }
}
