import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/google_sign_in_button.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_messages.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.inviteToken});

  final String? inviteToken;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _role = UserRole.student;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  bool get _isInviteFlow => widget.inviteToken?.isNotEmpty == true;

  List<UserRole> get _registrationRoles =>
      _isInviteFlow ? UserRole.values : UserRole.selfRegistrationRoles;

  @override
  void initState() {
    super.initState();
    if (!_registrationRoles.contains(_role)) {
      _role = _registrationRoles.first;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(friendlyAuthMessage(error))),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text,
            password: _passwordController.text,
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            role: _role,
            phoneNumber: _phoneController.text,
            inviteToken: widget.inviteToken,
          );

      if (!mounted) return;

      if (result.hasSession) {
        _showMessage('Account created successfully.');
        return;
      }

      await ref.read(authRepositoryProvider).signOut();
      if (!mounted) return;
      _showMessage(
        'Account created. Check your email to confirm before signing in.',
      );
      context.go(AppRoutes.login);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (error) {
      if (mounted) setState(() => _isGoogleLoading = false);
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isLoading || _isGoogleLoading;

    return AuthScaffold(
      title: _isInviteFlow ? 'Accept your invite' : 'Create account',
      subtitle: _isInviteFlow
          ? 'Complete your profile to join the school portal'
          : 'Students and parents can register here. Staff receive invite links.',
      showBackButton: true,
      onBack: () => context.go(AppRoutes.login),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isInviteFlow) ...[
              GoogleSignInButton(
                onPressed: isBusy ? null : _signInWithGoogle,
                isLoading: _isGoogleLoading,
              ),
              const SizedBox(height: 20),
              const AuthDivider(label: 'or register with email'),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    enabled: !isBusy,
                    validator: (value) =>
                        value?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last name'),
                    enabled: !isBusy,
                    validator: (value) =>
                        value?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isBusy,
              validator: (value) =>
                  value?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              enabled: !isBusy,
            ),
            if (!_isInviteFlow) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'I am a',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: [
                  for (final role in _registrationRoles)
                    DropdownMenuItem(
                      value: role,
                      child: Text(role.label),
                    ),
                ],
                onChanged: isBusy
                    ? null
                    : (value) {
                        if (value != null) setState(() => _role = value);
                      },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              enabled: !isBusy,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: isBusy ? null : _register,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isInviteFlow ? 'Complete Registration' : 'Create Account'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isBusy ? null : () => context.go(AppRoutes.login),
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
