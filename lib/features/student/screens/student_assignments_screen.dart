import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/storage_provider.dart';
import '../../../shared/models/assignment.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../assignments/providers/assignments_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../student_nav.dart';

class StudentAssignmentsScreen extends ConsumerWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);
    final submissionsAsync = ref.watch(studentSubmissionsProvider);
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
        child: assignmentsAsync.when(
          loading: () => const LoadingView(message: 'Loading assignments...'),
          error: (error, _) => ErrorView(message: '$error'),
          data: (assignments) {
            final submissions = submissionsAsync.value ?? [];
            final submissionMap = {
              for (final s in submissions) s.assignmentId: s,
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Assignments',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: assignments.isEmpty
                      ? const Center(child: Text('No assignments yet'))
                      : ListView.separated(
                          itemCount: assignments.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final assignment = assignments[index] as Assignment;
                            final submission = submissionMap[assignment.id];

                            return Card(
                              child: ListTile(
                                title: Text(assignment.title),
                                subtitle: Text(
                                  '${assignment.subjectName ?? ''}\n'
                                  'Due: ${_formatDate(assignment.dueDate)}',
                                ),
                                isThreeLine: true,
                                trailing: _statusChip(assignment, submission),
                                onTap: () => _openAssignment(
                                  context,
                                  ref,
                                  assignment,
                                  submission,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget? _statusChip(Assignment assignment, Submission? submission) {
    if (submission == null) {
      return assignment.isOverdue
          ? const Chip(label: Text('Overdue'))
          : const Chip(label: Text('Pending'));
    }
    return Chip(label: Text(submission.status.label));
  }

  Future<void> _openAssignment(
    BuildContext context,
    WidgetRef ref,
    Assignment assignment,
    Submission? existing,
  ) async {
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) return;

    final contentController =
        TextEditingController(text: existing?.content ?? '');
    String? filePath = existing?.fileUrl;
    String? pickedFileName;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(assignment.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (assignment.description != null) Text(assignment.description!),
                const SizedBox(height: 8),
                Text('Due: ${_formatDate(assignment.dueDate)}'),
                Text('Max score: ${assignment.maxScore}'),
                if (existing?.score != null) ...[
                  const SizedBox(height: 8),
                  Text('Your score: ${existing!.score}'),
                  if (existing.feedback != null) Text('Feedback: ${existing.feedback}'),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Your submission',
                    hintText: 'Enter your answer or notes',
                  ),
                  maxLines: 5,
                  enabled: existing?.status != SubmissionStatus.graded,
                ),
                if (existing?.status != SubmissionStatus.graded) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(withData: true);
                      if (result != null && result.files.single.bytes != null) {
                        setDialogState(() {
                          pickedFileName = result.files.single.name;
                        });
                        filePath = await ref
                            .read(storageServiceProvider)
                            .uploadAssignmentFile(
                              studentId: profile.id,
                              assignmentId: assignment.id,
                              fileName: result.files.single.name,
                              bytes: result.files.single.bytes!,
                            );
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      pickedFileName ?? filePath ?? 'Attach file (optional)',
                    ),
                  ),
                ],
                if (existing?.fileUrl != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final url = await ref
                          .read(storageServiceProvider)
                          .getSignedUrl(existing!.fileUrl!);
                      await launchUrl(Uri.parse(url));
                    },
                    child: const Text('View attached file'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Close')),
            if (existing?.status != SubmissionStatus.graded)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(existing == null ? 'Submit' : 'Update'),
              ),
          ],
        ),
      ),
    );

    if (submitted != true) {
      contentController.dispose();
      return;
    }

    await ref.read(assignmentsRepositoryProvider).submitAssignment(
          assignmentId: assignment.id,
          studentId: profile.id,
          content: contentController.text.trim(),
          fileUrl: filePath,
          isLate: assignment.isOverdue,
        );

    ref.invalidate(studentSubmissionsProvider);
    ref.invalidate(studentAssignmentsProvider);
    contentController.dispose();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submission saved')),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
