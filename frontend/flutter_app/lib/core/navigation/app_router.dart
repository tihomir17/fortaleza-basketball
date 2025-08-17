// lib/core/navigation/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/main.dart'; // To access the service locator (sl)
import '../../features/authentication/presentation/cubit/auth_cubit.dart';
import '../../features/authentication/presentation/cubit/auth_state.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/teams/presentation/cubit/team_cubit.dart';
import '../../features/teams/presentation/cubit/team_detail_cubit.dart';
import '../../features/teams/presentation/screens/team_detail_screen.dart';
// Import Playbook dependencies
import '../../features/plays/presentation/cubit/playbook_cubit.dart';
import '../../features/plays/presentation/screens/playbook_screen.dart';
import '../../features/possessions/presentation/screens/log_possession_screen.dart';

class AppRouter {
  final AuthCubit authCubit;
  AppRouter({required this.authCubit});

  late final GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    debugLogDiagnostics: true,
    initialLocation: '/teams',

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      // All routes that require the user to be logged in go here
      GoRoute(
        path: '/teams',
        builder: (context, state) {
          final token = authCubit.state.token;
          if (token == null) {
            // This is a safeguard; the redirect should prevent this.
            return const Scaffold(
              body: Center(child: Text("Authentication Error")),
            );
          }
          // THIS IS THE FIX: We get the token and pass it to fetchTeams.
          return BlocProvider(
            create: (context) => sl<TeamCubit>()..fetchTeams(token: token),
            child: const HomeScreen(),
          );
        },
        routes: [
          GoRoute(
            path: ':teamId', // e.g., /teams/1
            builder: (context, state) {
              final teamId =
                  int.tryParse(state.pathParameters['teamId'] ?? '') ?? 0;
              final token = authCubit.state.token;

              if (token == null) {
                return const Scaffold(
                  body: Center(child: Text("Authentication Error")),
                );
              }

              return BlocProvider(
                create: (context) =>
                    sl<TeamDetailCubit>()
                      ..fetchTeamDetails(token: token, teamId: teamId),
                child: TeamDetailScreen(teamId: teamId), // Pass teamId here
              );
            },
            routes: [
              // Nested route for the playbook
              GoRoute(
                path: 'plays', // e.g., /teams/1/plays
                builder: (context, state) {
                  final teamId =
                      int.tryParse(state.pathParameters['teamId'] ?? '') ?? 0;
                  final teamName =
                      state.extra as String? ??
                      'Team'; // Get team name passed as extra
                  final token = authCubit.state.token;

                  if (token == null) {
                    return const Scaffold(
                      body: Center(child: Text("Authentication Error")),
                    );
                  }

                  return BlocProvider(
                    create: (context) =>
                        sl<PlaybookCubit>()
                          ..fetchPlays(token: token, teamId: teamId),
                    child: PlaybookScreen(teamName: teamName, teamId: teamId),
                  );
                },
              ),
              GoRoute(
                path: 'log-possession', // /teams/:teamId/log-possession
                builder: (context, state) {
                  // We get the team object passed as an 'extra' parameter
                  final team = state.extra as Team?;
                  if (team == null) {
                    return const Scaffold(body: Center(child: Text("Error: Team data not provided.")));
                  }
                  return LogPossessionScreen(team: team);
                },
              ),
            ],
          ),
        ],
      ),
    ],

    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authCubit.state.status == AuthStatus.authenticated;
      final bool loggingIn = state.matchedLocation == '/login';

      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/teams';

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
