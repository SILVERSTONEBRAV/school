/// Admin-toggleable platform features. API keys stored in [config] JSON.
class FeatureKeys {
  FeatureKeys._();

  static const qrCheckin = 'qr_checkin';
  static const aiGradePredictions = 'ai_grade_predictions';
  static const smsPushAlerts = 'sms_push_alerts';
  static const timetableGenerator = 'timetable_generator';
  static const documentVault = 'document_vault';
  static const multiSchool = 'multi_school';
  static const facialRecognition = 'facial_recognition';
  static const aiChatbot = 'ai_chatbot';
  static const blockchainCredentials = 'blockchain_credentials';
  static const gallery = 'gallery';
  static const schoolPortal = 'school_portal';
  static const courseMaterials = 'course_materials';
  static const inAppNotifications = 'in_app_notifications';

  static const all = [
    qrCheckin,
    aiGradePredictions,
    smsPushAlerts,
    timetableGenerator,
    documentVault,
    multiSchool,
    facialRecognition,
    aiChatbot,
    blockchainCredentials,
    gallery,
    schoolPortal,
    courseMaterials,
    inAppNotifications,
  ];

  static String label(String key) => switch (key) {
        qrCheckin => 'QR Gate Check-in',
        aiGradePredictions => 'AI Grade Predictions',
        smsPushAlerts => 'SMS / Push Alerts',
        timetableGenerator => 'AI Timetable Generator',
        documentVault => 'Document Vault',
        multiSchool => 'Multi-School Mode',
        facialRecognition => 'Facial Recognition Attendance',
        aiChatbot => 'AI School Assistant',
        blockchainCredentials => 'Blockchain Credentials',
        gallery => 'Community Gallery',
        schoolPortal => 'School Portal',
        courseMaterials => 'Course Materials Upload',
        inAppNotifications => 'In-App Notifications',
        _ => key,
      };
}

class FeatureFlag {
  const FeatureFlag({
    required this.id,
    required this.schoolId,
    required this.featureKey,
    required this.isEnabled,
    required this.config,
  });

  final String id;
  final String schoolId;
  final String featureKey;
  final bool isEnabled;
  final Map<String, dynamic> config;

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      featureKey: json['feature_key'] as String,
      isEnabled: json['is_enabled'] as bool? ?? false,
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'school_id': schoolId,
        'feature_key': featureKey,
        'is_enabled': isEnabled,
        'config': config,
      };
}

class PaymentMethodConfig {
  const PaymentMethodConfig({
    required this.id,
    required this.schoolId,
    required this.channel,
    required this.isEnabled,
    required this.displayName,
    required this.config,
    this.instructions,
  });

  final String id;
  final String schoolId;
  final String channel;
  final bool isEnabled;
  final String displayName;
  final Map<String, dynamic> config;
  final String? instructions;

  bool get isManual =>
      channel.startsWith('manual_');

  bool get isOnline =>
      channel.endsWith('_online');

  factory PaymentMethodConfig.fromJson(Map<String, dynamic> json) {
    return PaymentMethodConfig(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      channel: json['channel'] as String,
      isEnabled: json['is_enabled'] as bool? ?? false,
      displayName: json['display_name'] as String,
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_enabled': isEnabled,
        'display_name': displayName,
        'config': config,
        'instructions': instructions,
      };
}

enum PaymentSubmissionStatus {
  pending,
  confirmed,
  rejected,
  processing;

  String get label => name[0].toUpperCase() + name.substring(1);

  static PaymentSubmissionStatus fromDb(String v) =>
      PaymentSubmissionStatus.values.firstWhere((e) => e.name == v);
}

class PaymentSubmission {
  const PaymentSubmission({
    required this.id,
    required this.studentId,
    this.invoiceId,
    required this.submittedBy,
    required this.amount,
    required this.channel,
    this.referenceCode,
    this.payerPhone,
    this.proofFileUrl,
    required this.status,
    this.excessAmount = 0,
    this.studentName,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final String? invoiceId;
  final String submittedBy;
  final double amount;
  final String channel;
  final String? referenceCode;
  final String? payerPhone;
  final String? proofFileUrl;
  final PaymentSubmissionStatus status;
  final double excessAmount;
  final String? studentName;
  final DateTime createdAt;

  factory PaymentSubmission.fromJson(Map<String, dynamic> json) {
    final student = json['student_profiles'] as Map<String, dynamic>?;
    final profile = student?['profiles'] as Map<String, dynamic>?;
    return PaymentSubmission(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      invoiceId: json['invoice_id'] as String?,
      submittedBy: json['submitted_by'] as String,
      amount: (json['amount'] as num).toDouble(),
      channel: json['channel'] as String,
      referenceCode: json['reference_code'] as String?,
      payerPhone: json['payer_phone'] as String?,
      proofFileUrl: json['proof_file_url'] as String?,
      status: PaymentSubmissionStatus.fromDb(json['status'] as String),
      excessAmount: (json['excess_amount'] as num?)?.toDouble() ?? 0,
      studentName: profile != null
          ? '${profile['first_name']} ${profile['last_name']}'.trim()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class FeeCredit {
  const FeeCredit({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.remainingAmount,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final double amount;
  final double remainingAmount;
  final String? notes;
  final DateTime createdAt;

  factory FeeCredit.fromJson(Map<String, dynamic> json) {
    return FeeCredit(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
