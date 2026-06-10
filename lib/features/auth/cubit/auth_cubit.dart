import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial()) {
    _checkSession();
  }

  final _client = Supabase.instance.client;

  static const _adminEmails = {
    'cstinson29@priorypanther.com',
    'smunoz27@priorypanther.com',
    'asudhof29@priorypanther.com',
  };
  static const _superAdminEmails = {
    'lwalker30@priorypanther.com',
    'tom.mandle@gmail.com',
    'jstinson1@yahoo.com',
  };

  static bool _isAllowedEmail(String email) {
    final lower = email.trim().toLowerCase();
    return lower.endsWith('@priorypanther.com');
  }

  static bool _isMentorEmail(String email) {
    final lower = email.trim().toLowerCase();
    return _adminEmails.contains(lower);
  }

  static bool _isSuperAdminEmail(String email) {
    final lower = email.trim().toLowerCase();
    return _superAdminEmails.contains(lower) || lower.endsWith('@prioryca.org');
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
    if (!_isAllowedEmail(email) && !_isMentorEmail(email) && !_isSuperAdminEmail(email)) {
      emit(
        const AuthError(
          'Only @priorypanther.com or @prioryca.org accounts are allowed.',
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
        emit(_isMentorEmail(addr)
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
    if (!_isAllowedEmail(email) && !_isMentorEmail(email) && !_isSuperAdminEmail(email)) {
      emit(
        const AuthError(
          'Only @priorypanther.com or @prioryca.org accounts are allowed.',
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
        emit(_isMentorEmail(addr)
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

  /// Permanently deletes the signed-in user's Supabase account.
  /// Requires the `delete_user` Postgres function to exist (see CLAUDE.md note).
  /// Returns an error message on failure, null on success.
  Future<String?> deleteAccount() async {
    try {
      await _client.rpc('delete_user');
      await _client.auth.signOut();
      emit(const AuthUnauthenticated());
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Something went wrong. Check your connection.';
    }
  }
}
