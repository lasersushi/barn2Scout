import 'dart:math' as math;

import 'team_rating.dart';

/// Cutoffs for the picklist's reliability buckets ([TeamStrength.rank]), in
/// one place so they can be re-tuned each season.
class ReliabilityConfig {
  const ReliabilityConfig({
    this.minMatchesForRealSigma = 3,
    this.steadyMax = 0.90,
    this.variableMax = 1.20,
  });

  /// Matches a team must have played before its reliability bucket is judged.
  final int minMatchesForRealSigma;

  /// Reliability-bucket cutoffs on a team's stabilised swing relative to the
  /// field's — see `TeamStrength._stability`. 1.0 is exactly average.
  ///
  /// Below [steadyMax] is "steady", below [variableMax] is "variable", above is
  /// "streaky".
  ///
  /// Calibrated to the terciles of 2026 NorCal DCMP (`2026cancmp`, 60 teams,
  /// 136 played matches), which fell at 0.90 and 1.18 and split the field
  /// 20/21/19. Re-check each January with
  /// `lib/prototype/rating_calibration.dart`.
  final double steadyMax;
  final double variableMax;
}

const ReliabilityConfig kReliabilityConfig = ReliabilityConfig();

/// A team ranked for the picklist, entirely from TBA data — no human scouting.
/// Wraps a [TeamRating] with the rating model's expected points, which rank
/// it, and a consistency bucket built on its *implied contribution*.
class TeamStrength {
  const TeamStrength({
    required this.rating,
    required this.expectedPoints,
    required this.reliabilityBucket,
  });

  final TeamRating rating;

  /// The points this team is expected to add to an alliance: the same
  /// [RatingModel] number match predictions sum. Higher is better.
  final double expectedPoints;

  /// Consistency from the spread of implied contribution: 0 = steady,
  /// 1 = variable, 2 = streaky, null = not enough matches played to judge.
  final int? reliabilityBucket;

  int get team => rating.team;

  /// Every team in [ratings] ranked by its expected points (desc).
  ///
  /// That's the same number match predictions use, so the picklist and the
  /// prediction bars never disagree about who's stronger. Replaying 65 2026
  /// events, it predicted both the last third of quals and the playoffs
  /// better (Brier −0.005 to −0.008, 2–3 standard errors) than plain OPR or
  /// the blend it replaced: a median implied contribution plus nudges for
  /// DPR, ranking points and win rate. RP and win rate are outcomes of
  /// strength plus schedule luck, so they counted strength twice, and DPR
  /// was mostly noise.
  ///
  /// The blend's median was there for 1678 at 2026 NorCal DCMP, 11th on OPR
  /// after a weekend of dead matches. Its prior (its earlier events) holds it
  /// up instead: 4th by expected points, 6th officially.
  static List<TeamStrength> rank(
    EventRatings ratings, {
    ReliabilityConfig config = kReliabilityConfig,
  }) {
    final all = ratings.teams.values.toList();
    if (all.isEmpty) return const [];

    // Reliability denominator: the typical *stabilised* swing at this event.
    // See [_stability] and [_bucket].
    final stabilities = all.map(_stability).whereType<double>().toList();
    final medianStability = stabilities.isEmpty ? 0.0 : _median(stabilities);

    final out = [
      for (final r in all)
        TeamStrength(
          rating: r,
          expectedPoints: ratings.model.pointsOf('frc${r.team}'),
          reliabilityBucket: _bucket(r, config, medianStability),
        ),
    ]..sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
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
  /// [ReliabilityConfig.steadyMax] / [ReliabilityConfig.variableMax] hold the
  /// cutoffs.
  static int? _bucket(
    TeamRating r,
    ReliabilityConfig config,
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
