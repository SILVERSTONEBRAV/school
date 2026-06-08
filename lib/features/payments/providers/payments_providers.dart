import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/platform_models.dart';
import '../../auth/providers/auth_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../data/payments_repository.dart';

export '../../../shared/models/platform_models.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(supabaseClientProvider));
});

final enabledPaymentMethodsProvider = FutureProvider((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);
  if (schoolId == null) return <PaymentMethodConfig>[];
  return ref.watch(paymentsRepositoryProvider).fetchEnabledMethods(schoolId);
});

final pendingPaymentsProvider = FutureProvider((ref) async {
  return ref.watch(paymentsRepositoryProvider).fetchPendingSubmissions();
});

final studentPaymentSubmissionsProvider =
    FutureProvider.family<List<PaymentSubmission>, String>((ref, studentId) {
  return ref.watch(paymentsRepositoryProvider).fetchSubmissionsForStudent(studentId);
});

final feeCreditsProvider =
    FutureProvider.family<List<FeeCredit>, String>((ref, studentId) {
  return ref.watch(paymentsRepositoryProvider).fetchCredits(studentId);
});
