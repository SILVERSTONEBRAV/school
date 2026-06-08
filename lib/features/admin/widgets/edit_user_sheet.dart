import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../shared/models/parent_profile_details.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/models/staff_profile_details.dart';
import '../../../shared/models/student_profile_details.dart';
import '../../../shared/models/user_account_status.dart';
import '../../../shared/models/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/admin_providers.dart';

class EditUserSheet extends ConsumerStatefulWidget {
  const EditUserSheet({super.key, required this.profile});

  final Profile profile;

  @override
  ConsumerState<EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends ConsumerState<EditUserSheet> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _roll;
  late final TextEditingController _employeeId;
  late final TextEditingController _jobTitle;
  late final TextEditingController _department;
  late final TextEditingController _address;
  late final TextEditingController _occupation;
  late final TextEditingController _newPassword;

  late UserAccountStatus _status;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _rollNumber;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _firstName = TextEditingController(text: p.firstName);
    _lastName = TextEditingController(text: p.lastName);
    _phone = TextEditingController(text: p.phoneNumber ?? '');
    _roll = TextEditingController();
    _employeeId = TextEditingController();
    _jobTitle = TextEditingController();
    _department = TextEditingController();
    _address = TextEditingController();
    _occupation = TextEditingController();
    _newPassword = TextEditingController();
    _status = p.status;
    _loadRoleDetails();
  }

  Future<void> _loadRoleDetails() async {
    final repo = ref.read(adminRepositoryProvider);
    final id = widget.profile.id;

    if (widget.profile.role == UserRole.student) {
      final d = await repo.fetchStudentDetails(id);
      if (d != null && mounted) {
        _roll.text = d.rollNumber ?? '';
        setState(() => _rollNumber = d.rollNumber);
      }
    } else if (widget.profile.role == UserRole.parent) {
      final d = await repo.fetchParentDetails(id);
      if (d != null && mounted) {
        _address.text = d.address ?? '';
        _occupation.text = d.occupation ?? '';
      }
    } else if (_isStaffRole(widget.profile.role)) {
      final d = await repo.fetchStaffDetails(id);
      if (d != null && mounted) {
        _employeeId.text = d.employeeId ?? '';
        _jobTitle.text = d.jobTitle ?? '';
        _department.text = d.department ?? '';
      }
    }
  }

  bool _isStaffRole(UserRole role) =>
      UserRole.inviteOnlyRoles.contains(role) || role == UserRole.teacher;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _roll.dispose();
    _employeeId.dispose();
    _jobTitle.dispose();
    _department.dispose();
    _address.dispose();
    _occupation.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final repo = ref.read(adminRepositoryProvider);
    final p = widget.profile;

    try {
      await repo.updateProfile(
        Profile(
          id: p.id,
          email: p.email,
          role: p.role,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          avatarUrl: p.avatarUrl,
          schoolId: p.schoolId,
          status: _status,
          createdAt: p.createdAt,
          updatedAt: p.updatedAt,
        ),
      );

      if (p.role == UserRole.student) {
        await repo.upsertStudentDetails(
          StudentProfileDetails(
            profileId: p.id,
            rollNumber: _roll.text.trim().isEmpty ? null : _roll.text.trim(),
          ),
        );
      } else if (p.role == UserRole.parent) {
        await repo.upsertParentDetails(
          ParentProfileDetails(
            profileId: p.id,
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
            occupation:
                _occupation.text.trim().isEmpty ? null : _occupation.text.trim(),
          ),
        );
      } else if (_isStaffRole(p.role)) {
        await repo.upsertStaffDetails(
          StaffProfileDetails(
            profileId: p.id,
            employeeId: _employeeId.text.trim().isEmpty
                ? null
                : _employeeId.text.trim(),
            jobTitle:
                _jobTitle.text.trim().isEmpty ? null : _jobTitle.text.trim(),
            department: _department.text.trim().isEmpty
                ? null
                : _department.text.trim(),
          ),
        );
      }

      final admin = ref.read(currentProfileProvider).value;
      await repo.logAudit(
        actorId: admin!.id,
        action: 'update_profile',
        targetUserId: p.id,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    try {
      await ref.read(adminRepositoryProvider).sendPasswordResetEmail(
            widget.profile.email,
          );
      final admin = ref.read(currentProfileProvider).value;
      await ref.read(adminRepositoryProvider).logAudit(
            actorId: admin!.id,
            action: 'send_password_reset',
            targetUserId: widget.profile.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset link sent to ${widget.profile.email}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $error')),
      );
    }
  }

  Future<void> _setPassword() async {
    if (_newPassword.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(adminUserServiceProvider).updatePassword(
            userId: widget.profile.id,
            password: _newPassword.text,
          );
      if (!mounted) return;
      _newPassword.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDigitalId() {
    final qrData =
        'SCHOOL|${widget.profile.id}|${_rollNumber ?? _roll.text}|${widget.profile.fullName}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Digital student ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: qrData, size: 180),
            const SizedBox(height: 12),
            Text(widget.profile.fullName,
                style: Theme.of(context).textTheme.titleMedium),
            if (_rollNumber != null || _roll.text.isNotEmpty)
              Text('Roll: ${_rollNumber ?? _roll.text}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(p.firstName.isNotEmpty ? p.firstName[0] : '?'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.fullName, style: theme.textTheme.titleLarge),
                      Text(p.email),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text(p.role.label)),
                          Chip(
                            label: Text(p.status.label),
                            backgroundColor: p.status == UserAccountStatus.active
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.errorContainer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Profile', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstName,
                    decoration: const InputDecoration(labelText: 'First name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lastName,
                    decoration: const InputDecoration(labelText: 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UserAccountStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final s in UserAccountStatus.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            if (p.role == UserRole.student) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _roll,
                decoration: const InputDecoration(labelText: 'Roll number'),
              ),
            ],
            if (p.role == UserRole.parent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _occupation,
                decoration: const InputDecoration(labelText: 'Occupation'),
              ),
            ],
            if (_isStaffRole(p.role)) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _employeeId,
                decoration: const InputDecoration(labelText: 'Employee ID'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _jobTitle,
                decoration: const InputDecoration(labelText: 'Job title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _department,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
            ],
            const SizedBox(height: 24),
            Text('Security', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _sendPasswordReset,
              icon: const Icon(Icons.mail_outline),
              label: const Text('Send password reset email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPassword,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Set new password directly',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _isLoading ? null : _setPassword,
              child: const Text('Update password'),
            ),
            if (p.role == UserRole.student) ...[
              const SizedBox(height: 24),
              Text('Digital ID', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showDigitalId,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Show QR student ID'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
