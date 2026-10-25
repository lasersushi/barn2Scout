import 'package:barn2scout/app.dart';
import 'package:barn2scout/features/auth/cubit/auth_cubit.dart';
import 'package:barn2scout/features/auth/view/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for a Supabase rejection: loading first, then an error, which is
/// the sequence that used to unmount LoginPage and swallow the snackbar.
class _RejectingAuthCubit extends AuthCubit {
  _RejectingAuthCubit(this.message);
  final String message;

  @override
  Future<void> signIn(String email, String password) async {
    emit(const AuthLoading());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    emit(AuthError(message));
  }
}

Future<void> _pumpGate(WidgetTester tester, AuthCubit cubit) =>
    tester.pumpWidget(MaterialApp(
      home: BlocProvider<AuthCubit>.value(value: cubit, child: const AuthGate()),
    ));

Future<void> _signIn(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), 'hunter2');
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
}

void main() {
  testWidgets('a rejected sign-in shows its error and keeps the form filled',
      (tester) async {
    final cubit = _RejectingAuthCubit('Email not confirmed');
    await _pumpGate(tester, cubit);

    await _signIn(tester, 'scout@priorypanther.com');
    await tester.pump(); // AuthLoading
    expect(find.byType(LoginPage), findsOneWidget,
        reason: 'LoginPage must stay mounted while signing in');

    await tester.pump(const Duration(milliseconds: 10)); // AuthError
    await tester.pump(); // snackbar entrance

    expect(find.widgetWithText(SnackBar, 'Email not confirmed'), findsOneWidget);
    expect(find.text('scout@priorypanther.com'), findsOneWidget);
    await cubit.close();
  });

  test('the same error twice in a row is emitted both times', () async {
    final cubit = AuthCubit();
    final errors = <AuthError>[];
    final sub = cubit.stream.listen((s) {
      if (s is AuthError) errors.add(s);
    });

    // Wrong domain fails before any Supabase call, so no client is needed.
    await cubit.signIn('scout@gmail.com', 'pw');
    await cubit.signIn('scout@gmail.com', 'pw');
    await Future<void>.delayed(Duration.zero);

    expect(errors, hasLength(2));
    await sub.cancel();
    await cubit.close();
  });
}
