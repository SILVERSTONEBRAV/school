enum SubmissionStatus {
  submitted,
  graded,
  late;

  String get label => switch (this) {
        SubmissionStatus.submitted => 'Submitted',
        SubmissionStatus.graded => 'Graded',
        SubmissionStatus.late => 'Late',
      };

  String get dbValue => name;

  static SubmissionStatus fromDb(String value) {
    return SubmissionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SubmissionStatus.submitted,
    );
  }
}

class Assignment {
  const Assignment({
    required this.id,
    required this.classSubjectId,
    required this.title,
    this.description,
    required this.dueDate,
    required this.maxScore,
    this.createdBy,
    this.subjectName,
    this.className,
    required this.createdAt,
  });

  final String id;
  final String classSubjectId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final double maxScore;
  final String? createdBy;
  final String? subjectName;
  final String? className;
  final DateTime createdAt;

  bool get isOverdue => DateTime.now().isAfter(dueDate);

  String get displayName =>
      '${subjectName ?? 'Subject'} — $title';

  factory Assignment.fromJson(Map<String, dynamic> json) {
    final classSubject = json['class_subjects'] as Map<String, dynamic>?;
    final subject = classSubject?['subjects'] as Map<String, dynamic>?;
    final classData = classSubject?['classes'] as Map<String, dynamic>?;

    return Assignment(
      id: json['id'] as String,
      classSubjectId: json['class_subject_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 100,
      createdBy: json['created_by'] as String?,
      subjectName: subject?['name'] as String?,
      className: classData?['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson(String createdBy) {
    return {
      'class_subject_id': classSubjectId,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'max_score': maxScore,
      'created_by': createdBy,
    };
  }
}

class Submission {
  const Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.content,
    this.fileUrl,
    this.score,
    this.feedback,
    required this.status,
    required this.submittedAt,
    this.studentName,
    this.assignmentTitle,
  });

  final String id;
  final String assignmentId;
  final String studentId;
  final String? content;
  final String? fileUrl;
  final double? score;
  final String? feedback;
  final SubmissionStatus status;
  final DateTime submittedAt;
  final String? studentName;
  final String? assignmentTitle;

  factory Submission.fromJson(Map<String, dynamic> json) {
    final student = json['student_profiles'] as Map<String, dynamic>?;
    final profile = student?['profiles'] as Map<String, dynamic>?;
    final assignment = json['assignments'] as Map<String, dynamic>?;

    return Submission(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      studentId: json['student_id'] as String,
      content: json['content'] as String?,
      fileUrl: json['file_url'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      status: SubmissionStatus.fromDb(json['status'] as String),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      studentName: profile != null
          ? '${profile['first_name']} ${profile['last_name']}'.trim()
          : null,
      assignmentTitle: assignment?['title'] as String?,
    );
  }

  Map<String, dynamic> toSubmitJson() {
    return {
      'assignment_id': assignmentId,
      'student_id': studentId,
      'content': content,
      'file_url': fileUrl,
      'status': status.dbValue,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toGradeJson(String gradedBy, double score, String? feedback) {
    return {
      'score': score,
      'feedback': feedback,
      'status': SubmissionStatus.graded.dbValue,
      'graded_by': gradedBy,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
