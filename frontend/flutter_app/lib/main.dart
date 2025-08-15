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
import 'features/teams/presentation/cubit/team_detail_cubit.dart';


// Create a global instance of GetIt for service location
final sl = GetIt.instance;

void setupServiceLocator() {
  // Auth
  sl.registerSingleton<AuthRepository>(AuthRepository());
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(authRepository: sl<AuthRepository>()));

  // Teams
  sl.registerLazySingleton<TeamRepository>(() => TeamRepository());
  // Use lazySingleton and we will reset it from the AuthCubit
  sl.registerLazySingleton<TeamCubit>(() => TeamCubit(teamRepository: sl<TeamRepository>()));
  sl.registerFactory<TeamDetailCubit>(() => TeamDetailCubit(teamRepository: sl<TeamRepository>()));
}

void main() {
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => sl<AuthCubit>()..checkAuthentication(),
      child: MaterialApp(
        title: 'Basketball Analytics',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            // <-- The state is named authState
            // Check the status of the authState
            if (authState.status == AuthStatus.authenticated) {
              // We are authenticated! We can safely access authState.token
              return BlocProvider(
                create: (context) => sl<TeamCubit>()
                  // Call fetchTeams immediately with the token from the state
                  ..fetchTeams(token: authState.token!),
                child: const HomeScreen(),
              );
            }
            // If we are not authenticated, show the login screen
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
