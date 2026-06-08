import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/school.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../admin_nav.dart';
import '../providers/admin_providers.dart';

class SchoolSetupScreen extends ConsumerStatefulWidget {
  const SchoolSetupScreen({super.key});

  @override
  ConsumerState<SchoolSetupScreen> createState() => _SchoolSetupScreenState();
}

class _SchoolSetupScreenState extends ConsumerState<SchoolSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _mottoController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  School? _existingSchool;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _mottoController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mottoController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _populateForm(School? school) {
    if (school == null || _existingSchool?.id == school.id) return;
    _existingSchool = school;
    _nameController.text = school.name;
    _mottoController.text = school.motto ?? '';
    _addressController.text = school.address ?? '';
    _phoneController.text = school.phone ?? '';
    _emailController.text = school.email ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final school = School(
        id: _existingSchool?.id ?? '',
        name: _nameController.text.trim(),
        motto: _emptyToNull(_mottoController.text),
        address: _emptyToNull(_addressController.text),
        phone: _emptyToNull(_phoneController.text),
        email: _emptyToNull(_emailController.text),
        createdAt: _existingSchool?.createdAt ?? DateTime.now(),
      );

      await ref.read(adminRepositoryProvider).saveSchool(school);
      ref.invalidate(schoolProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School profile saved')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final schoolAsync = ref.watch(schoolProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Admin Portal',
      subtitle: profile?.fullName,
      navItems: adminNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: schoolAsync.when(
          loading: () => const LoadingView(message: 'Loading school profile...'),
          error: (error, _) => ErrorView(
            message: 'Failed to load school: $error',
            onRetry: () => ref.invalidate(schoolProvider),
          ),
          data: (school) {
            _populateForm(school);

            return ListView(
              children: [
                Text(
                  'School Setup',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure your school profile and branding.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'School name *',
                            ),
                            validator: (value) =>
                                value?.trim().isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _mottoController,
                            decoration: const InputDecoration(labelText: 'Motto'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(labelText: 'Address'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(labelText: 'Phone'),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: _isSaving ? null : _save,
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Save School Profile'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
