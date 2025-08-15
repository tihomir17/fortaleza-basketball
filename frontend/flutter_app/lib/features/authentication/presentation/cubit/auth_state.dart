// lib/features/authentication/presentation/cubit/auth_state.dart

import 'package:equatable/equatable.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? token; // <-- ADD THIS PROPERTY

  const AuthState._({this.status = AuthStatus.unknown, this.token});

  const AuthState.unknown() : this._();

  // The authenticated state now requires a token
  const AuthState.authenticated({required String token})
      : this._(status: AuthStatus.authenticated, token: token);

  const AuthState.unauthenticated() : this._(status: AuthStatus.unauthenticated);

  @override
  List<Object?> get props => [status, token];
}