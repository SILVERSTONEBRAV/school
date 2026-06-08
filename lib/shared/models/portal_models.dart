class GalleryPost {
  const GalleryPost({
    required this.id,
    required this.caption,
    required this.imageUrl,
    required this.createdAt,
    this.authorName,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String? caption;
  final String imageUrl;
  final DateTime createdAt;
  final String? authorName;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  GalleryPost copyWith({int? likeCount, int? commentCount, bool? likedByMe}) {
    return GalleryPost(
      id: id,
      caption: caption,
      imageUrl: imageUrl,
      createdAt: createdAt,
      authorName: authorName,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  factory GalleryPost.fromJson(Map<String, dynamic> json) {
    final author = json['profiles'] as Map<String, dynamic>?;
    return GalleryPost(
      id: json['id'] as String,
      caption: json['caption'] as String?,
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: author != null
          ? '${author['first_name']} ${author['last_name']}'.trim()
          : null,
    );
  }
}

class GalleryComment {
  const GalleryComment({
    required this.id,
    required this.body,
    required this.authorName,
    required this.createdAt,
  });

  final String id;
  final String body;
  final String authorName;
  final DateTime createdAt;

  factory GalleryComment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return GalleryComment(
      id: json['id'] as String,
      body: json['body'] as String,
      authorName: profile != null
          ? '${profile['first_name']} ${profile['last_name']}'.trim()
          : 'User',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CourseMaterial {
  const CourseMaterial({
    required this.id,
    required this.classSubjectId,
    required this.title,
    required this.fileUrl,
    this.description,
    this.fileName,
    this.materialType,
    required this.createdAt,
  });

  final String id;
  final String classSubjectId;
  final String title;
  final String fileUrl;
  final String? description;
  final String? fileName;
  final String? materialType;
  final DateTime createdAt;

  factory CourseMaterial.fromJson(Map<String, dynamic> json) {
    return CourseMaterial(
      id: json['id'] as String,
      classSubjectId: json['class_subject_id'] as String,
      title: json['title'] as String,
      fileUrl: json['file_url'] as String,
      description: json['description'] as String?,
      fileName: json['file_name'] as String?,
      materialType: json['material_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson(String uploadedBy) => {
        'class_subject_id': classSubjectId,
        'title': title,
        'description': description,
        'file_url': fileUrl,
        'file_name': fileName,
        'material_type': materialType ?? 'document',
        'uploaded_by': uploadedBy,
      };
}

class PortalFaq {
  const PortalFaq({
    required this.id,
    required this.question,
    required this.answer,
    this.category,
  });

  final String id;
  final String question;
  final String answer;
  final String? category;

  factory PortalFaq.fromJson(Map<String, dynamic> json) => PortalFaq(
        id: json['id'] as String,
        question: json['question'] as String,
        answer: json['answer'] as String,
        category: json['category'] as String?,
      );

  Map<String, dynamic> toJson(String schoolId) => {
        'school_id': schoolId,
        'question': question,
        'answer': answer,
        'category': category,
      };
}

class PortalDownload {
  const PortalDownload({
    required this.id,
    required this.title,
    required this.fileUrl,
    this.description,
    this.category,
  });

  final String id;
  final String title;
  final String fileUrl;
  final String? description;
  final String? category;

  factory PortalDownload.fromJson(Map<String, dynamic> json) => PortalDownload(
        id: json['id'] as String,
        title: json['title'] as String,
        fileUrl: json['file_url'] as String,
        description: json['description'] as String?,
        category: json['category'] as String?,
      );
}

class PortalReview {
  const PortalReview({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.body,
    this.reviewerRole,
    this.isPublished = false,
  });

  final String id;
  final String reviewerName;
  final int rating;
  final String body;
  final String? reviewerRole;
  final bool isPublished;

  factory PortalReview.fromJson(Map<String, dynamic> json) => PortalReview(
        id: json['id'] as String,
        reviewerName: json['reviewer_name'] as String,
        rating: json['rating'] as int,
        body: json['body'] as String,
        reviewerRole: json['reviewer_role'] as String?,
        isPublished: json['is_published'] as bool? ?? false,
      );
}

class PortalSuccessStory {
  const PortalSuccessStory({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.authorName,
  });

  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? authorName;

  factory PortalSuccessStory.fromJson(Map<String, dynamic> json) =>
      PortalSuccessStory(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        imageUrl: json['image_url'] as String?,
        authorName: json['author_name'] as String?,
      );
}

class PortalContact {
  const PortalContact({
    required this.id,
    required this.department,
    this.contactName,
    this.email,
    this.phone,
  });

  final String id;
  final String department;
  final String? contactName;
  final String? email;
  final String? phone;

  factory PortalContact.fromJson(Map<String, dynamic> json) => PortalContact(
        id: json['id'] as String,
        department: json['department'] as String,
        contactName: json['contact_name'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
      );
}

class PortalAppRelease {
  const PortalAppRelease({
    required this.id,
    required this.schoolId,
    required this.platform,
    this.downloadUrl,
    this.version,
    this.releaseNotes,
    this.isEnabled = true,
    this.sortOrder = 0,
  });

  final String id;
  final String schoolId;
  final String platform;
  final String? downloadUrl;
  final String? version;
  final String? releaseNotes;
  final bool isEnabled;
  final int sortOrder;

  factory PortalAppRelease.fromJson(Map<String, dynamic> json) =>
      PortalAppRelease(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        platform: json['platform'] as String,
        downloadUrl: json['download_url'] as String?,
        version: json['version'] as String?,
        releaseNotes: json['release_notes'] as String?,
        isEnabled: json['is_enabled'] as bool? ?? true,
        sortOrder: json['sort_order'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'download_url': downloadUrl,
        'version': version,
        'release_notes': releaseNotes,
        'is_enabled': isEnabled,
        'sort_order': sortOrder,
      };
}

class PortalHelpArticle {
  const PortalHelpArticle({
    required this.id,
    required this.title,
    required this.body,
    this.category,
  });

  final String id;
  final String title;
  final String body;
  final String? category;

  factory PortalHelpArticle.fromJson(Map<String, dynamic> json) =>
      PortalHelpArticle(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        category: json['category'] as String?,
      );
}
