import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/portal_models.dart';
import '../../../shared/models/school.dart';

class PortalRepository {
  PortalRepository(this._client);

  final SupabaseClient _client;

  Future<School?> fetchSchoolPortal(String schoolId) async {
    final data = await _client
        .from('schools')
        .select()
        .eq('id', schoolId)
        .maybeSingle();
    if (data == null) return null;
    return School.fromJson(data);
  }

  Future<void> updateSchoolPortal(School school) async {
    await _client.from('schools').update(school.toJson()).eq('id', school.id);
  }

  Future<List<PortalFaq>> fetchFaqs(String schoolId) async {
    final data = await _client
        .from('portal_faqs')
        .select()
        .eq('school_id', schoolId)
        .eq('is_published', true)
        .order('sort_order');
    return (data as List).map((e) => PortalFaq.fromJson(e)).toList();
  }

  Future<List<PortalDownload>> fetchDownloads(String schoolId) async {
    final data = await _client
        .from('portal_downloads')
        .select()
        .eq('school_id', schoolId)
        .eq('is_published', true)
        .order('created_at', ascending: false);
    return (data as List).map((e) => PortalDownload.fromJson(e)).toList();
  }

  Future<List<PortalContact>> fetchContacts(String schoolId) async {
    final data = await _client
        .from('portal_contacts')
        .select()
        .eq('school_id', schoolId)
        .eq('is_published', true)
        .order('sort_order');
    return (data as List).map((e) => PortalContact.fromJson(e)).toList();
  }

  Future<List<PortalSuccessStory>> fetchStories(String schoolId) async {
    final data = await _client
        .from('portal_success_stories')
        .select()
        .eq('school_id', schoolId)
        .eq('is_published', true)
        .order('created_at', ascending: false);
    return (data as List).map((e) => PortalSuccessStory.fromJson(e)).toList();
  }

  Future<List<PortalReview>> fetchReviews(String schoolId) async {
    final data = await _client
        .from('portal_reviews')
        .select()
        .eq('school_id', schoolId)
        .eq('is_published', true)
        .order('created_at', ascending: false);
    return (data as List).map((e) => PortalReview.fromJson(e)).toList();
  }

  Future<List<PortalHelpArticle>> fetchHelp(String schoolId) async {
    final data = await _client
        .from('portal_help_articles')
        .select()
        .eq('school_id', schoolId)
        .eq('is_published', true)
        .order('sort_order');
    return (data as List).map((e) => PortalHelpArticle.fromJson(e)).toList();
  }

  Future<void> submitReview({
    required String schoolId,
    required String reviewerName,
    required int rating,
    required String body,
    String? reviewerRole,
  }) async {
    await _client.from('portal_reviews').insert({
      'school_id': schoolId,
      'reviewer_name': reviewerName,
      'reviewer_role': reviewerRole,
      'rating': rating,
      'body': body,
      'is_published': false,
    });
  }

  // Admin CMS
  Future<void> saveFaq(String schoolId, PortalFaq faq) async {
    if (faq.id.isEmpty) {
      await _client.from('portal_faqs').insert(faq.toJson(schoolId));
    } else {
      await _client.from('portal_faqs').update({
        'question': faq.question,
        'answer': faq.answer,
        'category': faq.category,
      }).eq('id', faq.id);
    }
  }

  Future<void> saveDownload(String schoolId, PortalDownload d, String fileUrl) async {
    await _client.from('portal_downloads').insert({
      'school_id': schoolId,
      'title': d.title,
      'description': d.description,
      'file_url': fileUrl,
      'category': d.category,
    });
  }

  Future<List<PortalAppRelease>> fetchAppReleases(String schoolId) async {
    final data = await _client
        .from('portal_app_releases')
        .select()
        .eq('school_id', schoolId)
        .order('sort_order');

    return (data as List)
        .map((e) => PortalAppRelease.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateAppRelease(PortalAppRelease release) async {
    await _client
        .from('portal_app_releases')
        .update(release.toJson())
        .eq('id', release.id);
  }
}
