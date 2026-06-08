class AtRiskStudent {
  const AtRiskStudent({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.attendanceRate,
    required this.totalDays,
  });

  final String studentId;
  final String firstName;
  final String lastName;
  final String email;
  final double attendanceRate;
  final int totalDays;

  String get fullName => '$firstName $lastName'.trim();

  factory AtRiskStudent.fromJson(Map<String, dynamic> json) {
    return AtRiskStudent(
      studentId: json['student_id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0,
      totalDays: json['total_days'] as int? ?? 0,
    );
  }
}
