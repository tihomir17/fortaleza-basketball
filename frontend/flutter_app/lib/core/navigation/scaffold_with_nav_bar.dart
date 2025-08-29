// lib/core/navigation/scaffold_with_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.child, super.key});

  // The widget to display in the body of the Scaffold.
  final Widget child;

  // A helper map to associate routes with their titles
  static const Map<String, String> _routeTitles = {
    '/': 'DASHBOARD',
    '/teams': 'MY TEAMS',
    '/games': 'GAMES',
  };

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    final String title =
        _routeTitles[location] ?? ''; // Default to empty string
    logger.d('ScaffoldWithNavBar: Building scaffold for location: $location with title: $title');

    return Scaffold(
      appBar: UserProfileAppBar(title: title),
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
    logger.d('ScaffoldWithNavBar: Calculating selected index for location: $location');
    // Note: The order here MUST match the order of the BottomNavigationBarItem list
    if (location.startsWith('/teams')) {
      logger.d('ScaffoldWithNavBar: Selected index is 1 (Teams).');
      return 1;
    }
    if (location.startsWith('/games')) {
      logger.d('ScaffoldWithNavBar: Selected index is 2 (Games).');
      return 2;
    }
    // If it's not teams or games, it must be the dashboard (or root)
    logger.d('ScaffoldWithNavBar: Selected index is 0 (Dashboard).');
    return 0;
  }

  // Navigate to the correct route when a tab is tapped
  void _onItemTapped(int index, BuildContext context) {
    logger.i('ScaffoldWithNavBar: Item tapped with index: $index');
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        logger.i('ScaffoldWithNavBar: Navigating to Dashboard (/).');
        break;
      case 1:
        GoRouter.of(context).go('/teams');
        logger.i('ScaffoldWithNavBar: Navigating to Teams (/teams).');
        break;
      case 2:
        GoRouter.of(context).go('/games');
        logger.i('ScaffoldWithNavBar: Navigating to Games (/games).');
        break;
    }
  }
}
