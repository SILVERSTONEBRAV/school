import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/profile.dart';
import '../data/auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final session = authState.value?.session;

  if (session == null) return null;

  final profile =
      await ref.watch(authRepositoryProvider).fetchProfile(session.user.id);

  if (profile == null) {
    throw StateError(
      'Your account exists but your profile is not set up yet. '
      'Contact your school administrator or try signing out and back in.',
    );
  }

  return profile;
});
