import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/announcements_panel.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/student_providers.dart';
import '../student_nav.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final academicsAsync = ref.watch(studentAcademicsProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Student Portal',
      subtitle: profile?.fullName,
      navItems: studentNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      showNotifications: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: academicsAsync.when(
          loading: () => const LoadingView(message: 'Loading dashboard...'),
          error: (error, _) => ErrorView(
            message: '$error',
            onRetry: () => ref.invalidate(studentAcademicsProvider),
          ),
          data: (academics) {
            final recentGrades = academics.grades.take(3).toList();

            return ListView(
              children: [
                if (academics.fromCache)
                  Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.cloud_off_outlined),
                      title: Text(AppLocalizations.of(context).offlineMode),
                    ),
                  ),
                Text(
                  'Welcome, ${profile?.firstName ?? 'Student'}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  academics.displayClassName ?? 'Not enrolled in a class',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const AnnouncementsPanel(),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _SummaryCard(
                      title: 'Subjects',
                      value: '${academics.subjects.length}',
                      icon: Icons.menu_book_outlined,
                    ),
                    _SummaryCard(
                      title: 'Attendance',
                      value: '${academics.attendancePercentage.toStringAsFixed(0)}%',
                      icon: Icons.event_available_outlined,
                    ),
                    _SummaryCard(
                      title: 'Grades',
                      value: '${academics.grades.length}',
                      icon: Icons.assessment_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Recent Grades', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (recentGrades.isEmpty)
                  const Card(
                    child: ListTile(title: Text('No grades yet')),
                  )
                else
                  for (final grade in recentGrades)
                    Card(
                      child: ListTile(
                        title: Text(grade.subjectName ?? 'Subject'),
                        trailing: Text(grade.score.toStringAsFixed(1)),
                      ),
                    ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.studentSchedule),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('View Schedule'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.studentGrades),
                      icon: const Icon(Icons.assessment_outlined),
                      label: const Text('All Grades'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.studentAssignments),
                      icon: const Icon(Icons.assignment_outlined),
                      label: const Text('Assignments'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
