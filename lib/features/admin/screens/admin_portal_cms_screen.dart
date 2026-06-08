import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/models/portal_models.dart';
import '../../../shared/models/school.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../admin_nav.dart';
import '../providers/admin_providers.dart';
import '../../portal/providers/portal_providers.dart';

class AdminPortalCmsScreen extends ConsumerStatefulWidget {
  const AdminPortalCmsScreen({super.key});

  @override
  ConsumerState<AdminPortalCmsScreen> createState() =>
      _AdminPortalCmsScreenState();
}

class _AdminPortalCmsScreenState extends ConsumerState<AdminPortalCmsScreen> {
  final _mission = TextEditingController();
  final _vision = TextEditingController();
  final _about = TextEditingController();
  final _tagline = TextEditingController();
  final _website = TextEditingController();
  final _mapUrl = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _mission.dispose();
    _vision.dispose();
    _about.dispose();
    _tagline.dispose();
    _website.dispose();
    _mapUrl.dispose();
    super.dispose();
  }

  void _loadSchool(School? school) {
    if (school == null || _loaded) return;
    _mission.text = school.mission ?? '';
    _vision.text = school.vision ?? '';
    _about.text = school.about ?? '';
    _tagline.text = school.tagline ?? '';
    _website.text = school.website ?? AppConfig.publicWebsiteUrl;
    _mapUrl.text = school.mapUrl ?? '';
    _loaded = true;
  }

  Future<void> _save(School school) async {
    await ref.read(portalRepositoryProvider).updateSchoolPortal(
          School(
            id: school.id,
            name: school.name,
            logoUrl: school.logoUrl,
            motto: school.motto,
            tagline: _tagline.text.trim().isEmpty ? null : _tagline.text.trim(),
            mission: _mission.text.trim().isEmpty ? null : _mission.text.trim(),
            vision: _vision.text.trim().isEmpty ? null : _vision.text.trim(),
            about: _about.text.trim().isEmpty ? null : _about.text.trim(),
            address: school.address,
            phone: school.phone,
            email: school.email,
            website: _website.text.trim().isEmpty ? null : _website.text.trim(),
            mapUrl: _mapUrl.text.trim().isEmpty ? null : _mapUrl.text.trim(),
            createdAt: school.createdAt,
          ),
        );
    ref.invalidate(portalSchoolProvider);
    ref.invalidate(schoolProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Website content saved')),
    );
  }

  Future<void> _openWebsite() async {
    final url = Uri.parse(
      _website.text.trim().isEmpty
          ? AppConfig.publicWebsiteUrl
          : _website.text.trim(),
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _editAppRelease(PortalAppRelease release) async {
    final urlCtrl = TextEditingController(text: release.downloadUrl ?? '');
    final versionCtrl = TextEditingController(text: release.version ?? '');
    final notesCtrl = TextEditingController(text: release.releaseNotes ?? '');
    var enabled = release.isEnabled;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('${_platformLabel(release.platform)} download'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  labelText: release.platform == 'web'
                      ? 'Web app URL'
                      : 'Download URL',
                  hintText: release.platform == 'web'
                      ? AppConfig.appBaseUrl.isNotEmpty
                          ? AppConfig.appBaseUrl
                          : 'https://app.yourschool.com/login'
                      : 'https://...',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: versionCtrl,
                decoration: const InputDecoration(labelText: 'Version'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              SwitchListTile(
                title: const Text('Enabled on website'),
                value: enabled,
                onChanged: (v) => setDialog(() => enabled = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      urlCtrl.dispose();
      versionCtrl.dispose();
      notesCtrl.dispose();
      return;
    }

    await ref.read(portalRepositoryProvider).updateAppRelease(
          PortalAppRelease(
            id: release.id,
            schoolId: release.schoolId,
            platform: release.platform,
            downloadUrl: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
            version: versionCtrl.text.trim().isEmpty ? null : versionCtrl.text.trim(),
            releaseNotes:
                notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
            isEnabled: enabled,
            sortOrder: release.sortOrder,
          ),
        );
    urlCtrl.dispose();
    versionCtrl.dispose();
    notesCtrl.dispose();
    ref.invalidate(portalAppReleasesProvider);
  }

  String _platformLabel(String platform) => switch (platform) {
        'web' => 'Web app',
        'windows' => 'Windows',
        'android' => 'Android',
        'ios' => 'iOS',
        _ => platform,
      };

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final portalAsync = ref.watch(portalSchoolProvider);
    final releasesAsync = ref.watch(portalAppReleasesProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Admin Portal',
      subtitle: profile?.fullName,
      navItems: adminNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: portalAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('$e')),
        data: (school) {
          if (school == null) {
            return const Center(child: Text('Configure school first'));
          }
          _loadSchool(school);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Public Website CMS',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Content is published on your Next.js website (Vercel). '
                'Parents and visitors browse there; this app is for signed-in users.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _tagline,
                decoration: const InputDecoration(labelText: 'Tagline'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mission,
                decoration: const InputDecoration(labelText: 'Mission'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _vision,
                decoration: const InputDecoration(labelText: 'Vision'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _about,
                decoration: const InputDecoration(labelText: 'About us'),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _website,
                decoration: const InputDecoration(
                  labelText: 'Public website URL',
                  helperText: 'Next.js site on Vercel',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mapUrl,
                decoration: const InputDecoration(
                  labelText: 'Google Maps / location URL',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _save(school),
                child: const Text('Save website content'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openWebsite,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open public website'),
              ),
              const SizedBox(height: 32),
              Text(
                'App downloads (Get the App page)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Set download links for Windows, Android, iOS, and web. '
                'Web URL should point to your Flutter web app login.',
              ),
              const SizedBox(height: 12),
              releasesAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => Text('$e'),
                data: (releases) => Column(
                  children: [
                    for (final r in releases)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            switch (r.platform) {
                              'web' => Icons.language,
                              'windows' => Icons.desktop_windows_outlined,
                              'android' => Icons.android,
                              'ios' => Icons.phone_iphone,
                              _ => Icons.download_outlined,
                            },
                          ),
                          title: Text(_platformLabel(r.platform)),
                          subtitle: Text(
                            r.downloadUrl ?? 'No URL set',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Switch(
                            value: r.isEnabled,
                            onChanged: (_) => _editAppRelease(r),
                          ),
                          onTap: () => _editAppRelease(r),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
