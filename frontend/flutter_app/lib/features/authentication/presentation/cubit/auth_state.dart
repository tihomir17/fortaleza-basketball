// lib/features/authentication/presentation/cubit/auth_state.dart

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;

  const AuthState._({this.status = AuthStatus.unknown});

  // Initial state of the app
  const AuthState.unknown() : this._();

  // State when user is logged in
  const AuthState.authenticated() : this._(status: AuthStatus.authenticated);

  // State when user is logged out
  const AuthState.unauthenticated() : this._(status: AuthStatus.unauthenticated);
}