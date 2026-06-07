import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/team_analytics.dart';
import '../../../features/scouting/config/field_config.dart';
import '../../../features/scouting/config/game_config.dart';

/// Slides up from the rankings list when the user taps a team row.
/// Shows per-phase stat cards driven by [kDefaultGameConfig].
class TeamDossierSheet extends StatelessWidget {
  const TeamDossierSheet({
    super.key,
    required this.team,
    required this.rank,
    required this.totalTeams,
  });

  final TeamAnalytics team;
  final int rank;
  final int totalTeams;

  static Future<void> show(
    BuildContext context, {
    required TeamAnalytics team,
    required int rank,
    required int totalTeams,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TeamDossierSheet(
        team: team,
        rank: rank,
        totalTeams: totalTeams,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMine = team.team == AppConfig.myTeamNumber;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Headline card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Team ${team.team}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                              if (isMine) ...[
                                const SizedBox(width: 8),
                                _Badge(text: 'YOU', color: cs.primary),
                              ],
                            ],
                          ),
                          Text(
                            '${team.matches} match${team.matches == 1 ? '' : 'es'} scouted',
                            style: TextStyle(color: cs.onPrimaryContainer),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Text(
                            team.composite.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'rank #$rank of $totalTeams',
                            style: TextStyle(color: cs.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Per-phase stat cards
            for (final phase in ScoutPhase.values)
              _PhaseCard(phase: phase, team: team),
          ],
        );
      },
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.phase, required this.team});

  final ScoutPhase phase;
  final TeamAnalytics team;

  static const _titles = {
    ScoutPhase.auto: 'Auto',
    ScoutPhase.teleop: 'Teleop',
    ScoutPhase.endgame: 'Endgame',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fields = fieldsForPhase(phase);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titles[phase]!.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 12),
              for (final f in fields) ...[
                _FieldRow(field: f, team: team),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field, required this.team});

  final FieldConfig field;
  final TeamAnalytics team;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = Text(
      field.label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    );

    // League max — used to scale bars relative to the best-seen value.
    double leagueMax(Map<String, double> map) =>
        map.values.fold<double>(0.0001, math.max);

    switch (field.type) {
      case FieldType.counter:
      case FieldType.stopwatch:
        final v = team.avg[field.key] ?? 0;
        final unit = field.type == FieldType.stopwatch ? 's' : '/match';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: label),
                Text(
                  '${v.toStringAsFixed(1)}$unit',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _Bar(frac: v / leagueMax(team.avg), fill: cs.primary, track: cs.surfaceContainerHighest),
          ],
        );

      case FieldType.rating:
        final v = team.avg[field.key] ?? 0;
        return Row(
          children: [
            Expanded(child: label),
            _Stars(value: v, outOf: field.max ?? 5),
          ],
        );

      case FieldType.toggle:
        final p = team.pct[field.key] ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: label),
                Text(
                  '${(p * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _Bar(frac: p, fill: cs.tertiary, track: cs.surfaceContainerHighest),
          ],
        );

      case FieldType.choice:
        final d = team.dist[field.key] ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 8),
            _DistBar(options: field.options, dist: d),
          ],
        );

      case FieldType.text:
        return label;
    }
  }
}

// ───────────────────────────────────────────── shared mini-widgets ─────────

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

class _Stars extends StatelessWidget {
  const _Stars({required this.value, required this.outOf});

  final double value;
  final int outOf;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= outOf; i++)
          Icon(
            value >= i
                ? Icons.star
                : (value >= i - 0.5 ? Icons.star_half : Icons.star_border),
            size: 18,
            color: Colors.amber.shade600,
          ),
        const SizedBox(width: 6),
        Text(value.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _DistBar extends StatelessWidget {
  const _DistBar({required this.options, required this.dist});

  final List<String> options;
  final Map<String, int> dist;

  static const _palette = [
    Color(0xFF9E9E9E),
    Color(0xFF607D8B),
    Color(0xFF42A5F5),
    Color(0xFF2E7D32),
  ];

  @override
  Widget build(BuildContext context) {
    final total = options.fold<int>(0, (a, o) => a + (dist[o] ?? 0));
    if (total == 0) return const Text('No data', style: TextStyle(fontSize: 12));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              for (var i = 0; i < options.length; i++)
                if ((dist[options[i]] ?? 0) > 0)
                  Expanded(
                    flex: dist[options[i]]!,
                    child: Container(
                      height: 14,
                      color: _palette[i % _palette.length],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (var i = 0; i < options.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _palette[i % _palette.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${options[i]} ${dist[options[i]] ?? 0}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
          ],
        ),
      ],
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
