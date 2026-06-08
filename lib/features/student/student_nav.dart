import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../shared/widgets/app_shell.dart';

const studentNavItems = [
  NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: AppRoutes.student,
  ),
  NavItem(
    label: 'Schedule',
    icon: Icons.calendar_month_outlined,
    route: AppRoutes.studentSchedule,
  ),
  NavItem(
    label: 'Assignments',
    icon: Icons.assignment_outlined,
    route: AppRoutes.studentAssignments,
  ),
  NavItem(
    label: 'Grades',
    icon: Icons.assessment_outlined,
    route: AppRoutes.studentGrades,
  ),
  NavItem(
    label: 'Attendance',
    icon: Icons.event_available_outlined,
    route: AppRoutes.studentAttendance,
  ),
  NavItem(
    label: 'Fees',
    icon: Icons.account_balance_wallet_outlined,
    route: AppRoutes.studentFees,
  ),
];
