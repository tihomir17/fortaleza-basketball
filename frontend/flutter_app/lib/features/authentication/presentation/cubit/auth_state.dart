// lib/features/authentication/presentation/cubit/auth_state.dart

import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart'; // Make sure to import your User model

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? token;
  final User? user; // <-- The required user object

  const AuthState._({this.status = AuthStatus.unknown, this.token, this.user});

  const AuthState.unknown() : this._();

  // The authenticated state now requires BOTH the token and the user
  const AuthState.authenticated({required String token, required User user})
    : this._(status: AuthStatus.authenticated, token: token, user: user);

  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  @override
  List<Object?> get props => [status, token, user];
}
