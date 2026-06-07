import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial()) {
    _checkSession();
  }

  final _client = Supabase.instance.client;

  static bool _isAllowedEmail(String email) =>
      email.trim().toLowerCase().endsWith('@priorypanther.com');

  void _checkSession() {
    final user = _client.auth.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user.email ?? ''));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> signIn(String email, String password) async {
    if (!_isAllowedEmail(email)) {
      emit(const AuthError('Only @priorypanther.com accounts are allowed.'));
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
        emit(AuthAuthenticated(user.email ?? ''));
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
    if (!_isAllowedEmail(email)) {
      emit(const AuthError('Only @priorypanther.com accounts are allowed.'));
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
        emit(AuthAuthenticated(user.email ?? ''));
      } else {
        emit(const AuthError('Sign up failed. Try a different email.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(const AuthError('Something went wrong. Check your connection.'));
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    emit(const AuthUnauthenticated());
  }
}
