import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';
import '../../features/auth/providers/auth_providers.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});
