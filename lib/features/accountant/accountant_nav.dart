import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../shared/widgets/app_shell.dart';

const accountantNavItems = [
  NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: AppRoutes.accountant,
  ),
  NavItem(
    label: 'Fee Structures',
    icon: Icons.receipt_long_outlined,
    route: AppRoutes.accountantFees,
  ),
  NavItem(
    label: 'Invoices',
    icon: Icons.description_outlined,
    route: AppRoutes.accountantInvoices,
  ),
  NavItem(
    label: 'Payments',
    icon: Icons.payments_outlined,
    route: AppRoutes.accountantPayments,
  ),
  NavItem(
    label: 'Confirm Payments',
    icon: Icons.pending_actions_outlined,
    route: AppRoutes.accountantPending,
  ),
];
