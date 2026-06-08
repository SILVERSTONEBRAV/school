import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/portal_models.dart';

class MaterialsRepository {
  MaterialsRepository(this._client);

  final SupabaseClient _client;

  Future<List<CourseMaterial>> fetchByTeacher(String teacherId) async {
    final data = await _client
        .from('course_materials')
        .select('*, class_subjects!inner(teacher_id)')
        .eq('class_subjects.teacher_id', teacherId)
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => CourseMaterial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CourseMaterial>> fetchForStudentClasses(
    List<String> classSubjectIds,
  ) async {
    if (classSubjectIds.isEmpty) return [];

    final data = await _client
        .from('course_materials')
        .select()
        .inFilter('class_subject_id', classSubjectIds)
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => CourseMaterial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CourseMaterial> uploadMaterial({
    required String classSubjectId,
    required String title,
    required String fileUrl,
    required String uploadedBy,
    String? description,
    String? fileName,
  }) async {
    final data = await _client
        .from('course_materials')
        .insert({
          'class_subject_id': classSubjectId,
          'title': title,
          'description': description,
          'file_url': fileUrl,
          'file_name': fileName,
          'uploaded_by': uploadedBy,
        })
        .select()
        .single();

    return CourseMaterial.fromJson(data);
  }

  Future<String> uploadFile({
    required String teacherId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$teacherId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('course-materials').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  Future<String> getSignedUrl(String path) async {
    return _client.storage.from('course-materials').createSignedUrl(path, 3600);
  }
}
