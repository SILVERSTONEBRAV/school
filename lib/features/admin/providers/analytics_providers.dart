import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(supabaseClientProvider));
});

final analyticsProvider = FutureProvider((ref) {
  return ref.watch(analyticsRepositoryProvider).fetchAnalytics();
});
