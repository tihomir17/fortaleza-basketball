import 'package:get_it/get_it.dart';
import 'package:flutter_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:flutter_app/features/teams/data/repositories/team_repository.dart';
import 'package:flutter_app/features/games/data/repositories/game_repository.dart';
import 'package:flutter_app/core/api/api_client.dart';

final getIt = GetIt.instance;

void setupDependencyInjection() {
  // Core services
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<TeamRepository>(() => TeamRepository());
  getIt.registerLazySingleton<GameRepository>(() => GameRepository());
  
  // Auth token (will be set after login)
  getIt.registerSingleton<String>('', instanceName: 'auth_token');
}
