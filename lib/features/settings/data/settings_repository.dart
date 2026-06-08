import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/platform_models.dart';

class SettingsRepository {
  SettingsRepository(this._client);

  final SupabaseClient _client;

  Future<List<FeatureFlag>> fetchFeatureFlags(String schoolId) async {
    final data = await _client
        .from('feature_flags')
        .select()
        .eq('school_id', schoolId)
        .order('feature_key');

    return (data as List)
        .map((e) => FeatureFlag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateFeatureFlag(FeatureFlag flag) async {
    await _client.from('feature_flags').upsert({
      'id': flag.id.isNotEmpty ? flag.id : null,
      'school_id': flag.schoolId,
      'feature_key': flag.featureKey,
      'is_enabled': flag.isEnabled,
      'config': flag.config,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'school_id,feature_key');
  }

  Future<List<PaymentMethodConfig>> fetchPaymentMethods(String schoolId) async {
    final data = await _client
        .from('payment_method_configs')
        .select()
        .eq('school_id', schoolId)
        .order('sort_order');

    return (data as List)
        .map((e) => PaymentMethodConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updatePaymentMethod(PaymentMethodConfig config) async {
    await _client
        .from('payment_method_configs')
        .update(config.toJson())
        .eq('id', config.id);
  }

  Future<bool> isFeatureEnabled(String schoolId, String featureKey) async {
    final data = await _client
        .from('feature_flags')
        .select('is_enabled')
        .eq('school_id', schoolId)
        .eq('feature_key', featureKey)
        .maybeSingle();

    return data?['is_enabled'] as bool? ?? false;
  }
}
