// lib/features/authentication/presentation/cubit/auth_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown());

  // This method can be called at app start-up to check for a saved session
  void checkAuthentication() {
    if (_authRepository.isLoggedIn()) {
      emit(const AuthState.authenticated());
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> login(String username, String password) async {
    final success = await _authRepository.login(username, password);
    if (success) {
      emit(const AuthState.authenticated());
    } else {
      // We can emit a failure state here if we want to show an error message
      emit(const AuthState.unauthenticated());
    }
  }

  void logout() {
    _authRepository.logout();
    emit(const AuthState.unauthenticated());
  }
}