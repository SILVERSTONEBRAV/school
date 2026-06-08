import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform-aware OAuth / email confirmation redirect URLs for Supabase Auth.
///
/// Add these to Supabase Dashboard → Authentication → URL Configuration → Redirect URLs:
/// - `com.schoolmgmt.app://login-callback`
/// - `com.schoolmgmt.app://login-callback/`
/// - `com.schoolmgmt.app://login-callback/**`
/// - `http://localhost:**` (web dev)
///
/// Google Cloud Console only needs the Supabase callback URL, e.g.
/// `https://<project-ref>.supabase.co/auth/v1/callback`
class AuthRedirectConfig {
  AuthRedirectConfig._();

  static const scheme = 'com.schoolmgmt.app';
  static const host = 'login-callback';
  static const path = '/';

  /// Deep link used by mobile and desktop after OAuth completes in the browser.
  static const desktopRedirect = '$scheme://$host$path';

  /// Redirect URI passed to Supabase for the current platform.
  static String get oauthRedirectUri {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return desktopRedirect;
  }

  /// Email confirmation links for password sign-up.
  static String? get emailRedirectTo => oauthRedirectUri;

  static bool isAuthCallbackUri(Uri uri) {
    if (kIsWeb) {
      return uri.queryParameters.containsKey('code') ||
          uri.fragment.contains('access_token') ||
          uri.fragment.contains('error_description');
    }
    return uri.scheme == scheme && uri.host == host;
  }
}
