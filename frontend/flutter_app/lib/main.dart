// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/features/games/data/repositories/game_repository.dart';
import 'package:flutter_app/features/games/presentation/cubit/game_cubit.dart';
import 'package:flutter_app/features/games/presentation/cubit/game_detail_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter here

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
import 'features/calendar/data/repositories/event_repository.dart';

// Features - Cubits
import 'features/authentication/presentation/cubit/auth_cubit.dart';
import 'features/authentication/presentation/cubit/auth_state.dart';
import 'features/teams/presentation/cubit/team_cubit.dart';
import 'features/teams/presentation/cubit/team_detail_cubit.dart';
import 'features/plays/presentation/cubit/playbook_cubit.dart';
import 'features/competitions/presentation/cubit/competition_cubit.dart';
import 'features/calendar/presentation/cubit/calendar_cubit.dart';

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
  sl.registerLazySingleton<GameRepository>(() => GameRepository());
  sl.registerLazySingleton<EventRepository>(() => EventRepository());

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

  // Cubits
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
  sl.registerLazySingleton<GameCubit>(
    () => GameCubit(gameRepository: sl<GameRepository>()),
  );

  sl.registerLazySingleton<CalendarCubit>(
    () => CalendarCubit(
      gameRepository: sl<GameRepository>(),
      eventRepository: sl<EventRepository>(),
    ),
  );

  // Factories for screen-specific state
  sl.registerFactory<TeamDetailCubit>(
    () => TeamDetailCubit(teamRepository: sl<TeamRepository>()),
  );
  sl.registerFactory<PlaybookCubit>(
    () => PlaybookCubit(playRepository: sl<PlayRepository>()),
  );
  sl.registerFactory<GameDetailCubit>(
    () => GameDetailCubit(gameRepository: sl<GameRepository>()),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  await sl<AuthCubit>().checkAuthentication();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create the router here, passing the AuthCubit directly.
    // This avoids any context issues.
    _router = AppRouter(authCubit: sl<AuthCubit>()).router;
  }

  @override
  Widget build(BuildContext context) {
    // We provide all global cubits at the top of the tree.
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AuthCubit>()),
        BlocProvider.value(value: sl<ThemeCubit>()),
        BlocProvider(create: (context) => sl<TeamCubit>()),
        BlocProvider(create: (context) => sl<CompetitionCubit>()),
        BlocProvider(create: (context) => sl<GameCubit>()),
        BlocProvider(create: (context) => sl<CalendarCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, authState) {
          if (authState.status == AuthStatus.authenticated &&
              authState.token != null) {
            context.read<TeamCubit>().fetchTeams(token: authState.token!);
            context.read<CompetitionCubit>().fetchCompetitions(
              token: authState.token!,
            );
            context.read<GameCubit>().fetchGames(token: authState.token!);
          }
        },
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: 'Basketball Analytics',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              routerConfig: _router, // Use the router instance from our state
            );
          },
        ),
      ),
    );
  }
}
