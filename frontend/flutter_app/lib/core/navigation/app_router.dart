// lib/core/navigation/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/features/possessions/presentation/screens/live_tracking_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

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
import '../../features/games/presentation/screens/match_stats_screen.dart';
import '../../features/games/presentation/screens/player_stats_screen.dart';
import '../../features/games/presentation/cubit/game_detail_cubit.dart';
import '../../features/playbook/presentation/screens/playbook_hub_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
// Import the new screens
import '../../features/games/presentation/screens/scouting_reports_screen.dart';
import '../../features/scouting/presentation/screens/self_scouting_screen.dart';
import '../../features/scouting/presentation/screens/coach_self_scouting_screen.dart';
import '../../features/scouting/presentation/screens/opponent_scouting_screen.dart';
import '../../features/games/presentation/screens/game_analytics_screen.dart';
import '../../features/games/presentation/screens/post_game_report_screen.dart';
import '../../features/games/presentation/screens/advanced_post_game_report_screen.dart';
import '../../features/games/presentation/screens/schedule_game_screen.dart';
import '../../features/calendar/presentation/screens/schedule_event_screen.dart';
import '../debug/debug_screen.dart';
import '../../features/scouting/presentation/cubit/self_scouting_cubit.dart';
// Individual game prep and post game screen imports
import '../../features/scouting/presentation/screens/individual_game_prep_screen.dart';
import '../../features/scouting/presentation/screens/individual_post_game_screen.dart';
// Staff-specific screen imports
import '../../features/staff/presentation/screens/player_health_screen.dart';
import '../../features/staff/presentation/screens/injury_reports_screen.dart';
import '../../features/staff/presentation/screens/training_programs_screen.dart';
import '../../features/staff/presentation/screens/performance_metrics_screen.dart';

class AppRouter {
  final AuthCubit authCubit;
  AppRouter({required this.authCubit}) {
    logger.d('AppRouter initialized.');
  }

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    debugLogDiagnostics: true,

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) {
          return CoachScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/teams',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: ':teamId',
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
                    path: 'play-categories',
                    builder: (context, state) {
                      final teamId =
                          int.tryParse(state.pathParameters['teamId'] ?? '') ??
                          0;
                      final teamName = state.extra as String? ?? 'Team';
                      return BlocProvider(
                        create: (context) => sl<PlaybookCubit>()
                          ..fetchPlaysForTeam(
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
                path: 'add',
                builder: (context, state) => const ScheduleGameScreen(),
              ),
              GoRoute(
                path: ':gameId',
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
                routes: [
                  GoRoute(
                    path: 'stats', // Matches '/games/:gameId/stats'
                    builder: (context, state) {
                      final gameId = int.tryParse(state.pathParameters['gameId'] ?? '') ?? 0;
                      return MatchStatsScreen(gameId: gameId);
                    },
                  ),
                  GoRoute(
                    path: 'player-stats', // Matches '/games/:gameId/player-stats'
                    builder: (context, state) {
                      final gameId = int.tryParse(state.pathParameters['gameId'] ?? '') ?? 0;
                      return PlayerStatsScreen(gameId: gameId);
                    },
                  ),
                  GoRoute(
                    path: 'track', // Matches '/games/:gameId/track'
                    builder: (context, state) {
                      // Get the gameId from the URL path parameters
                      final gameId =
                          int.tryParse(state.pathParameters['gameId'] ?? '') ??
                          0;
                      // We no longer need to pass the game object as 'extra'
                      return LiveTrackingScreen(gameId: gameId);
                    },
                  ),
                  GoRoute(
                    path: 'post-game-report', // Matches '/games/:gameId/post-game-report'
                    builder: (context, state) {
                      final gameId =
                          int.tryParse(state.pathParameters['gameId'] ?? '') ?? 0;
                      final teamId = int.tryParse(state.uri.queryParameters['teamId'] ?? '') ?? 0;
                      return PostGameReportScreen(
                        gameId: gameId,
                        teamId: teamId,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'advanced-report', // Matches '/games/:gameId/advanced-report'
                    builder: (context, state) {
                      final gameId =
                          int.tryParse(state.pathParameters['gameId'] ?? '') ?? 0;
                      return AdvancedPostGameReportScreen(gameId: gameId);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/playbook',
            builder: (context, state) {
              // This is better than a global one because it ensures the state is fresh
              // every time the user navigates to the playbook hub.
              return BlocProvider(
                create: (context) => sl<PlaybookCubit>(),
                child: const PlaybookHubScreen(),
              );
            },
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) => const CalendarScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => ScheduleEventScreen(
                  initialDate: DateTime.now(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/scouting-reports',
            builder: (context, state) => const ScoutingReportsScreen(),
          ),
          GoRoute(
            path: '/opponent-scouting',
            builder: (context, state) => const OpponentScoutingScreen(),
          ),
          GoRoute(
            path: '/games/:gameId/player-stats',
            builder: (context, state) {
              final gameId = int.tryParse(state.pathParameters['gameId'] ?? '') ?? 0;
              return PlayerStatsScreen(gameId: gameId);
            },
          ),
          GoRoute(
            path: '/self-scouting',
            builder: (context, state) => BlocProvider(
              create: (context) => sl<SelfScoutingCubit>(),
              child: const SelfScoutingScreen(),
            ),
          ),
          GoRoute(
            path: '/coach-self-scouting',
            builder: (context, state) => BlocProvider(
              create: (context) => sl<SelfScoutingCubit>(),
              child: const CoachSelfScoutingScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const GameAnalyticsScreen(),
          ),
          GoRoute(
            path: '/debug',
            builder: (context, state) => const DebugScreen(),
          ),
          // Staff-specific routes
          GoRoute(
            path: '/player-health',
            builder: (context, state) => const PlayerHealthScreen(),
          ),
          GoRoute(
            path: '/injury-reports',
            builder: (context, state) => const InjuryReportsScreen(),
          ),
          GoRoute(
            path: '/training-programs',
            builder: (context, state) => const TrainingProgramsScreen(),
          ),
          GoRoute(
            path: '/performance-metrics',
            builder: (context, state) => const PerformanceMetricsScreen(),
          ),
          // Individual game prep and post game routes
          GoRoute(
            path: '/individual-game-prep',
            builder: (context, state) => const IndividualGamePrepScreen(),
          ),
          GoRoute(
            path: '/individual-post-game',
            builder: (context, state) => const IndividualPostGameScreen(),
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authCubit.state.status == AuthStatus.authenticated;
      final bool isLoggingIn = state.matchedLocation == '/login';
      logger.d('AppRouter redirect: Current location ${state.matchedLocation}, LoggedIn: $loggedIn, IsLoggingIn: $isLoggingIn');
      if (!loggedIn && !isLoggingIn) {
        logger.i('AppRouter redirect: Not logged in, redirecting to /login');
        return '/login';
      }
      if (loggedIn && isLoggingIn) {
        logger.i('AppRouter redirect: Logged in and on login page, redirecting to /');
        return '/';
      }
      logger.d('AppRouter redirect: No redirect needed.');
      return null;
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
    logger.d('GoRouterRefreshStream initialized.');
  }
}
