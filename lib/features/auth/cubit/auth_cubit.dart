import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial()) {
    _checkSession();
  }

  final _client = Supabase.instance.client;

  static bool _isAllowedEmail(String email) {
    final lower = email.trim().toLowerCase();
    return lower.endsWith('@priorypanther.com');
  }

  static bool _isTeacherEmail(String email) {
    final lower = email.trim().toLowerCase();
    return lower.endsWith('@prioryca.org');
  }

  void _checkSession() {
    // Always require sign-in on cold start — stored sessions are ignored.
    emit(const AuthUnauthenticated());
  }

  /// Call this when the app resumes after being backgrounded for too long.
  Future<void> signOutDueToInactivity() async {
    await _client.auth.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> signIn(String email, String password) async {
    if (!_isAllowedEmail(email) && !_isTeacherEmail(email)) {
      emit(
        const AuthError(
          'Only @priorypanther.com or @prioryca.org accounts are allowed. If you are a mentor, please contact Lucas for assistance.',
        ),
      );
      return;
    }
    emit(const AuthLoading());
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = res.user;
      if (user != null) {
        final addr = user.email ?? '';
        emit(_isTeacherEmail(addr)
            ? AuthAuthenticatedAdmin(addr)
            : AuthAuthenticated(addr));
      } else {
        emit(const AuthError('Sign in failed. Check your credentials.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(const AuthError('Something went wrong. Check your connection.'));
    }
  }

  Future<void> signUp(String email, String password) async {
    if (!_isAllowedEmail(email) && !_isTeacherEmail(email)) {
      emit(
        const AuthError(
          'Only @priorypanther.com or @prioryca.org accounts are allowed. If you are a mentor, please contact Lucas for assistance.',
        ),
      );
      return;
    }
    emit(const AuthLoading());
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      final user = res.user;
      if (user != null) {
        final addr = user.email ?? '';
        emit(_isTeacherEmail(addr)
            ? AuthAuthenticatedAdmin(addr)
            : AuthAuthenticated(addr));
      } else {
        emit(const AuthError('Sign up failed. Try a different email.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(const AuthError('Something went wrong. Check your connection.'));
    }
  }

  /// Re-authenticates with [currentPassword] then updates to [newPassword].
  /// Returns an error message string on failure, null on success.
  Future<String?> updatePassword(String currentPassword, String newPassword) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return 'Not signed in.';
    if (newPassword.length < 6) return 'Password must be at least 6 characters.';
    try {
      // Re-authenticate to confirm identity before changing the password.
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Check your connection.';
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    emit(const AuthUnauthenticated());
  }
}
