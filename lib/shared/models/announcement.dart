class Announcement {
  const Announcement({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.body,
    this.authorName,
    required this.isPinned,
    required this.publishedAt,
  });

  final String id;
  final String schoolId;
  final String title;
  final String body;
  final String? authorName;
  final bool isPinned;
  final DateTime publishedAt;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;

    return Announcement(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      authorName: author != null
          ? '${author['first_name']} ${author['last_name']}'.trim()
          : null,
      isPinned: json['is_pinned'] as bool? ?? false,
      publishedAt: DateTime.parse(json['published_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson({
    required String schoolId,
    required String authorId,
  }) {
    return {
      'school_id': schoolId,
      'title': title,
      'body': body,
      'author_id': authorId,
      'is_pinned': isPinned,
    };
  }
}
