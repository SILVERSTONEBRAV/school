import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/models/user_account_status.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../admin_nav.dart';
import '../providers/academic_providers.dart';
import '../providers/admin_providers.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/bulk_student_import_dialog.dart';
import '../widgets/edit_user_sheet.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  UserRole? _filterRole;
  UserAccountStatus? _filterStatus;
  String _searchQuery = '';
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final profilesAsync = ref.watch(profilesProvider);
    final auditAsync = ref.watch(auditLogProvider);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'User Management',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add users',
                  onSelected: (value) async {
                    switch (value) {
                      case 'single':
                        final created = await showDialog<bool>(
                          context: context,
                          builder: (_) => const AddUserDialog(),
                        );
                        if (created == true) ref.invalidate(profilesProvider);
                      case 'bulk':
                        await showDialog(
                          context: context,
                          builder: (_) => const BulkStudentImportDialog(),
                        );
                        ref.invalidate(profilesProvider);
                      case 'invite':
                        await _showInviteDialog();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'single',
                      child: ListTile(
                        leading: Icon(Icons.person_add),
                        title: Text('Add user manually'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'bulk',
                      child: ListTile(
                        leading: Icon(Icons.upload_file),
                        title: Text('Bulk import students (CSV)'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'invite',
                      child: ListTile(
                        leading: Icon(Icons.mail_outline),
                        title: Text('Send staff invite link'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    ref.invalidate(profilesProvider);
                    ref.invalidate(auditLogProvider);
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'All users'),
                Tab(text: 'Audit log'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _UsersTab(
                    profilesAsync: profilesAsync,
                    filterRole: _filterRole,
                    filterStatus: _filterStatus,
                    searchQuery: _searchQuery,
                    onFilterRoleChanged: (v) => setState(() => _filterRole = v),
                    onFilterStatusChanged: (v) =>
                        setState(() => _filterStatus = v),
                    onSearchChanged: (v) => setState(() => _searchQuery = v),
                    onUserTap: _openUserSheet,
                    onLinkFamily: _showLinkDialog,
                  ),
                  auditAsync.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => ErrorView(message: '$e'),
                    data: (entries) => ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(e.action.replaceAll('_', ' ')),
                          subtitle: Text(
                            '${e.actorName ?? "System"} · ${e.targetUserId ?? ""}',
                          ),
                          trailing: Text(
                            e.createdAt.toLocal().toString().substring(0, 16),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUserSheet(Profile user) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditUserSheet(profile: user),
    );
    if (saved == true) {
      ref.invalidate(profilesProvider);
      ref.invalidate(auditLogProvider);
    }
  }

  Future<void> _showInviteDialog() async {
    final emailController = TextEditingController();
    var role = UserRole.teacher;
    final school = ref.read(schoolProvider).value;
    final adminProfile = ref.read(currentProfileProvider).value;

    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Send staff invite'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: [
                    for (final r in UserRole.inviteOnlyRoles)
                      DropdownMenuItem(value: r, child: Text(r.label)),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => role = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create invite'),
            ),
          ],
        ),
      ),
    );

    if (sent != true || !mounted) {
      emailController.dispose();
      return;
    }

    try {
      final invite = await ref.read(adminRepositoryProvider).createStaffInvite(
            email: emailController.text,
            role: role,
            schoolId: school?.id,
            invitedBy: adminProfile?.id,
          );
      emailController.dispose();
      if (!mounted) return;
      final link = AppConfig.registrationInviteUrl(invite['token'] as String);
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invite created'),
          content: SelectableText(link),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied')),
                  );
                }
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      emailController.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $error')),
      );
    }
  }

  Future<void> _showLinkDialog(Profile profile) async {
    if (profile.role == UserRole.parent) {
      final students = await ref.read(studentsProvider.future);
      if (!mounted || students.isEmpty) return;
      var studentId = students.first.id;
      final rel = TextEditingController(text: 'Guardian');
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: const Text('Link child'),
            content: DropdownButtonFormField<String>(
              initialValue: studentId,
              items: [
                for (final s in students)
                  DropdownMenuItem(value: s.id, child: Text(s.fullName)),
              ],
              onChanged: (v) => setS(() => studentId = v!),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Link')),
            ],
          ),
        ),
      );
      if (ok == true) {
        await ref.read(adminRepositoryProvider).linkParentStudent(
              parentId: profile.id,
              studentId: studentId,
              relationship: rel.text,
            );
      }
      rel.dispose();
    }
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({
    required this.profilesAsync,
    required this.filterRole,
    required this.filterStatus,
    required this.searchQuery,
    required this.onFilterRoleChanged,
    required this.onFilterStatusChanged,
    required this.onSearchChanged,
    required this.onUserTap,
    required this.onLinkFamily,
  });

  final AsyncValue profilesAsync;
  final UserRole? filterRole;
  final UserAccountStatus? filterStatus;
  final String searchQuery;
  final ValueChanged<UserRole?> onFilterRoleChanged;
  final ValueChanged<UserAccountStatus?> onFilterStatusChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Profile> onUserTap;
  final ValueChanged<Profile> onLinkFamily;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: onSearchChanged,
              ),
            ),
            DropdownButton<UserRole?>(
              value: filterRole,
              hint: const Text('All roles'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All roles')),
                for (final r in UserRole.values)
                  DropdownMenuItem(value: r, child: Text(r.label)),
              ],
              onChanged: onFilterRoleChanged,
            ),
            DropdownButton<UserAccountStatus?>(
              value: filterStatus,
              hint: const Text('All statuses'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All statuses')),
                for (final s in UserAccountStatus.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: onFilterStatusChanged,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: profilesAsync.when(
            loading: () => const LoadingView(message: 'Loading users...'),
            error: (e, _) => ErrorView(message: '$e'),
            data: (profiles) {
              final filtered = (profiles as List<Profile>).where((p) {
                final q = searchQuery.trim().toLowerCase();
                final matchSearch = q.isEmpty ||
                    p.fullName.toLowerCase().contains(q) ||
                    p.email.toLowerCase().contains(q);
                final matchRole = filterRole == null || p.role == filterRole;
                final matchStatus =
                    filterStatus == null || p.status == filterStatus;
                return matchSearch && matchRole && matchStatus;
              }).toList();

              return Card(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user.firstName.isNotEmpty
                              ? user.firstName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(user.fullName),
                      subtitle: Text(user.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(user.status.label),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(label: Text(user.role.label)),
                          if (user.role == UserRole.parent)
                            IconButton(
                              icon: const Icon(Icons.family_restroom),
                              onPressed: () => onLinkFamily(user),
                            ),
                        ],
                      ),
                      onTap: () => onUserTap(user),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
