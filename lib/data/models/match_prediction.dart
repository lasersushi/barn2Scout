import 'dart:math' as math;

import '../../core/utils/stats_utils.dart';
import 'tba_match.dart';
import 'team_rating.dart';

/// Tunable weights for the blended prediction model. All in one place so the
/// model can be re-tuned over a season without hunting through logic.
///
/// OPR does the heavy lifting (it sets the predicted scores directly); the
/// other terms are small nudges in points.
class PredictionConfig {
  const PredictionConfig({
    this.wDef = 0.3,
    this.wRp = 2.0,
    this.wWin = 4.0,
    this.fallbackSigma = 25.0,
    this.minMatchesForRealSigma = 3,
  });

  /// Points added per unit a team's DPR is better (lower) than the event mean.
  final double wDef;

  /// Points added per ranking-point above the event-mean avg RP.
  final double wRp;

  /// Points added for a perfect record vs the points removed for a winless one
  /// (scales `winRate - 0.5`).
  final double wWin;

  /// Spread to assume for a team without enough played matches to measure one.
  final double fallbackSigma;

  /// Matches a team must have played before we trust its measured spread.
  final int minMatchesForRealSigma;
}

const PredictionConfig kPredictionConfig = PredictionConfig();

/// A predicted outcome for one match. Built purely from TBA-derived
/// [TeamRating]s — see [MatchPrediction.compute]. Pure value type, safe to
/// build inside `build()`.
class MatchPrediction {
  const MatchPrediction({
    required this.redScore,
    required this.blueScore,
    required this.redWinPct,
    required this.ratedTeams,
    this.totalTeams = 6,
  });

  /// Expected alliance scores = sum of member OPRs.
  final double redScore;
  final double blueScore;

  /// P(red wins), 0..1.
  final double redWinPct;
  double get blueWinPct => 1.0 - redWinPct;

  /// How many of the [totalTeams] had real TBA data (the rest used event
  /// averages). Drives the "×/6" confidence note.
  final int ratedTeams;
  final int totalTeams;

  /// No prediction worth showing until the event has produced some ratings.
  bool get hasData => ratedTeams > 0;

  /// Compute a prediction for [match] from the event's [ratings] map
  /// (team number → [TeamRating]).
  ///
  /// Model:
  ///   score(alliance)  = Σ OPR
  ///   margin mean      = (ΣOPR + Σadj)_red - (ΣOPR + Σadj)_blue
  ///                      where adj blends defense (DPR), ranking (RP), record
  ///   margin spread    = √(σ_red² + σ_blue²), σ per alliance = mean team σ
  ///   P(red wins)      = 1 - Φ(-margin / spread)
  factory MatchPrediction.compute(
    TbaMatch match,
    Map<int, TeamRating> ratings, {
    PredictionConfig config = kPredictionConfig,
  }) {
    final all = ratings.values.toList();

    double meanOf(Iterable<double> xs, double fallback) =>
        xs.isEmpty ? fallback : xs.reduce((a, b) => a + b) / xs.length;

    // Event-wide averages — used as the fallback for any team TBA hasn't
    // rated yet, so a missing team is treated as "average", never zero.
    final meanOpr = meanOf(all.map((r) => r.opr), 0);
    final meanDpr = meanOf(all.map((r) => r.dpr), 0);
    final meanRp = meanOf(all.map((r) => r.avgRp).whereType<double>(), 0);

    // Data-driven typical spread: the average measured team spread. Falls back
    // to the config constant only before any team has enough matches.
    final realStds = all
        .where((r) =>
            r.scoreStd != null &&
            r.matchesPlayed >= config.minMatchesForRealSigma)
        .map((r) => r.scoreStd!);
    final typicalSigma =
        realStds.isEmpty ? config.fallbackSigma : meanOf(realStds, config.fallbackSigma);

    ({double expected, double adj, double sigma, int rated}) sideOf(
        List<String> teamKeys) {
      var expected = 0.0;
      var adj = 0.0;
      var sigmaSum = 0.0;
      var rated = 0;
      var n = 0;

      for (final key in teamKeys) {
        n++;
        final num = int.tryParse(TbaMatch.displayNumber(key));
        final r = num == null ? null : ratings[num];

        final opr = r?.opr ?? meanOpr;
        final dpr = r?.dpr ?? meanDpr;
        final rp = r?.avgRp ?? meanRp;
        final win = r?.winRate ?? 0.5;
        final sigma = (r != null &&
                r.scoreStd != null &&
                r.matchesPlayed >= config.minMatchesForRealSigma)
            ? r.scoreStd!
            : typicalSigma;

        expected += opr;
        adj += config.wDef * (meanDpr - dpr) +
            config.wRp * (rp - meanRp) +
            config.wWin * (win - 0.5);
        sigmaSum += sigma;
        if (r != null) rated++;
      }

      // Mean (not sum) of the member spreads: each team's measured σ is already
      // an alliance-level score spread, so summing would over-count ~3×.
      final sigma = n == 0 ? typicalSigma : sigmaSum / n;
      return (expected: expected, adj: adj, sigma: sigma, rated: rated);
    }

    final red = sideOf(match.redTeams);
    final blue = sideOf(match.blueTeams);

    final marginMean = (red.expected + red.adj) - (blue.expected + blue.adj);
    final sigmaMargin =
        math.sqrt(red.sigma * red.sigma + blue.sigma * blue.sigma);

    final double redWin;
    if (sigmaMargin < 1e-9) {
      redWin = marginMean > 0 ? 1.0 : (marginMean < 0 ? 0.0 : 0.5);
    } else {
      redWin = 1.0 - normalCdf(-marginMean / sigmaMargin);
    }

    return MatchPrediction(
      redScore: red.expected,
      blueScore: blue.expected,
      redWinPct: redWin.clamp(0.0, 1.0),
      ratedTeams: red.rated + blue.rated,
    );
  }
}
