import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../fees/providers/fees_providers.dart';
import '../../payments/providers/payments_providers.dart';
import '../../payments/widgets/pay_fees_sheet.dart';
import '../student_nav.dart';

class StudentFeesScreen extends ConsumerWidget {
  const StudentFeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final feesAsync = ref.watch(studentFeesProvider);
    final creditsAsync = profile == null
        ? const AsyncValue<List<FeeCredit>>.data([])
        : ref.watch(feeCreditsProvider(profile.id));
    final submissionsAsync = profile == null
        ? const AsyncValue<List<PaymentSubmission>>.data([])
        : ref.watch(studentPaymentSubmissionsProvider(profile.id));
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Student Portal',
      subtitle: profile?.fullName,
      navItems: studentNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: feesAsync.when(
          loading: () => const LoadingView(message: 'Loading fees...'),
          error: (error, _) => ErrorView(message: '$error'),
          data: (fees) {
            return ListView(
              children: [
                Text(
                  'Fee Management',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _FeeCard(title: 'Total Due', value: fees.totalDue),
                    _FeeCard(title: 'Paid', value: fees.totalPaid),
                    _FeeCard(title: 'Outstanding', value: fees.outstanding),
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
                Text('Invoices', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (fees.invoices.isEmpty)
                  const Card(child: ListTile(title: Text('No invoices')))
                else
                  for (final invoice in fees.invoices)
                    Card(
                      child: ListTile(
                        title: Text(invoice.feeName ?? 'Fee'),
                        subtitle: Text(invoice.status.label),
                        trailing: invoice.balance > 0 && profile != null
                            ? FilledButton(
                                onPressed: () async {
                                  await showPayFeesSheet(
                                    context,
                                    ref,
                                    studentId: profile.id,
                                    invoice: invoice,
                                  );
                                  ref.invalidate(studentFeesProvider);
                                  ref.invalidate(feeCreditsProvider(profile.id));
                                  ref.invalidate(
                                    studentPaymentSubmissionsProvider(profile.id),
                                  );
                                },
                                child: Text(
                                  'Pay ${invoice.balance.toStringAsFixed(0)}',
                                ),
                              )
                            : Text('\$${invoice.balance.toStringAsFixed(2)}'),
                      ),
                    ),
                const SizedBox(height: 16),
                Text(
                  'Pending Submissions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                submissionsAsync.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => Text('$e'),
                  data: (items) {
                    final pending = items
                        .where((p) => p.status == PaymentSubmissionStatus.pending)
                        .toList();
                    if (pending.isEmpty) {
                      return const Card(
                        child: ListTile(title: Text('No pending payments')),
                      );
                    }
                    return Column(
                      children: [
                        for (final p in pending)
                          Card(
                            child: ListTile(
                              title: Text(p.amount.toStringAsFixed(2)),
                              subtitle: Text(
                                '${p.channel} · ${p.referenceCode ?? "—"}',
                              ),
                              trailing: Chip(label: Text(p.status.label)),
                            ),
                          ),
                      ],
                    );
                  },
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
                        trailing: Text('\$${payment.amount.toStringAsFixed(2)}'),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  const _FeeCard({required this.title, required this.value});

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
              Text(
                '\$${value.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
