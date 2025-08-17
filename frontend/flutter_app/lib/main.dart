// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_app/core/navigation/app_router.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
// Import all repositories and cubits
import 'features/authentication/data/repositories/auth_repository.dart';
import 'features/authentication/data/repositories/user_repository.dart';
import 'features/authentication/presentation/cubit/auth_cubit.dart';
import 'features/teams/data/repositories/team_repository.dart';
import 'features/teams/presentation/cubit/team_cubit.dart';
import 'features/teams/presentation/cubit/team_detail_cubit.dart';
import 'features/plays/data/repositories/play_repository.dart';
import 'features/plays/presentation/cubit/playbook_cubit.dart';
import 'features/possessions/data/repositories/possession_repository.dart';
import 'features/competitions/data/repositories/competition_repository.dart';
import 'features/competitions/presentation/cubit/competition_cubit.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  // Global Services & Repositories (Singletons)
  sl.registerSingleton<AuthRepository>(AuthRepository());
  sl.registerSingleton<UserRepository>(UserRepository());
  sl.registerSingleton<RefreshSignal>(RefreshSignal());
  sl.registerLazySingleton<TeamRepository>(() => TeamRepository());
  sl.registerLazySingleton<PlayRepository>(() => PlayRepository());
  sl.registerLazySingleton<PossessionRepository>(() => PossessionRepository());
  sl.registerLazySingleton<CompetitionRepository>(
    () => CompetitionRepository(),
  );

  // Cubits (Lazy Singletons or Factories)
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(authRepository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton<TeamCubit>(
    () => TeamCubit(teamRepository: sl<TeamRepository>()),
  );
  sl.registerLazySingleton<CompetitionCubit>(
    () => CompetitionCubit(competitionRepository: sl<CompetitionRepository>()),
  );
  sl.registerFactory<TeamDetailCubit>(
    () => TeamDetailCubit(teamRepository: sl<TeamRepository>()),
  );
  sl.registerFactory<PlaybookCubit>(
    () => PlaybookCubit(playRepository: sl<PlayRepository>()),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  await sl<AuthCubit>().checkAuthentication(); // Wait for initial auth check
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  late final AppRouter appRouter = AppRouter(authCubit: sl<AuthCubit>());

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Provide the single instance of AuthCubit
        BlocProvider.value(value: sl<AuthCubit>()),

        // Create other global cubits. They will listen to AuthCubit for changes.
        BlocProvider(create: (context) => sl<TeamCubit>()),
        BlocProvider(create: (context) => sl<CompetitionCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        // This listener is the key. When the auth state changes, we fetch data.
        listener: (context, authState) {
          if (authState.status == AuthStatus.authenticated &&
              authState.token != null) {
            // When a user logs in, fetch the initial data for the session.
            context.read<TeamCubit>().fetchTeams(token: authState.token!);
            context.read<CompetitionCubit>().fetchCompetitions(
              token: authState.token!,
            );
          }
        },
        child: MaterialApp.router(
          title: 'Basketball Analytics',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF003366),
            ),
            // ... your other theme data
          ),
          routerConfig: appRouter.router,
        ),
      ),
    );
  }
}
