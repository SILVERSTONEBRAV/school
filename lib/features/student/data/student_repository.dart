import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/attendance.dart';
import '../../../shared/models/class_subject.dart';
import '../../../shared/models/grade_record.dart';
import '../../../shared/models/school_class.dart';

class StudentAcademics {
  const StudentAcademics({
    this.enrolledClass,
    required this.subjects,
    required this.grades,
    required this.attendance,
    this.fromCache = false,
    this.cachedClassName,
    this.cachedAttendancePercentage,
  });

  final SchoolClass? enrolledClass;
  final List<ClassSubject> subjects;
  final List<GradeRecord> grades;
  final List<AttendanceRecord> attendance;
  final bool fromCache;
  final String? cachedClassName;
  final double? cachedAttendancePercentage;

  String? get displayClassName => enrolledClass?.name ?? cachedClassName;

  double get attendancePercentage {
    if (fromCache && cachedAttendancePercentage != null) {
      return cachedAttendancePercentage!;
    }
    if (attendance.isEmpty) return 0;
    final present = attendance.where(
      (record) =>
          record.status == AttendanceStatus.present ||
          record.status == AttendanceStatus.late,
    );
    return (present.length / attendance.length) * 100;
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'className': enrolledClass?.name,
      'attendancePercentage': attendancePercentage,
      'grades': grades
          .map(
            (g) => {
              'subjectName': g.subjectName,
              'termName': g.termName,
              'score': g.score,
            },
          )
          .toList(),
    };
  }

  factory StudentAcademics.fromCache(Map<String, dynamic> json) {
    final grades = (json['grades'] as List? ?? [])
        .map(
          (g) => GradeRecord(
            id: '',
            studentId: '',
            classSubjectId: '',
            termId: '',
            score: (g['score'] as num).toDouble(),
            subjectName: g['subjectName'] as String?,
            termName: g['termName'] as String?,
          ),
        )
        .toList();

    return StudentAcademics(
      subjects: const [],
      grades: grades,
      attendance: const [],
      fromCache: true,
      cachedClassName: json['className'] as String?,
      cachedAttendancePercentage:
          (json['attendancePercentage'] as num?)?.toDouble(),
    );
  }
}

class StudentRepository {
  StudentRepository(this._client);

  final SupabaseClient _client;

  Future<StudentAcademics> fetchAcademics(String studentId) async {
    final enrollment = await _client
        .from('enrollments')
        .select('*, classes(*)')
        .eq('student_id', studentId)
        .eq('status', 'active')
        .maybeSingle();

    SchoolClass? enrolledClass;
    List<ClassSubject> subjects = [];

    if (enrollment != null) {
      final classData = enrollment['classes'] as Map<String, dynamic>?;
      if (classData != null) {
        enrolledClass = SchoolClass.fromJson(classData);

        final subjectData = await _client
            .from('class_subjects')
            .select(
              '*, classes(name), subjects(name, code), teacher:profiles!teacher_id(first_name, last_name)',
            )
            .eq('class_id', enrolledClass.id);

        subjects = (subjectData as List)
            .map((item) => ClassSubject.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    final gradesData = await _client
        .from('grades')
        .select(
          '*, student_profiles(profiles(first_name, last_name)), class_subjects(subjects(name)), terms(name)',
        )
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    final attendanceData = await _client
        .from('attendance')
        .select()
        .eq('student_id', studentId)
        .order('date', ascending: false)
        .limit(60);

    return StudentAcademics(
      enrolledClass: enrolledClass,
      subjects: subjects,
      grades: (gradesData as List)
          .map((item) => GradeRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      attendance: (attendanceData as List)
          .map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
