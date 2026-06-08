import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../shared/widgets/app_shell.dart';

const teacherNavItems = [
  NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: AppRoutes.teacher,
  ),
  NavItem(
    label: 'Attendance',
    icon: Icons.fact_check_outlined,
    route: AppRoutes.teacherAttendance,
  ),
  NavItem(
    label: 'Gradebook',
    icon: Icons.grade_outlined,
    route: AppRoutes.teacherGradebook,
  ),
  NavItem(
    label: 'Assignments',
    icon: Icons.assignment_outlined,
    route: AppRoutes.teacherAssignments,
  ),
  NavItem(
    label: 'Materials',
    icon: Icons.menu_book_outlined,
    route: AppRoutes.teacherMaterials,
  ),
];
