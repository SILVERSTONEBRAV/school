class StaffProfileDetails {
  const StaffProfileDetails({
    required this.profileId,
    this.employeeId,
    this.jobTitle,
    this.department,
    this.hireDate,
  });

  final String profileId;
  final String? employeeId;
  final String? jobTitle;
  final String? department;
  final DateTime? hireDate;

  factory StaffProfileDetails.fromJson(Map<String, dynamic> json) {
    return StaffProfileDetails(
      profileId: json['profile_id'] as String,
      employeeId: json['employee_id'] as String?,
      jobTitle: json['job_title'] as String?,
      department: json['department'] as String?,
      hireDate: json['hire_date'] != null
          ? DateTime.parse(json['hire_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'employee_id': employeeId,
        'job_title': jobTitle,
        'department': department,
        'hire_date': hireDate?.toIso8601String().split('T').first,
      };
}
