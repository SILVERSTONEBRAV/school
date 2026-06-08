import 'package:flutter/foundation.dart' show kIsWeb;

import '../constants/app_routes.dart';

class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://auanvazqxlqbrnxmmkhk.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1YW52YXpxeGxxYnJueG1ta2hrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4NDgxOTcsImV4cCI6MjA5NjQyNDE5N30.9CzEqrYLFSJTzflCfIpyS_ZkX5o94Mrw9qJQ-yE4tho',
  );

  /// Flutter web app URL (login, dashboards). e.g. https://app.yourschool.com
  static const String appBaseUrl = String.fromEnvironment('APP_BASE_URL');

  /// Public Next.js website URL. e.g. https://yourschool.com
  static const String publicWebsiteUrl = String.fromEnvironment(
    'PUBLIC_WEBSITE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String appName = 'School Management';

  static String registrationInviteUrl(String token) {
    final path = '${AppRoutes.register}?invite=$token';
    if (kIsWeb) return '${Uri.base.origin}$path';
    if (appBaseUrl.isNotEmpty) return '$appBaseUrl$path';
    return path;
  }
}
