import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_role.dart';
import '../providers/admin_providers.dart';

/// CSV format: first_name,last_name,email,password,roll_number
class BulkStudentImportDialog extends ConsumerStatefulWidget {
  const BulkStudentImportDialog({super.key});

  @override
  ConsumerState<BulkStudentImportDialog> createState() =>
      _BulkStudentImportDialogState();
}

class _BulkStudentImportDialogState
    extends ConsumerState<BulkStudentImportDialog> {
  bool _isImporting = false;
  int _done = 0;
  int _total = 0;
  final _errors = <String>[];

  Future<void> _pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    final text = String.fromCharCodes(result.files.single.bytes!);
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return;

    final rows = <List<String>>[];
    for (var i = 0; i < lines.length; i++) {
      if (i == 0 && lines[i].toLowerCase().contains('email')) continue;
      rows.add(lines[i].split(',').map((c) => c.trim()).toList());
    }

    setState(() {
      _isImporting = true;
      _done = 0;
      _total = rows.length;
      _errors.clear();
    });

    final school = ref.read(schoolProvider).value;
    final service = ref.read(adminUserServiceProvider);

    for (final row in rows) {
      if (row.length < 4) {
        _errors.add('Invalid row: ${row.join(",")}');
        setState(() => _done++);
        continue;
      }

      try {
        await service.createUser(
          email: row[2],
          password: row[3],
          firstName: row[0],
          lastName: row[1],
          role: UserRole.student,
          schoolId: school?.id,
          rollNumber: row.length > 4 ? row[4] : null,
        );
      } catch (error) {
        _errors.add('${row[2]}: $error');
      }

      if (mounted) setState(() => _done++);
    }

    if (mounted) setState(() => _isImporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk import students'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload a CSV file with columns:\n'
              'first_name, last_name, email, password, roll_number',
            ),
            if (_isImporting) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _total > 0 ? _done / _total : null),
              Text('Importing $_done / $_total'),
            ],
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${_errors.length} errors',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              SizedBox(
                height: 80,
                child: ListView(
                  children: _errors
                      .take(5)
                      .map((e) => Text(e, style: const TextStyle(fontSize: 12)))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _isImporting ? null : _pickAndImport,
          child: const Text('Choose CSV'),
        ),
      ],
    );
  }
}
