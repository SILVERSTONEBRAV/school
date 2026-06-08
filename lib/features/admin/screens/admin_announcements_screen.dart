import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/announcement.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../announcements/providers/announcements_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../admin_nav.dart';
import '../providers/admin_providers.dart';

class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState
    extends ConsumerState<AdminAnnouncementsScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final announcementsAsync = ref.watch(announcementsProvider);
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
                    'Announcements',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _createAnnouncement,
                  icon: const Icon(Icons.add),
                  label: const Text('Post Announcement'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: announcementsAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(message: '$error'),
                data: (items) => items.isEmpty
                    ? const Center(child: Text('No announcements yet'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index] as Announcement;
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                item.isPinned ? Icons.push_pin : Icons.campaign,
                              ),
                              title: Text(item.title),
                              subtitle: Text(item.body, maxLines: 2),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(item.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAnnouncement() async {
    final profile = ref.read(currentProfileProvider).value;
    final schoolId = await ref.read(schoolIdProvider.future);
    if (profile == null || schoolId == null || !mounted) return;

    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    var isPinned = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Post Announcement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 4,
              ),
              SwitchListTile(
                title: const Text('Pin to top'),
                value: isPinned,
                onChanged: (v) => setDialogState(() => isPinned = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Post')),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    await ref.read(announcementsRepositoryProvider).createAnnouncement(
          schoolId: schoolId,
          title: titleController.text.trim(),
          body: bodyController.text.trim(),
          authorId: profile.id,
          isPinned: isPinned,
        );

    final profiles = await ref.read(profilesProvider.future);
    await ref.read(notificationsRepositoryProvider).notifyUsers(
          userIds: profiles.map((p) => p.id).toList(),
          title: 'School announcement',
          body: titleController.text.trim(),
          type: 'announcement',
        );

    ref.invalidate(announcementsProvider);
    titleController.dispose();
    bodyController.dispose();
  }

  Future<void> _delete(String id) async {
    await ref.read(announcementsRepositoryProvider).deleteAnnouncement(id);
    ref.invalidate(announcementsProvider);
  }
}
