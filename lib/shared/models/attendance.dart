enum AttendanceStatus {
  present,
  absent,
  late,
  excused;

  String get label => switch (this) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.late => 'Late',
        AttendanceStatus.excused => 'Excused',
      };

  String get dbValue => name;

  static AttendanceStatus fromDb(String value) {
    return AttendanceStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AttendanceStatus.present,
    );
  }
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    this.remarks,
    this.studentName,
  });

  final String id;
  final String studentId;
  final String classId;
  final DateTime date;
  final AttendanceStatus status;
  final String? remarks;
  final String? studentName;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final student = json['student_profiles'] as Map<String, dynamic>?;
    final profile = student?['profiles'] as Map<String, dynamic>?;

    return AttendanceRecord(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      classId: json['class_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatus.fromDb(json['status'] as String),
      remarks: json['remarks'] as String?,
      studentName: profile != null
          ? '${profile['first_name']} ${profile['last_name']}'.trim()
          : null,
    );
  }

  Map<String, dynamic> toInsertJson(String markedBy) {
    return {
      'student_id': studentId,
      'class_id': classId,
      'date': _formatDate(date),
      'status': status.dbValue,
      'remarks': remarks,
      'marked_by': markedBy,
    };
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
