import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../admin_nav.dart';
import '../data/analytics_repository.dart';
import '../providers/analytics_providers.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  static const _roleColors = [
    Color(0xFF1E3A5F),
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final analyticsAsync = ref.watch(analyticsProvider);
    final location = GoRouterState.of(context).uri.path;

    return AppShell(
      title: 'Admin Portal',
      subtitle: profile?.fullName,
      navItems: adminNavItems,
      selectedRoute: location,
      onNavigate: (route) => context.go(route),
      onSignOut: () => ref.read(authRepositoryProvider).signOut(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: analyticsAsync.when(
          loading: () => const LoadingView(message: 'Loading analytics...'),
          error: (error, _) => ErrorView(
            message: '$error',
            onRetry: () => ref.invalidate(analyticsProvider),
          ),
          data: (data) => ListView(
            children: [
              Text(
                'Analytics',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SummaryCard(
                    title: 'Total Billed',
                    value: '\$${data.totalBilled.toStringAsFixed(0)}',
                  ),
                  _SummaryCard(
                    title: 'Collected',
                    value: '\$${data.totalCollected.toStringAsFixed(0)}',
                  ),
                  _SummaryCard(
                    title: 'Outstanding',
                    value:
                        '\$${(data.totalBilled - data.totalCollected).toStringAsFixed(0)}',
                  ),
                  _SummaryCard(
                    title: 'Enrollments',
                    value: '${data.enrollmentByClass.values.fold(0, (a, b) => a + b)}',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _RoleChart(data: data)),
                  const SizedBox(width: 16),
                  Expanded(child: _FeeChart(data: data)),
                ],
              ),
              const SizedBox(height: 24),
              if (data.attendanceCounts.isNotEmpty) _AttendanceChart(data: data),
              if (data.enrollmentByClass.isNotEmpty) ...[
                const SizedBox(height: 24),
                _EnrollmentChart(data: data),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChart extends StatelessWidget {
  const _RoleChart({required this.data});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final roles = UserRole.values.where((r) => (data.roleCounts[r] ?? 0) > 0).toList();
    if (roles.isEmpty) {
      return const Card(
        child: SizedBox(height: 200, child: Center(child: Text('No user data'))),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Users by Role', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    for (var i = 0; i < roles.length; i++)
                      PieChartSectionData(
                        value: (data.roleCounts[roles[i]] ?? 0).toDouble(),
                        title: roles[i].label,
                        color: AdminAnalyticsScreen._roleColors[i % 6],
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeChart extends StatelessWidget {
  const _FeeChart({required this.data});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final outstanding = data.totalBilled - data.totalCollected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fee Collection', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: [data.totalBilled, data.totalCollected, outstanding]
                          .reduce((a, b) => a > b ? a : b) *
                      1.2 +
                      1,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(
                        toY: data.totalBilled,
                        color: Colors.blueGrey,
                        width: 28,
                      ),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(
                        toY: data.totalCollected,
                        color: Colors.green,
                        width: 28,
                      ),
                    ]),
                    BarChartGroupData(x: 2, barRods: [
                      BarChartRodData(
                        toY: outstanding,
                        color: Colors.orange,
                        width: 28,
                      ),
                    ]),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) => switch (value.toInt()) {
                          0 => const Text('Billed', style: TextStyle(fontSize: 10)),
                          1 => const Text('Paid', style: TextStyle(fontSize: 10)),
                          2 => const Text('Due', style: TextStyle(fontSize: 10)),
                          _ => const Text(''),
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceChart extends StatelessWidget {
  const _AttendanceChart({required this.data});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final entries = data.attendanceCounts.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance Overview',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: entries.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble() * 1.2 + 1,
                  barGroups: [
                    for (var i = 0; i < entries.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: entries[i].value.toDouble(),
                            color: _statusColor(entries[i].key),
                            width: 28,
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          if (value.toInt() >= entries.length) {
                            return const Text('');
                          }
                          return Text(
                            entries[value.toInt()].key,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'present' => Colors.green,
        'absent' => Colors.red,
        'late' => Colors.orange,
        'excused' => Colors.blue,
        _ => Colors.grey,
      };
}

class _EnrollmentChart extends StatelessWidget {
  const _EnrollmentChart({required this.data});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final entries = data.enrollmentByClass.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enrollment by Class',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('${entry.value} students'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
