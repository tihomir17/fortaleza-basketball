// lib/features/authentication/presentation/cubit/auth_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../main.dart'; // <-- IMPORT GetIt INSTANCE
import '../../../teams/presentation/cubit/team_cubit.dart'; // <-- IMPORT TeamCubit
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown());

  // This method is called at app start-up.
  Future<void> checkAuthentication() async {
    // Check if the repository's in-memory token exists from a previous session.
    final token = _authRepository.authToken;
    if (token != null) {
      // If a token exists, we MUST also fetch the user profile to have a complete state.
      final user = await _authRepository.getMyProfile(token);
      if (user != null) {
        // If we successfully get the user, the session is valid.
        emit(AuthState.authenticated(token: token, user: user));
      } else {
        // If we have a token but can't get a user (e.g., token expired),
        // then the session is invalid.
        emit(const AuthState.unauthenticated());
      }
    } else {
      // If no token exists, we are unauthenticated.
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> login(String username, String password) async {
    final token = await _authRepository.login(username, password);
    if (token != null) {
      // After getting the token, get the user profile
      final user = await _authRepository.getMyProfile(token);
      if (user != null) {
        // On success, emit the authenticated state WITH the token AND user
        emit(AuthState.authenticated(token: token, user: user));
      } else {
        // If profile fetch fails, treat it as a login failure
        emit(const AuthState.unauthenticated());
      }
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _resetApp() async {
    // Unregister and re-register the feature cubits to ensure a clean state
    await sl.resetLazySingleton<TeamCubit>();

    // If you add more feature cubits, reset them here too
    // await sl.resetLazySingleton<PlaysCubit>();
  }
  void logout() {
    _authRepository.logout();
    _resetApp();
    emit(const AuthState.unauthenticated());
  }
}