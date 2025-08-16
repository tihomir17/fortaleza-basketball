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

import 'features/authentication/data/repositories/user_repository.dart';

import 'core/navigation/app_router.dart';

// Create a global instance of GetIt for service location
final sl = GetIt.instance;

void setupServiceLocator() {
  // Auth
  sl.registerSingleton<AuthRepository>(AuthRepository());
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(authRepository: sl<AuthRepository>()));
  sl.registerLazySingleton<UserRepository>(() => UserRepository()); // <-- ADD THIS

  // Repositories (can be singletons as they are stateless)
  sl.registerLazySingleton<TeamRepository>(() => TeamRepository());
  sl.registerLazySingleton<PlayRepository>(() => PlayRepository());

  // Cubits that hold user-specific data MUST be lazy singletons
  sl.registerLazySingleton<TeamCubit>(() => TeamCubit(teamRepository: sl<TeamRepository>()));
  sl.registerFactory<TeamDetailCubit>(() => TeamDetailCubit(teamRepository: sl<TeamRepository>()));

  // sl.registerLazySingleton<TeamDetailCubit>(() => TeamDetailCubit(teamRepository: sl<TeamRepository>()));
  sl.registerFactory<PlaybookCubit>(() => PlaybookCubit(playRepository: sl<PlayRepository>()));
  sl.registerFactory<CreatePlayCubit>(() => CreatePlayCubit(playRepository: sl<PlayRepository>()));
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
    return BlocProvider.value(
      value: sl<AuthCubit>(),
      child: MaterialApp.router(
        title: 'Basketball Analytics',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        // Use the router configuration from our AppRouter class
        routerConfig: appRouter.router,
      ),
    );
  }
}
