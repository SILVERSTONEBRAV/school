import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;
  static const _bucket = 'assignments';

  Future<String> uploadAssignmentFile({
    required String studentId,
    required String assignmentId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$studentId/$assignmentId/$fileName';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return path;
  }

  Future<String> getSignedUrl(String path) async {
    return _client.storage.from(_bucket).createSignedUrl(path, 3600);
  }
}
