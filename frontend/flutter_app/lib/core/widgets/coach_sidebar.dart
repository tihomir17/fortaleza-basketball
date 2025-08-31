// lib/core/widgets/coach_sidebar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

class CoachSidebar extends StatelessWidget {
  const CoachSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    logger.d('CoachSidebar: Building sidebar.');
    // Get the current route to highlight the active item
    final currentRoute = GoRouterState.of(context).matchedLocation;
    logger.d('CoachSidebar: Current route is $currentRoute');

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
            onTap: () {
              logger.i('CoachSidebar: Navigating to Dashboard (/).');
              context.go('/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Team Management'),
            selected: currentRoute.startsWith('/teams'),
            onTap: () {
              logger.i('CoachSidebar: Navigating to Team Management (/teams).');
              context.go('/teams');
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Playbook'),
            selected: currentRoute.startsWith('/playbook'), // New route
            onTap: () {
              logger.i('CoachSidebar: Navigating to Playbook (/playbook).');
              context.go('/playbook'); // New route
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Calendar'),
            selected: currentRoute.startsWith('/calendar'), // New route
            onTap: () {
              logger.i('CoachSidebar: Navigating to Calendar (/calendar).');
              context.go('/calendar'); // New route
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Game Analysis'),
            selected: currentRoute.startsWith('/games'),
            onTap: () {
              logger.i('CoachSidebar: Navigating to Game Analysis (/games).');
              context.go('/games');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Advanced Analytics'),
            selected: currentRoute.startsWith('/analytics'),
            onTap: () {
              logger.i('CoachSidebar: Navigating to Advanced Analytics (/analytics).');
              context.go('/analytics');
            },
          ),
          ListTile(
            leading: const Icon(Icons.video_library_outlined),
            title: const Text('Scouting Reports'),
            selected: currentRoute.startsWith('/scouting-reports'),
            onTap: () {
              logger.i('CoachSidebar: Navigating to Scouting Reports (/scouting-reports).');
              context.go('/scouting-reports');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_search_outlined),
            title: const Text('Self Scouting'),
            selected: currentRoute.startsWith('/self-scouting'),
            onTap: () {
              logger.i('CoachSidebar: Navigating to Self Scouting (/self-scouting).');
              context.go('/self-scouting');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Debug Logs'),
            selected: currentRoute.startsWith('/debug'),
            onTap: () {
              logger.i('CoachSidebar: Navigating to Debug Logs (/debug).');
              context.go('/debug');
            },
          ),
        ],
      ),
    );
  }
}
