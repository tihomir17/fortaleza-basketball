// lib/core/navigation/scaffold_with_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.child, super.key});

  // The widget to display in the body of the Scaffold.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Teams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_basketball_outlined),
            activeIcon: Icon(Icons.sports_basketball),
            label: 'Games',
          ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
      ),
    );
  }

  // Calculate the selected index based on the current route
  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    // Note: The order here MUST match the order of the BottomNavigationBarItem list
    if (location.startsWith('/teams')) {
      return 1;
    }
    if (location.startsWith('/games')) {
      return 2;
    }
    // If it's not teams or games, it must be the dashboard (or root)
    return 0;
  }

  // Navigate to the correct route when a tab is tapped
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/teams');
        break;
      case 2:
        GoRouter.of(context).go('/games');
        break;
    }
  }
}
