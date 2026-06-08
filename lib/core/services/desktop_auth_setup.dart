import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/auth_redirect_config.dart';

/// Registers the OAuth callback URL scheme on Windows so the browser can
/// return to this app after Google sign-in.
Future<void> setupDesktopAuth() async {
  if (kIsWeb || !Platform.isWindows) return;

  final exe = Platform.resolvedExecutable;
  final scheme = AuthRedirectConfig.scheme;

  final command = '''
\$key = 'HKCU:\\Software\\Classes\\$scheme'
New-Item -Path \$key -Force | Out-Null
Set-ItemProperty -Path \$key -Name '(default)' -Value 'URL:School Management Auth'
New-ItemProperty -Path \$key -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
New-Item -Path "\$key\\shell\\open\\command" -Force | Out-Null
Set-ItemProperty -Path "\$key\\shell\\open\\command" -Name '(default)' -Value '"$exe" "%1"'
''';

  try {
    await Process.run(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command],
    );
  } catch (_) {
    // Best-effort; run scripts/register_auth_protocol.ps1 manually if needed.
  }
}
