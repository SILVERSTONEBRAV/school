import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/page_header.dart';
import '../../auth/providers/auth_providers.dart';
import '../admin_nav.dart';
import '../providers/admin_providers.dart';

class AdminCommandCenterScreen extends ConsumerWidget {
  const AdminCommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final statsAsync = ref.watch(adminStatsProvider);
    final atRiskAsync = ref.watch(atRiskStudentsProvider);
    final auditAsync = ref.watch(auditLogProvider);
    final location = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);

    return AppShell(
      title: 'Admin Portal',
      subtitle: profile?.fullName,
      navItems: adminNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ListView(
          children: [
            const PageHeader(
              title: 'Command Center',
              subtitle: 'AI-assisted insights and live school operations',
            ),
            const SizedBox(height: 24),
            statsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: '$e'),
              data: (stats) {
                final total =
                    stats.values.fold<int>(0, (sum, count) => sum + count);
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _PulseCard(
                      icon: Icons.hub_outlined,
                      label: 'Total users',
                      value: '$total',
                      color: theme.colorScheme.primary,
                    ),
                    _PulseCard(
                      icon: Icons.school_outlined,
                      label: 'Students',
                      value: '${stats[UserRole.student] ?? 0}',
                      color: Colors.blue,
                    ),
                    _PulseCard(
                      icon: Icons.menu_book_outlined,
                      label: 'Teachers',
                      value: '${stats[UserRole.teacher] ?? 0}',
                      color: Colors.teal,
                    ),
                    _PulseCard(
                      icon: Icons.warning_amber_outlined,
                      label: 'At-risk students',
                      value: atRiskAsync.value?.length.toString() ?? '—',
                      color: Colors.orange,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology_outlined,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Smart alerts — attendance risk',
                            style: theme.textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Students below 75% attendance in the last 30 days',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    atRiskAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) =>
                          const Text('Could not load risk insights'),
                      data: (students) {
                        if (students.isEmpty) {
                          return const Text('No at-risk students detected 🎉');
                        }
                        return Column(
                          children: [
                            for (final s in students.take(8))
                              ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    s.firstName.isNotEmpty
                                        ? s.firstName[0]
                                        : '?',
                                  ),
                                ),
                                title: Text(s.fullName),
                                subtitle: Text(s.email),
                                trailing: Chip(
                                  label: Text('${s.attendanceRate}%'),
                                  backgroundColor:
                                      theme.colorScheme.errorContainer,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent admin activity',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    auditAsync.when(
                      loading: () => const LoadingView(),
                      error: (e, _) => Text('Audit log unavailable: $e'),
                      data: (entries) {
                        if (entries.isEmpty) {
                          return const Text('No activity yet');
                        }
                        return Column(
                          children: [
                            for (final entry in entries.take(10))
                              ListTile(
                                dense: true,
                                leading: const Icon(Icons.history, size: 20),
                                title: Text(entry.action.replaceAll('_', ' ')),
                                subtitle: Text(
                                  entry.actorName ?? 'System',
                                ),
                                trailing: Text(
                                  DateFormat.MMMd()
                                      .add_jm()
                                      .format(entry.createdAt),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.adminUsers),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Manage users'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.adminAnalytics),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Analytics'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
