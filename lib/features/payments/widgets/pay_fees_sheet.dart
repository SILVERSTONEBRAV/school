import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/fee.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../providers/payments_providers.dart';

Future<void> showPayFeesSheet(
  BuildContext context,
  WidgetRef ref, {
  required String studentId,
  required Invoice invoice,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _PayFeesSheet(studentId: studentId, invoice: invoice),
  );
}

class _PayFeesSheet extends ConsumerStatefulWidget {
  const _PayFeesSheet({required this.studentId, required this.invoice});

  final String studentId;
  final Invoice invoice;

  @override
  ConsumerState<_PayFeesSheet> createState() => _PayFeesSheetState();
}

class _PayFeesSheetState extends ConsumerState<_PayFeesSheet> {
  PaymentMethodConfig? _method;
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _amount.text = widget.invoice.balance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_method == null) return;
    setState(() => _loading = true);

    try {
      final profile = ref.read(currentProfileProvider).value!;
      final schoolId = await ref.read(schoolIdProvider.future);
      String? proofUrl;

      if (_method!.isManual) {
        final pick = await FilePicker.pickFiles(withData: true);
        if (pick != null && pick.files.single.bytes != null) {
          proofUrl = await ref.read(paymentsRepositoryProvider).uploadProof(
                studentId: widget.studentId,
                fileName: pick.files.single.name,
                bytes: pick.files.single.bytes!,
              );
        }
      }

      final submission = await ref.read(paymentsRepositoryProvider).submitPayment(
            schoolId: schoolId!,
            studentId: widget.studentId,
            submittedBy: profile.id,
            invoiceId: widget.invoice.id,
            amount: double.parse(_amount.text),
            channel: _method!.channel,
            referenceCode: _reference.text,
            payerPhone: _phone.text,
            proofFileUrl: proofUrl,
          );

      if (_method!.channel == 'mpesa_online') {
        await ref.read(paymentsRepositoryProvider).initiateMpesaPayment(
              phone: _phone.text,
              amount: double.parse(_amount.text),
              reference: _reference.text,
            );
      } else if (_method!.channel == 'stripe_online') {
        await ref.read(paymentsRepositoryProvider).initiateStripePayment(
              amount: double.parse(_amount.text),
              reference: _reference.text,
            );
      }

      await ref.read(notificationsRepositoryProvider).notifyUsers(
            userIds: [profile.id],
            title: 'Payment submitted',
            body: 'Your payment of ${_amount.text} is pending confirmation.',
            type: 'payment',
            referenceId: submission.id,
          );

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _method!.isManual
                ? 'Payment submitted — awaiting accountant confirmation'
                : 'Online payment initiated',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final methods = ref.watch(enabledPaymentMethodsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pay ${widget.invoice.feeName ?? "Fee"}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          methods.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (items) {
              if (items.isEmpty) {
                return const Text(
                  'No payment methods enabled. Contact school admin.',
                );
              }
              return DropdownButtonFormField<PaymentMethodConfig>(
                decoration: const InputDecoration(labelText: 'Payment method'),
                items: [
                  for (final m in items)
                    DropdownMenuItem(value: m, child: Text(m.displayName)),
                ],
                onChanged: (v) => setState(() => _method = v),
              );
            },
          ),
          if (_method != null && _method!.instructions != null) ...[
            const SizedBox(height: 8),
            Text(
              _method!.instructions!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_method!.config.isNotEmpty)
              Text(
                _method!.config.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join('\n'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reference,
            decoration: const InputDecoration(
              labelText: 'M-Pesa / transaction reference',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Payer phone'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading || _method == null ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit payment'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
