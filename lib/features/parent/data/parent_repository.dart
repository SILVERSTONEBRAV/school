import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/assignment.dart';
import '../../../shared/models/child_summary.dart';
import '../../../shared/models/fee.dart';
import '../../assignments/data/assignments_repository.dart';
import '../../fees/data/fees_repository.dart';
import '../../student/data/student_repository.dart';

class ParentRepository {
  ParentRepository(
    this._client,
    this._studentRepo,
    this._feesRepo,
    this._assignmentsRepo,
  );

  final SupabaseClient _client;
  final StudentRepository _studentRepo;
  final FeesRepository _feesRepo;
  final AssignmentsRepository _assignmentsRepo;

  Future<List<ChildSummary>> fetchChildren(String parentId) async {
    final data = await _client.from('student_parents').select('''
          student_id,
          relationship,
          student_profiles(
            roll_number,
            profiles(first_name, last_name),
            enrollments(status, classes(name))
          )
        ''').eq('parent_id', parentId);

    return (data as List)
        .map((item) => ChildSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StudentAcademics> fetchChildAcademics(String studentId) {
    return _studentRepo.fetchAcademics(studentId);
  }

  Future<FeeSummary> fetchChildFees(String studentId) {
    return _feesRepo.fetchFeeSummary(studentId);
  }

  Future<List<Assignment>> fetchChildAssignments(String studentId) {
    return _assignmentsRepo.fetchStudentAssignments(studentId);
  }

  Future<List<Submission>> fetchChildSubmissions(String studentId) {
    return _assignmentsRepo.fetchStudentSubmissions(studentId);
  }
}
