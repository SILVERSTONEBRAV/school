import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/fee.dart';

class FeesRepository {
  FeesRepository(this._client);

  final SupabaseClient _client;

  Future<List<FeeStructure>> fetchFeeStructures(String schoolId) async {
    final data = await _client
        .from('fee_structures')
        .select('*, classes(name)')
        .eq('school_id', schoolId)
        .order('name');

    return (data as List)
        .map((item) => FeeStructure.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<FeeStructure> saveFeeStructure(FeeStructure fee) async {
    if (fee.id.isEmpty) {
      final data = await _client
          .from('fee_structures')
          .insert(fee.toJson())
          .select('*, classes(name)')
          .single();
      return FeeStructure.fromJson(data);
    }

    final data = await _client
        .from('fee_structures')
        .update(fee.toJson())
        .eq('id', fee.id)
        .select('*, classes(name)')
        .single();
    return FeeStructure.fromJson(data);
  }

  Future<List<Invoice>> fetchInvoices({String? studentId}) async {
    var query = _client.from('invoices').select(
          '*, fee_structures(name), student_profiles(profiles(first_name, last_name))',
        );

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    final data = await query.order('created_at', ascending: false);

    return (data as List)
        .map((item) => Invoice.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Invoice> createInvoice({
    required String studentId,
    required String feeStructureId,
    required double amount,
    DateTime? dueDate,
  }) async {
    final data = await _client
        .from('invoices')
        .upsert({
          'student_id': studentId,
          'fee_structure_id': feeStructureId,
          'amount': amount,
          'due_date': dueDate != null ? _formatDate(dueDate) : null,
        }, onConflict: 'student_id,fee_structure_id')
        .select(
          '*, fee_structures(name), student_profiles(profiles(first_name, last_name))',
        )
        .single();

    return Invoice.fromJson(data);
  }

  Future<void> assignFeeToClass({
    required String feeStructureId,
    required String classId,
    required double amount,
    DateTime? dueDate,
  }) async {
    final enrollments = await _client
        .from('enrollments')
        .select('student_id')
        .eq('class_id', classId)
        .eq('status', 'active');

    for (final row in enrollments as List) {
      await createInvoice(
        studentId: row['student_id'] as String,
        feeStructureId: feeStructureId,
        amount: amount,
        dueDate: dueDate,
      );
    }
  }

  Future<List<Payment>> fetchPayments({String? studentId}) async {
    var query = _client.from('payments').select(
          '*, invoices(fee_structures(name)), student_profiles(profiles(first_name, last_name))',
        );

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    final data = await query.order('paid_at', ascending: false);

    return (data as List)
        .map((item) => Payment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Payment> recordPayment({
    required String invoiceId,
    required String studentId,
    required double amount,
    required String paymentMethod,
    String? reference,
    required String recordedBy,
  }) async {
    final data = await _client
        .from('payments')
        .insert({
          'invoice_id': invoiceId,
          'student_id': studentId,
          'amount': amount,
          'payment_method': paymentMethod,
          'reference': reference,
          'recorded_by': recordedBy,
        })
        .select(
          '*, invoices(fee_structures(name)), student_profiles(profiles(first_name, last_name))',
        )
        .single();

    return Payment.fromJson(data);
  }

  Future<FeeSummary> fetchFeeSummary(String studentId) async {
    final invoices = await fetchInvoices(studentId: studentId);
    final payments = await fetchPayments(studentId: studentId);

    final totalDue = invoices.fold<double>(0, (sum, inv) => sum + inv.amount);
    final totalPaid = invoices.fold<double>(0, (sum, inv) => sum + inv.amountPaid);

    return FeeSummary(
      totalDue: totalDue,
      totalPaid: totalPaid,
      invoices: invoices,
      payments: payments,
    );
  }

  Future<Map<String, double>> fetchCollectionStats(String schoolId) async {
    final invoices = await _client
        .from('invoices')
        .select('amount, amount_paid, student_profiles!inner(profile_id)');

    double totalDue = 0;
    double totalCollected = 0;

    for (final row in invoices as List) {
      totalDue += (row['amount'] as num).toDouble();
      totalCollected += (row['amount_paid'] as num?)?.toDouble() ?? 0;
    }

    return {
      'totalDue': totalDue,
      'totalCollected': totalCollected,
      'outstanding': totalDue - totalCollected,
    };
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
