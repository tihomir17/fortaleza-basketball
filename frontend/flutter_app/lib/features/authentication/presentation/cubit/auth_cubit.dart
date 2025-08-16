// lib/features/authentication/presentation/cubit/auth_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState.unknown());

  // THIS METHOD IS NOW CORRECT
  Future<void> checkAuthentication() async {
    // 1. Try to load the token from storage
    final token = await _authRepository.tryToLoadToken();
    if (token == null) {
      emit(const AuthState.unauthenticated());
      return;
    }

    // 2. If a token exists, use it to fetch the user profile
    final user = await _authRepository.getCurrentUser(token);
    if (user != null) {
      // 3. If user is fetched successfully, we are authenticated
      emit(AuthState.authenticated(token: token, user: user));
    } else {
      // If the token is invalid/expired, we are unauthenticated
      emit(const AuthState.unauthenticated());
    }
  }

  // THIS METHOD IS ALSO CORRECTED
  Future<void> login(String username, String password) async {
    // 1. Log in to get the token
    final token = await _authRepository.login(username, password);
    if (token == null) {
      emit(const AuthState.unauthenticated());
      return;
    }

    // 2. Use the new token to get the user profile
    final user = await _authRepository.getCurrentUser(token);
    if (user != null) {
      // 3. Emit the full authenticated state
      emit(AuthState.authenticated(token: token, user: user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(const AuthState.unauthenticated());
  }
}
