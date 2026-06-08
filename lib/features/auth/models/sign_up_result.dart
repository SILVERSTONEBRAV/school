class SignUpResult {
  const SignUpResult({
    required this.needsEmailConfirmation,
    required this.hasSession,
  });

  final bool needsEmailConfirmation;
  final bool hasSession;
}
