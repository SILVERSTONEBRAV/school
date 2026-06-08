class ChildSummary {
  const ChildSummary({
    required this.studentId,
    required this.fullName,
    this.relationship,
    this.rollNumber,
    this.className,
  });

  final String studentId;
  final String fullName;
  final String? relationship;
  final String? rollNumber;
  final String? className;

  factory ChildSummary.fromJson(Map<String, dynamic> json) {
    final student = json['student_profiles'] as Map<String, dynamic>?;
    final profile = student?['profiles'] as Map<String, dynamic>?;
    final enrollments = student?['enrollments'] as List?;
    Map<String, dynamic>? activeEnrollment;
    if (enrollments != null) {
      for (final entry in enrollments) {
        final map = entry as Map<String, dynamic>;
        if (map['status'] == 'active') {
          activeEnrollment = map;
          break;
        }
      }
    }
    final classData = activeEnrollment?['classes'] as Map<String, dynamic>?;

    return ChildSummary(
      studentId: json['student_id'] as String,
      fullName: profile != null
          ? '${profile['first_name']} ${profile['last_name']}'.trim()
          : 'Unknown',
      relationship: json['relationship'] as String?,
      rollNumber: student?['roll_number'] as String?,
      className: classData?['name'] as String?,
    );
  }
}
