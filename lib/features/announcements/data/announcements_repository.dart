import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/announcement.dart';

class AnnouncementsRepository {
  AnnouncementsRepository(this._client);

  final SupabaseClient _client;

  Future<String?> resolveSchoolId(String? profileSchoolId) async {
    if (profileSchoolId != null) return profileSchoolId;

    final school = await _client
        .from('schools')
        .select('id')
        .order('created_at')
        .limit(1)
        .maybeSingle();

    return school?['id'] as String?;
  }

  Future<List<Announcement>> fetchAnnouncements(String schoolId) async {
    final data = await _client
        .from('announcements')
        .select('*, author:profiles!author_id(first_name, last_name)')
        .eq('school_id', schoolId)
        .order('is_pinned', ascending: false)
        .order('published_at', ascending: false)
        .limit(20);

    return (data as List)
        .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Announcement> createAnnouncement({
    required String schoolId,
    required String title,
    required String body,
    required String authorId,
    bool isPinned = false,
  }) async {
    final data = await _client
        .from('announcements')
        .insert({
          'school_id': schoolId,
          'title': title,
          'body': body,
          'author_id': authorId,
          'is_pinned': isPinned,
        })
        .select('*, author:profiles!author_id(first_name, last_name)')
        .single();

    return Announcement.fromJson(data);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _client.from('announcements').delete().eq('id', id);
  }
}
