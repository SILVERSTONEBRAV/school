import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_shell.dart';
import '../../auth/providers/auth_providers.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;

    return AppShell(
      title: 'Staff Portal',
      subtitle: profile?.fullName,
      navItems: const [
        NavItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          route: '/staff',
        ),
      ],
      selectedRoute: '/staff',
      onNavigate: (_) {},
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Staff portal — coming in Phase 2'),
        ),
      ),
    );
  }
}
