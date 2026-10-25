part of 'auth_cubit.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.email);
  final String email;
}

class AuthAuthenticatedAdmin extends AuthState {
  const AuthAuthenticatedAdmin(this.email);
  final String email;
}

class AuthAuthenticatedSuperAdmin extends AuthState {
  const AuthAuthenticatedSuperAdmin(this.email);
  final String email;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Deliberately not const: Cubit drops an emit identical to the current
/// state, so a canonicalized `const AuthError(sameMessage)` repeated (e.g.
/// the wrong domain twice in a row) would never reach the login listener.
class AuthError extends AuthState {
  AuthError(this.message);
  final String message;
}
