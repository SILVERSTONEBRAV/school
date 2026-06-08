class StudentProfileDetails {
  const StudentProfileDetails({
    required this.profileId,
    this.rollNumber,
    this.dateOfBirth,
    this.admissionDate,
  });

  final String profileId;
  final String? rollNumber;
  final DateTime? dateOfBirth;
  final DateTime? admissionDate;

  factory StudentProfileDetails.fromJson(Map<String, dynamic> json) {
    return StudentProfileDetails(
      profileId: json['profile_id'] as String,
      rollNumber: json['roll_number'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      admissionDate: json['admission_date'] != null
          ? DateTime.parse(json['admission_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'roll_number': rollNumber,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'admission_date': admissionDate?.toIso8601String().split('T').first,
      };
}
