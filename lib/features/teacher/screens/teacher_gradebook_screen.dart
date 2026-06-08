import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/class_subject.dart';
import '../../../shared/models/term.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/teacher_providers.dart';
import '../teacher_nav.dart';

class TeacherGradebookScreen extends ConsumerStatefulWidget {
  const TeacherGradebookScreen({super.key});

  @override
  ConsumerState<TeacherGradebookScreen> createState() =>
      _TeacherGradebookScreenState();
}

class _TeacherGradebookScreenState extends ConsumerState<TeacherGradebookScreen> {
  ClassSubject? _selectedSubject;
  Term? _selectedTerm;
  final _scores = <String, TextEditingController>{};
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in _scores.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final subjectsAsync = ref.watch(teacherClassSubjectsProvider);
    final termsAsync = ref.watch(teacherTermsProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Teacher Portal',
      subtitle: profile?.fullName,
      navItems: teacherNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: subjectsAsync.when(
        loading: () => const LoadingView(message: 'Loading subjects...'),
        error: (error, _) => ErrorView(message: '$error'),
        data: (subjects) {
          final terms = termsAsync.value ?? [];
          _selectedSubject ??= subjects.isNotEmpty ? subjects.first : null;
          _selectedTerm ??= terms.where((t) => t.isActive).firstOrNull ?? terms.firstOrNull;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Gradebook', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<ClassSubject>(
                        initialValue: _selectedSubject,
                        decoration: const InputDecoration(labelText: 'Class & subject'),
                        items: [
                          for (final subject in subjects)
                            DropdownMenuItem(
                              value: subject,
                              child: Text(subject.displayName),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSubject = value;
                            _clearScores();
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<Term>(
                        initialValue: _selectedTerm,
                        decoration: const InputDecoration(labelText: 'Term'),
                        items: [
                          for (final term in terms)
                            DropdownMenuItem(value: term, child: Text(term.name)),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTerm = value;
                            _clearScores();
                          });
                        },
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _canSave ? _save : null,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save Grades'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _selectedSubject == null || _selectedTerm == null
                      ? const Center(child: Text('Select a subject and term'))
                      : _GradeEntryList(
                          classSubjectId: _selectedSubject!.id,
                          classId: _selectedSubject!.classId,
                          termId: _selectedTerm!.id,
                          scores: _scores,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool get _canSave =>
      !_isSaving && _selectedSubject != null && _selectedTerm != null;

  void _clearScores() {
    for (final controller in _scores.values) {
      controller.dispose();
    }
    _scores.clear();
  }

  Future<void> _save() async {
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null || _selectedSubject == null || _selectedTerm == null) {
      return;
    }

    final parsed = <String, double>{};
    for (final entry in _scores.entries) {
      final value = double.tryParse(entry.value.text.trim());
      if (value != null) parsed[entry.key] = value;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(teacherRepositoryProvider).saveGrades(
            classSubjectId: _selectedSubject!.id,
            termId: _selectedTerm!.id,
            scores: parsed,
            gradedBy: profile.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grades saved')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _GradeEntryList extends ConsumerWidget {
  const _GradeEntryList({
    required this.classSubjectId,
    required this.classId,
    required this.termId,
    required this.scores,
  });

  final String classSubjectId;
  final String classId;
  final String termId;
  final Map<String, TextEditingController> scores;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(_gradeStudentsProvider(classId));
    final gradesAsync = ref.watch(_gradesProvider((classSubjectId, termId)));

    return studentsAsync.when(
      loading: () => const LoadingView(message: 'Loading students...'),
      error: (error, _) => ErrorView(message: '$error'),
      data: (students) {
        gradesAsync.whenData((grades) {
          for (final grade in grades) {
            scores.putIfAbsent(
              grade.studentId,
              () => TextEditingController(text: grade.score.toString()),
            );
          }
          for (final student in students) {
            scores.putIfAbsent(student.studentId, () => TextEditingController());
          }
        });

        if (students.isEmpty) {
          return const Center(child: Text('No students enrolled'));
        }

        return Card(
          child: ListView.separated(
            itemCount: students.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = students[index];
              final controller = scores[student.studentId] ?? TextEditingController();

              return ListTile(
                title: Text(student.fullName),
                subtitle: Text(student.rollNumber ?? ''),
                trailing: SizedBox(
                  width: 80,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Score',
                      isDense: true,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

final _gradeStudentsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, classId) {
  return ref.watch(teacherRepositoryProvider).fetchClassStudents(classId);
});

final _gradesProvider = FutureProvider.family<
    List<dynamic>,
    (String, String)>((ref, params) {
  return ref.watch(teacherRepositoryProvider).fetchGrades(
        classSubjectId: params.$1,
        termId: params.$2,
      );
});
