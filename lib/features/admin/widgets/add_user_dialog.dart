import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_account_status.dart';
import '../../../shared/models/user_role.dart';
import '../providers/admin_providers.dart';

class AddUserDialog extends ConsumerStatefulWidget {
  const AddUserDialog({super.key, this.initialRole});

  final UserRole? initialRole;

  @override
  ConsumerState<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rollController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _departmentController = TextEditingController();
  final _addressController = TextEditingController();
  final _occupationController = TextEditingController();

  late UserRole _role = widget.initialRole ?? UserRole.student;
  UserAccountStatus _status = UserAccountStatus.active;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _rollController.dispose();
    _employeeIdController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  bool get _isStudent => _role == UserRole.student;
  bool get _isParent => _role == UserRole.parent;
  bool get _isStaffRole => UserRole.inviteOnlyRoles.contains(_role) ||
      _role == UserRole.teacher;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final school = ref.read(schoolProvider).value;

    try {
      await ref.read(adminUserServiceProvider).createUser(
            email: _emailController.text,
            password: _passwordController.text,
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            role: _role,
            phoneNumber: _phoneController.text,
            schoolId: school?.id,
            status: _status,
            rollNumber: _isStudent ? _rollController.text : null,
            employeeId: _isStaffRole ? _employeeIdController.text : null,
            jobTitle: _isStaffRole ? _jobTitleController.text : null,
            department: _isStaffRole ? _departmentController.text : null,
            address: _isParent ? _addressController.text : null,
            occupation: _isParent ? _occupationController.text : null,
          );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create user: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add user'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: [
                    for (final role in UserRole.values)
                      DropdownMenuItem(value: role, child: Text(role.label)),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (v) => setState(() => _role = v ?? _role),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'First name'),
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Last name'),
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Temporary password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserAccountStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Account status'),
                  items: [
                    for (final s in UserAccountStatus.values)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (v) => setState(() => _status = v ?? _status),
                ),
                if (_isStudent) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _rollController,
                    decoration: const InputDecoration(labelText: 'Roll number'),
                  ),
                ],
                if (_isParent) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _occupationController,
                    decoration: const InputDecoration(labelText: 'Occupation'),
                  ),
                ],
                if (_isStaffRole) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _employeeIdController,
                    decoration: const InputDecoration(labelText: 'Employee ID'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _jobTitleController,
                    decoration: const InputDecoration(labelText: 'Job title'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _departmentController,
                    decoration: const InputDecoration(labelText: 'Department'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create user'),
        ),
      ],
    );
  }
}
