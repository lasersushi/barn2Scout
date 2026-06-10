import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../update/cubit/update_cubit.dart';
import '../cubit/settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return ListView(
            children: [
              _SectionHeader('Scouter'),
              ListTile(
                title: const Text('Scouter name'),
                subtitle: Text(settings.scouterName.isEmpty
                    ? 'Not set'
                    : settings.scouterName),
                trailing: TextButton(
                  onPressed: () => _editScouterName(context, settings.scouterName),
                  child: const Text('Edit'),
                ),
              ),

              _SectionHeader('Appearance'),
              ListTile(
                title: const Text('Theme'),
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (modes) =>
                      context.read<SettingsCubit>().setThemeMode(modes.first),
                ),
              ),

              _SectionHeader('Event'),
              ListTile(
                title: const Text('Active event'),
                subtitle: Text(
                  settings.eventKeyOverride ?? '(auto-detected from TBA)',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () =>
                          _editEventOverride(context, settings.eventKeyOverride),
                      child: const Text('Override'),
                    ),
                    if (settings.eventKeyOverride != null)
                      TextButton(
                        onPressed: () =>
                            context.read<SettingsCubit>().clearEventOverride(),
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ),

              _SectionHeader('Tabs'),
              SwitchListTile(
                title: const Text('Past Matches tab'),
                subtitle: const Text('Show a tab with completed matches'),
                value: settings.showPastMatchesTab,
                onChanged: (value) =>
                    context.read<SettingsCubit>().setShowPastMatchesTab(value),
              ),

              _SectionHeader('About'),
              ListTile(
                title: const Text('Team'),
                trailing: Text('#${AppConfig.myTeamNumber}'),
              ),
              BlocBuilder<UpdateCubit, UpdateState>(
                builder: (context, update) {
                  final installed = update.installed;
                  final version = installed == null
                      ? '…'
                      : 'v${installed.version} (${installed.buildNumber})'
                          '${installed.patchNumber != null ? ' · patch ${installed.patchNumber}' : ''}';
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Version'),
                        trailing: Text(version),
                      ),
                      ListTile(
                        title: const Text('Check for updates'),
                        subtitle: switch (update) {
                          UpdateChecking() => const Text('Checking…'),
                          UpdateUpToDate() => const Text('Up to date'),
                          UpdateCheckFailure() =>
                            const Text('Couldn\'t reach GitHub (offline?)'),
                          UpdateAvailable(:final release) => Text(
                              '${release.tagName} available — see banner above'),
                          _ => null,
                        },
                        trailing: const Icon(Icons.refresh),
                        onTap: () => context
                            .read<UpdateCubit>()
                            .checkForUpdate(userInitiated: true),
                      ),
                    ],
                  );
                },
              ),

              _SectionHeader('Account'),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change password'),
                onTap: () => _changePassword(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () => context.read<AuthCubit>().signOut(),
              ),
              ListTile(
                leading: Icon(Icons.delete_forever,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Delete account',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => _deleteAccount(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your Barn2Scout account. '
          'Your scouting records will remain on the server for the team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await context.read<AuthCubit>().deleteAccount();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final result = await showDialog<({String current, String next})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(
              (current: currentCtrl.text, next: newCtrl.text),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    if (result.current.isEmpty || result.next.isEmpty) return;

    final error =
        await context.read<AuthCubit>().updatePassword(result.current, result.next);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Password updated.'),
        backgroundColor: error != null
            ? Theme.of(context).colorScheme.error
            : Colors.green.shade700,
      ),
    );
  }

  Future<void> _editScouterName(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scouter name'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      context.read<SettingsCubit>().setScouterName(result);
    }
  }

  Future<void> _editEventOverride(BuildContext context, String? current) async {
    final controller = TextEditingController(text: current ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Event key override'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. 2027casvr',
            helperText: 'TBA-style event key. Leave blank to auto-detect.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      if (result.isEmpty) {
        context.read<SettingsCubit>().clearEventOverride();
      } else {
        context.read<SettingsCubit>().setEventOverride(result);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
