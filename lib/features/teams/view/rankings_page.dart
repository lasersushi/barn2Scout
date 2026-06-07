import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/team_analytics.dart';
import '../cubit/analytics_cubit.dart';
import 'team_dossier_sheet.dart';

/// Ranked list of every team in the scouting database, sorted by composite
/// score. Tap any row to open the [TeamDossierSheet] with per-phase breakdowns.
class RankingsPage extends StatelessWidget {
  const RankingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      builder: (context, state) => switch (state) {
        AnalyticsLoading() =>
          const Center(child: CircularProgressIndicator()),
        AnalyticsEmpty() => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.leaderboard_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  const Text('No scouting records yet.',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    'Scout some matches and rankings will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        AnalyticsLoaded s => _RankingList(teams: s.teams),
      },
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.teams});

  final List<TeamAnalytics> teams;

  double get _maxComposite =>
      teams.isEmpty ? 1 : teams.first.composite.clamp(0.0001, double.infinity);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: teams.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _RankRow(
        team: teams[i],
        rank: i + 1,
        totalTeams: teams.length,
        maxComposite: _maxComposite,
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.team,
    required this.rank,
    required this.totalTeams,
    required this.maxComposite,
  });

  final TeamAnalytics team;
  final int rank;
  final int totalTeams;
  final double maxComposite;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMine = team.team == AppConfig.myTeamNumber;

    return InkWell(
      onTap: () => TeamDossierSheet.show(
        context,
        team: team,
        rank: rank,
        totalTeams: totalTeams,
      ),
      child: Container(
        color: isMine ? cs.primaryContainer.withValues(alpha: 0.35) : null,
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rank number
            SizedBox(
              width: 32,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            // Name + bar + mini-stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Team ${team.team}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 8),
                        _Badge(text: 'YOU', color: cs.primary),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        '${team.matches} match${team.matches == 1 ? '' : 'es'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _Bar(
                    frac: team.composite / maxComposite,
                    fill: cs.primary,
                    track: cs.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _miniStats(team),
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Composite score bubble
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  team.composite.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                Text(
                  'pts',
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// One-line summary of key counters — auto-derived from [kDefaultGameConfig]
  /// via the avg map, so new counter fields appear here for free.
  String _miniStats(TeamAnalytics t) {
    final parts = <String>[];
    for (final e in t.avg.entries) {
      parts.add('${_shortKey(e.key)} ${e.value.toStringAsFixed(1)}');
    }
    return parts.take(4).join('  ·  ');
  }

  String _shortKey(String key) {
    // Strip the phase prefix (auto_ / teleop_ / endgame_) for brevity.
    final trimmed = key.replaceFirst(RegExp(r'^(auto|teleop|endgame)_'), '');
    return trimmed.replaceAll('_', ' ');
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.frac, required this.fill, required this.track});

  final double frac;
  final Color fill;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final f = (frac.clamp(0.0, 1.0) * 1000).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: [
          if (f > 0)
            Expanded(flex: f, child: Container(height: 8, color: fill)),
          if (f < 1000)
            Expanded(flex: 1000 - f, child: Container(height: 8, color: track)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
