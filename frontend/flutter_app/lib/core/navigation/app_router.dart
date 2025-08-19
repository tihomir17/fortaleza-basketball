// lib/core/navigation/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/main.dart';
// Import the new shell route
import 'scaffold_with_nav_bar.dart';

// Import all screens and cubits
import '../../features/authentication/presentation/cubit/auth_cubit.dart';
import '../../features/authentication/presentation/cubit/auth_state.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/teams/data/models/team_model.dart';
import '../../features/teams/presentation/cubit/team_detail_cubit.dart';
import '../../features/teams/presentation/screens/team_detail_screen.dart';
import '../../features/plays/presentation/cubit/playbook_cubit.dart';
import '../../features/plays/presentation/screens/playbook_screen.dart';
import '../../features/possessions/presentation/screens/log_possession_screen.dart';
import '../../features/games/presentation/screens/games_screen.dart';
import '../../features/games/presentation/screens/game_detail_screen.dart';
import '../../features/games/presentation/cubit/game_detail_cubit.dart';

class AppRouter {
  final AuthCubit authCubit;
  AppRouter({required this.authCubit});

  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/teams',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    debugLogDiagnostics: true,

    routes: [
      // Routes that do NOT have the bottom nav bar
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // THIS IS THE CORRECTED SHELL ROUTE STRUCTURE
      // It wraps all main pages that share the BottomNavBar.
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          // The content for the first tab: Teams
          GoRoute(
            path: '/teams',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
            routes: [
              // This route is NOT part of the shell, so it will cover the nav bar.
              GoRoute(
                path: ':teamId', // Matches '/teams/1'
                parentNavigatorKey: _rootNavigatorKey, // Important!
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
                    parentNavigatorKey: _rootNavigatorKey,
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
                  GoRoute(
                    path: 'log-possession', // '/teams/:teamId/log-possession'
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final team = state.extra as Team?;
                      if (team == null) {
                        return const Scaffold(
                          body: Center(child: Text("Error")),
                        );
                      }
                      return LogPossessionScreen();
                    },
                  ),
                ],
              ),
            ],
          ),
          // The content for the second tab: Games
          GoRoute(
            path: '/games',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GamesScreen()),
            routes: [
              // This route is also not part of the shell.
              GoRoute(
                path: ':gameId', // Matches '/games/1'
                parentNavigatorKey: _rootNavigatorKey,
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
        ],
      ),
    ],

    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authCubit.state.status == AuthStatus.authenticated;
      final String location = state.matchedLocation;

      // If we are not logged in and not on the login page, redirect to login
      if (!loggedIn && location != '/login') {
        return '/login';
      }
      // If we are logged in and on the login page, redirect to the home page
      if (loggedIn && location == '/login') {
        return '/teams';
      }
      return null;
    },
  );
}

// Helper class to make GoRouter listen to BLoC streams
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}
