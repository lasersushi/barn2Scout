import 'dart:math' as math;

import 'package:barn2scout/core/utils/linear_algebra.dart';
import 'package:barn2scout/core/utils/stats_utils.dart';
import 'package:barn2scout/data/models/match_prediction.dart';
import 'package:barn2scout/data/models/tba_match.dart';
import 'package:barn2scout/data/models/team_rating.dart';

import 'backtest_fixtures.dart';

/// Rebuilds the [TeamRating]s the app's old (pre-Phase 2) prediction model
/// would have been handed, given that TBA had posted exactly the [known] quals.
///
/// Live, the app reads OPR/DPR from TBA's `/oprs` and avg RP / W-L-T from
/// `/rankings`, which only ever describe the event "so far" — TBA can't be
/// asked what they said at match 37. So this re-derives them the way TBA does,
/// and the backtest checks the end-of-quals result against TBA's own numbers:
///
/// * OPR/DPR: `numpy.linalg.pinv(M) · s` over played quals (TBA's
///   matchstats_helper), solved exactly by [_minNormSolve].
/// * The team list is every team on the qual schedule, played or not. A team
///   that hasn't played yet comes back at OPR 0 — and the app counts it as
///   rated, so it is in the map here too, not left out.
/// * Avg RP and W-L-T follow FIRST's ranking rules: a surrogate appearance
///   doesn't count; a disqualified team gets 0 RP and no W-L-T result.
///   A team that hasn't played has no ranking row yet.
/// * Score mean/std/matches played use every played appearance, as
///   `ScheduleRepository.fetchTeamRatings` builds them from the match list.
///   So does the median implied contribution: each appearance's alliance
///   score minus its partners' OPRs (the mean OPR for an unrated partner).
///
/// [legacyPredict] turns these into the old app's predictions.
Map<int, TeamRating> legacyRatingsAsOf(
  BacktestEvent event,
  List<TbaMatch> known,
) {
  int? number(String key) => int.tryParse(TbaMatch.displayNumber(key));

  final teams = event.scheduledQualTeams.toList()..sort();
  final index = {for (var i = 0; i < teams.length; i++) teams[i]: i};
  final n = teams.length;

  // Normal equations M·x = s: one row of the design matrix A per alliance
  // appearance, with a 1 for each robot on it. So M = AᵀA counts how often
  // each pair were partners (the diagonal: each team's matches).
  final normal = List.generate(n, (_) => List<double>.filled(n, 0));
  final ownScores = List<double>.filled(n, 0); // Aᵀ · own alliance score
  final oppScores = List<double>.filled(n, 0); // Aᵀ · opposing score → DPR
  final scores = List.generate(n, (_) => <double>[]);
  final rankedMatches = List<int>.filled(n, 0);
  final rpTotal = List<int>.filled(n, 0);
  final wins = List<int>.filled(n, 0);
  final losses = List<int>.filled(n, 0);
  final ties = List<int>.filled(n, 0);

  for (final m in known) {
    final extras = event.extras[m.key];
    for (final red in const [true, false]) {
      final keys = red ? m.redTeams : m.blueTeams;
      final own = (red ? m.redScore : m.blueScore)!;
      final opp = (red ? m.blueScore : m.redScore)!;
      final members =
          keys.map((key) => index[number(key)]).whereType<int>().toList();
      for (final i in members) {
        for (final j in members) {
          normal[i][j] += 1;
        }
        ownScores[i] += own;
        oppScores[i] += opp;
        scores[i].add(own.toDouble());
      }

      for (final key in keys) {
        final i = index[number(key)];
        if (i == null || (extras?.surrogates.contains(key) ?? false)) continue;
        rankedMatches[i]++;
        if (extras?.disqualified.contains(key) ?? false) continue;
        rpTotal[i] += (red ? extras?.redRp : extras?.blueRp) ?? 0;
        if (own > opp) {
          wins[i]++;
        } else if (own < opp) {
          losses[i]++;
        } else {
          ties[i]++;
        }
      }
    }
  }

  final [opr, dpr] = _minNormSolve(normal, [ownScores, oppScores]);

  final meanOpr = n == 0 ? 0.0 : opr.reduce((a, b) => a + b) / n;
  double oprOf(String key) {
    final i = index[number(key)];
    return i == null ? meanOpr : opr[i];
  }

  final contribs = List.generate(n, (_) => <double>[]);
  for (final m in known) {
    for (final (keys, score) in [
      (m.redTeams, m.redScore!),
      (m.blueTeams, m.blueScore!),
    ]) {
      for (final key in keys) {
        final i = index[number(key)];
        if (i == null) continue;
        var partners = 0.0;
        for (final other in keys) {
          if (other != key) partners += oprOf(other);
        }
        contribs[i].add(score - partners);
      }
    }
  }

  return {
    for (var i = 0; i < n; i++)
      teams[i]: scores[i].isEmpty
          ? TeamRating(
              team: teams[i],
              opr: opr[i],
              dpr: dpr[i],
              ccwm: opr[i] - dpr[i],
            )
          : TeamRating(
              team: teams[i],
              opr: opr[i],
              dpr: dpr[i],
              ccwm: opr[i] - dpr[i],
              avgRp:
                  rankedMatches[i] == 0 ? null : rpTotal[i] / rankedMatches[i],
              winRate: wins[i] + losses[i] + ties[i] == 0
                  ? null
                  : wins[i] / (wins[i] + losses[i] + ties[i]),
              wins: wins[i],
              losses: losses[i],
              ties: ties[i],
              scoreMean: scores[i].reduce((a, b) => a + b) / scores[i].length,
              scoreStd: _sampleStd(scores[i]),
              matchesPlayed: scores[i].length,
              contribMedian: _median(contribs[i]),
            ),
  };
}

