import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/attendance.dart';
import '../../../shared/models/school_class.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/teacher_providers.dart';
import '../teacher_nav.dart';

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState
    extends ConsumerState<TeacherAttendanceScreen> {
  SchoolClass? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  final _statuses = <String, AttendanceStatus>{};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final classesAsync = ref.watch(teacherClassesProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Teacher Portal',
      subtitle: profile?.fullName,
      navItems: teacherNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: classesAsync.when(
        loading: () => const LoadingView(message: 'Loading classes...'),
        error: (error, _) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(teacherClassesProvider),
        ),
        data: (classes) {
          _selectedClass ??= classes.isNotEmpty ? classes.first : null;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Attendance', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<SchoolClass>(
                        initialValue: _selectedClass,
                        decoration: const InputDecoration(labelText: 'Class'),
                        items: [
                          for (final schoolClass in classes)
                            DropdownMenuItem(
                              value: schoolClass,
                              child: Text(schoolClass.name),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedClass = value;
                            _statuses.clear();
                          });
                        },
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                            _statuses.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_formatDate(_selectedDate)),
                    ),
                    FilledButton.icon(
                      onPressed: _selectedClass == null || _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save Attendance'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _selectedClass == null
                      ? const Center(child: Text('No classes assigned'))
                      : _AttendanceList(
                          classId: _selectedClass!.id,
                          date: _selectedDate,
                          statuses: _statuses,
                          onStatusChanged: (studentId, status) {
                            setState(() => _statuses[studentId] = status);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null || _selectedClass == null) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(teacherRepositoryProvider).saveAttendance(
            classId: _selectedClass!.id,
            date: _selectedDate,
            statuses: _statuses,
            markedBy: profile.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved')),
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

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _AttendanceList extends ConsumerWidget {
  const _AttendanceList({
    required this.classId,
    required this.date,
    required this.statuses,
    required this.onStatusChanged,
  });

  final String classId;
  final DateTime date;
  final Map<String, AttendanceStatus> statuses;
  final void Function(String studentId, AttendanceStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(_classStudentsProvider(classId));
    final existingAsync = ref.watch(_attendanceProvider((classId, date)));

    return studentsAsync.when(
      loading: () => const LoadingView(message: 'Loading students...'),
      error: (error, _) => ErrorView(message: '$error'),
      data: (students) {
        existingAsync.whenData((existing) {
          for (final record in existing) {
            statuses.putIfAbsent(record.studentId, () => record.status);
          }
        });

        if (students.isEmpty) {
          return const Center(child: Text('No students enrolled in this class'));
        }

        return Card(
          child: ListView.separated(
            itemCount: students.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = students[index];
              final status = statuses[student.studentId] ?? AttendanceStatus.present;

              return ListTile(
                title: Text(student.fullName),
                subtitle: Text(student.rollNumber ?? student.email ?? ''),
                trailing: DropdownButton<AttendanceStatus>(
                  value: status,
                  items: [
                    for (final item in AttendanceStatus.values)
                      DropdownMenuItem(value: item, child: Text(item.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) onStatusChanged(student.studentId, value);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

final _classStudentsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, classId) {
  return ref.watch(teacherRepositoryProvider).fetchClassStudents(classId);
});

final _attendanceProvider = FutureProvider.family<
    List<AttendanceRecord>,
    (String, DateTime)>((ref, params) {
  return ref.watch(teacherRepositoryProvider).fetchAttendance(
        classId: params.$1,
        date: params.$2,
      );
});
