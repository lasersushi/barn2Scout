import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/scout_profile.dart';
import '../cubit/management_cubit.dart';

/// Admins grant the "AI role": unlimited AI generations plus Chat and Match
/// briefs. Admins have it already; everyone else gets 20 team summaries a day.
class AiAccessPage extends StatelessWidget {
  const AiAccessPage({super.key});

  static Future<void> push(BuildContext context) {
    final cubit = context.read<ManagementCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const AiAccessPage()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('AI access')),
      body: BlocBuilder<ManagementCubit, ManagementState>(
        builder: (context, state) {
          if (state is! ManagementLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final scouts = state.profiles.where((p) => !p.isAdmin).toList();
          final admins = state.profiles.where((p) => p.isAdmin).toList();

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Scouts with the AI role can use AI as much as they like, '
                  'including Chat and Match briefs. Everyone else gets 20 team '
                  'summaries a day. A team-wide spending cap still applies to '
                  'everyone.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
              for (final p in scouts) _ScoutSwitch(profile: p),
              if (admins.isNotEmpty) ...[
                const Divider(),
                for (final p in admins)
                  ListTile(
                    title: Text(p.displayName),
                    subtitle: const Text('Unlimited (admin)'),
                    trailing: const Icon(Icons.verified_outlined),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ScoutSwitch extends StatelessWidget {
  const _ScoutSwitch({required this.profile});

  final ScoutProfile profile;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(profile.displayName),
      subtitle: Text(profile.email),
      value: profile.aiAccess,
      onChanged: (enabled) async {
        final messenger = ScaffoldMessenger.of(context);
        final error = await context
            .read<ManagementCubit>()
            .setAiAccess(profile.userId, enabled);
        if (error != null) {
          messenger.showSnackBar(
            SnackBar(content: Text("Couldn't change AI access: $error")),
          );
        }
      },
    );
  }
}
