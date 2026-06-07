import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/view/home_shell.dart';

/// Root widget. Repository providers are installed above this in `main()`, so
/// any screen can reach them via `context.read<...Repository>()`.
class Barn2ScoutApp extends StatelessWidget {
  const Barn2ScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barn2Scout',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
