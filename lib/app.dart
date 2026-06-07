import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/view/login_page.dart';
import 'features/settings/cubit/settings_cubit.dart';
import 'features/shell/view/home_shell.dart';

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
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) => switch (state) {
        AuthInitial() || AuthLoading() =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        AuthUnauthenticated() || AuthError() => const LoginPage(),
        AuthAuthenticated() => const HomeShell(),
      },
    );
  }
}
