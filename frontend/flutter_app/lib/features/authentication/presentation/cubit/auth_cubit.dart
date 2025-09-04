// lib/features/authentication/presentation/cubit/auth_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/main.dart'; // To access GetIt (sl)
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';
import 'package:flutter_app/core/services/api_service.dart';
// Import all the cubits that need to be triggered
import '../../../teams/presentation/cubit/team_cubit.dart';
import '../../../competitions/presentation/cubit/competition_cubit.dart';
import '../../../games/presentation/cubit/game_cubit.dart';
import '../../../calendar/presentation/cubit/calendar_cubit.dart';
import '../../../plays/presentation/cubit/play_category_cubit.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState.unknown()) {
    logger.i('AuthCubit initialized with unknown state.');
  }

  /// This is a centralized helper method called after any successful login.
  /// It fetches all initial data needed for a user session.
  Future<void> _onLoginSuccess(String token, User user) async {
    // Set the auth token in the ApiService
    sl<ApiService>().setAuthToken(token);
    
    // Get instances of the other global/session-wide cubits from the service locator.
    final teamCubit = sl<TeamCubit>();
    final competitionCubit = sl<CompetitionCubit>();
    final gameCubit = sl<GameCubit>();
    final calendarCubit = sl<CalendarCubit>();
    final playCategoryCubit = sl<PlayCategoryCubit>();

    // Tell each cubit to fetch its essential data using the new token.
    // We don't need to await these; they can run in parallel.
    teamCubit.fetchTeams(token: token);
    competitionCubit.fetchCompetitions(token: token);
    gameCubit.fetchGames(token: token);
    calendarCubit.fetchCalendarData(token: token);
    playCategoryCubit.fetchCategories(token: token);

    // Finally, emit the authenticated state. The UI will react to this,
    // and the other cubits will be updating their own states in the background.
    emit(AuthState.authenticated(token: token, user: user));
    logger.i('User authenticated: ${user.username}');
  }

  /// Checks for a saved token on app startup and authenticates the user.
  Future<void> checkAuthentication() async {
    logger.d('Checking authentication status...');
    final token = await _authRepository.tryToLoadToken();
    if (token == null) {
      emit(const AuthState.unauthenticated());
      logger.w('No authentication token found. User unauthenticated.');
      return;
    }

    final user = await _authRepository.getCurrentUser(token);
    if (user != null) {
      await _onLoginSuccess(token, user);
    } else {
      // Token was invalid or expired
      emit(const AuthState.unauthenticated());
      logger.w('Token found but invalid or expired. User unauthenticated.');
    }
  }

  /// Attempts to log in a user with credentials.
  Future<void> login(String username, String password) async {
    logger.d('Attempting login for user: $username');
    final token = await _authRepository.login(username, password);
    if (token == null) {
      emit(const AuthState.unauthenticated());
      logger.e('Login failed for user: $username');
      return;
    }

    final user = await _authRepository.getCurrentUser(token);
    if (user != null) {
      await _onLoginSuccess(token, user);
    } else {
      emit(const AuthState.unauthenticated());
      logger.e('Login successful but failed to retrieve user data for: $username');
    }
  }

  /// Logs the user out and resets all user-specific data.
  Future<void> logout() async {
    logger.i('User logging out.');
    // Clear the token from storage first.
    await _authRepository.logout();

    // Clear the auth token from ApiService
    sl<ApiService>().clearAuthToken();

    // This tells GoRouter to navigate to the login screen RIGHT NOW.
    // The old screens (HomeScreen, etc.) will be disposed.
    emit(const AuthState.unauthenticated());

    await sl.resetLazySingleton<TeamCubit>();
    await sl.resetLazySingleton<CompetitionCubit>();
    await sl.resetLazySingleton<GameCubit>();
    await sl.resetLazySingleton<CalendarCubit>();
    await sl.resetLazySingleton<PlayCategoryCubit>();
    logger.i('User logged out and cubits reset.');
  }
}
