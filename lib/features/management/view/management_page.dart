import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/scout_profile.dart';
import '../cubit/management_cubit.dart';
import 'assign_sheet.dart';

class ManagementPage extends StatefulWidget {
  const ManagementPage({super.key});

  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  @override
  void initState() {
    super.initState();
    context.read<ManagementCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ManagementCubit>().load(),
          ),
        ],
      ),
      body: BlocBuilder<ManagementCubit, ManagementState>(
        builder: (context, state) => switch (state) {
          ManagementLoading() =>
            const Center(child: CircularProgressIndicator()),
          ManagementNoEvent() => const _NoEventState(),
          ManagementError s => _ErrorState(message: s.message),
          ManagementLoaded s => _Roster(state: s),
        },
      ),
    );
  }
}

class _Roster extends StatelessWidget {
  const _Roster({required this.state});

  final ManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gaps = state.unassignedTeams;

    return ListView(
      children: [
        _CoverageBar(state: state),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            '${state.eventName}  ·  ${state.eventKey}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),

        const _SectionHeader('Scouts'),
        if (state.profiles.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No scouts yet. People appear here after they sign in for the '
              'first time. Note that it iwll take a little while for the list to populate after a new scout signs in.',
            ),
          )
        else
          ...state.profiles.map((p) => _ScoutRow(profile: p, state: state)),

        if (gaps.isNotEmpty) ...[
          _SectionHeader('Unassigned  (${gaps.length})'),
          ...gaps.map(
            (team) => ListTile(
              dense: true,
              leading: Icon(Icons.error_outline, color: cs.error, size: 20),
              title: Text('${team.teamNumber}  ${team.nickname}'),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CoverageBar extends StatelessWidget {
  const _CoverageBar({required this.state});

  final ManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = state.teams.length;
    final assigned = total - state.unassignedTeams.length;
    final done = state.teams
        .where((t) => state.scoutedTeams.contains(t.teamNumber))
        .length;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: 'Teams', value: '$total'),
            _Stat(label: 'Assigned', value: '$assigned'),
            _Stat(label: 'Scouted', value: '$done'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: cs.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
        ),
      ],
    );
  }
}

class _ScoutRow extends StatelessWidget {
  const _ScoutRow({required this.profile, required this.state});

  final ScoutProfile profile;
  final ManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final assigned = state.assignedCountFor(profile.userId);
    final done = state.doneCountFor(profile.userId);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.secondaryContainer,
        child: Text(
          profile.displayName.characters.first.toUpperCase(),
          style: TextStyle(color: cs.onSecondaryContainer),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              profile.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (profile.isAdmin) ...[
            const SizedBox(width: 6),
            _Badge(profile.role == 'super_admin' ? 'ADMIN' : 'ADMIN'),
          ],
        ],
      ),
      subtitle: Text(
        assigned == 0
            ? 'No teams assigned'
            : '$done of $assigned scouted',
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          AssignSheet.show(context, scout: profile, state: state),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cs.primary.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
    );
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

class _NoEventState extends StatelessWidget {
  const _NoEventState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text(
              'No upcoming competitions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Pit assignments appear once an event is active or upcoming.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text(
              "Couldn't load assignments",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<ManagementCubit>().load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
