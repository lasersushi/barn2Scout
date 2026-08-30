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

    // Reliability denominator: the typical *stabilised* swing at this event.
    // See [_stability] and [_bucket].
    final stabilities = all.map(_stability).whereType<double>().toList();
    final medianStability = stabilities.isEmpty ? 0.0 : _median(stabilities);

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
          reliabilityBucket: _bucket(r, config, medianStability),
        ),
    ]..sort((a, b) => b.blend.compareTo(a.blend));
    return out;
  }

  /// Median of a non-empty [xs].
  static double _median(List<double> xs) {
    final sorted = [...xs]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /// A team's match-to-match swing, rescaled so it can be compared across
  /// robots of wildly different output.
  ///
  /// Contribution std grows with how much a robot scores — measured at 2026
  /// NorCal DCMP, teams above 200 median contribution averaged 99 points of
  /// std against 66 for teams below 60. Dividing by `sqrt(median)` is the
  /// standard variance-stabilising correction for that: without it, comparing
  /// raw stds marks every big scorer streaky purely for being a big scorer.
  ///
  /// Null when the team has no contribution data, or a non-positive median
  /// (nothing meaningful to be consistent *about*).
  static double? _stability(TeamRating r) {
    final median = r.contribMedian;
    final std = r.contribStd;
    if (median == null || std == null || median <= 1e-9) return null;
    return std / math.sqrt(median);
  }

  /// Consistency: how a team's stabilised swing compares to a typical robot's
  /// at the same event. 1.0 is exactly average.
  ///
  /// Three earlier versions all ended up re-measuring team strength instead of
  /// consistency, which is the failure mode to watch for here:
  ///
  /// * `allianceStd / allianceMean` mostly measured which partners a team drew,
  ///   and gave high-OPR teams a bigger denominator so they looked steadier —
  ///   14 of 15 teams landed in one bucket.
  /// * `contribStd / contribMedian` inverted that bias, collapsing to roughly
  ///   `1 / strength` and marking every weak team streaky.
  /// * `contribStd / eventMedianStd` inverted it again, marking every *strong*
  ///   team streaky — 254 was flagged despite a 100% win rate.
  ///
  /// [PredictionConfig.steadyMax] / [PredictionConfig.variableMax] hold the
  /// cutoffs.
  static int? _bucket(
    TeamRating r,
    PredictionConfig config,
    double medianStability,
  ) {
    final stability = _stability(r);
    if (stability == null ||
        medianStability <= 1e-9 ||
        r.matchesPlayed < config.minMatchesForRealSigma) {
      return null; // not enough match data to judge consistency
    }

    final spread = stability / medianStability;
    if (spread < config.steadyMax) return 0;
    if (spread < config.variableMax) return 1;
    return 2;
  }
}