/// The picklist's ranking value before Phase 4, frozen here so the picklist
/// backtest can keep scoring it as the baseline: the median implied
/// contribution (OPR without one), plus nudges for DPR (capped at ±5
/// points), ranking points and win rate.
Map<int, double> legacyBlend(Map<int, TeamRating> ratings) {
  const wDef = 0.3, wRp = 2.0, wWin = 4.0, dprAdjClamp = 5.0;
  final all = ratings.values.toList();
  double meanOf(Iterable<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
  final meanDpr = meanOf(all.map((r) => r.dpr));
  final meanRp = meanOf(all.map((r) => r.avgRp).whereType<double>());
  return {
    for (final r in all)
      r.team: (r.contribMedian ?? r.opr) +
          (wDef * (meanDpr - r.dpr)).clamp(-dprAdjClamp, dprAdjClamp) +
          wRp * ((r.avgRp ?? meanRp) - meanRp) +
          wWin * ((r.winRate ?? 0.5) - 0.5),
  };
}

/// Median of [xs], null when empty.
double? _median(List<double> xs) {
  if (xs.isEmpty) return null;
  final sorted = [...xs]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// The app's match prediction before the rating model replaced it, frozen
/// here so the backtest can keep scoring it as the baseline.
///
///   score(alliance) = Σ OPR
///   margin          = (ΣOPR + Σadj)_red − (ΣOPR + Σadj)_blue, where adj
///                     nudges for DPR, ranking points and win rate
///   σ per alliance  = mean of member σs: a team's own score std once it has
///                     3+ matches, else the mean of those teams' stds (25
///                     until any team has 3)
///   P(red wins)     = 1 − Φ(−margin / √(σ_red² + σ_blue²))
MatchPrediction legacyPredict(TbaMatch match, Map<int, TeamRating> ratings) {
  const wDef = 0.3, wRp = 2.0, wWin = 4.0;
  const fallbackSigma = 25.0, minMatchesForRealSigma = 3;
  final all = ratings.values.toList();

  double meanOf(Iterable<double> xs, double fallback) =>
      xs.isEmpty ? fallback : xs.reduce((a, b) => a + b) / xs.length;

  final meanOpr = meanOf(all.map((r) => r.opr), 0);
  final meanDpr = meanOf(all.map((r) => r.dpr), 0);
  final meanRp = meanOf(all.map((r) => r.avgRp).whereType<double>(), 0);
  final realStds = all
      .where((r) =>
          r.scoreStd != null && r.matchesPlayed >= minMatchesForRealSigma)
      .map((r) => r.scoreStd!);
  final typicalSigma = meanOf(realStds, fallbackSigma);

  ({double expected, double adj, double sigma, int rated}) sideOf(
      List<String> teamKeys) {
    var expected = 0.0, adj = 0.0, sigmaSum = 0.0;
    var rated = 0;
    for (final key in teamKeys) {
      final r = ratings[int.tryParse(TbaMatch.displayNumber(key))];
      expected += r?.opr ?? meanOpr;
      adj += wDef * (meanDpr - (r?.dpr ?? meanDpr)) +
          wRp * ((r?.avgRp ?? meanRp) - meanRp) +
          wWin * ((r?.winRate ?? 0.5) - 0.5);
      sigmaSum += (r != null &&
              r.scoreStd != null &&
              r.matchesPlayed >= minMatchesForRealSigma)
          ? r.scoreStd!
          : typicalSigma;
      if (r != null) rated++;
    }
    final sigma = teamKeys.isEmpty ? typicalSigma : sigmaSum / teamKeys.length;
    return (expected: expected, adj: adj, sigma: sigma, rated: rated);
  }

  final red = sideOf(match.redTeams);
  final blue = sideOf(match.blueTeams);
  final margin = (red.expected + red.adj) - (blue.expected + blue.adj);
  final sigma = math.sqrt(red.sigma * red.sigma + blue.sigma * blue.sigma);
  final redWin = sigma < 1e-9
      ? (margin > 0 ? 1.0 : (margin < 0 ? 0.0 : 0.5))
      : 1.0 - normalCdf(-margin / sigma);

  return MatchPrediction(
    redScore: red.expected,
    blueScore: blue.expected,
    redWinPct: redWin.clamp(0.0, 1.0),
    ratedTeams: red.rated + blue.rated,
  );
}

/// TBA's OPR solve, `pinv(M) · s`: the minimum-norm least-squares answer,
/// for each right-hand side in [rhs].
///
/// A one-shot ridge (adding a small λ to M's diagonal) isn't enough. Mid-event,
/// when the alliance results played roughly equal the number of teams, M has
/// eigenvalues down near 1e-4. pinv inverts those fully — which is why the
/// live app showed OPRs in the thousands in that window — while a ridge that
/// size quietly halves them.
///
/// So this iterates instead (iterated Tikhonov): factor M + λI once, then keep
/// solving for the correction the remaining residual implies. On an eigenvalue
/// μ each pass multiplies the error by λ / (μ + λ) — a few passes for anything
/// well above λ — while directions with μ = 0 (team combinations the matches
/// can't tell apart, or teams that haven't played) stay at exactly 0. That is
/// what makes the result the minimum-norm one.
List<List<double>> _minNormSolve(
  List<List<double>> m,
  List<List<double>> rhs,
) {
  const lambda = 1e-6;
  final n = m.length;
  final solver = Cholesky([
    for (var i = 0; i < n; i++)
      [for (var j = 0; j < n; j++) m[i][j] + (i == j ? lambda : 0)],
  ]);

  List<double> refine(List<double> s) {
    final tolerance = 1e-12 * s.fold<double>(1, (a, v) => math.max(a, v.abs()));
    var x = List<double>.filled(n, 0);
    for (var pass = 0; pass < 10000; pass++) {
      final residual = List<double>.generate(n, (i) {
        var mx = 0.0;
        for (var j = 0; j < n; j++) {
          mx += m[i][j] * x[j];
        }
        return s[i] - mx;
      });
      if (residual.every((r) => r.abs() <= tolerance)) return x;
      final step = solver.solve(residual);
      x = [for (var i = 0; i < n; i++) x[i] + step[i]];
    }
    throw StateError('minimum-norm OPR solve did not converge');
  }

  return [for (final s in rhs) refine(s)];
}

/// Bessel-corrected std, null below 2 samples — matches
/// `ScheduleRepository._meanStd`.
double? _sampleStd(List<double> xs) {
  if (xs.length < 2) return null;
  final mean = xs.reduce((a, b) => a + b) / xs.length;
  final variance =
      xs.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
          (xs.length - 1);
  return math.sqrt(variance);
}
