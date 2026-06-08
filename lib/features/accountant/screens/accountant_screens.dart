import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/fee.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../admin/providers/academic_providers.dart';
import '../../admin/providers/admin_providers.dart';
import '../../fees/providers/fees_providers.dart';
import '../accountant_nav.dart';

class AccountantDashboardScreen extends ConsumerWidget {
  const AccountantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final statsAsync = ref.watch(feeStatsProvider);
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
        child: statsAsync.when(
          loading: () => const LoadingView(message: 'Loading financial summary...'),
          error: (error, _) => ErrorView(message: '$error'),
          data: (stats) {
            return ListView(
              children: [
                Text('Financial Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _MoneyCard(
                      title: 'Total Billed',
                      amount: stats['totalDue'] ?? 0,
                      icon: Icons.receipt_long_outlined,
                    ),
                    _MoneyCard(
                      title: 'Collected',
                      amount: stats['totalCollected'] ?? 0,
                      icon: Icons.payments_outlined,
                      color: Colors.green,
                    ),
                    _MoneyCard(
                      title: 'Outstanding',
                      amount: stats['outstanding'] ?? 0,
                      icon: Icons.warning_amber_outlined,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AccountantFeeStructuresScreen extends ConsumerStatefulWidget {
  const AccountantFeeStructuresScreen({super.key});

  @override
  ConsumerState<AccountantFeeStructuresScreen> createState() =>
      _AccountantFeeStructuresScreenState();
}

class _AccountantFeeStructuresScreenState
    extends ConsumerState<AccountantFeeStructuresScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final feesAsync = ref.watch(feeStructuresProvider);
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
            Row(
              children: [
                Expanded(
                  child: Text('Fee Structures',
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                FilledButton.icon(
                  onPressed: () => _showFeeDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Fee'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: feesAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(message: '$error'),
                data: (fees) => fees.isEmpty
                    ? const Center(child: Text('No fee structures yet'))
                    : ListView.separated(
                        itemCount: fees.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final fee = fees[index];
                          return Card(
                            child: ListTile(
                              title: Text(fee.name),
                              subtitle: Text(
                                [
                                  if (fee.className != null) fee.className,
                                  if (fee.description != null) fee.description,
                                ].whereType<String>().join(' · '),
                              ),
                              trailing: Text('\$${fee.amount.toStringAsFixed(2)}'),
                              onTap: () => _showFeeDialog(context, fee: fee),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFeeDialog(BuildContext context, {FeeStructure? fee}) async {
    final school = await ref.read(schoolProvider.future);
    if (school == null || !context.mounted) return;

    final nameController = TextEditingController(text: fee?.name ?? '');
    final descController = TextEditingController(text: fee?.description ?? '');
    final amountController =
        TextEditingController(text: fee?.amount.toString() ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fee == null ? 'New Fee Structure' : 'Edit Fee Structure'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    await ref.read(feesRepositoryProvider).saveFeeStructure(
          FeeStructure(
            id: fee?.id ?? '',
            schoolId: school.id,
            name: nameController.text.trim(),
            description: descController.text.trim().isEmpty
                ? null
                : descController.text.trim(),
            amount: double.tryParse(amountController.text.trim()) ?? 0,
            createdAt: fee?.createdAt ?? DateTime.now(),
          ),
        );
    ref.invalidate(feeStructuresProvider);
    nameController.dispose();
    descController.dispose();
    amountController.dispose();
  }
}

class AccountantInvoicesScreen extends ConsumerStatefulWidget {
  const AccountantInvoicesScreen({super.key});

  @override
  ConsumerState<AccountantInvoicesScreen> createState() =>
      _AccountantInvoicesScreenState();
}

class _AccountantInvoicesScreenState extends ConsumerState<AccountantInvoicesScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final invoicesAsync = ref.watch(invoicesProvider);
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
            Row(
              children: [
                Expanded(
                  child: Text('Invoices',
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                FilledButton.icon(
                  onPressed: () => _createInvoice(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Invoice'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: invoicesAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(message: '$error'),
                data: (invoices) => invoices.isEmpty
                    ? const Center(child: Text('No invoices yet'))
                    : ListView.separated(
                        itemCount: invoices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final invoice = invoices[index];
                          return Card(
                            child: ListTile(
                              title: Text(invoice.studentName ?? 'Student'),
                              subtitle: Text(
                                '${invoice.feeName ?? 'Fee'} · ${invoice.status.label}',
                              ),
                              trailing: Text(
                                '\$${invoice.balance.toStringAsFixed(2)}',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createInvoice(BuildContext context) async {
    final students = await ref.read(studentsProvider.future);
    final fees = await ref.read(feeStructuresProvider.future);
    if (!context.mounted || students.isEmpty || fees.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Need at least one student and fee structure')),
        );
      }
      return;
    }

    var studentId = students.first.id;
    var feeId = fees.first.id;
    var amount = fees.first.amount;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Invoice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: studentId,
                decoration: const InputDecoration(labelText: 'Student'),
                items: [
                  for (final student in students)
                    DropdownMenuItem(
                      value: student.id,
                      child: Text(student.fullName),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => studentId = value);
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: feeId,
                decoration: const InputDecoration(labelText: 'Fee'),
                items: [
                  for (final fee in fees)
                    DropdownMenuItem(
                      value: fee.id,
                      child: Text(fee.name),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      feeId = value;
                      amount = fees.firstWhere((f) => f.id == value).amount;
                    });
                  }
                },
              ),
              Text('Amount: \$${amount.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (saved != true) return;

    await ref.read(feesRepositoryProvider).createInvoice(
          studentId: studentId,
          feeStructureId: feeId,
          amount: amount,
        );
    ref.invalidate(invoicesProvider);
    ref.invalidate(feeStatsProvider);
  }
}

class AccountantPaymentsScreen extends ConsumerStatefulWidget {
  const AccountantPaymentsScreen({super.key});

  @override
  ConsumerState<AccountantPaymentsScreen> createState() =>
      _AccountantPaymentsScreenState();
}

class _AccountantPaymentsScreenState extends ConsumerState<AccountantPaymentsScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final paymentsAsync = ref.watch(paymentsProvider);
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
            Row(
              children: [
                Expanded(
                  child: Text('Payments',
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                FilledButton.icon(
                  onPressed: () => _recordPayment(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Record Payment'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: paymentsAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(message: '$error'),
                data: (payments) => payments.isEmpty
                    ? const Center(child: Text('No payments recorded'))
                    : ListView.separated(
                        itemCount: payments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          return Card(
                            child: ListTile(
                              title: Text(payment.studentName ?? 'Student'),
                              subtitle: Text(
                                '${payment.feeName ?? 'Fee'} · ${payment.paymentMethod}',
                              ),
                              trailing: Text('\$${payment.amount.toStringAsFixed(2)}'),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordPayment(BuildContext context) async {
    final invoices = await ref.read(invoicesProvider.future);
    final openInvoices =
        invoices.where((inv) => inv.balance > 0).toList();

    if (!context.mounted || openInvoices.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No open invoices to pay')),
        );
      }
      return;
    }

    var selectedId = openInvoices.first.id;
    var selected = openInvoices.first;
    final amountController =
        TextEditingController(text: selected.balance.toStringAsFixed(2));
    var method = 'cash';

    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration: const InputDecoration(labelText: 'Invoice'),
                items: [
                  for (final invoice in openInvoices)
                    DropdownMenuItem(
                      value: invoice.id,
                      child: Text(
                        '${invoice.studentName} — ${invoice.feeName}',
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedId = value;
                      selected = openInvoices.firstWhere((inv) => inv.id == value);
                      amountController.text = selected.balance.toStringAsFixed(2);
                    });
                  }
                },
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: const InputDecoration(labelText: 'Method'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => method = value);
                },
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

    await ref.read(feesRepositoryProvider).recordPayment(
          invoiceId: selected.id,
          studentId: selected.studentId,
          amount: double.tryParse(amountController.text.trim()) ?? 0,
          paymentMethod: method,
          recordedBy: profile.id,
        );
    ref.invalidate(paymentsProvider);
    ref.invalidate(invoicesProvider);
    ref.invalidate(feeStatsProvider);
    amountController.dispose();
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.title,
    required this.amount,
    required this.icon,
    this.color,
  });

  final String title;
  final double amount;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text('\$${amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
