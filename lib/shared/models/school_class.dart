class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.schoolId,
    required this.academicYearId,
    required this.name,
    this.classTeacherId,
    this.classTeacherName,
    required this.createdAt,
  });

  final String id;
  final String schoolId;
  final String academicYearId;
  final String name;
  final String? classTeacherId;
  final String? classTeacherName;
  final DateTime createdAt;

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    final teacher = json['class_teacher'] as Map<String, dynamic>?;
    return SchoolClass(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      name: json['name'] as String,
      classTeacherId: json['class_teacher_id'] as String?,
      classTeacherName: teacher != null
          ? '${teacher['first_name']} ${teacher['last_name']}'.trim()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'school_id': schoolId,
      'academic_year_id': academicYearId,
      'name': name,
      'class_teacher_id': classTeacherId,
    };
  }
}
