import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/team_strength.dart';

/// Slides up when a team row is tapped on the picklist board. Shows that team's
/// strength entirely from The Blue Alliance — OPR/DPR/CCWM, ranking, record,
/// and the spread of its real match scores. No human scouting feeds this.
class TeamDossierSheet extends StatelessWidget {
  const TeamDossierSheet({
    super.key,
    required this.strength,
    required this.rank,
    required this.totalTeams,
  });

  final TeamStrength strength;
  final int rank;
  final int totalTeams;

  static Future<void> show(
    BuildContext context, {
    required TeamStrength strength,
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
        strength: strength,
        rank: rank,
        totalTeams: totalTeams,
      ),
    );
  }

  static const _relLabels = ['Steady', 'Variable', 'Streaky'];
  static const _relColors = [
    Color(0xFF2E7D32),
    Color(0xFFF9A825),
    Color(0xFFC62828),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = strength.rating;
    final isMine = r.team == AppConfig.myTeamNumber;
    final bucket = strength.reliabilityBucket;

    String num1(double? v) => v == null ? '—' : v.toStringAsFixed(1);
    String pct(double? v) => v == null ? '—' : '${(v * 100).toStringAsFixed(0)}%';

    final scoreSpread = r.scoreMean == null
        ? '—'
        : '${r.scoreMean!.toStringAsFixed(0)}'
            '${r.scoreStd == null ? '' : ' ± ${r.scoreStd!.toStringAsFixed(0)}'}'
            ' (${r.matchesPlayed} matches)';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 32),
          children: [
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
                                'Team ${r.team}',
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
                          const SizedBox(height: 4),
                          if (bucket != null)
                            Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 10, color: _relColors[bucket]),
                                const SizedBox(width: 4),
                                Text(
                                  '${_relLabels[bucket]} scorer',
                                  style:
                                      TextStyle(color: cs.onPrimaryContainer),
                                ),
                              ],
                            )
                          else
                            Text('Consistency: not enough matches',
                                style: TextStyle(color: cs.onPrimaryContainer)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            strength.blend.toStringAsFixed(0),
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
            // TBA stats card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THE BLUE ALLIANCE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StatRow('OPR (offense)', num1(r.opr)),
                      _StatRow('DPR (defense)', num1(r.dpr)),
                      _StatRow('CCWM (net contribution)', num1(r.ccwm)),
                      _StatRow('Event rank', r.rank == null ? '—' : '#${r.rank}'),
                      _StatRow('Avg ranking points', num1(r.avgRp)),
                      _StatRow('Win rate', pct(r.winRate)),
                      _StatRow('Avg match score', scoreSpread),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'All figures from The Blue Alliance — no scouting data.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
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
