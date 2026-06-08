class ClassSubject {
  const ClassSubject({
    required this.id,
    required this.classId,
    required this.subjectId,
    this.teacherId,
    this.className,
    this.subjectName,
    this.subjectCode,
    this.teacherName,
    required this.creditHours,
  });

  final String id;
  final String classId;
  final String subjectId;
  final String? teacherId;
  final String? className;
  final String? subjectName;
  final String? subjectCode;
  final String? teacherName;
  final double creditHours;

  String get displayName =>
      '${subjectName ?? 'Subject'} (${className ?? 'Class'})';

  factory ClassSubject.fromJson(Map<String, dynamic> json) {
    final classData = json['classes'] as Map<String, dynamic>?;
    final subjectData = json['subjects'] as Map<String, dynamic>?;
    final teacher = json['teacher'] as Map<String, dynamic>?;

    return ClassSubject(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      subjectId: json['subject_id'] as String,
      teacherId: json['teacher_id'] as String?,
      className: classData?['name'] as String?,
      subjectName: subjectData?['name'] as String?,
      subjectCode: subjectData?['code'] as String?,
      teacherName: teacher != null
          ? '${teacher['first_name']} ${teacher['last_name']}'.trim()
          : null,
      creditHours: (json['credit_hours'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'credit_hours': creditHours,
    };
  }
}
