class Subject {
  const Subject({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.code,
    required this.createdAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final String code;
  final DateTime createdAt;

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'school_id': schoolId,
      'name': name,
      'code': code,
    };
  }
}
