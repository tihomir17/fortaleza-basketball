// lib/features/authentication/presentation/cubit/auth_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown());

  // checkAuthentication can be improved later with secure storage
  void checkAuthentication() {
    if (_authRepository.isLoggedIn()) {
      emit(AuthState.authenticated(token: _authRepository.authToken!));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> login(String username, String password) async {
    final token = await _authRepository.login(username, password);
    if (token != null) {
      // On success, emit the authenticated state WITH the token
      emit(AuthState.authenticated(token: token));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  void logout() {
    _authRepository.logout();
    emit(const AuthState.unauthenticated());
  }
}