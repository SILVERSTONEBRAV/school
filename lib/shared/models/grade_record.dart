class GradeRecord {
  const GradeRecord({
    required this.id,
    required this.studentId,
    required this.classSubjectId,
    required this.termId,
    required this.score,
    this.gradeLetter,
    this.comments,
    this.studentName,
    this.subjectName,
    this.termName,
  });

  final String id;
  final String studentId;
  final String classSubjectId;
  final String termId;
  final double score;
  final String? gradeLetter;
  final String? comments;
  final String? studentName;
  final String? subjectName;
  final String? termName;

  factory GradeRecord.fromJson(Map<String, dynamic> json) {
    final classSubject = json['class_subjects'] as Map<String, dynamic>?;
    final subject = classSubject?['subjects'] as Map<String, dynamic>?;
    final student = json['student_profiles'] as Map<String, dynamic>?;
    final profile = student?['profiles'] as Map<String, dynamic>?;
    final term = json['terms'] as Map<String, dynamic>?;

    return GradeRecord(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      classSubjectId: json['class_subject_id'] as String,
      termId: json['term_id'] as String,
      score: (json['score'] as num).toDouble(),
      gradeLetter: json['grade_letter'] as String?,
      comments: json['comments'] as String?,
      studentName: profile != null
          ? '${profile['first_name']} ${profile['last_name']}'.trim()
          : null,
      subjectName: subject?['name'] as String?,
      termName: term?['name'] as String?,
    );
  }

  Map<String, dynamic> toUpsertJson(String gradedBy) {
    return {
      'student_id': studentId,
      'class_subject_id': classSubjectId,
      'term_id': termId,
      'score': score,
      'grade_letter': gradeLetter,
      'comments': comments,
      'graded_by': gradedBy,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
