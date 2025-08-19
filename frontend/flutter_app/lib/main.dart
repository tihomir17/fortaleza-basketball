// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/features/games/data/repositories/game_repository.dart';
import 'package:flutter_app/features/games/presentation/cubit/game_cubit.dart';
import 'package:flutter_app/features/games/presentation/cubit/game_detail_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

// Core
import 'core/navigation/app_router.dart';
import 'core/navigation/refresh_signal.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';

// Features - Repositories
import 'features/authentication/data/repositories/auth_repository.dart';
import 'features/authentication/data/repositories/user_repository.dart';
import 'features/teams/data/repositories/team_repository.dart';
import 'features/plays/data/repositories/play_repository.dart';
import 'features/possessions/data/repositories/possession_repository.dart';
import 'features/competitions/data/repositories/competition_repository.dart';

// Features - Cubits
import 'features/authentication/presentation/cubit/auth_cubit.dart';
import 'features/authentication/presentation/cubit/auth_state.dart';
import 'features/teams/presentation/cubit/team_cubit.dart';
import 'features/teams/presentation/cubit/team_detail_cubit.dart';
import 'features/plays/presentation/cubit/playbook_cubit.dart';
import 'features/competitions/presentation/cubit/competition_cubit.dart';

// Global Service Locator instance
final sl = GetIt.instance;

void setupServiceLocator() {
  // --- SINGLETONS (Live for the entire app lifecycle) ---

  // Global Services
  sl.registerSingleton<AuthRepository>(AuthRepository());
  sl.registerSingleton<UserRepository>(UserRepository());
  sl.registerSingleton<RefreshSignal>(RefreshSignal());

  // Repositories (Stateless, can live for the whole session)
  sl.registerLazySingleton<TeamRepository>(() => TeamRepository());
  sl.registerLazySingleton<PlayRepository>(() => PlayRepository());
  sl.registerLazySingleton<PossessionRepository>(() => PossessionRepository());
  sl.registerLazySingleton<CompetitionRepository>(
    () => CompetitionRepository(),
  );

  // --- CUBITS (State Management) ---
  // Cubits with global or session-wide state are lazy singletons.
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(authRepository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  sl.registerLazySingleton<TeamCubit>(
    () => TeamCubit(teamRepository: sl<TeamRepository>()),
  );
  sl.registerLazySingleton<CompetitionCubit>(
    () => CompetitionCubit(competitionRepository: sl<CompetitionRepository>()),
  );

  // Cubits with screen-specific state are factories to ensure they are created fresh each time.
  sl.registerFactory<TeamDetailCubit>(
    () => TeamDetailCubit(teamRepository: sl<TeamRepository>()),
  );
  sl.registerFactory<PlaybookCubit>(
    () => PlaybookCubit(playRepository: sl<PlayRepository>()),
  );

  sl.registerFactory<GameDetailCubit>(
    () => GameDetailCubit(gameRepository: sl<GameRepository>()),
  );

  sl.registerLazySingleton<GameRepository>(() => GameRepository());
  sl.registerLazySingleton<GameCubit>(
    () => GameCubit(gameRepository: sl<GameRepository>()),
  );
}

Future<void> main() async {
  // Ensure Flutter is initialized before any async setup
  WidgetsFlutterBinding.ensureInitialized();

  // Set up all dependencies
  setupServiceLocator();

  // Wait for the initial authentication check to complete before starting the UI
  await sl<AuthCubit>().checkAuthentication();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Initialize the app's router
  late final AppRouter appRouter = AppRouter(authCubit: sl<AuthCubit>());

  @override
  Widget build(BuildContext context) {
    // MultiBlocProvider makes global cubits available to the entire widget tree
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AuthCubit>()),
        BlocProvider.value(value: sl<ThemeCubit>()),
        BlocProvider(create: (context) => sl<TeamCubit>()),
        BlocProvider(create: (context) => sl<CompetitionCubit>()),
        BlocProvider(create: (context) => sl<GameCubit>()),
      ],
      // BlocBuilder for Theme: rebuilds the MaterialApp when the theme changes
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          // BlocListener for Auth: triggers actions when auth state changes
          return BlocListener<AuthCubit, AuthState>(
            listener: (context, authState) {
              if (authState.status == AuthStatus.authenticated &&
                  authState.token != null) {
                // When a user logs in, fetch all necessary session data
                context.read<TeamCubit>().fetchTeams(token: authState.token!);
                context.read<CompetitionCubit>().fetchCompetitions(
                  token: authState.token!,
                );
                context.read<GameCubit>().fetchGames(token: authState.token!);
              }
            },
            child: MaterialApp.router(
              title: 'Basketball Analytics',
              debugShowCheckedModeBanner: false,

              // Set up the light and dark themes, and let the ThemeCubit control the mode
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,

              // Use the GoRouter configuration for all navigation
              routerConfig: appRouter.router,
            ),
          );
        },
      ),
    );
  }
}
