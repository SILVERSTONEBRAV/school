import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/academic_year.dart';
import '../../../shared/models/class_subject.dart';
import '../../../shared/models/enrolled_student.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/models/school_class.dart';
import '../../../shared/models/subject.dart';
import '../../../shared/models/term.dart';
import '../../../shared/models/user_role.dart';

class AcademicRepository {
  AcademicRepository(this._client);

  final SupabaseClient _client;

  Future<List<AcademicYear>> fetchAcademicYears(String schoolId) async {
    final data = await _client
        .from('academic_years')
        .select()
        .eq('school_id', schoolId)
        .order('start_date', ascending: false);

    return (data as List)
        .map((item) => AcademicYear.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AcademicYear> saveAcademicYear(AcademicYear year) async {
    if (year.isActive) {
      await _client
          .from('academic_years')
          .update({'is_active': false})
          .eq('school_id', year.schoolId);
    }

    if (year.id.isEmpty) {
      final data = await _client
          .from('academic_years')
          .insert(year.toJson())
          .select()
          .single();
      return AcademicYear.fromJson(data);
    }

    final data = await _client
        .from('academic_years')
        .update(year.toJson())
        .eq('id', year.id)
        .select()
        .single();
    return AcademicYear.fromJson(data);
  }

  Future<List<Term>> fetchTerms(String academicYearId) async {
    final data = await _client
        .from('terms')
        .select()
        .eq('academic_year_id', academicYearId)
        .order('start_date');

    return (data as List)
        .map((item) => Term.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Term> saveTerm(Term term) async {
    if (term.isActive) {
      await _client
          .from('terms')
          .update({'is_active': false})
          .eq('academic_year_id', term.academicYearId);
    }

    if (term.id.isEmpty) {
      final data =
          await _client.from('terms').insert(term.toJson()).select().single();
      return Term.fromJson(data);
    }

    final data = await _client
        .from('terms')
        .update(term.toJson())
        .eq('id', term.id)
        .select()
        .single();
    return Term.fromJson(data);
  }

  Future<List<SchoolClass>> fetchClasses(String schoolId) async {
    final data = await _client
        .from('classes')
        .select('*, class_teacher:profiles!class_teacher_id(first_name, last_name)')
        .eq('school_id', schoolId)
        .order('name');

    return (data as List)
        .map((item) => SchoolClass.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SchoolClass> saveClass(SchoolClass schoolClass) async {
    if (schoolClass.id.isEmpty) {
      final data = await _client
          .from('classes')
          .insert(schoolClass.toJson())
          .select(
            '*, class_teacher:profiles!class_teacher_id(first_name, last_name)',
          )
          .single();
      return SchoolClass.fromJson(data);
    }

    final data = await _client
        .from('classes')
        .update(schoolClass.toJson())
        .eq('id', schoolClass.id)
        .select(
          '*, class_teacher:profiles!class_teacher_id(first_name, last_name)',
        )
        .single();
    return SchoolClass.fromJson(data);
  }

  Future<List<Subject>> fetchSubjects(String schoolId) async {
    final data = await _client
        .from('subjects')
        .select()
        .eq('school_id', schoolId)
        .order('name');

    return (data as List)
        .map((item) => Subject.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Subject> saveSubject(Subject subject) async {
    if (subject.id.isEmpty) {
      final data = await _client
          .from('subjects')
          .insert(subject.toJson())
          .select()
          .single();
      return Subject.fromJson(data);
    }

    final data = await _client
        .from('subjects')
        .update(subject.toJson())
        .eq('id', subject.id)
        .select()
        .single();
    return Subject.fromJson(data);
  }

  Future<List<ClassSubject>> fetchClassSubjects(String classId) async {
    final data = await _client
        .from('class_subjects')
        .select(
          '*, classes(name), subjects(name, code), teacher:profiles!teacher_id(first_name, last_name)',
        )
        .eq('class_id', classId);

    return (data as List)
        .map((item) => ClassSubject.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ClassSubject> assignClassSubject({
    required String classId,
    required String subjectId,
    String? teacherId,
  }) async {
    final data = await _client
        .from('class_subjects')
        .upsert({
          'class_id': classId,
          'subject_id': subjectId,
          'teacher_id': teacherId,
        }, onConflict: 'class_id,subject_id')
        .select(
          '*, classes(name), subjects(name, code), teacher:profiles!teacher_id(first_name, last_name)',
        )
        .single();

    return ClassSubject.fromJson(data);
  }

  Future<List<EnrolledStudent>> fetchEnrollments(String classId) async {
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

  Future<void> enrollStudent({
    required String studentId,
    required String classId,
    required String academicYearId,
  }) async {
    await _client.from('enrollments').upsert({
      'student_id': studentId,
      'class_id': classId,
      'academic_year_id': academicYearId,
      'status': 'active',
    }, onConflict: 'student_id,class_id');
  }

  Future<List<Profile>> fetchStudents() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('role', UserRole.student.dbValue)
        .order('first_name');

    return (data as List)
        .map((item) => Profile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Profile>> fetchTeachers() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('role', UserRole.teacher.dbValue)
        .order('first_name');

    return (data as List)
        .map((item) => Profile.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
