import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/assignment.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../parent_nav.dart';
import '../providers/parent_providers.dart';
import 'parent_dashboard_screen.dart';

class ParentAssignmentsScreen extends ConsumerWidget {
  const ParentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final assignmentsAsync = ref.watch(selectedChildAssignmentsProvider);
    final submissionsAsync = ref.watch(selectedChildSubmissionsProvider);
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
                    'Assignments',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const ChildSelector(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: assignmentsAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(message: '$error'),
                data: (assignments) {
                  final submissions = submissionsAsync.value ?? [];
                  final submissionMap = {
                    for (final s in submissions) s.assignmentId: s,
                  };

                  if (assignments.isEmpty) {
                    return const Center(child: Text('No assignments'));
                  }

                  return ListView.separated(
                    itemCount: assignments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final assignment = assignments[index] as Assignment;
                      final submission = submissionMap[assignment.id];

                      return Card(
                        child: ListTile(
                          title: Text(assignment.title),
                          subtitle: Text(
                            '${assignment.subjectName ?? ''} · Due ${_formatDate(assignment.dueDate)}',
                          ),
                          trailing: Chip(
                            label: Text(
                              submission?.status.label ??
                                  (assignment.isOverdue ? 'Overdue' : 'Pending'),
                            ),
                          ),
                          onTap: submission != null
                              ? () => _showDetail(context, assignment, submission)
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    Assignment assignment,
    Submission submission,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(assignment.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${submission.status.label}'),
            if (submission.content != null) ...[
              const SizedBox(height: 8),
              Text('Submission: ${submission.content}'),
            ],
            if (submission.fileUrl != null) ...[
              const SizedBox(height: 8),
              Text('File attached: ${submission.fileUrl}'),
            ],
            if (submission.score != null) ...[
              const SizedBox(height: 8),
              Text('Score: ${submission.score} / ${assignment.maxScore}'),
            ],
            if (submission.feedback != null) ...[
              const SizedBox(height: 8),
              Text('Feedback: ${submission.feedback}'),
            ],
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

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
