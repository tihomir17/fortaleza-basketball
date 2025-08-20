// lib/core/navigation/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/main.dart'; // To access the service locator (sl)

// Import the shell route UI
import 'scaffold_with_nav_bar.dart';

// Import all screens and cubits needed for routing
import '../../features/authentication/presentation/cubit/auth_cubit.dart';
import '../../features/authentication/presentation/cubit/auth_state.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
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
    initialLocation: '/',
    debugLogDiagnostics: true,

    // This is the key to making the router react to login/logout events.
    refreshListenable: GoRouterRefreshStream(authCubit.stream),

    routes: [
      // Top-level route that does NOT have the bottom navigation bar.
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(
        path: '/log-possession',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LogPossessionScreen(),
      ),

      // The ShellRoute wraps all the main pages that share the BottomNavigationBar.
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          // Tab 1: Dashboard
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          // Tab 2: Teams
          GoRoute(
            path: '/teams',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
            routes: [
              GoRoute(
                path: ':teamId', // Matches '/teams/1'
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final teamId =
                      int.tryParse(state.pathParameters['teamId'] ?? '') ?? 0;
                  final token = authCubit.state.token;
                  return BlocProvider(
                    create: (context) =>
                        sl<TeamDetailCubit>()
                          ..fetchTeamDetails(token: token!, teamId: teamId),
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
                      final token = authCubit.state.token;
                      return BlocProvider(
                        create: (context) =>
                            sl<PlaybookCubit>()
                              ..fetchPlays(token: token!, teamId: teamId),
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
          // Tab 3: Games
          GoRoute(
            path: '/games',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GamesScreen()),
            routes: [
              GoRoute(
                path: ':gameId', // Matches '/games/1'
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final gameId =
                      int.tryParse(state.pathParameters['gameId'] ?? '') ?? 0;
                  final token = authCubit.state.token;
                  return BlocProvider(
                    create: (context) =>
                        sl<GameDetailCubit>()
                          ..fetchGameDetails(token: token!, gameId: gameId),
                    child: GameDetailScreen(gameId: gameId),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],

    // The redirect logic is now simple. It runs whenever the 'refreshListenable' fires.
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authCubit.state.status == AuthStatus.authenticated;
      final String location = state.matchedLocation;
      final bool isLoggingIn = location == '/login';

      if (!loggedIn && !isLoggingIn) {
        return '/login';
      }
      if (loggedIn && isLoggingIn) {
        return '/'; // Go to the dashboard
      }
      return null;
    },
  );
}

// Helper class to convert a BLoC Stream into a Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    // It's important to use asBroadcastStream to allow multiple subscriptions
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}
