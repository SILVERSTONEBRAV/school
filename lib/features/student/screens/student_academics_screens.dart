import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/services/report_card_service.dart';
import '../../../shared/models/attendance.dart';
import '../../../shared/models/grade_record.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/models/school.dart';
import '../../../shared/models/school_class.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../admin/providers/admin_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/student_providers.dart';
import '../student_nav.dart';

class StudentScheduleScreen extends ConsumerWidget {
  const StudentScheduleScreen({super.key});

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
      child: academicsAsync.when(
        loading: () => const LoadingView(message: 'Loading schedule...'),
        error: (error, _) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(studentAcademicsProvider),
        ),
        data: (academics) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                Text('My Schedule', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  academics.enrolledClass?.name ?? 'Not enrolled in a class',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                if (academics.subjects.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('No subjects assigned yet'),
                      subtitle: Text('Ask your admin to enroll you and assign subjects.'),
                    ),
                  )
                else
                  for (final subject in academics.subjects)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: Text(subject.subjectName ?? 'Subject'),
                        subtitle: Text(
                          '${subject.subjectCode ?? ''} · ${subject.teacherName ?? 'No teacher'}',
                        ),
                        trailing: Text('${subject.creditHours.toStringAsFixed(1)} cr'),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StudentGradesScreen extends ConsumerWidget {
  const StudentGradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final academicsAsync = ref.watch(studentAcademicsProvider);
    final schoolAsync = ref.watch(schoolProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Student Portal',
      subtitle: profile?.fullName,
      navItems: studentNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      showNotifications: true,
      child: academicsAsync.when(
        loading: () => const LoadingView(message: 'Loading grades...'),
        error: (error, _) => ErrorView(message: '$error'),
        data: (academics) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Grades',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    if (profile != null && academics.grades.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () => _downloadReportCard(
                          profile,
                          schoolAsync.value,
                          academics.enrolledClass,
                          academics.grades,
                          academics.attendancePercentage,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Report Card'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: academics.grades.isEmpty
                      ? const Center(child: Text('No grades posted yet'))
                      : ListView.separated(
                          itemCount: academics.grades.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final grade = academics.grades[index];
                            return Card(
                              child: ListTile(
                                title: Text(grade.subjectName ?? 'Subject'),
                                subtitle: Text(grade.termName ?? 'Term'),
                                trailing: Text(
                                  grade.score.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            );
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

  Future<void> _downloadReportCard(
    Profile profile,
    School? school,
    SchoolClass? enrolledClass,
    List<GradeRecord> grades,
    double attendancePercentage,
  ) async {
    final bytes = await ReportCardService().generateReportCard(
      student: profile,
      school: school,
      enrolledClass: enrolledClass,
      grades: grades,
      attendancePercentage: attendancePercentage,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'report_card_${profile.lastName}',
    );
  }
}

class StudentAttendanceScreen extends ConsumerWidget {
  const StudentAttendanceScreen({super.key});

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
      child: academicsAsync.when(
        loading: () => const LoadingView(message: 'Loading attendance...'),
        error: (error, _) => ErrorView(message: '$error'),
        data: (academics) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Attendance', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.pie_chart_outline),
                    title: const Text('Attendance rate'),
                    trailing: Text(
                      '${academics.attendancePercentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: academics.attendance.isEmpty
                      ? const Center(child: Text('No attendance records yet'))
                      : ListView.separated(
                          itemCount: academics.attendance.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final record = academics.attendance[index];
                            return Card(
                              child: ListTile(
                                title: Text(record.status.label),
                                subtitle: Text(_formatDate(record.date)),
                                leading: Icon(_iconForStatus(record.status)),
                              ),
                            );
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

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  IconData _iconForStatus(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.present => Icons.check_circle_outline,
      AttendanceStatus.absent => Icons.cancel_outlined,
      AttendanceStatus.late => Icons.schedule,
      AttendanceStatus.excused => Icons.info_outline,
    };
  }
}
