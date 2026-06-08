import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/announcements_panel.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/teacher_providers.dart';
import '../teacher_nav.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final classesAsync = ref.watch(teacherClassesProvider);
    final subjectsAsync = ref.watch(teacherClassSubjectsProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Teacher Portal',
      subtitle: profile?.fullName,
      navItems: teacherNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      showNotifications: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const AnnouncementsPanel(),
            Text(
              'Welcome, ${profile?.firstName ?? 'Teacher'}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            classesAsync.when(
              loading: () => const LoadingView(message: 'Loading classes...'),
              error: (error, _) => ErrorView(message: '$error'),
              data: (classes) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Classes (${classes.length})',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      if (classes.isEmpty)
                        const Text('No classes assigned yet')
                      else
                        for (final schoolClass in classes)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.class_outlined),
                            title: Text(schoolClass.name),
                          ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            subjectsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (subjects) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned Subjects (${subjects.length})',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      for (final subject in subjects)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.menu_book_outlined),
                          title: Text(subject.displayName),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.teacherAttendance),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Mark Attendance'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.teacherGradebook),
                  icon: const Icon(Icons.grade_outlined),
                  label: const Text('Open Gradebook'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.teacherAssignments),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Assignments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
