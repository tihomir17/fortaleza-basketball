import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'features/authentication/data/repositories/auth_repository.dart';
import 'features/authentication/presentation/cubit/auth_cubit.dart';

import 'features/teams/data/repositories/team_repository.dart';
import 'features/teams/presentation/cubit/team_cubit.dart';
import 'features/teams/presentation/cubit/team_detail_cubit.dart';

import 'features/plays/data/repositories/play_repository.dart';
import 'features/plays/presentation/cubit/playbook_cubit.dart';
import 'features/plays/presentation/cubit/create_play_cubit.dart';
import 'features/possessions/data/repositories/possession_repository.dart';

import 'features/authentication/data/repositories/user_repository.dart';
import 'core/navigation/refresh_signal.dart';

import 'core/navigation/app_router.dart';

// Create a global instance of GetIt for service location
final sl = GetIt.instance;

void setupServiceLocator() {
  // Auth & Global Services (Singletons)
  sl.registerSingleton<AuthRepository>(AuthRepository());
  sl.registerSingleton<UserRepository>(UserRepository());
  sl.registerSingleton<RefreshSignal>(RefreshSignal());
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(authRepository: sl<AuthRepository>()),
  );

  // Repositories (Stateless, can be singletons)
  sl.registerLazySingleton<TeamRepository>(() => TeamRepository());
  sl.registerLazySingleton<PlayRepository>(() => PlayRepository());
  sl.registerLazySingleton<PossessionRepository>(() => PossessionRepository());
  // --- CUBIT REGISTRATION ---

  // Session-Wide List State: A singleton that we reset on logout. CORRECT.
  sl.registerLazySingleton<TeamCubit>(
    () => TeamCubit(teamRepository: sl<TeamRepository>()),
  );

  // Screen-Specific Detail State: MUST be a factory.
  sl.registerFactory<TeamDetailCubit>(
    () => TeamDetailCubit(teamRepository: sl<TeamRepository>()),
  );

  // Screen-Specific Detail State: MUST be a factory.
  sl.registerFactory<PlaybookCubit>(
    () => PlaybookCubit(playRepository: sl<PlayRepository>()),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  // We need to wait for the initial auth check to complete
  await sl<AuthCubit>().checkAuthentication();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Create an instance of our AppRouter
  late final AppRouter appRouter = AppRouter(authCubit: sl<AuthCubit>());

  @override
  Widget build(BuildContext context) {
    // We still provide the AuthCubit at the top level
    return MultiBlocProvider(
      providers: [
        // --- GLOBAL PROVIDERS ---
        // These cubits are available to ALL routes and screens in the app.
        BlocProvider.value(value: sl<AuthCubit>()),
        BlocProvider(create: (context) {
          final token = sl<AuthCubit>().state.token;
          // Only create and fetch if we have a token.
          return sl<TeamCubit>()..fetchTeams(token: token ?? '');
        }),
      ],
      child: MaterialApp.router(
        title: 'Basketball Analytics',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        // Use the router configuration from our AppRouter class
        routerConfig: appRouter.router,
      ),
    );
  }
}
