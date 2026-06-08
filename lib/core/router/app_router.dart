import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/accountant/screens/accountant_pending_payments_screen.dart';
import '../../features/accountant/screens/accountant_screens.dart';
import '../../features/admin/screens/academic_management_screen.dart';
import '../../features/admin/screens/admin_analytics_screen.dart';
import '../../features/admin/screens/admin_announcements_screen.dart';
import '../../features/admin/screens/admin_command_center_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_portal_cms_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/admin/screens/school_setup_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/update_password_screen.dart';
import '../../features/materials/screens/teacher_materials_screen.dart';
import '../../features/parent/screens/parent_academics_screens.dart';
import '../../features/parent/screens/parent_assignments_screen.dart';
import '../../features/parent/screens/parent_dashboard_screen.dart';
import '../../features/staff/screens/staff_dashboard_screen.dart';
import '../../features/student/screens/student_academics_screens.dart';
import '../../features/student/screens/student_dashboard_screen.dart';
import '../../features/student/screens/student_assignments_screen.dart';
import '../../features/student/screens/student_fees_screen.dart';
import '../../features/teacher/screens/teacher_assignments_screen.dart';
import '../../features/teacher/screens/teacher_attendance_screen.dart';
import '../../features/teacher/screens/teacher_dashboard_screen.dart';
import '../../features/teacher/screens/teacher_gradebook_screen.dart';
import '../../shared/models/user_role.dart';
import '../constants/app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileAsync = ref.watch(currentProfileProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: _RouterRefresh(authState, profileAsync),
    redirect: (context, state) {
      final isLoading = authState.isLoading || profileAsync.isLoading;
      final session = authState.value?.session;
      final profile = profileAsync.value;
      final authEvent = authState.value?.event;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (isLoading) return null;

      if (state.matchedLocation == AppRoutes.updatePassword &&
          (authEvent == AuthChangeEvent.passwordRecovery || session != null)) {
        return null;
      }

      if (authEvent == AuthChangeEvent.passwordRecovery) {
        return AppRoutes.updatePassword;
      }

      if (session == null) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      if (profileAsync.hasError) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      if (profile == null) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      if (isAuthRoute) {
        return profile.role.homeRoute;
      }

      if (!_isAllowedRoute(state.matchedLocation, profile.role)) {
        return profile.role.homeRoute;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => RegisterScreen(
          inviteToken: state.uri.queryParameters['invite'],
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.updatePassword,
        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'school',
            builder: (context, state) => const SchoolSetupScreen(),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) => const UserManagementScreen(),
          ),
          GoRoute(
            path: 'academic',
            builder: (context, state) => const AcademicManagementScreen(),
          ),
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AdminAnalyticsScreen(),
          ),
          GoRoute(
            path: 'announcements',
            builder: (context, state) => const AdminAnnouncementsScreen(),
          ),
          GoRoute(
            path: 'command-center',
            builder: (context, state) => const AdminCommandCenterScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
          GoRoute(
            path: 'portal',
            builder: (context, state) => const AdminPortalCmsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.teacher,
        builder: (context, state) => const TeacherDashboardScreen(),
        routes: [
          GoRoute(
            path: 'attendance',
            builder: (context, state) => const TeacherAttendanceScreen(),
          ),
          GoRoute(
            path: 'gradebook',
            builder: (context, state) => const TeacherGradebookScreen(),
          ),
          GoRoute(
            path: 'assignments',
            builder: (context, state) => const TeacherAssignmentsScreen(),
          ),
          GoRoute(
            path: 'materials',
            builder: (context, state) => const TeacherMaterialsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.student,
        builder: (context, state) => const StudentDashboardScreen(),
        routes: [
          GoRoute(
            path: 'assignments',
            builder: (context, state) => const StudentAssignmentsScreen(),
          ),
          GoRoute(
            path: 'schedule',
            builder: (context, state) => const StudentScheduleScreen(),
          ),
          GoRoute(
            path: 'grades',
            builder: (context, state) => const StudentGradesScreen(),
          ),
          GoRoute(
            path: 'attendance',
            builder: (context, state) => const StudentAttendanceScreen(),
          ),
          GoRoute(
            path: 'fees',
            builder: (context, state) => const StudentFeesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.parent,
        builder: (context, state) => const ParentDashboardScreen(),
        routes: [
          GoRoute(
            path: 'assignments',
            builder: (context, state) => const ParentAssignmentsScreen(),
          ),
          GoRoute(
            path: 'grades',
            builder: (context, state) => const ParentGradesScreen(),
          ),
          GoRoute(
            path: 'attendance',
            builder: (context, state) => const ParentAttendanceScreen(),
          ),
          GoRoute(
            path: 'fees',
            builder: (context, state) => const ParentFeesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.staff,
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountant,
        builder: (context, state) => const AccountantDashboardScreen(),
        routes: [
          GoRoute(
            path: 'fees',
            builder: (context, state) => const AccountantFeeStructuresScreen(),
          ),
          GoRoute(
            path: 'invoices',
            builder: (context, state) => const AccountantInvoicesScreen(),
          ),
          GoRoute(
            path: 'payments',
            builder: (context, state) => const AccountantPaymentsScreen(),
          ),
          GoRoute(
            path: 'pending',
            builder: (context, state) => const AccountantPendingPaymentsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});

bool _isAllowedRoute(String location, UserRole role) {
  return switch (role) {
    UserRole.admin => location.startsWith(AppRoutes.admin),
    UserRole.teacher => location.startsWith(AppRoutes.teacher),
    UserRole.student => location.startsWith(AppRoutes.student),
    UserRole.parent => location.startsWith(AppRoutes.parent),
    UserRole.staff => location.startsWith(AppRoutes.staff),
    UserRole.accountant => location.startsWith(AppRoutes.accountant),
  };
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._authState, this._profile) {
    _authState.whenData((_) => notifyListeners());
    _profile.when(
      data: (_) => notifyListeners(),
      loading: () {},
      error: (_, _) => notifyListeners(),
    );
  }

  final AsyncValue _authState;
  final AsyncValue _profile;
}
