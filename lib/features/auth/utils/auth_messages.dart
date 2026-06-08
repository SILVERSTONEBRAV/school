import 'package:supabase_flutter/supabase_flutter.dart';

String friendlyAuthMessage(Object error) {
  if (error is PostgrestException) {
    final message = error.message.toLowerCase();
    if (message.contains('infinite recursion')) {
      return 'Profile access is misconfigured in the database. '
          'Apply the latest Supabase migration (fix_rls_recursion).';
    }
    if (message.contains('profiles')) {
      return 'Could not load your profile. Contact your school administrator.';
    }
    return error.message;
  }

  if (error is AuthException) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (message.contains('user already registered')) {
      return 'An account with this email already exists. Try signing in.';
    }
    if (message.contains('password')) {
      return error.message;
    }
    if (message.contains('email') && message.contains('send')) {
      return 'Account may have been created, but we could not send a confirmation email. Try signing in or contact your school admin.';
    }
    return error.message;
  }

  return error.toString();
}
