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
          final staffType = authState.user?.staffType;
          final isPhysio = isStaff && staffType == 'PHYSIO';
          final isStrengthConditioning = isStaff && staffType == 'STRENGTH_CONDITIONING';
          final isManagement = isStaff && staffType == 'MANAGEMENT';
          
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
                  isPhysio ? 'Physio Menu' :
                  isStrengthConditioning ? 'S&C Menu' :
                  isManagement ? 'Management Menu' :
                  isStaff ? 'Staff Menu' : 'Coach Menu',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontFamily: 'Anton',
                  ),
                ),
              ),
              
              // Dashboard - Visible for coaches, players, and staff
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
              
              // Staff-specific menu items
              if (isPhysio) ...[
                ListTile(
                  leading: const Icon(Icons.medical_services_outlined),
                  title: const Text('Player Health'),
                  selected: currentRoute.startsWith('/player-health'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Player Health (/player-health).');
                    context.go('/player-health');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: const Text('Injury Reports'),
                  selected: currentRoute.startsWith('/injury-reports'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Injury Reports (/injury-reports).');
                    context.go('/injury-reports');
                  },
                ),
              ],
              
              if (isStrengthConditioning) ...[
                ListTile(
                  leading: const Icon(Icons.fitness_center_outlined),
                  title: const Text('Training Programs'),
                  selected: currentRoute.startsWith('/training-programs'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Training Programs (/training-programs).');
                    context.go('/training-programs');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.trending_up_outlined),
                  title: const Text('Performance Metrics'),
                  selected: currentRoute.startsWith('/performance-metrics'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Performance Metrics (/performance-metrics).');
                    context.go('/performance-metrics');
                  },
                ),
              ],
              
              if (isManagement) ...[
                ListTile(
                  leading: const Icon(Icons.business_outlined),
                  title: const Text('Team Management'),
                  selected: currentRoute.startsWith('/teams'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Team Management (/teams).');
                    context.go('/teams');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Team Analytics Reports'),
                  selected: currentRoute.startsWith('/scouting-reports'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Team Analytics Reports (/scouting-reports).');
                    context.go('/scouting-reports');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search_outlined),
                  title: const Text('Opponent Scouting'),
                  selected: currentRoute.startsWith('/opponent-scouting'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Opponent Scouting (/opponent-scouting).');
                    context.go('/opponent-scouting');
                  },
                ),
              ],
              
              // Player-only menu items (not visible to staff)
              if (isPlayer && !isStaff) ...[
                ListTile(
                  leading: const Icon(Icons.sports_basketball_outlined),
                  title: const Text('Game Preparation'),
                  selected: currentRoute.startsWith('/individual-game-prep'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Game Preparation (/individual-game-prep).');
                    context.go('/individual-game-prep');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('Post Game Scouting'),
                  selected: currentRoute.startsWith('/individual-post-game'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Post Game Scouting (/individual-post-game).');
                    context.go('/individual-post-game');
                  },
                ),
              ],
              
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
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Team Analytics Reports'),
                  selected: currentRoute.startsWith('/scouting-reports'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Team Analytics Reports (/scouting-reports).');
                    context.go('/scouting-reports');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search_outlined),
                  title: const Text('Opponent Scouting'),
                  selected: currentRoute.startsWith('/opponent-scouting'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Opponent Scouting (/opponent-scouting).');
                    context.go('/opponent-scouting');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_search_outlined),
                  title: const Text('Player Analytics Reports'),
                  selected: currentRoute.startsWith('/coach-self-scouting'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Player Analytics Reports (/coach-self-scouting).');
                    context.go('/coach-self-scouting');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sports_basketball_outlined),
                  title: const Text('Game Preparation'),
                  selected: currentRoute.startsWith('/individual-game-prep'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Game Preparation (/individual-game-prep).');
                    context.go('/individual-game-prep');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('Post Game Scouting'),
                  selected: currentRoute.startsWith('/individual-post-game'),
                  onTap: () {
                    logger.i('CoachSidebar: Navigating to Post Game Scouting (/individual-post-game).');
                    context.go('/individual-post-game');
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
