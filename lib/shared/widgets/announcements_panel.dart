import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/announcements/providers/announcements_providers.dart';
import '../../l10n/app_localizations.dart';
import '../models/announcement.dart';

class AnnouncementsPanel extends ConsumerWidget {
  const AnnouncementsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final l10n = AppLocalizations.of(context);

    return announcementsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (announcements) {
        if (announcements.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.announcements, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final item in announcements.take(3))
              _AnnouncementCard(announcement: item as Announcement),
            if (announcements.length > 3)
              TextButton(
                onPressed: () => _showAll(context, announcements.cast<Announcement>()),
                child: Text('View all (${announcements.length})'),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showAll(BuildContext context, List<Announcement> items) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).announcements),
        content: SizedBox(
          width: 480,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.title),
                subtitle: Text(item.body, maxLines: 4, overflow: TextOverflow.ellipsis),
              );
            },
          ),
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
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          announcement.isPinned ? Icons.push_pin : Icons.campaign_outlined,
        ),
        title: Text(announcement.title),
        subtitle: Text(
          announcement.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(announcement.title),
              content: Text(announcement.body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
