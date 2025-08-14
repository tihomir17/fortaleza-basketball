import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'features/authentication/data/repositories/auth_repository.dart';
import 'features/authentication/presentation/cubit/auth_cubit.dart';
import 'features/authentication/presentation/cubit/auth_state.dart';
import 'features/authentication/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

import 'features/teams/data/repositories/team_repository.dart';
import 'features/teams/presentation/cubit/team_cubit.dart';

// Create a global instance of GetIt for service location
final sl = GetIt.instance;

// This function sets up our singletons
void setupServiceLocator() {
  // Register AuthRepository as a singleton.
  // It will be created once and the same instance will be used everywhere.
  sl.registerSingleton<AuthRepository>(AuthRepository());

  // Register AuthCubit as a lazy singleton.
  // It will be created only when it's first requested.
  // It depends on AuthRepository, so we fetch it from the service locator.
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(authRepository: sl<AuthRepository>()),
  );

  sl.registerLazySingleton<TeamRepository>(
    () => TeamRepository(authRepository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton<TeamCubit>(
    () => TeamCubit(teamRepository: sl<TeamRepository>()),
  );
}

void main() {
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the AuthCubit to the entire widget tree below it.
    // We fetch the instance from our service locator `sl`.
    return BlocProvider<AuthCubit>(
      create: (_) => sl<AuthCubit>()..checkAuthentication(),
      child: MaterialApp(
        title: 'Basketball Analytics',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        // The BlocBuilder will rebuild the UI based on the AuthState
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              // If authenticated, provide the TeamCubit to the HomeScreen
              return BlocProvider(
                create: (context) => sl<TeamCubit>()..fetchTeams(), // <-- MODIFIED LINE
                child: const HomeScreen(),
              );
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
