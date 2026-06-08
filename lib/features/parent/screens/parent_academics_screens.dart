import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/attendance.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../payments/providers/payments_providers.dart';
import '../../payments/widgets/pay_fees_sheet.dart';
import '../parent_nav.dart';
import '../providers/parent_providers.dart';
import 'parent_dashboard_screen.dart';

class ParentGradesScreen extends ConsumerWidget {
  const ParentGradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final academicsAsync = ref.watch(selectedChildAcademicsProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Parent Portal',
      subtitle: profile?.fullName,
      navItems: parentNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Grades', style: Theme.of(context).textTheme.headlineMedium),
                ),
                const ChildSelector(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: academicsAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(message: '$error'),
                data: (academics) {
                  if (academics == null || academics.grades.isEmpty) {
                    return const Center(child: Text('No grades available'));
                  }

                  return ListView.separated(
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParentAttendanceScreen extends ConsumerWidget {
  const ParentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final academicsAsync = ref.watch(selectedChildAcademicsProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Parent Portal',
      subtitle: profile?.fullName,
      navItems: parentNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Attendance',
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                const ChildSelector(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: academicsAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(message: '$error'),
                data: (academics) {
                  if (academics == null) {
                    return const Center(child: Text('Select a child'));
                  }

                  return Column(
                    children: [
                      Card(
                        child: ListTile(
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
                            ? const Center(child: Text('No records yet'))
                            : ListView.separated(
                                itemCount: academics.attendance.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final record = academics.attendance[index];
                                  return Card(
                                    child: ListTile(
                                      leading: Icon(_iconForStatus(record.status)),
                                      title: Text(record.status.label),
                                      subtitle: Text(_formatDate(record.date)),
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
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  IconData _iconForStatus(AttendanceStatus status) => switch (status) {
        AttendanceStatus.present => Icons.check_circle_outline,
        AttendanceStatus.absent => Icons.cancel_outlined,
        AttendanceStatus.late => Icons.schedule,
        AttendanceStatus.excused => Icons.info_outline,
      };
}

class ParentFeesScreen extends ConsumerWidget {
  const ParentFeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final child = ref.watch(selectedChildProvider);
    final feesAsync = ref.watch(selectedChildFeesProvider);
    final creditsAsync = child == null
        ? const AsyncValue<List<FeeCredit>>.data([])
        : ref.watch(feeCreditsProvider(child.studentId));
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Parent Portal',
      subtitle: profile?.fullName,
      navItems: parentNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fees',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const ChildSelector(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: feesAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(message: '$error'),
                data: (fees) => ListView(
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _FeeStatCard(title: 'Total Due', value: fees.totalDue),
                        _FeeStatCard(title: 'Paid', value: fees.totalPaid),
                        _FeeStatCard(
                          title: 'Outstanding',
                          value: fees.outstanding,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    creditsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (credits) {
                        if (credits.isEmpty) return const SizedBox.shrink();
                        final total = credits.fold<double>(
                          0,
                          (sum, c) => sum + c.remainingAmount,
                        );
                        return Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: ListTile(
                            leading: const Icon(Icons.savings_outlined),
                            title: const Text('Fee credit balance'),
                            subtitle: const Text(
                              'Overpayments carried to next term/year',
                            ),
                            trailing: Text(
                              total.toStringAsFixed(2),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Invoices',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (fees.invoices.isEmpty)
                      const Card(child: ListTile(title: Text('No invoices')))
                    else
                      for (final invoice in fees.invoices)
                        Card(
                          child: ListTile(
                            title: Text(invoice.feeName ?? 'Fee'),
                            subtitle: Text(invoice.status.label),
                            trailing: invoice.balance > 0 && child != null
                                ? FilledButton(
                                    onPressed: () async {
                                      await showPayFeesSheet(
                                        context,
                                        ref,
                                        studentId: child.studentId,
                                        invoice: invoice,
                                      );
                                      ref.invalidate(selectedChildFeesProvider);
                                      ref.invalidate(
                                        feeCreditsProvider(child.studentId),
                                      );
                                    },
                                    child: Text(
                                      'Pay ${invoice.balance.toStringAsFixed(0)}',
                                    ),
                                  )
                                : Text(
                                    '\$${invoice.balance.toStringAsFixed(2)} due',
                                  ),
                          ),
                        ),
                    const SizedBox(height: 16),
                    Text(
                      'Payment History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (fees.payments.isEmpty)
                      const Card(child: ListTile(title: Text('No payments yet')))
                    else
                      for (final payment in fees.payments)
                        Card(
                          child: ListTile(
                            title: Text(payment.feeName ?? 'Payment'),
                            subtitle: Text(payment.paymentMethod),
                            trailing: Text(
                              '\$${payment.amount.toStringAsFixed(2)}',
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeStatCard extends StatelessWidget {
  const _FeeStatCard({required this.title, required this.value});

  final String title;
  final double value;

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
              Text('\$${value.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
