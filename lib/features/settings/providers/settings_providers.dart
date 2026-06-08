import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/platform_models.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/settings_repository.dart';

export '../../../shared/models/platform_models.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(supabaseClientProvider));
});

final featureFlagsProvider = FutureProvider((ref) async {
  final school = await ref.watch(schoolIdProvider.future);
  if (school == null) return <FeatureFlag>[];
  return ref.watch(settingsRepositoryProvider).fetchFeatureFlags(school);
});

final paymentMethodConfigsProvider = FutureProvider((ref) async {
  final school = await ref.watch(schoolIdProvider.future);
  if (school == null) return <PaymentMethodConfig>[];
  return ref.watch(settingsRepositoryProvider).fetchPaymentMethods(school);
});

final schoolIdProvider = FutureProvider<String?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('schools')
      .select('id')
      .order('created_at')
      .limit(1)
      .maybeSingle();
  return data?['id'] as String?;
});

final featureEnabledProvider =
    FutureProvider.family<bool, String>((ref, featureKey) async {
  final schoolId = await ref.watch(schoolIdProvider.future);
  if (schoolId == null) return false;
  return ref
      .watch(settingsRepositoryProvider)
      .isFeatureEnabled(schoolId, featureKey);
});
