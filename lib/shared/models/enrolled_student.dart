class EnrolledStudent {
  const EnrolledStudent({
    required this.enrollmentId,
    required this.studentId,
    required this.classId,
    required this.fullName,
    this.rollNumber,
    this.email,
  });

  final String enrollmentId;
  final String studentId;
  final String classId;
  final String fullName;
  final String? rollNumber;
  final String? email;

  factory EnrolledStudent.fromJson(Map<String, dynamic> json) {
    final student = json['student_profiles'] as Map<String, dynamic>?;
    final profile = student?['profiles'] as Map<String, dynamic>?;

    return EnrolledStudent(
      enrollmentId: json['id'] as String,
      studentId: json['student_id'] as String,
      classId: json['class_id'] as String,
      fullName: profile != null
          ? '${profile['first_name']} ${profile['last_name']}'.trim()
          : 'Unknown',
      rollNumber: student?['roll_number'] as String?,
      email: profile?['email'] as String?,
    );
  }
}
