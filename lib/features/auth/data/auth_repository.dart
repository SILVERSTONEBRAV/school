import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/auth_redirect_config.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/models/user_role.dart';
import '../models/sign_up_result.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
    String? phoneNumber,
    String? inviteToken,
  }) async {
    if (!UserRole.selfRegistrationRoles.contains(role) && inviteToken == null) {
      throw const AuthException(
        'This role requires an invite from your school administrator.',
      );
    }

    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: AuthRedirectConfig.emailRedirectTo,
      data: {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'role': role.dbValue,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber.trim(),
        if (inviteToken != null && inviteToken.isNotEmpty)
          'invite_token': inviteToken.trim(),
      },
    );

    if (response.user == null) {
      throw const AuthException('Registration failed. Please try again.');
    }

    return SignUpResult(
      needsEmailConfirmation: response.session == null,
      hasSession: response.session != null,
    );
  }

  Future<void> signInWithGoogle() async {
    final redirectTo = AuthRedirectConfig.oauthRedirectUri;
    final launched = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      queryParams: const {
        'prompt': 'select_account',
      },
    );

    if (!launched) {
      throw const AuthException('Could not open the Google sign-in page.');
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: AuthRedirectConfig.emailRedirectTo,
    );
  }

  Future<void> updatePassword({required String newPassword}) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
