// lib/core/navigation/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/main.dart'; // To access the service locator (sl)
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

class AppRouter {
  final AuthCubit authCubit;
  AppRouter({required this.authCubit});

  late final GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    debugLogDiagnostics: true,
    initialLocation: '/teams', // Default page for logged-in users

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      // This top-level route contains all screens that require authentication
      GoRoute(
        path: '/teams',
        // The builder is now simple because TeamCubit is provided globally
        builder: (context, state) => const HomeScreen(),
        routes: [
          // Nested route for team details
          GoRoute(
            path: ':teamId', // Matches '/teams/1', '/teams/2', etc.
            builder: (context, state) {
              final teamId =
                  int.tryParse(state.pathParameters['teamId'] ?? '') ?? 0;
              final token = authCubit.state.token;

              if (token == null) {
                // Safeguard, redirect logic should handle this
                return const Scaffold(
                  body: Center(child: Text("Authentication Error")),
                );
              }

              // Provide the FACTORY-scoped cubit for this specific screen
              return BlocProvider(
                create: (context) =>
                    sl<TeamDetailCubit>()
                      ..fetchTeamDetails(token: token, teamId: teamId),
                child: TeamDetailScreen(teamId: teamId),
              );
            },
            routes: [
              // Further nested route for a team's playbook
              GoRoute(
                path: 'plays', // Matches '/teams/1/plays'
                builder: (context, state) {
                  final teamId =
                      int.tryParse(state.pathParameters['teamId'] ?? '') ?? 0;
                  final teamName = state.extra as String? ?? 'Team';
                  final token = authCubit.state.token;

                  if (token == null) {
                    return const Scaffold(
                      body: Center(child: Text("Authentication Error")),
                    );
                  }

                  // Provide the FACTORY-scoped cubit for this specific screen
                  return BlocProvider(
                    create: (context) =>
                        sl<PlaybookCubit>()
                          ..fetchPlays(token: token, teamId: teamId),
                    child: PlaybookScreen(teamName: teamName, teamId: teamId),
                  );
                },
              ),
              // Further nested route for logging a possession for a team
              GoRoute(
                path: 'log-possession', // Matches '/teams/1/log-possession'
                builder: (context, state) {
                  final team = state.extra as Team?;
                  if (team == null) {
                    return const Scaffold(
                      body: Center(
                        child: Text("Error: Team data not provided."),
                      ),
                    );
                  }
                  // This screen can now access the globally provided TeamCubit
                  return LogPossessionScreen(team: team);
                },
              ),
            ],
          ),
        ],
      ),
    ],

    // This redirect logic is the core of our protected routes
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authCubit.state.status == AuthStatus.authenticated;
      final bool isLoggingIn = state.matchedLocation == '/login';

      // If user is not logged in and not on the login page, redirect to login
      if (!loggedIn && !isLoggingIn) {
        return '/login';
      }
      // If user is logged in and tries to go to the login page, redirect to home
      if (loggedIn && isLoggingIn) {
        return '/teams';
      }

      // Otherwise, no redirect is needed
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
