import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/nexus_match.dart';
import '../../../data/models/tba_match.dart';

/// A list tile showing one of Team 751's matches.
///
/// Pass [nexus] for live queue status chips (upcoming matches only).
/// Leave it null for past matches — the chip is simply omitted.
class MatchTile extends StatelessWidget {
  const MatchTile({super.key, required this.match, this.nexus});

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
          if (nexus != null) StatusChip(nexus!.status),
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

/// Small colored chip showing Nexus queue status (e.g. "Now queuing").
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
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
        color: _color(context).withValues(alpha: 0.15),
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
