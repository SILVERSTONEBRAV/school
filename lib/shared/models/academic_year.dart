class AcademicYear {
  const AcademicYear({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'school_id': schoolId,
      'name': name,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'is_active': isActive,
    };
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
