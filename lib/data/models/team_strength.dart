import 'dart:math' as math;

import 'match_prediction.dart';
import 'team_rating.dart';

/// A team ranked for the picklist, entirely from TBA data — no human scouting.
/// Wraps a [TeamRating] with a single blended strength number and a consistency
/// bucket, both built on the team's *implied contribution* rather than raw OPR
/// and raw alliance scores.
class TeamStrength {
  const TeamStrength({
    required this.rating,
    required this.blend,
    required this.reliabilityBucket,
  });

  final TeamRating rating;

  /// Blended strength used to rank: the robust contribution base plus small
  /// point-denominated nudges for defense (DPR), ranking points, and win
  /// record. Higher is better.
  final double blend;

  /// Consistency from the spread of implied contribution: 0 = steady,
  /// 1 = variable, 2 = streaky, null = not enough matches played to judge.
  final int? reliabilityBucket;

  int get team => rating.team;

  /// Rank all [ratings] by blended strength (desc).
  ///
  /// Two deliberate departures from a plain OPR sort, both traced to 1678 at
  /// 2026 NorCal DCMP landing 11th after a weekend of connection issues:
  ///
  /// * The base is [TeamRating.contribMedian] — a median, which three dead
  ///   matches out of nineteen cannot move — falling back to OPR, whose
  ///   least-squares fit a single dead match can drag arbitrarily far.
  /// * The DPR nudge is capped at [PredictionConfig.dprAdjClamp], because a
  ///   disabled robot inflates its own DPR (it isn't defending, so opponents
  ///   score freely) and uncapped that term outweighed every real signal.
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

    // Floor for the reliability denominator, so a team whose implied
    // contribution sits near zero can't divide its way to an infinite spread.
    final meanContrib =
        mean(all.map((r) => r.contribMedian).whereType<double>(), 0);
    final contribFloor = (meanContrib * 0.25).abs();

    double dprAdj(TeamRating r) => (config.wDef * (meanDpr - r.dpr))
        .clamp(-config.dprAdjClamp, config.dprAdjClamp)
        .toDouble();

    final out = [
      for (final r in all)
        TeamStrength(
          rating: r,
          blend: (r.contribMedian ?? r.opr) +
              dprAdj(r) +
              config.wRp * ((r.avgRp ?? meanRp) - meanRp) +
              config.wWin * ((r.winRate ?? 0.5) - 0.5),
          reliabilityBucket: _bucket(r, config, contribFloor),
        ),
    ]..sort((a, b) => b.blend.compareTo(a.blend));
    return out;
  }

  /// Consistency measured as the spread of a team's implied contribution
  /// relative to its own typical output.
  ///
  /// The old version divided the *alliance* score's std by the *alliance*
  /// score's mean, which mostly measured which partners a team happened to
  /// draw, and flattered high-OPR teams by handing them a bigger denominator.
  /// At 2026 NorCal DCMP that put 14 of 15 teams in the same bucket.
  static int? _bucket(
    TeamRating r,
    PredictionConfig config,
    double contribFloor,
  ) {
    final median = r.contribMedian;
    final std = r.contribStd;
    if (median == null ||
        std == null ||
        r.matchesPlayed < config.minMatchesForRealSigma) {
      return null; // not enough match data to judge consistency
    }
    final denom = math.max(median, contribFloor);
    if (denom <= 1e-9) return null;

    final spread = std / denom;
    if (spread < config.steadyMax) return 0;
    if (spread < config.variableMax) return 1;
    return 2;
  }
}
