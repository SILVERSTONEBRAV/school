import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/platform_models.dart';

class PaymentsRepository {
  PaymentsRepository(this._client);

  final SupabaseClient _client;

  Future<List<PaymentMethodConfig>> fetchEnabledMethods(String schoolId) async {
    final data = await _client
        .from('payment_method_configs')
        .select()
        .eq('school_id', schoolId)
        .eq('is_enabled', true)
        .order('sort_order');

    return (data as List)
        .map((e) => PaymentMethodConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentSubmission> submitPayment({
    required String schoolId,
    required String studentId,
    required String submittedBy,
    required String invoiceId,
    required double amount,
    required String channel,
    String? referenceCode,
    String? payerPhone,
    String? proofFileUrl,
    String? notes,
  }) async {
    final data = await _client
        .from('payment_submissions')
        .insert({
          'school_id': schoolId,
          'student_id': studentId,
          'invoice_id': invoiceId,
          'submitted_by': submittedBy,
          'amount': amount,
          'channel': channel,
          'reference_code': referenceCode,
          'payer_phone': payerPhone,
          'proof_file_url': proofFileUrl,
          'notes': notes,
          'status': channel.endsWith('_online') ? 'processing' : 'pending',
        })
        .select(
          '*, student_profiles(profiles(first_name, last_name))',
        )
        .single();

    return PaymentSubmission.fromJson(data);
  }

  Future<List<PaymentSubmission>> fetchPendingSubmissions() async {
    final data = await _client
        .from('payment_submissions')
        .select(
          '*, student_profiles(profiles(first_name, last_name))',
        )
        .inFilter('status', ['pending', 'processing'])
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => PaymentSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PaymentSubmission>> fetchSubmissionsForStudent(
    String studentId,
  ) async {
    final data = await _client
        .from('payment_submissions')
        .select(
          '*, student_profiles(profiles(first_name, last_name))',
        )
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => PaymentSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> confirmSubmission(String submissionId, String confirmedBy) async {
    await _client.rpc('confirm_payment_submission', params: {
      'p_submission_id': submissionId,
      'p_confirmed_by': confirmedBy,
      'p_apply_credit': true,
    });
  }

  Future<void> rejectSubmission(
    String submissionId,
    String reason,
  ) async {
    await _client.from('payment_submissions').update({
      'status': 'rejected',
      'rejection_reason': reason,
    }).eq('id', submissionId);
  }

  Future<List<FeeCredit>> fetchCredits(String studentId) async {
    final data = await _client
        .from('fee_credits')
        .select()
        .eq('student_id', studentId)
        .gt('remaining_amount', 0)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => FeeCredit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> uploadProof({
    required String studentId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$studentId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('payment-proofs').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  /// Placeholder for M-Pesa STK — requires configured API keys in admin settings.
  Future<Map<String, dynamic>> initiateMpesaPayment({
    required String phone,
    required double amount,
    required String reference,
  }) async {
    return {
      'status': 'queued',
      'message': 'M-Pesa STK push queued. Configure API keys in Admin → Payment Settings.',
      'reference': reference,
    };
  }

  /// Placeholder for Stripe — requires configured keys.
  Future<Map<String, dynamic>> initiateStripePayment({
    required double amount,
    required String reference,
  }) async {
    return {
      'status': 'placeholder',
      'message': 'Stripe checkout will open when publishable key is configured.',
      'reference': reference,
    };
  }
}
