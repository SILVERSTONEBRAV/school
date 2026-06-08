import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/fee.dart';
import '../../admin/providers/admin_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/fees_repository.dart';

final feesRepositoryProvider = Provider<FeesRepository>((ref) {
  return FeesRepository(ref.watch(supabaseClientProvider));
});

final feeStructuresProvider = FutureProvider<List<FeeStructure>>((ref) async {
  final school = await ref.watch(schoolProvider.future);
  if (school == null) return [];
  return ref.watch(feesRepositoryProvider).fetchFeeStructures(school.id);
});

final invoicesProvider = FutureProvider<List<Invoice>>((ref) {
  return ref.watch(feesRepositoryProvider).fetchInvoices();
});

final paymentsProvider = FutureProvider<List<Payment>>((ref) {
  return ref.watch(feesRepositoryProvider).fetchPayments();
});

final feeStatsProvider = FutureProvider((ref) async {
  final school = await ref.watch(schoolProvider.future);
  if (school == null) {
    return {'totalDue': 0.0, 'totalCollected': 0.0, 'outstanding': 0.0};
  }
  return ref.watch(feesRepositoryProvider).fetchCollectionStats(school.id);
});

final studentFeesProvider = FutureProvider<FeeSummary>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) {
    return const FeeSummary(
      totalDue: 0,
      totalPaid: 0,
      invoices: [],
      payments: [],
    );
  }
  return ref.watch(feesRepositoryProvider).fetchFeeSummary(profile.id);
});
