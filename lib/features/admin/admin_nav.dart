import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../shared/widgets/app_shell.dart';

const adminNavItems = [
  NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: AppRoutes.admin,
  ),
  NavItem(
    label: 'Command Center',
    icon: Icons.hub_outlined,
    route: AppRoutes.adminCommandCenter,
  ),
  NavItem(
    label: 'School Setup',
    icon: Icons.school_outlined,
    route: AppRoutes.adminSchool,
  ),
  NavItem(
    label: 'User Management',
    icon: Icons.people_outline,
    route: AppRoutes.adminUsers,
  ),
  NavItem(
    label: 'Academic Setup',
    icon: Icons.calendar_today_outlined,
    route: AppRoutes.adminAcademic,
  ),
  NavItem(
    label: 'Analytics',
    icon: Icons.analytics_outlined,
    route: AppRoutes.adminAnalytics,
  ),
  NavItem(
    label: 'Announcements',
    icon: Icons.campaign_outlined,
    route: AppRoutes.adminAnnouncements,
  ),
  NavItem(
    label: 'Portal CMS',
    icon: Icons.web_outlined,
    route: AppRoutes.adminPortal,
  ),
  NavItem(
    label: 'Settings',
    icon: Icons.tune_outlined,
    route: AppRoutes.adminSettings,
  ),
];
