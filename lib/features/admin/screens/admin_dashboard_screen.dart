import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/page_header.dart';
import '../../auth/providers/auth_providers.dart';
import '../admin_nav.dart';
import '../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final statsAsync = ref.watch(adminStatsProvider);
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
        padding: const EdgeInsets.all(28),
        child: statsAsync.when(
          loading: () => const LoadingView(message: 'Loading dashboard...'),
          error: (error, _) => ErrorView(
            message: 'Failed to load dashboard: $error',
            onRetry: () => ref.invalidate(adminStatsProvider),
          ),
          data: (stats) {
            final schoolName = schoolAsync.value?.name ?? 'Not configured';

            return ListView(
              children: [
                PageHeader(
                  title: 'Dashboard',
                  subtitle: schoolName,
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final role in UserRole.values)
                      StatCard(
                        title: role.label,
                        value: '${stats[role] ?? 0}',
                        icon: _iconForRole(role),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                SectionCard(
                  title: 'Quick Actions',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.adminSchool),
                        icon: const Icon(Icons.settings),
                        label: const Text('Configure School'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.adminUsers),
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Manage Users'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.adminAcademic),
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: const Text('Academic Setup'),
                      ),
                            OutlinedButton.icon(
                              onPressed: () => context.go(AppRoutes.adminCommandCenter),
                              icon: const Icon(Icons.hub_outlined),
                              label: const Text('Command Center'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => context.go(AppRoutes.adminAnalytics),
                              icon: const Icon(Icons.analytics_outlined),
                              label: const Text('Analytics'),
                            ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.adminAnnouncements),
                        icon: const Icon(Icons.campaign_outlined),
                        label: const Text('Announcements'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static IconData _iconForRole(UserRole role) => switch (role) {
        UserRole.admin => Icons.admin_panel_settings_outlined,
        UserRole.teacher => Icons.menu_book_outlined,
        UserRole.student => Icons.school_outlined,
        UserRole.parent => Icons.family_restroom_outlined,
        UserRole.staff => Icons.badge_outlined,
        UserRole.accountant => Icons.account_balance_wallet_outlined,
      };
}
