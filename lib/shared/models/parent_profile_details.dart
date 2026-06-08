class ParentProfileDetails {
  const ParentProfileDetails({
    required this.profileId,
    this.address,
    this.occupation,
  });

  final String profileId;
  final String? address;
  final String? occupation;

  factory ParentProfileDetails.fromJson(Map<String, dynamic> json) {
    return ParentProfileDetails(
      profileId: json['profile_id'] as String,
      address: json['address'] as String?,
      occupation: json['occupation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'address': address,
        'occupation': occupation,
      };
}
