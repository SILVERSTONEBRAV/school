import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/assignment.dart';

class AssignmentsRepository {
  AssignmentsRepository(this._client);

  final SupabaseClient _client;

  static const _assignmentSelect =
      '*, class_subjects(subjects(name), classes(name))';

  Future<List<Assignment>> fetchTeacherAssignments(String teacherId) async {
    final classSubjects = await _client
        .from('class_subjects')
        .select('id')
        .eq('teacher_id', teacherId);

    final ids = (classSubjects as List)
        .map((row) => row['id'] as String)
        .toList();

    if (ids.isEmpty) return [];

    final data = await _client
        .from('assignments')
        .select(_assignmentSelect)
        .inFilter('class_subject_id', ids)
        .order('due_date');

    return (data as List)
        .map((item) => Assignment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Assignment>> fetchStudentAssignments(String studentId) async {
    final enrollment = await _client
        .from('enrollments')
        .select('class_id')
        .eq('student_id', studentId)
        .eq('status', 'active')
        .maybeSingle();

    if (enrollment == null) return [];

    final classId = enrollment['class_id'] as String;
    final classSubjects = await _client
        .from('class_subjects')
        .select('id')
        .eq('class_id', classId);

    final ids = (classSubjects as List)
        .map((row) => row['id'] as String)
        .toList();

    if (ids.isEmpty) return [];

    final data = await _client
        .from('assignments')
        .select(_assignmentSelect)
        .inFilter('class_subject_id', ids)
        .order('due_date');

    return (data as List)
        .map((item) => Assignment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Assignment> createAssignment(Assignment assignment, String createdBy) async {
    final data = await _client
        .from('assignments')
        .insert(assignment.toInsertJson(createdBy))
        .select(_assignmentSelect)
        .single();

    return Assignment.fromJson(data);
  }

  Future<List<Submission>> fetchSubmissions(String assignmentId) async {
    final data = await _client
        .from('submissions')
        .select(
          '*, student_profiles(profiles(first_name, last_name)), assignments(title)',
        )
        .eq('assignment_id', assignmentId);

    return (data as List)
        .map((item) => Submission.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Submission>> fetchStudentSubmissions(String studentId) async {
    final data = await _client
        .from('submissions')
        .select(
          '*, student_profiles(profiles(first_name, last_name)), assignments(title)',
        )
        .eq('student_id', studentId);

    return (data as List)
        .map((item) => Submission.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Submission?> fetchStudentSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    final data = await _client
        .from('submissions')
        .select(
          '*, student_profiles(profiles(first_name, last_name)), assignments(title)',
        )
        .eq('assignment_id', assignmentId)
        .eq('student_id', studentId)
        .maybeSingle();

    if (data == null) return null;
    return Submission.fromJson(data);
  }

  Future<Submission> submitAssignment({
    required String assignmentId,
    required String studentId,
    required String content,
    String? fileUrl,
    required bool isLate,
  }) async {
    final data = await _client
        .from('submissions')
        .upsert({
          'assignment_id': assignmentId,
          'student_id': studentId,
          'content': content,
          'file_url': ?fileUrl,
          'status': isLate ? 'late' : 'submitted',
          'submitted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'assignment_id,student_id')
        .select(
          '*, student_profiles(profiles(first_name, last_name)), assignments(title)',
        )
        .single();

    return Submission.fromJson(data);
  }

  Future<Submission> gradeSubmission({
    required String submissionId,
    required double score,
    String? feedback,
    required String gradedBy,
  }) async {
    final data = await _client
        .from('submissions')
        .update({
          'score': score,
          'feedback': feedback,
          'status': 'graded',
          'graded_by': gradedBy,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', submissionId)
        .select(
          '*, student_profiles(profiles(first_name, last_name)), assignments(title)',
        )
        .single();

    return Submission.fromJson(data);
  }

  Future<List<String>> fetchEnrolledStudentIds(String classSubjectId) async {
    final classSubject = await _client
        .from('class_subjects')
        .select('class_id')
        .eq('id', classSubjectId)
        .single();

    final classId = classSubject['class_id'] as String;
    final enrollments = await _client
        .from('enrollments')
        .select('student_id')
        .eq('class_id', classId)
        .eq('status', 'active');

    return (enrollments as List)
        .map((row) => row['student_id'] as String)
        .toList();
  }
}
