import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/settings_providers.dart';
import '../../shared/models/platform_models.dart';

class AiChatbotFab extends ConsumerWidget {
  const AiChatbotFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(featureEnabledProvider(FeatureKeys.aiChatbot));

    return enabled.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (on) {
        if (!on) return const SizedBox.shrink();
        return Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _openChat(context),
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text('Ask AI'),
          ),
        );
      },
    );
  }

  void _openChat(BuildContext context) {
    final messageCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('School Assistant',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Ask about fees, schedules, assignments, or school policies. '
              'Connect your AI API key in Admin → Settings when ready.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageCtrl,
              decoration: const InputDecoration(
                hintText: 'How do I pay fees via Paybill?',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      messageCtrl.text.trim().isEmpty
                          ? 'AI assistant ready — configure API key in admin settings'
                          : 'Demo mode: "${messageCtrl.text.trim()}" — full AI replies when API key is set.',
                    ),
                  ),
                );
                messageCtrl.dispose();
              },
              child: const Text('Send'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
