import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/user_role.dart';

class AnalyticsData {
  const AnalyticsData({
    required this.roleCounts,
    required this.totalBilled,
    required this.totalCollected,
    required this.attendanceCounts,
    required this.enrollmentByClass,
  });

  final Map<UserRole, int> roleCounts;
  final double totalBilled;
  final double totalCollected;
  final Map<String, int> attendanceCounts;
  final Map<String, int> enrollmentByClass;
}

class AnalyticsRepository {
  AnalyticsRepository(this._client);

  final SupabaseClient _client;

  Future<AnalyticsData> fetchAnalytics() async {
    final roleCounts = <UserRole, int>{};
    for (final role in UserRole.values) {
      final data = await _client
          .from('profiles')
          .select('id')
          .eq('role', role.dbValue);
      roleCounts[role] = (data as List).length;
    }

    final invoices = await _client.from('invoices').select('amount, amount_paid');
    double totalBilled = 0;
    double totalCollected = 0;
    for (final row in invoices as List) {
      totalBilled += (row['amount'] as num).toDouble();
      totalCollected += (row['amount_paid'] as num?)?.toDouble() ?? 0;
    }

    final attendance = await _client.from('attendance').select('status');
    final attendanceCounts = <String, int>{};
    for (final row in attendance as List) {
      final status = row['status'] as String;
      attendanceCounts[status] = (attendanceCounts[status] ?? 0) + 1;
    }

    final enrollments = await _client
        .from('enrollments')
        .select('classes(name)')
        .eq('status', 'active');

    final enrollmentByClass = <String, int>{};
    for (final row in enrollments as List) {
      final classData = row['classes'] as Map<String, dynamic>?;
      final name = classData?['name'] as String? ?? 'Unknown';
      enrollmentByClass[name] = (enrollmentByClass[name] ?? 0) + 1;
    }

    return AnalyticsData(
      roleCounts: roleCounts,
      totalBilled: totalBilled,
      totalCollected: totalCollected,
      attendanceCounts: attendanceCounts,
      enrollmentByClass: enrollmentByClass,
    );
  }
}
