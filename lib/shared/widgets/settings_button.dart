import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_settings_providers.dart';
import '../../l10n/app_localizations.dart';

class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => _showSettings(context, ref),
      icon: const Icon(Icons.settings_outlined),
      tooltip: AppLocalizations.of(context).settings,
    );
  }

  Future<void> _showSettings(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.read(themeModeProvider);
    final locale = ref.read(localeProvider);

    await showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.settings, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(l10n.theme),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l10n.systemTheme)),
                ButtonSegment(value: ThemeMode.light, label: Text(l10n.lightTheme)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l10n.darkTheme)),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) {
                ref.read(themeModeProvider.notifier).setTheme(selection.first);
              },
            ),
            const SizedBox(height: 20),
            Text(l10n.language),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'en', label: Text(l10n.english)),
                ButtonSegment(value: 'sw', label: Text(l10n.swahili)),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (selection) {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(Locale(selection.first));
              },
            ),
          ],
        ),
      ),
    );
  }
}
