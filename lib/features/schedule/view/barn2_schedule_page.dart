import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/nexus_match.dart';
import '../../../data/models/tba_match.dart';
import '../cubit/schedule_cubit.dart';

/// Team 751's matches at the current event, with live Nexus queue status.
class Barn2SchedulePage extends StatefulWidget {
  const Barn2SchedulePage({super.key});

  @override
  State<Barn2SchedulePage> createState() => _Barn2SchedulePageState();
}

class _Barn2SchedulePageState extends State<Barn2SchedulePage> {
  @override
  void initState() {
    super.initState();
    // Load on first render; cubit ignores duplicate calls while loading.
    context.read<ScheduleCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: switch (state) {
              ScheduleLoaded s => Text('751 @ ${s.eventName}'),
              _ => const Text('My Schedule'),
            },
            actions: [
              if (state is ScheduleLoaded)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<ScheduleCubit>().load(),
                ),
            ],
          ),
          body: switch (state) {
            ScheduleInitial() || ScheduleLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ScheduleError s => _ErrorView(
                message: s.message,
                onRetry: () => context.read<ScheduleCubit>().load(),
              ),
            ScheduleLoaded s => s.myMatches.isEmpty
                ? const Center(child: Text('No matches found for Team 751.'))
                : ListView.separated(
                    itemCount: s.myMatches.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _MatchTile(
                      match: s.myMatches[i],
                      nexus: s.nexusFor(s.myMatches[i].label),
                    ),
                  ),
          },
        );
      },
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match, this.nexus});

  final TbaMatch match;
  final NexusMatch? nexus;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final alliance = match.allianceFor(AppConfig.myTeamKey);
    final isRed = alliance == 'red';
    final allianceColor = isRed ? Colors.red.shade700 : Colors.blue.shade700;

    final partners = (isRed ? match.redTeams : match.blueTeams)
        .where((k) => k != AppConfig.myTeamKey)
        .map(TbaMatch.displayNumber)
        .join(' · ');

    final opponents = (isRed ? match.blueTeams : match.redTeams)
        .map(TbaMatch.displayNumber)
        .join(' · ');

    final myScore = isRed ? match.redScore : match.blueScore;
    final oppScore = isRed ? match.blueScore : match.redScore;
    final won = match.winningAlliance == alliance;

    return ListTile(
      leading: Container(
        width: 4,
        height: double.infinity,
        color: allianceColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Text(match.label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          if (nexus != null) _StatusChip(nexus!.status),
          const Spacer(),
          if (match.isPlayed)
            Text(
              '$myScore – $oppScore',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: won ? Colors.green.shade700 : cs.error,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Partners: $partners'),
          Text('Vs: $opponents',
              style: TextStyle(color: cs.onSurfaceVariant)),
          if (nexus?.estimatedQueueTime != null && !match.isPlayed)
            Text(
              'Queue: ${DateFormat('h:mm a').format(nexus!.estimatedQueueTime!)}',
              style: TextStyle(color: cs.primary, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;

  Color _color(BuildContext context) => switch (status) {
        'Now queuing' => Colors.orange.shade700,
        'On deck' => Colors.amber.shade700,
        'On field' => Colors.green.shade700,
        _ => Theme.of(context).colorScheme.outline,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color(context).withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color(context), width: 0.5),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: _color(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
