import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/settings/cubit/settings_cubit.dart';
import 'features/shell/view/home_shell.dart';

/// Root widget. Repository providers and SettingsCubit are installed above
/// this in `main()`, so any screen can reach them via `context.read<...>()`.
class Barn2ScoutApp extends StatelessWidget {
  const Barn2ScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      // Only rebuild MaterialApp when themeMode changes — not on every
      // settings update (e.g. scouter name edits don't need a full rebuild).
      buildWhen: (prev, curr) => prev.themeMode != curr.themeMode,
      builder: (context, settings) {
        return MaterialApp(
          title: 'Barn2Scout',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: const HomeShell(),
        );
      },
    );
  }
}
