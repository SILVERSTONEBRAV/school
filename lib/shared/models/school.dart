class School {
  const School({
    required this.id,
    required this.name,
    this.logoUrl,
    this.motto,
    this.tagline,
    this.mission,
    this.vision,
    this.about,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.establishedYear,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? motto;
  final String? tagline;
  final String? mission;
  final String? vision;
  final String? about;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final int? establishedYear;
  final DateTime createdAt;

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      motto: json['motto'] as String?,
      tagline: json['tagline'] as String?,
      mission: json['mission'] as String?,
      vision: json['vision'] as String?,
      about: json['about'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mapUrl: json['map_url'] as String?,
      establishedYear: json['established_year'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'logo_url': logoUrl,
      'motto': motto,
      'tagline': tagline,
      'mission': mission,
      'vision': vision,
      'about': about,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'latitude': latitude,
      'longitude': longitude,
      'map_url': mapUrl,
      'established_year': establishedYear,
    };
  }
}
