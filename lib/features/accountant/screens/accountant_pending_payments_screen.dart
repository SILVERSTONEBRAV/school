import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../../payments/providers/payments_providers.dart';
import '../accountant_nav.dart';

class AccountantPendingPaymentsScreen extends ConsumerWidget {
  const AccountantPendingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final pendingAsync = ref.watch(pendingPaymentsProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Accountant Portal',
      subtitle: profile?.fullName,
      navItems: accountantNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pending Payments',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Confirm manual payments (Till, Paybill, Bank). '
              'Excess amounts are automatically credited for next term.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pendingAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => Center(child: Text('$e')),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No pending payments'));
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final p = items[i];
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${p.studentName ?? "Student"} — ${p.amount.toStringAsFixed(2)}',
                          ),
                          subtitle: Text(
                            '${p.channel} · Ref: ${p.referenceCode ?? "—"}\n${p.status.label}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                color: Colors.green,
                                tooltip: 'Confirm',
                                onPressed: profile == null
                                    ? null
                                    : () async {
                                        await ref
                                            .read(paymentsRepositoryProvider)
                                            .confirmSubmission(p.id, profile.id);
                                        await ref
                                            .read(notificationsRepositoryProvider)
                                            .notifyUsers(
                                              userIds: [p.submittedBy],
                                              title: 'Payment confirmed',
                                              body:
                                                  'Your payment of ${p.amount.toStringAsFixed(2)} has been confirmed.',
                                              type: 'payment',
                                              referenceId: p.id,
                                            );
                                        ref.invalidate(pendingPaymentsProvider);
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined),
                                color: Colors.red,
                                tooltip: 'Reject',
                                onPressed: () async {
                                  await ref
                                      .read(paymentsRepositoryProvider)
                                      .rejectSubmission(
                                        p.id,
                                        'Rejected by accountant',
                                      );
                                  ref.invalidate(pendingPaymentsProvider);
                                },
                              ),
                            ],
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
