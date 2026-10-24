import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/assignment_repository.dart';
import '../../../data/repositories/pit_scouting_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/scouting_repository.dart';
import '../../leaderboard/cubit/leaderboard_cubit.dart';
import '../../leaderboard/view/leaderboard_tab.dart';

/// Admin view of every scout's XP at the current event, including scouts who
/// haven't filed a report yet. Reached from the Manage tab.
class ScoutXpPage extends StatelessWidget {
  const ScoutXpPage({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ScoutXpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => LeaderboardCubit(
        ctx.read<ScoutingRepository>(),
        ctx.read<PitScoutingRepository>(),
        ctx.read<AssignmentRepository>(),
        ctx.read<ScheduleRepository>(),
        includeIdleScouts: true,
      )..init(),
      child: const _ScoutXpView(),
    );
  }
}

class _ScoutXpView extends StatelessWidget {
  const _ScoutXpView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scout XP'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<LeaderboardCubit>().init(),
          ),
        ],
      ),
      body: BlocBuilder<LeaderboardCubit, LeaderboardState>(
        builder: (context, state) => switch (state) {
          LeaderboardLoading() =>
            const Center(child: CircularProgressIndicator()),
          LeaderboardNoEvent() => const _NoEventState(),
          LeaderboardLoaded s => _XpList(state: s),
        },
      ),
    );
  }
}

class _XpList extends StatelessWidget {
  const _XpList({required this.state});

  final LeaderboardLoaded state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = state.entries;
    final reports =
        entries.fold<int>(0, (sum, e) => sum + e.matchCount + e.pitCount);
    final totalXp = entries.fold<int>(0, (sum, e) => sum + e.xp);
    final idle = entries.where((e) => e.xp == 0).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: 'Scouts', value: '${entries.length}'),
                _Stat(label: 'Reports', value: '$reports'),
                _Stat(label: 'Total XP', value: '$totalXp'),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            '${state.eventKey}'
            '${idle > 0 ? '  ·  $idle with no reports yet' : ''}\n'
            'Based on records synced to this device. Admins appear once they '
            'file a report.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No scouts yet. People appear here after they sign in for the '
              'first time.',
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final e in entries) ...[
            const Divider(height: 1),
            LeaderboardRow(entry: e),
          ],
      ],
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
              'No active competition.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Scout XP appears once an event is active or upcoming.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
