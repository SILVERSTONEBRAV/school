import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/enrolled_student.dart';
import '../../../shared/models/academic_year.dart';
import '../../../shared/models/class_subject.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/models/school_class.dart';
import '../../../shared/models/subject.dart';
import '../../../shared/models/term.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../admin_nav.dart';
import '../providers/academic_providers.dart';
import '../providers/admin_providers.dart';

class AcademicManagementScreen extends ConsumerWidget {
  const AcademicManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Admin Portal',
      subtitle: profile?.fullName,
      navItems: adminNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                'Academic Setup',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Years & Terms'),
                Tab(text: 'Classes'),
                Tab(text: 'Subjects'),
                Tab(text: 'Enrollments'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _YearsTermsTab(),
                  _ClassesTab(),
                  _SubjectsTab(),
                  _EnrollmentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearsTermsTab extends ConsumerStatefulWidget {
  const _YearsTermsTab();

  @override
  ConsumerState<_YearsTermsTab> createState() => _YearsTermsTabState();
}

class _YearsTermsTabState extends ConsumerState<_YearsTermsTab> {
  AcademicYear? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(academicYearsProvider);

    return yearsAsync.when(
      loading: () => const LoadingView(message: 'Loading academic years...'),
      error: (error, _) => ErrorView(
        message: '$error',
        onRetry: () => ref.invalidate(academicYearsProvider),
      ),
      data: (years) {
        _selectedYear ??= years.where((year) => year.isActive).firstOrNull ?? years.firstOrNull;

        return Row(
          children: [
            Expanded(
              flex: 2,
              child: _YearList(
                years: years,
                selected: _selectedYear,
                onSelect: (year) => setState(() => _selectedYear = year),
                onRefresh: () => ref.invalidate(academicYearsProvider),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 3,
              child: _selectedYear == null
                  ? const Center(child: Text('Select or create an academic year'))
                  : _TermsPanel(academicYear: _selectedYear!),
            ),
          ],
        );
      },
    );
  }
}

class _YearList extends ConsumerWidget {
  const _YearList({
    required this.years,
    required this.selected,
    required this.onSelect,
    required this.onRefresh,
  });

  final List<AcademicYear> years;
  final AcademicYear? selected;
  final ValueChanged<AcademicYear> onSelect;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Academic Years', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
              FilledButton.icon(
                onPressed: () => _showYearDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: years.isEmpty
              ? const Center(child: Text('No academic years yet'))
              : ListView.builder(
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    final year = years[index];
                    return ListTile(
                      selected: selected?.id == year.id,
                      title: Text(year.name),
                      subtitle: Text(
                        '${_fmt(year.startDate)} – ${_fmt(year.endDate)}',
                      ),
                      trailing: year.isActive
                          ? const Chip(label: Text('Active'))
                          : null,
                      onTap: () => onSelect(year),
                      onLongPress: () => _showYearDialog(context, ref, year: year),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showYearDialog(
    BuildContext context,
    WidgetRef ref, {
    AcademicYear? year,
  }) async {
    final school = await ref.read(schoolProvider.future);
    if (school == null || !context.mounted) return;

    final nameController = TextEditingController(text: year?.name ?? '');
    var startDate = year?.startDate ?? DateTime.now();
    var endDate = year?.endDate ?? DateTime.now().add(const Duration(days: 365));
    var isActive = year?.isActive ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(year == null ? 'New Academic Year' : 'Edit Academic Year'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              ListTile(
                title: const Text('Start date'),
                subtitle: Text(_fmt(startDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => startDate = picked);
                },
              ),
              ListTile(
                title: const Text('End date'),
                subtitle: Text(_fmt(endDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => endDate = picked);
                },
              ),
              SwitchListTile(
                title: const Text('Active year'),
                value: isActive,
                onChanged: (value) => setDialogState(() => isActive = value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;

    await ref.read(academicRepositoryProvider).saveAcademicYear(
          AcademicYear(
            id: year?.id ?? '',
            schoolId: school.id,
            name: nameController.text.trim(),
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            createdAt: year?.createdAt ?? DateTime.now(),
          ),
        );
    ref.invalidate(academicYearsProvider);
    nameController.dispose();
  }

  String _fmt(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _TermsPanel extends ConsumerWidget {
  const _TermsPanel({required this.academicYear});

  final AcademicYear academicYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAsync = ref.watch(_termsProvider(academicYear.id));

    return termsAsync.when(
      loading: () => const LoadingView(message: 'Loading terms...'),
      error: (error, _) => ErrorView(message: '$error'),
      data: (terms) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Terms — ${academicYear.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showTermDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Term'),
                ),
              ],
            ),
          ),
          Expanded(
            child: terms.isEmpty
                ? const Center(child: Text('No terms for this year'))
                : ListView.builder(
                    itemCount: terms.length,
                    itemBuilder: (context, index) {
                      final term = terms[index];
                      return ListTile(
                        title: Text(term.name),
                        subtitle: Text('${_fmt(term.startDate)} – ${_fmt(term.endDate)}'),
                        trailing: term.isActive ? const Chip(label: Text('Active')) : null,
                        onTap: () => _showTermDialog(context, ref, term: term),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTermDialog(
    BuildContext context,
    WidgetRef ref, {
    Term? term,
  }) async {
    final nameController = TextEditingController(text: term?.name ?? '');
    var startDate = term?.startDate ?? academicYear.startDate;
    var endDate = term?.endDate ?? academicYear.startDate.add(const Duration(days: 90));
    var isActive = term?.isActive ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(term == null ? 'New Term' : 'Edit Term'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              SwitchListTile(
                title: const Text('Active term'),
                value: isActive,
                onChanged: (value) => setDialogState(() => isActive = value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;

    await ref.read(academicRepositoryProvider).saveTerm(
          Term(
            id: term?.id ?? '',
            academicYearId: academicYear.id,
            name: nameController.text.trim(),
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            createdAt: term?.createdAt ?? DateTime.now(),
          ),
        );
    ref.invalidate(_termsProvider(academicYear.id));
    nameController.dispose();
  }

  String _fmt(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

final _termsProvider = FutureProvider.family<List<Term>, String>((ref, yearId) {
  return ref.watch(academicRepositoryProvider).fetchTerms(yearId);
});

class _ClassesTab extends ConsumerWidget {
  const _ClassesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final teachersAsync = ref.watch(teachersProvider);

    return classesAsync.when(
      loading: () => const LoadingView(message: 'Loading classes...'),
      error: (error, _) => ErrorView(message: '$error', onRetry: () => ref.invalidate(classesProvider)),
      data: (classes) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Classes', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: yearsAsync.hasValue
                        ? () => _showClassDialog(
                              context,
                              ref,
                              years: yearsAsync.value ?? [],
                              teachers: teachersAsync.value ?? [],
                            )
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Class'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: classes.isEmpty
                  ? const Center(child: Text('No classes yet'))
                  : ListView.builder(
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final schoolClass = classes[index];
                        return ListTile(
                          title: Text(schoolClass.name),
                          subtitle: Text(
                            schoolClass.classTeacherName ?? 'No class teacher assigned',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.menu_book_outlined),
                            tooltip: 'Manage subjects',
                            onPressed: () => _showSubjectsDialog(context, ref, schoolClass),
                          ),
                          onTap: () => _showClassDialog(
                            context,
                            ref,
                            schoolClass: schoolClass,
                            years: yearsAsync.value ?? [],
                            teachers: teachersAsync.value ?? [],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showClassDialog(
    BuildContext context,
    WidgetRef ref, {
    SchoolClass? schoolClass,
    required List<AcademicYear> years,
    required List<Profile> teachers,
  }) async {
    final school = await ref.read(schoolProvider.future);
    if (school == null || years.isEmpty || !context.mounted) {
      if (context.mounted && years.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create an academic year first')),
        );
      }
      return;
    }

    final nameController = TextEditingController(text: schoolClass?.name ?? '');
    var yearId = schoolClass?.academicYearId ?? years.first.id;
    String? teacherId = schoolClass?.classTeacherId;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(schoolClass == null ? 'New Class' : 'Edit Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Class name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: yearId,
                decoration: const InputDecoration(labelText: 'Academic year'),
                items: [
                  for (final year in years)
                    DropdownMenuItem(value: year.id, child: Text(year.name)),
                ],
                onChanged: (value) => setDialogState(() => yearId = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: teacherId,
                decoration: const InputDecoration(labelText: 'Class teacher'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  for (final teacher in teachers)
                    DropdownMenuItem(value: teacher.id, child: Text(teacher.fullName)),
                ],
                onChanged: (value) => setDialogState(() => teacherId = value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;

    await ref.read(academicRepositoryProvider).saveClass(
          SchoolClass(
            id: schoolClass?.id ?? '',
            schoolId: school.id,
            academicYearId: yearId,
            name: nameController.text.trim(),
            classTeacherId: teacherId,
            createdAt: schoolClass?.createdAt ?? DateTime.now(),
          ),
        );
    ref.invalidate(classesProvider);
    nameController.dispose();
  }

  Future<void> _showSubjectsDialog(
    BuildContext context,
    WidgetRef ref,
    SchoolClass schoolClass,
  ) async {
    final subjects = await ref.read(subjectsProvider.future);
    final teachers = await ref.read(teachersProvider.future);
    final assigned = await ref
        .read(academicRepositoryProvider)
        .fetchClassSubjects(schoolClass.id);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => _ClassSubjectsDialog(
        schoolClass: schoolClass,
        subjects: subjects,
        teachers: teachers,
        assigned: assigned,
        onAssign: (subjectId, teacherId) async {
          await ref.read(academicRepositoryProvider).assignClassSubject(
                classId: schoolClass.id,
                subjectId: subjectId,
                teacherId: teacherId,
              );
        },
      ),
    );
  }
}

class _ClassSubjectsDialog extends StatefulWidget {
  const _ClassSubjectsDialog({
    required this.schoolClass,
    required this.subjects,
    required this.teachers,
    required this.assigned,
    required this.onAssign,
  });

  final SchoolClass schoolClass;
  final List<Subject> subjects;
  final List<Profile> teachers;
  final List<ClassSubject> assigned;
  final Future<void> Function(String subjectId, String? teacherId) onAssign;

  @override
  State<_ClassSubjectsDialog> createState() => _ClassSubjectsDialogState();
}

class _ClassSubjectsDialogState extends State<_ClassSubjectsDialog> {
  late List<ClassSubject> _assigned;

  @override
  void initState() {
    super.initState();
    _assigned = widget.assigned;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Subjects — ${widget.schoolClass.name}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final subject in widget.subjects)
              ListTile(
                title: Text('${subject.name} (${subject.code})'),
                subtitle: Text(
                  _assigned
                          .where((item) => item.subjectId == subject.id)
                          .map((item) => item.teacherName ?? 'No teacher')
                          .firstOrNull ??
                      'Not assigned',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add_alt_1),
                  onPressed: () => _pickTeacher(context, subject.id),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Future<void> _pickTeacher(BuildContext context, String subjectId) async {
    String? teacherId = _assigned
        .where((item) => item.subjectId == subjectId)
        .map((item) => item.teacherId)
        .firstOrNull;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign teacher'),
          content: DropdownButtonFormField<String?>(
            initialValue: teacherId,
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              for (final teacher in widget.teachers)
                DropdownMenuItem(value: teacher.id, child: Text(teacher.fullName)),
            ],
            onChanged: (value) => setDialogState(() => teacherId = value),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true) return;

    await widget.onAssign(subjectId, teacherId);
    if (!mounted) return;
    setState(() {
      final index = _assigned.indexWhere((item) => item.subjectId == subjectId);
      if (index >= 0) {
        _assigned[index] = ClassSubject(
          id: _assigned[index].id,
          classId: _assigned[index].classId,
          subjectId: subjectId,
          teacherId: teacherId,
          className: _assigned[index].className,
          subjectName: _assigned[index].subjectName,
          subjectCode: _assigned[index].subjectCode,
          teacherName: widget.teachers
              .where((t) => t.id == teacherId)
              .map((t) => t.fullName)
              .firstOrNull,
          creditHours: _assigned[index].creditHours,
        );
      } else {
        final subject = widget.subjects.firstWhere((s) => s.id == subjectId);
        _assigned.add(ClassSubject(
          id: '',
          classId: widget.schoolClass.id,
          subjectId: subjectId,
          teacherId: teacherId,
          className: widget.schoolClass.name,
          subjectName: subject.name,
          subjectCode: subject.code,
          teacherName: widget.teachers
              .where((t) => t.id == teacherId)
              .map((t) => t.fullName)
              .firstOrNull,
          creditHours: 1,
        ));
      }
    });
  }
}

class _SubjectsTab extends ConsumerWidget {
  const _SubjectsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return subjectsAsync.when(
      loading: () => const LoadingView(message: 'Loading subjects...'),
      error: (error, _) => ErrorView(message: '$error'),
      data: (subjects) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Subjects', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showSubjectDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subject'),
                ),
              ],
            ),
          ),
          Expanded(
            child: subjects.isEmpty
                ? const Center(child: Text('No subjects yet'))
                : ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return ListTile(
                        title: Text(subject.name),
                        subtitle: Text(subject.code),
                        onTap: () => _showSubjectDialog(context, ref, subject: subject),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubjectDialog(
    BuildContext context,
    WidgetRef ref, {
    Subject? subject,
  }) async {
    final school = await ref.read(schoolProvider.future);
    if (school == null || !context.mounted) return;

    final nameController = TextEditingController(text: subject?.name ?? '');
    final codeController = TextEditingController(text: subject?.code ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(subject == null ? 'New Subject' : 'Edit Subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    await ref.read(academicRepositoryProvider).saveSubject(
          Subject(
            id: subject?.id ?? '',
            schoolId: school.id,
            name: nameController.text.trim(),
            code: codeController.text.trim(),
            createdAt: subject?.createdAt ?? DateTime.now(),
          ),
        );
    ref.invalidate(subjectsProvider);
    nameController.dispose();
    codeController.dispose();
  }
}

class _EnrollmentsTab extends ConsumerStatefulWidget {
  const _EnrollmentsTab();

  @override
  ConsumerState<_EnrollmentsTab> createState() => _EnrollmentsTabState();
}

class _EnrollmentsTabState extends ConsumerState<_EnrollmentsTab> {
  SchoolClass? _selectedClass;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);
    final studentsAsync = ref.watch(studentsProvider);

    return classesAsync.when(
      loading: () => const LoadingView(message: 'Loading classes...'),
      error: (error, _) => ErrorView(message: '$error'),
      data: (classes) {
        _selectedClass ??= classes.firstOrNull;

        return Row(
          children: [
            SizedBox(
              width: 240,
              child: ListView(
                children: [
                  const ListTile(title: Text('Classes', style: TextStyle(fontWeight: FontWeight.bold))),
                  for (final item in classes)
                    ListTile(
                      selected: _selectedClass?.id == item.id,
                      title: Text(item.name),
                      onTap: () => setState(() => _selectedClass = item),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: _selectedClass == null
                  ? const Center(child: Text('Select a class'))
                  : _EnrollmentPanel(
                      schoolClass: _selectedClass!,
                      students: studentsAsync.value ?? [],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _EnrollmentPanel extends ConsumerWidget {
  const _EnrollmentPanel({
    required this.schoolClass,
    required this.students,
  });

  final SchoolClass schoolClass;
  final List<Profile> students;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(_enrollmentsProvider(schoolClass.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Enrolled — ${schoolClass.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: students.isEmpty
                    ? null
                    : () => _enrollStudent(context, ref),
                icon: const Icon(Icons.person_add),
                label: const Text('Enroll Student'),
              ),
            ],
          ),
        ),
        Expanded(
          child: enrollmentsAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(message: '$error'),
            data: (enrolled) => enrolled.isEmpty
                ? const Center(child: Text('No students enrolled'))
                : ListView.builder(
                    itemCount: enrolled.length,
                    itemBuilder: (context, index) {
                      final student = enrolled[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(student.fullName[0])),
                        title: Text(student.fullName),
                        subtitle: Text(student.rollNumber ?? student.email ?? ''),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _enrollStudent(BuildContext context, WidgetRef ref) async {
    var selectedId = students.first.id;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Enroll Student'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedId,
            items: [
              for (final student in students)
                DropdownMenuItem(value: student.id, child: Text(student.fullName)),
            ],
            onChanged: (value) {
              if (value != null) setDialogState(() => selectedId = value);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enroll')),
          ],
        ),
      ),
    );

    if (saved != true) return;

    await ref.read(academicRepositoryProvider).enrollStudent(
          studentId: selectedId,
          classId: schoolClass.id,
          academicYearId: schoolClass.academicYearId,
        );
    ref.invalidate(_enrollmentsProvider(schoolClass.id));
  }
}

final _enrollmentsProvider =
    FutureProvider.family<List<EnrolledStudent>, String>((ref, classId) {
  return ref.watch(academicRepositoryProvider).fetchEnrollments(classId);
});
