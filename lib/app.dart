import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/view/login_page.dart';
import 'features/settings/cubit/settings_cubit.dart';
import 'features/shell/view/home_shell.dart';
import 'features/shell/view/admin_shell.dart';

class Barn2ScoutApp extends StatelessWidget {
  const Barn2ScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (prev, curr) => prev.themeMode != curr.themeMode,
        builder: (context, settings) {
          return MaterialApp(
            title: 'Barn2Scout',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) => switch (state) {
        AuthInitial() =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        // LoginPage must stay mounted through AuthLoading (it shows its own
        // button spinner). Swapping it out unmounts its BlocConsumer, and a
        // fresh listener never fires for the AuthError it mounts into, so
        // sign-in errors were silently dropped.
        AuthUnauthenticated() || AuthLoading() || AuthError() =>
          const LoginPage(),
        AuthAuthenticated() => const HomeShell(),
        AuthAuthenticatedAdmin() => const AdminShell(),
        AuthAuthenticatedSuperAdmin() => const AdminShell(),
      },
    );
  }
}
