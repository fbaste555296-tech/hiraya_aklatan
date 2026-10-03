import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_providers.dart';
import 'route_names.dart';

/// Navigation destination descriptor for the bottom navigation bar.
class _NavItem {
  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Reader destinations (always visible).
const List<_NavItem> _readerItems = [
  _NavItem(
    path: RouteNames.library,
    icon: Icons.library_books_outlined,
    activeIcon: Icons.library_books,
    label: 'Library',
  ),
  _NavItem(
    path: RouteNames.myLibrary,
    icon: Icons.bookmark_outline,
    activeIcon: Icons.bookmark,
    label: 'My Library',
  ),
  _NavItem(
    path: RouteNames.vip,
    icon: Icons.star_outline,
    activeIcon: Icons.star,
    label: 'VIP',
  ),
  _NavItem(
    path: RouteNames.profile,
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
  ),
];

/// Admin-only destination, appended after the reader destinations.
const _NavItem _adminItem = _NavItem(
  path: RouteNames.adminPayments,
  icon: Icons.admin_panel_settings_outlined,
  activeIcon: Icons.admin_panel_settings,
  label: 'Admin',
);

/// Application shell hosting the authenticated pages with a role-aware
/// bottom navigation bar: readers see 4 tabs, admins see 5.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  List<_NavItem> _items(bool isAdmin) =>
      isAdmin ? [..._readerItems, _adminItem] : _readerItems;

  int _indexForLocation(String location, List<_NavItem> items) {
    for (var i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].path)) return i;
    }
    return 0;
  }

  void _onTap(int index, List<_NavItem> items) {
    context.go(items[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final items = _items(isAdmin);
    final location = GoRouterState.of(context).uri.toString();

    // Keep the highlighted tab in sync with deep links and redirects.
    final targetIndex = _indexForLocation(location, items);
    if (targetIndex != _currentIndex) {
      _currentIndex = targetIndex;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => _onTap(index, items),
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
