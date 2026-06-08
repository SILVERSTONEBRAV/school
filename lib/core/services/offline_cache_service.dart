import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheService {
  Future<void> save(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
    await prefs.setString('${key}_at', DateTime.now().toIso8601String());
  }

  Future<Map<String, dynamic>?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<DateTime?> loadedAt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${key}_at');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}
