import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/attendance.dart';
import '../../../shared/models/class_subject.dart';
import '../../../shared/models/enrolled_student.dart';
import '../../../shared/models/grade_record.dart';
import '../../../shared/models/school_class.dart';
import '../../../shared/models/term.dart';

class TeacherRepository {
  TeacherRepository(this._client);

  final SupabaseClient _client;

  Future<List<SchoolClass>> fetchMyClasses(String teacherId) async {
    final subjectClasses = await _client
        .from('class_subjects')
        .select('class_id, classes(id, name, school_id, academic_year_id, class_teacher_id, created_at)')
        .eq('teacher_id', teacherId);

    final homeroomClasses = await _client
        .from('classes')
        .select()
        .eq('class_teacher_id', teacherId);

    final classes = <String, SchoolClass>{};

    for (final row in subjectClasses as List) {
      final classData = row['classes'] as Map<String, dynamic>?;
      if (classData != null) {
        classes[classData['id'] as String] = SchoolClass.fromJson(classData);
      }
    }

    for (final row in homeroomClasses as List) {
      final schoolClass = SchoolClass.fromJson(row as Map<String, dynamic>);
      classes[schoolClass.id] = schoolClass;
    }

    return classes.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<ClassSubject>> fetchMyClassSubjects(String teacherId) async {
    final data = await _client
        .from('class_subjects')
        .select(
          '*, classes(name), subjects(name, code), teacher:profiles!teacher_id(first_name, last_name)',
        )
        .eq('teacher_id', teacherId);

    return (data as List)
        .map((item) => ClassSubject.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<EnrolledStudent>> fetchClassStudents(String classId) async {
    final data = await _client
        .from('enrollments')
        .select(
          '*, student_profiles(roll_number, profiles(first_name, last_name, email))',
        )
        .eq('class_id', classId)
        .eq('status', 'active');

    return (data as List)
        .map((item) => EnrolledStudent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AttendanceRecord>> fetchAttendance({
    required String classId,
    required DateTime date,
  }) async {
    final data = await _client
        .from('attendance')
        .select(
          '*, student_profiles(profiles(first_name, last_name))',
        )
        .eq('class_id', classId)
        .eq('date', _formatDate(date));

    return (data as List)
        .map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAttendance({
    required String classId,
    required DateTime date,
    required Map<String, AttendanceStatus> statuses,
    required String markedBy,
  }) async {
    final rows = statuses.entries
        .map(
          (entry) => {
            'student_id': entry.key,
            'class_id': classId,
            'date': _formatDate(date),
            'status': entry.value.dbValue,
            'marked_by': markedBy,
          },
        )
        .toList();

    if (rows.isEmpty) return;

    await _client.from('attendance').upsert(
          rows,
          onConflict: 'student_id,date',
        );
  }

  Future<List<Term>> fetchActiveTerms() async {
    final data = await _client
        .from('terms')
        .select()
        .eq('is_active', true)
        .order('start_date');

    return (data as List)
        .map((item) => Term.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Term>> fetchAllTerms() async {
    final data = await _client.from('terms').select().order('start_date');

    return (data as List)
        .map((item) => Term.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<GradeRecord>> fetchGrades({
    required String classSubjectId,
    required String termId,
  }) async {
    final data = await _client
        .from('grades')
        .select(
          '*, student_profiles(profiles(first_name, last_name)), class_subjects(subjects(name)), terms(name)',
        )
        .eq('class_subject_id', classSubjectId)
        .eq('term_id', termId);

    return (data as List)
        .map((item) => GradeRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveGrades({
    required String classSubjectId,
    required String termId,
    required Map<String, double> scores,
    required String gradedBy,
  }) async {
    final rows = scores.entries
        .map(
          (entry) => {
            'student_id': entry.key,
            'class_subject_id': classSubjectId,
            'term_id': termId,
            'score': entry.value,
            'graded_by': gradedBy,
            'updated_at': DateTime.now().toIso8601String(),
          },
        )
        .toList();

    if (rows.isEmpty) return;

    await _client.from('grades').upsert(
          rows,
          onConflict: 'student_id,class_subject_id,term_id',
        );
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
