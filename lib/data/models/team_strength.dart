import 'match_prediction.dart';
import 'team_rating.dart';

/// A team ranked for the picklist, entirely from TBA data — no human scouting.
/// Wraps a [TeamRating] with a single blended strength number (the same model
/// that drives match prediction) and a consistency bucket measured from the
/// spread of the team's real match scores.
class TeamStrength {
  const TeamStrength({
    required this.rating,
    required this.blend,
    required this.reliabilityBucket,
  });

  final TeamRating rating;

  /// Blended strength used to rank: OPR plus small point-denominated nudges for
  /// defense (DPR), ranking points, and win record. Higher is better.
  final double blend;

  /// Consistency from match-score spread: 0 = steady, 1 = variable,
  /// 2 = streaky, null = not enough matches played to judge.
  final int? reliabilityBucket;

  int get team => rating.team;

  /// Rank all [ratings] by blended strength (desc). The blend mirrors
  /// [MatchPrediction]'s per-team adjustment, with event-mean fallbacks for any
  /// missing DPR / ranking values, so a team is never penalised to zero.
  static List<TeamStrength> rank(
    Map<int, TeamRating> ratings, {
    PredictionConfig config = kPredictionConfig,
  }) {
    final all = ratings.values.toList();
    if (all.isEmpty) return const [];

    double mean(Iterable<double> xs, double fallback) =>
        xs.isEmpty ? fallback : xs.reduce((a, b) => a + b) / xs.length;

    final meanDpr = mean(all.map((r) => r.dpr), 0);
    final meanRp = mean(all.map((r) => r.avgRp).whereType<double>(), 0);

    final out = [
      for (final r in all)
        TeamStrength(
          rating: r,
          blend: r.opr +
              config.wDef * (meanDpr - r.dpr) +
              config.wRp * ((r.avgRp ?? meanRp) - meanRp) +
              config.wWin * ((r.winRate ?? 0.5) - 0.5),
          reliabilityBucket: _bucket(r, config),
        ),
    ]..sort((a, b) => b.blend.compareTo(a.blend));
    return out;
  }

  static int? _bucket(TeamRating r, PredictionConfig config) {
    final mean = r.scoreMean;
    final std = r.scoreStd;
    if (mean == null ||
        std == null ||
        mean < 1 ||
        r.matchesPlayed < config.minMatchesForRealSigma) {
      return null; // not enough match data to judge consistency
    }
    final cv = std / mean; // alliance-score coefficient of variation
    if (cv < 0.12) return 0;
    if (cv < 0.22) return 1;
    return 2;
  }
}
