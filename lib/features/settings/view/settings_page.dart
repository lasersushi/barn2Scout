import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
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
              const ListTile(
                title: Text('Version'),
                trailing: Text('1.0.0'),
              ),
            ],
          );
        },
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
