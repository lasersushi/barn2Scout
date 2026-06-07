import 'package:flutter/material.dart';

import '../../../data/models/match_prediction.dart';

/// The "tug-of-war" prediction bar shown under an upcoming match: predicted
/// score on each side, a fill split by win probability, and a confidence note
/// when not all six teams have TBA data yet.
///
/// Renders nothing when there's no rating data to predict from.
class MatchPredictionBar extends StatelessWidget {
  const MatchPredictionBar({super.key, required this.prediction});

  final MatchPrediction prediction;

  @override
  Widget build(BuildContext context) {
    final p = prediction;
    if (!p.hasData) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final rp = (p.redWinPct * 100).round();
    final rFlex = (p.redWinPct * 1000).round().clamp(0, 1000);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${p.redScore.round()}',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      if (rFlex > 0)
                        Expanded(
                          flex: rFlex,
                          child: Container(
                            height: 24,
                            color: Colors.red.shade600,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '$rp%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (rFlex < 1000)
                        Expanded(
                          flex: 1000 - rFlex,
                          child: Container(
                            height: 24,
                            color: Colors.blue.shade600,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${100 - rp}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '${p.blueScore.round()}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (p.ratedTeams < p.totalTeams)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${p.ratedTeams}/${p.totalTeams} teams rated',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
