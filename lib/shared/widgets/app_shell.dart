import 'package:flutter/material.dart';

import 'ai_chatbot_fab.dart';
import 'notification_bell.dart';
import 'settings_button.dart';

class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.navItems,
    required this.selectedRoute,
    required this.onNavigate,
    required this.onSignOut,
    required this.child,
    this.subtitle,
    this.showNotifications = true,
  });

  final String title;
  final String? subtitle;
  final List<NavItem> navItems;
  final String selectedRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;
  final Widget child;
  final bool showNotifications;

  static const _breakpoint = 900.0;

  int get _selectedIndex {
    final index = navItems.indexWhere(
      (item) => selectedRoute == item.route || selectedRoute.startsWith('${item.route}/'),
    );
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= _breakpoint;

        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                _DesktopSidebar(
                  title: title,
                  subtitle: subtitle,
                  navItems: navItems,
                  selectedIndex: _selectedIndex,
                  onNavigate: onNavigate,
                  onSignOut: onSignOut,
                ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        showNotifications: showNotifications,
                        onSignOut: onSignOut,
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            child,
                            const AiChatbotFab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            actions: _topBarActions(showNotifications, onSignOut),
          ),
          drawer: Drawer(
            child: _MobileSidebar(
              title: title,
              subtitle: subtitle,
              navItems: navItems,
              selectedRoute: selectedRoute,
              onNavigate: (route) {
                Navigator.of(context).pop();
                onNavigate(route);
              },
              onSignOut: onSignOut,
            ),
          ),
          body: Stack(
            children: [
              child,
              const AiChatbotFab(),
            ],
          ),
        );
      },
    );
  }

  static List<Widget> _topBarActions(bool showNotifications, VoidCallback onSignOut) {
    return [
      if (showNotifications) const NotificationBell(),
      const SettingsButton(),
      IconButton(
        onPressed: onSignOut,
        icon: const Icon(Icons.logout_rounded),
        tooltip: 'Sign out',
      ),
      const SizedBox(width: 8),
    ];
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showNotifications,
    required this.onSignOut,
  });

  final bool showNotifications;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            const Spacer(),
            ...AppShell._topBarActions(showNotifications, onSignOut),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.title,
    required this.subtitle,
    required this.navItems,
    required this.selectedIndex,
    required this.onNavigate,
    required this.onSignOut,
  });

  final String title;
  final String? subtitle;
  final List<NavItem> navItems;
  final int selectedIndex;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (var i = 0; i < navItems.length; i++)
                  _NavTile(
                    item: navItems[i],
                    selected: i == selectedIndex,
                    onTap: () => onNavigate(navItems[i].route),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: Icon(Icons.logout_rounded, color: colorScheme.error),
              title: Text(
                'Sign out',
                style: TextStyle(color: colorScheme.error),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: onSignOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileSidebar extends StatelessWidget {
  const _MobileSidebar({
    required this.title,
    required this.subtitle,
    required this.navItems,
    required this.selectedRoute,
    required this.onNavigate,
    required this.onSignOut,
  });

  final String title;
  final String? subtitle;
  final List<NavItem> navItems;
  final String selectedRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final item in navItems)
                  _NavTile(
                    item: item,
                    selected: selectedRoute == item.route ||
                        selectedRoute.startsWith('${item.route}/'),
                    onTap: () => onNavigate(item.route),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign out'),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? colorScheme.primary : null,
          ),
        ),
        selected: selected,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
