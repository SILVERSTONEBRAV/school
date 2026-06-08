import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/announcements_panel.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/parent_providers.dart';
import '../parent_nav.dart';

class ChildSelector extends ConsumerWidget {
  const ChildSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(parentChildrenProvider);

    return childrenAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (children) {
        if (children.length <= 1) {
          if (children.length == 1) {
            ref.read(selectedChildIdProvider.notifier).select(
                children.first.studentId,
              );
          }
          return children.isEmpty
              ? const Chip(label: Text('No linked children'))
              : Chip(label: Text(children.first.fullName));
        }

        final selectedId = ref.watch(selectedChildIdProvider) ??
            children.first.studentId;

        return DropdownButton<String>(
          value: selectedId,
          items: [
            for (final child in children)
              DropdownMenuItem(
                value: child.studentId,
                child: Text(child.fullName),
              ),
          ],
          onChanged: (value) {
            ref.read(selectedChildIdProvider.notifier).select(value);
          },
        );
      },
    );
  }
}

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final child = ref.watch(selectedChildProvider);
    final academicsAsync = ref.watch(selectedChildAcademicsProvider);
    final feesAsync = ref.watch(selectedChildFeesProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Parent Portal',
      subtitle: profile?.fullName,
      navItems: parentNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      showNotifications: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Child Overview',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const ChildSelector(),
              ],
            ),
            const SizedBox(height: 24),
            if (child == null)
              const Expanded(
                child: Center(
                  child: Text(
                    'No children linked to your account.\nAsk the school admin to link your profile.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: academicsAsync.when(
                  loading: () => const LoadingView(),
                  error: (error, _) => ErrorView(message: '$error'),
                  data: (academics) {
                    if (academics == null) {
                      return const Center(child: Text('Unable to load child data'));
                    }

                    final fees = feesAsync.value;

                    return ListView(
                      children: [
                        const AnnouncementsPanel(),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(child.fullName),
                            subtitle: Text(
                              [
                                if (child.relationship != null) child.relationship,
                                if (child.className != null) child.className,
                              ].whereType<String>().join(' · '),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _StatCard(
                              title: 'Attendance',
                              value:
                                  '${academics.attendancePercentage.toStringAsFixed(0)}%',
                              icon: Icons.event_available_outlined,
                            ),
                            _StatCard(
                              title: 'Grades',
                              value: '${academics.grades.length}',
                              icon: Icons.assessment_outlined,
                            ),
                            _StatCard(
                              title: 'Outstanding',
                              value: fees != null
                                  ? '\$${fees.outstanding.toStringAsFixed(0)}'
                                  : '—',
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text('Recent Grades',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        if (academics.grades.isEmpty)
                          const Card(child: ListTile(title: Text('No grades yet')))
                        else
                          for (final grade in academics.grades.take(5))
                            Card(
                              child: ListTile(
                                title: Text(grade.subjectName ?? 'Subject'),
                                trailing: Text(grade.score.toStringAsFixed(1)),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
