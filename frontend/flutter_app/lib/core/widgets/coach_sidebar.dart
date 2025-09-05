// lib/core/widgets/coach_sidebar.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/main.dart'; // Import for global logger
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_state.dart';

class CoachSidebar extends StatelessWidget {
  const CoachSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    logger.d('CoachSidebar: Building sidebar.');
    // Get the current route to highlight the active item
    final currentRoute = GoRouterState.of(context).matchedLocation;
    logger.d('CoachSidebar: Current route is $currentRoute');

    return Drawer(
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isPlayer = authState.status == AuthStatus.authenticated && 
                          authState.user != null && 
                          authState.user!.role == 'PLAYER';
          final isStaff = authState.status == AuthStatus.authenticated && 
                         authState.user != null && 
                         authState.user!.role == 'STAFF';
          
          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // A stylish header for the drawer
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Text(
                  isPlayer ? 'Player Menu' : 
                  isStaff ? 'Staff Menu' : 'Coach Menu',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontFamily: 'Anton',
                  ),
                ),
              ),
              
              // Dashboard - Visible for coaches and players, not staff
              if (!isStaff)
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('Dashboard'),
                  selected: currentRoute == '/',
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Dashboard (/).');
                    context.go('/');
                  },
                ),
              
              // Calendar - Always visible
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Calendar'),
                selected: currentRoute.startsWith('/calendar'),
                onTap: () {
                  logger.i('CoachSidebar: Navigating to Calendar (/calendar).');
                  context.go('/calendar');
                },
              ),
              
              // Self Scouting - Only visible for players
              if (isPlayer)
                ListTile(
                  leading: const Icon(Icons.person_search_outlined),
                  title: const Text('Self Scouting'),
                  selected: currentRoute.startsWith('/self-scouting'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Self Scouting (/self-scouting).');
                    context.go('/self-scouting');
                  },
                ),
              
              // Coach-only menu items (not visible to staff or players)
              if (!isPlayer && !isStaff) ...[
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
                  selected: currentRoute.startsWith('/playbook'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Playbook (/playbook).');
                    context.go('/playbook');
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
              ],
            ],
          );
        },
      ),
    );
  }
}
