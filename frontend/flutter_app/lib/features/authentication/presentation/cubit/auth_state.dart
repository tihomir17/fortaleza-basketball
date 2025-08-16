// lib/features/authentication/presentation/cubit/auth_state.dart

import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? token;
  final User? user; // user property

  const AuthState._({this.status = AuthStatus.unknown, this.token, this.user});

  const AuthState.unknown() : this._();

  // Authenticated state now requires BOTH a token and a user
  const AuthState.authenticated({required String token, required User user})
    : this._(status: AuthStatus.authenticated, token: token, user: user);

  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  @override
  List<Object?> get props => [status, token, user];
}
