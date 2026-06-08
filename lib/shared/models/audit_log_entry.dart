class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    this.actorName,
    this.targetUserId,
    this.details,
    required this.createdAt,
  });

  final String id;
  final String action;
  final String? actorName;
  final String? targetUserId;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    return AuditLogEntry(
      id: json['id'] as String,
      action: json['action'] as String,
      actorName: actor != null
          ? '${actor['first_name'] ?? ''} ${actor['last_name'] ?? ''}'.trim()
          : null,
      targetUserId: json['target_user_id'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
