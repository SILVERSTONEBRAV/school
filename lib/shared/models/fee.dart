enum InvoiceStatus {
  pending,
  partial,
  paid,
  overdue;

  String get label => switch (this) {
        InvoiceStatus.pending => 'Pending',
        InvoiceStatus.partial => 'Partial',
        InvoiceStatus.paid => 'Paid',
        InvoiceStatus.overdue => 'Overdue',
      };

  String get dbValue => name;

  static InvoiceStatus fromDb(String value) {
    return InvoiceStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => InvoiceStatus.pending,
    );
  }
}

class FeeStructure {
  const FeeStructure({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.amount,
    this.description,
    this.academicYearId,
    this.classId,
    this.dueDate,
    this.className,
    required this.createdAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final double amount;
  final String? description;
  final String? academicYearId;
  final String? classId;
  final DateTime? dueDate;
  final String? className;
  final DateTime createdAt;

  factory FeeStructure.fromJson(Map<String, dynamic> json) {
    final classData = json['classes'] as Map<String, dynamic>?;

    return FeeStructure(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      academicYearId: json['academic_year_id'] as String?,
      classId: json['class_id'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      className: classData?['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'school_id': schoolId,
      'name': name,
      'amount': amount,
      'description': description,
      'academic_year_id': academicYearId,
      'class_id': classId,
      'due_date': dueDate != null ? _formatDate(dueDate!) : null,
    };
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.studentId,
    required this.feeStructureId,
    required this.amount,
    required this.amountPaid,
    required this.status,
    this.dueDate,
    this.feeName,
    this.studentName,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final String feeStructureId;
  final double amount;
  final double amountPaid;
  final InvoiceStatus status;
  final DateTime? dueDate;
  final String? feeName;
  final String? studentName;
  final DateTime createdAt;

  double get balance => amount - amountPaid;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final fee = json['fee_structures'] as Map<String, dynamic>?;
    final student = json['student_profiles'] as Map<String, dynamic>?;
    final profile = student?['profiles'] as Map<String, dynamic>?;

    return Invoice(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      feeStructureId: json['fee_structure_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      status: InvoiceStatus.fromDb(json['status'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      feeName: fee?['name'] as String?,
      studentName: profile != null
          ? '${profile['first_name']} ${profile['last_name']}'.trim()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.invoiceId,
    required this.studentId,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    this.feeName,
    this.studentName,
    required this.paidAt,
  });

  final String id;
  final String invoiceId;
  final String studentId;
  final double amount;
  final String paymentMethod;
  final String? reference;
  final String? feeName;
  final String? studentName;
  final DateTime paidAt;

  factory Payment.fromJson(Map<String, dynamic> json) {
    final invoice = json['invoices'] as Map<String, dynamic>?;
    final fee = invoice?['fee_structures'] as Map<String, dynamic>?;
    final student = json['student_profiles'] as Map<String, dynamic>?;
    final profile = student?['profiles'] as Map<String, dynamic>?;

    return Payment(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String,
      studentId: json['student_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      reference: json['reference'] as String?,
      feeName: fee?['name'] as String?,
      studentName: profile != null
          ? '${profile['first_name']} ${profile['last_name']}'.trim()
          : null,
      paidAt: DateTime.parse(json['paid_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson(String recordedBy) {
    return {
      'invoice_id': invoiceId,
      'student_id': studentId,
      'amount': amount,
      'payment_method': paymentMethod,
      'reference': reference,
      'recorded_by': recordedBy,
    };
  }
}

class FeeSummary {
  const FeeSummary({
    required this.totalDue,
    required this.totalPaid,
    required this.invoices,
    required this.payments,
  });

  final double totalDue;
  final double totalPaid;
  final List<Invoice> invoices;
  final List<Payment> payments;

  double get outstanding => totalDue - totalPaid;
}
