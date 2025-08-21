// lib/core/widgets/coach_sidebar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CoachSidebar extends StatelessWidget {
  const CoachSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current route to highlight the active item
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // A stylish header for the drawer
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Coach Menu',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontFamily: 'Anton',
              ),
            ),
          ),
          // Navigation Items
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: currentRoute == '/',
            onTap: () => context.go('/'),
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Team Management'),
            selected: currentRoute.startsWith('/teams'),
            onTap: () => context.go('/teams'),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Playbook'),
            selected: currentRoute.startsWith('/playbook'), // New route
            onTap: () => context.go('/playbook'), // New route
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Calendar'),
            selected: currentRoute.startsWith('/calendar'), // New route
            onTap: () => context.go('/calendar'), // New route
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Analytics'),
            selected: currentRoute.startsWith('/games'),
            onTap: () => context.go('/games'),
          ),
          ListTile(
            leading: const Icon(Icons.video_library_outlined),
            title: const Text('Scouting Reports'),
            selected: currentRoute.startsWith('/scouting-reports'),
            onTap: () => context.go('/scouting-reports'),
          ),
          ListTile(
            leading: const Icon(Icons.person_search_outlined),
            title: const Text('Self Scouting'),
            selected: currentRoute.startsWith('/self-scouting'),
            onTap: () => context.go('/self-scouting'),
          ),
        ],
      ),
    );
  }
}
