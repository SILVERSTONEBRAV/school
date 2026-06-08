import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/models/class_subject.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../teacher/providers/teacher_providers.dart';
import '../../teacher/teacher_nav.dart';
import '../providers/materials_providers.dart';

class TeacherMaterialsScreen extends ConsumerWidget {
  const TeacherMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final materialsAsync = ref.watch(teacherMaterialsProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Teacher Portal',
      subtitle: profile?.fullName,
      navItems: teacherNavItems,
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
                    'Course Materials',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final subjects =
                        await ref.read(teacherClassSubjectsProvider.future);
                    if (!context.mounted) return;
                    await _upload(context, ref, subjects);
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload material'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: materialsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => Center(child: Text('$e')),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Upload PDFs, slides, and notes for your classes',
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final m = items[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.menu_book_outlined),
                          title: Text(m.title),
                          subtitle: Text(m.description ?? m.fileName ?? ''),
                          trailing: const Icon(Icons.download_outlined),
                          onTap: () async {
                            final url = await ref
                                .read(materialsRepositoryProvider)
                                .getSignedUrl(m.fileUrl);
                            await launchUrl(Uri.parse(url));
                          },
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

  Future<void> _upload(
    BuildContext context,
    WidgetRef ref,
    List<ClassSubject> subjects,
  ) async {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No class subjects assigned')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    var subjectId = subjects.first.id;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            DropdownButtonFormField<String>(
              initialValue: subjectId,
              items: [
                for (final s in subjects)
                  DropdownMenuItem(
                    value: s.id,
                    child: Text(s.displayName),
                  ),
              ],
              onChanged: (v) => subjectId = v!,
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
            child: const Text('Next'),
          ),
        ],
      ),
    );

    if (ok != true) {
      titleCtrl.dispose();
      return;
    }

    final pick = await FilePicker.pickFiles(withData: true);
    if (pick == null || pick.files.single.bytes == null) {
      titleCtrl.dispose();
      return;
    }

    final profile = ref.read(currentProfileProvider).value!;
    final path = await ref.read(materialsRepositoryProvider).uploadFile(
          teacherId: profile.id,
          fileName: pick.files.single.name,
          bytes: pick.files.single.bytes!,
        );

    await ref.read(materialsRepositoryProvider).uploadMaterial(
          classSubjectId: subjectId,
          title: titleCtrl.text.trim().isEmpty
              ? pick.files.single.name
              : titleCtrl.text.trim(),
          fileUrl: path,
          uploadedBy: profile.id,
          fileName: pick.files.single.name,
        );

    titleCtrl.dispose();
    ref.invalidate(teacherMaterialsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material uploaded')),
      );
    }
  }
}
