import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../shared/widgets/app_shell.dart';

const parentNavItems = [
  NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: AppRoutes.parent,
  ),
  NavItem(
    label: 'Assignments',
    icon: Icons.assignment_outlined,
    route: AppRoutes.parentAssignments,
  ),
  NavItem(
    label: 'Grades',
    icon: Icons.assessment_outlined,
    route: AppRoutes.parentGrades,
  ),
  NavItem(
    label: 'Attendance',
    icon: Icons.event_available_outlined,
    route: AppRoutes.parentAttendance,
  ),
  NavItem(
    label: 'Fees',
    icon: Icons.account_balance_wallet_outlined,
    route: AppRoutes.parentFees,
  ),
];
