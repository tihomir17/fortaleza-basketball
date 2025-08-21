// lib/core/navigation/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/features/possessions/presentation/screens/log_possession_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/main.dart';

// Import the shell and all necessary screens/cubits
import 'coach_scaffold.dart';
import '../../features/authentication/presentation/cubit/auth_cubit.dart';
import '../../features/authentication/presentation/cubit/auth_state.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/teams/presentation/cubit/team_detail_cubit.dart';
import '../../features/teams/presentation/screens/team_detail_screen.dart';
import '../../features/plays/presentation/cubit/playbook_cubit.dart';
import '../../features/plays/presentation/screens/playbook_screen.dart';
import '../../features/games/presentation/screens/games_screen.dart';
import '../../features/games/presentation/screens/game_detail_screen.dart';
import '../../features/games/presentation/cubit/game_detail_cubit.dart';
import '../../features/playbook/presentation/screens/playbook_hub_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
// Import the new screens
import '../../features/scouting/presentation/screens/scouting_reports_screen.dart';
import '../../features/scouting/presentation/screens/self_scouting_screen.dart';

class AppRouter {
  final AuthCubit authCubit;
  AppRouter({required this.authCubit});

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    debugLogDiagnostics: true,

    routes: [
      // The login screen is the only route outside the main shell
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // THIS IS THE NEW ROOT SHELL ROUTE FOR THE ENTIRE AUTHENTICATED APP
      ShellRoute(
        builder: (context, state, child) {
          // The CoachScaffold is now the root UI for everything else
          return CoachScaffold(child: child);
        },
        routes: [
          // All other routes are now children of this shell
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/teams',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: ':teamId', // Matches '/teams/1'
                builder: (context, state) {
                  final teamId =
                      int.tryParse(state.pathParameters['teamId'] ?? '') ?? 0;
                  return BlocProvider(
                    create: (context) => sl<TeamDetailCubit>()
                      ..fetchTeamDetails(
                        token: authCubit.state.token!,
                        teamId: teamId,
                      ),
                    child: TeamDetailScreen(teamId: teamId),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'plays', // '/teams/:teamId/plays'
                    builder: (context, state) {
                      final teamId =
                          int.tryParse(state.pathParameters['teamId'] ?? '') ??
                          0;
                      final teamName = state.extra as String? ?? 'Team';
                      return BlocProvider(
                        create: (context) => sl<PlaybookCubit>()
                          ..fetchPlays(
                            token: authCubit.state.token!,
                            teamId: teamId,
                          ),
                        child: PlaybookScreen(
                          teamName: teamName,
                          teamId: teamId,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/games',
            builder: (context, state) => const GamesScreen(),
            routes: [
              GoRoute(
                path: ':gameId', // Matches '/games/1'
                builder: (context, state) {
                  final gameId =
                      int.tryParse(state.pathParameters['gameId'] ?? '') ?? 0;
                  return BlocProvider(
                    create: (context) => sl<GameDetailCubit>()
                      ..fetchGameDetails(
                        token: authCubit.state.token!,
                        gameId: gameId,
                      ),
                    child: GameDetailScreen(gameId: gameId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/playbook',
            builder: (context, state) => const PlaybookHubScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/scouting-reports',
            builder: (context, state) => const ScoutingReportsScreen(),
          ),
          GoRoute(
            path: '/self-scouting',
            builder: (context, state) => const SelfScoutingScreen(),
          ),
          GoRoute(
            path: '/log-possession',
            builder: (context, state) => const LogPossessionScreen(),
          ),
        ],
      ),
    ],

    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authCubit.state.status == AuthStatus.authenticated;
      final bool isLoggingIn = state.matchedLocation == '/login';
      if (!loggedIn && !isLoggingIn) return '/login';
      if (loggedIn && isLoggingIn) return '/';
      return null;
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}
