import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../admin/admin_nav.dart';
import '../../auth/providers/auth_providers.dart';
import '../../settings/providers/settings_providers.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final flagsAsync = ref.watch(featureFlagsProvider);
    final paymentsAsync = ref.watch(paymentMethodConfigsProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Admin Portal',
      subtitle: profile?.fullName,
      navItems: adminNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Platform Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Features'),
                Tab(text: 'Payment Methods'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  flagsAsync.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (flags) => ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Card(
                          child: ListTile(
                            title: Text('API keys & integrations'),
                            subtitle: Text(
                              'Toggle features on/off. Enter API keys in each feature config (stored securely). '
                              'Payment credentials are configured in the Payment Methods tab.',
                            ),
                          ),
                        ),
                        for (final flag in flags)
                          SwitchListTile(
                            title: Text(FeatureKeys.label(flag.featureKey)),
                            subtitle: Text(
                              flag.config.isEmpty
                                  ? 'No config yet'
                                  : flag.config.entries
                                      .map((e) => '${e.key}: ${e.value}')
                                      .join(', '),
                            ),
                            value: flag.isEnabled,
                            onChanged: (v) async {
                              await ref
                                  .read(settingsRepositoryProvider)
                                  .updateFeatureFlag(FeatureFlag(
                                    id: flag.id,
                                    schoolId: flag.schoolId,
                                    featureKey: flag.featureKey,
                                    isEnabled: v,
                                    config: flag.config,
                                  ));
                              ref.invalidate(featureFlagsProvider);
                            },
                          ),
                      ],
                    ),
                  ),
                  paymentsAsync.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (methods) => ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final method in methods)
                          Card(
                            child: ExpansionTile(
                              leading: Icon(
                                method.isManual
                                    ? Icons.payments_outlined
                                    : Icons.cloud_outlined,
                              ),
                              title: Text(method.displayName),
                              subtitle: Text(method.channel),
                              trailing: Switch(
                                value: method.isEnabled,
                                onChanged: (v) async {
                                  await ref
                                      .read(settingsRepositoryProvider)
                                      .updatePaymentMethod(PaymentMethodConfig(
                                        id: method.id,
                                        schoolId: method.schoolId,
                                        channel: method.channel,
                                        isEnabled: v,
                                        displayName: method.displayName,
                                        config: method.config,
                                        instructions: method.instructions,
                                      ));
                                  ref.invalidate(paymentMethodConfigsProvider);
                                },
                              ),
                              children: [
                                if (method.instructions != null)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(method.instructions!),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Config: ${method.config}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Text(
                                    'Edit config JSON in Supabase dashboard or extend admin UI. '
                                    'Keys: till_number, paybill, account_number, consumer_key, publishable_key, etc.',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
