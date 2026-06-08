import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/assignment.dart';
import '../../../shared/models/class_subject.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../assignments/providers/assignments_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../../teacher/providers/teacher_providers.dart';
import '../teacher_nav.dart';

class TeacherAssignmentsScreen extends ConsumerStatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  ConsumerState<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState
    extends ConsumerState<TeacherAssignmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);
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
                FilledButton.icon(
                  onPressed: () => _createAssignment(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New Assignment'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: assignmentsAsync.when(
                loading: () => const LoadingView(message: 'Loading assignments...'),
                error: (error, _) => ErrorView(message: '$error'),
                data: (assignments) {
                  if (assignments.isEmpty) {
                    return const Center(child: Text('No assignments yet'));
                  }

                  return ListView.separated(
                    itemCount: assignments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final assignment = assignments[index] as Assignment;
                      return Card(
                        child: ListTile(
                          title: Text(assignment.title),
                          subtitle: Text(
                            '${assignment.className ?? ''} · ${assignment.subjectName ?? ''}\n'
                            'Due: ${_formatDate(assignment.dueDate)}',
                          ),
                          isThreeLine: true,
                          trailing: assignment.isOverdue
                              ? const Chip(label: Text('Overdue'))
                              : null,
                          onTap: () => _gradeSubmissions(assignment),
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

  Future<void> _createAssignment(BuildContext context) async {
    final subjects = await ref.read(teacherClassSubjectsProvider.future);
    if (!context.mounted || subjects.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No subjects assigned to you')),
        );
      }
      return;
    }

    ClassSubject selected = subjects.first;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    var dueDate = DateTime.now().add(const Duration(days: 7));
    final maxScoreController = TextEditingController(text: '100');

    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ClassSubject>(
                  initialValue: selected,
                  decoration: const InputDecoration(labelText: 'Class & subject'),
                  items: [
                    for (final subject in subjects)
                      DropdownMenuItem(
                        value: subject,
                        child: Text(subject.displayName),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selected = value);
                  },
                ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                ListTile(
                  title: const Text('Due date'),
                  subtitle: Text(_formatDate(dueDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => dueDate = picked);
                  },
                ),
                TextField(
                  controller: maxScoreController,
                  decoration: const InputDecoration(labelText: 'Max score'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;

    final assignment = await ref.read(assignmentsRepositoryProvider).createAssignment(
          Assignment(
            id: '',
            classSubjectId: selected.id,
            title: titleController.text.trim(),
            description: descController.text.trim().isEmpty
                ? null
                : descController.text.trim(),
            dueDate: dueDate,
            maxScore: double.tryParse(maxScoreController.text.trim()) ?? 100,
            createdAt: DateTime.now(),
          ),
          profile.id,
        );

    final studentIds = await ref
        .read(assignmentsRepositoryProvider)
        .fetchEnrolledStudentIds(selected.id);

    await ref.read(notificationsRepositoryProvider).notifyUsers(
          userIds: studentIds,
          title: 'New assignment: ${assignment.title}',
          body: 'Due ${_formatDate(assignment.dueDate)}',
          type: 'assignment',
          referenceId: assignment.id,
        );

    ref.invalidate(teacherAssignmentsProvider);
    titleController.dispose();
    descController.dispose();
    maxScoreController.dispose();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Assignment created')),
    );
  }

  Future<void> _gradeSubmissions(Assignment assignment) async {
    final submissions = await ref
        .read(assignmentsRepositoryProvider)
        .fetchSubmissions(assignment.id);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Submissions — ${assignment.title}'),
        content: SizedBox(
          width: 480,
          child: submissions.isEmpty
              ? const Text('No submissions yet')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final submission = submissions[index];
                    return ListTile(
                      title: Text(submission.studentName ?? 'Student'),
                      subtitle: Text(
                        submission.content ?? 'No content',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: submission.score != null
                          ? Text(submission.score!.toStringAsFixed(1))
                          : const Icon(Icons.edit),
                      onTap: () => _gradeSubmission(
                        context,
                        assignment,
                        submission,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _gradeSubmission(
    BuildContext context,
    Assignment assignment,
    Submission submission,
  ) async {
    final scoreController = TextEditingController(
      text: submission.score?.toString() ?? '',
    );
    final feedbackController = TextEditingController(text: submission.feedback ?? '');
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade ${submission.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (submission.content != null)
              Text('Submission: ${submission.content}'),
            TextField(
              controller: scoreController,
              decoration: InputDecoration(
                labelText: 'Score (max ${assignment.maxScore})',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(labelText: 'Feedback'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true) return;

    final score = double.tryParse(scoreController.text.trim()) ?? 0;

    await ref.read(assignmentsRepositoryProvider).gradeSubmission(
          submissionId: submission.id,
          score: score,
          feedback: feedbackController.text.trim().isEmpty
              ? null
              : feedbackController.text.trim(),
          gradedBy: profile.id,
        );

    await ref.read(notificationsRepositoryProvider).notifyUsers(
          userIds: [submission.studentId],
          title: 'Grade posted: ${assignment.title}',
          body: 'Score: ${score.toStringAsFixed(1)} / ${assignment.maxScore}',
          type: 'grade',
          referenceId: submission.id,
        );

    ref.invalidate(notificationsProvider);
    scoreController.dispose();
    feedbackController.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
