import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/portal_models.dart';

class GalleryRepository {
  GalleryRepository(this._client);

  final SupabaseClient _client;

  Future<List<GalleryPost>> fetchPosts(String schoolId, String? profileId) async {
    final data = await _client
        .from('gallery_posts')
        .select('*, profiles(first_name, last_name)')
        .eq('school_id', schoolId)
        .eq('is_published', true)
        .order('created_at', ascending: false);

    final posts = (data as List)
        .map((e) => GalleryPost.fromJson(e as Map<String, dynamic>))
        .toList();

    if (profileId == null) return posts;

    final enriched = <GalleryPost>[];
    for (final post in posts) {
      final likes = await _client
          .from('gallery_likes')
          .select('profile_id')
          .eq('post_id', post.id);
      final comments = await _client
          .from('gallery_comments')
          .select('id')
          .eq('post_id', post.id);
      final liked = (likes as List).any((l) => l['profile_id'] == profileId);
      enriched.add(post.copyWith(
        likeCount: likes.length,
        commentCount: comments.length,
        likedByMe: liked,
      ));
    }
    return enriched;
  }

  Future<void> toggleLike(String postId, String profileId, bool liked) async {
    if (liked) {
      await _client.from('gallery_likes').delete().match({
        'post_id': postId,
        'profile_id': profileId,
      });
    } else {
      await _client.from('gallery_likes').insert({
        'post_id': postId,
        'profile_id': profileId,
      });
    }
  }

  Future<List<GalleryComment>> fetchComments(String postId) async {
    final data = await _client
        .from('gallery_comments')
        .select('*, profiles(first_name, last_name)')
        .eq('post_id', postId)
        .order('created_at');

    return (data as List)
        .map((e) => GalleryComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addComment(String postId, String profileId, String body) async {
    await _client.from('gallery_comments').insert({
      'post_id': postId,
      'profile_id': profileId,
      'body': body,
    });
  }

  Future<void> createPost({
    required String schoolId,
    required String authorId,
    required String imageUrl,
    String? caption,
  }) async {
    await _client.from('gallery_posts').insert({
      'school_id': schoolId,
      'author_id': authorId,
      'image_url': imageUrl,
      'caption': caption,
    });
  }

  Future<String> uploadImage({
    required String schoolId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$schoolId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('gallery').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('gallery').getPublicUrl(path);
  }
}
