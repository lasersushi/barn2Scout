// ═══════════════════════════════════════════════════════════════════════════
// PORTABLE LOGIC MODULE — this is the keeper. The TUI shell around it
// (predictor_tui.dart) is throwaway; these pure functions graduate into the
// real lib/core/utils/stats_utils.dart + lib/data/models/match_prediction.dart.
//
// QUESTION this prototype answers:
//   Does the Lovat-style normal-distribution model give believable win
//   probabilities and scores from scouting stats — and how should we treat
//   the teams in a match that haven't been scouted yet? (The rejected plan
//   said "contribute 0", which looks wrong; this lets us feel out the
//   alternative: substitute a league-average prior.)
//
// Pure: no dart:io, no printing, no terminal codes. dart:math only.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

// ── Stats primitives (→ lib/core/utils/stats_utils.dart) ────────────────────

const double _sqrt2 = 1.4142135623730951;

/// Standard-normal CDF. Φ(x) = P(Z ≤ x) for Z ~ N(0,1).
double normalCdf(double x) => 0.5 * (1.0 + erf(x / _sqrt2));

/// Error function — Abramowitz & Stegun 7.1.26 (max abs error ≈ 1.5e-7).
/// This is the well-tested 5-coefficient form; use THIS in stats_utils, not
/// the 6-coefficient variant the draft plan listed.
double erf(double x) {
  final sign = x < 0 ? -1.0 : 1.0;
  final ax = x.abs();
  const p = 0.3275911;
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  final t = 1.0 / (1.0 + p * ax);
  final y = 1.0 -
      (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-ax * ax);
  return sign * y;
}

// ── Domain types (→ lib/data/models/match_prediction.dart) ──────────────────

/// One team's composite scoring summary. [mean] == null means "never scouted".
class TeamStat {
  const TeamStat(this.team, this.mean, this.std);
  final int team;
  final double? mean;
  final double? std;
  bool get scouted => mean != null;
}

/// What to do with a team that has no scouting data.
enum MissingPolicy {
  /// Contribute nothing (mean 0, std 0). The draft plan's approach.
  zero,

  /// Substitute the average scouted team (a weak Bayesian prior).
  leagueAverage,
}

class AllianceP {
  const AllianceP(this.expected, this.actual, this.teams);
  final double expected; // expected alliance score
  final double actual; // std of alliance score
  final List<TeamStat> teams;
}

class MatchP {
  const MatchP({
    required this.red,
    required this.blue,
    required this.diffMu,
    required this.diffSigma,
    required this.redWinPct,
    required this.scoutedCount,
  });

  final AllianceP red;
  final AllianceP blue;
  final double diffMu; // red.mu - blue.mu
  final double diffSigma;
  final double redWinPct; // 0..1
  final int scoutedCount; // of 6

  double get blueWinPct => 1.0 - redWinPct;
}

/// THE function under test. Combines three independent normal scorers per
/// alliance, subtracts the two alliance distributions, and reads the win
/// probability off the point-differential distribution at zero.
MatchP predictMatch(
  List<TeamStat> redTeams,
  List<TeamStat> blueTeams, {
  required MissingPolicy policy,
  required double leagueMean,
  required double leagueStd,
}) {
  AllianceP sideOf(List<TeamStat> ts) {
    var mu = 0.0;
    var varSum = 0.0;
    for (final t in ts) {
      final double m;
      final double s;
      if (t.scouted) {
        m = t.mean!;
        s = t.std ?? 0.0;
      } else {
        m = policy == MissingPolicy.leagueAverage ? leagueMean : 0.0;
        s = policy == MissingPolicy.leagueAverage ? leagueStd : 0.0;
      }
      mu += m;
      varSum += s * s; // variances of independent normals add
    }
    return AllianceP(mu, math.sqrt(varSum), ts);
  }

  final red = sideOf(redTeams);
  final blue = sideOf(blueTeams);

  final diffMu = red.expected - blue.expected;
  final diffSigma = math.sqrt(red.actual * red.actual + blue.actual * blue.actual);

  // P(red wins) = P(diff > 0) = 1 - Φ(0; diffMu, diffSigma)
  //             = 1 - Φ(-diffMu / diffSigma)
  final double redWinPct;
  if (diffSigma < 1e-9) {
    // No variance anywhere → deterministic. Avoids divide-by-zero NaN.
    redWinPct = diffMu > 0 ? 1.0 : (diffMu < 0 ? 0.0 : 0.5);
  } else {
    redWinPct = 1.0 - normalCdf(-diffMu / diffSigma);
  }

  final scouted =
      [...redTeams, ...blueTeams].where((t) => t.scouted).length;

  return MatchP(
    red: red,
    blue: blue,
    diffMu: diffMu,
    diffSigma: diffSigma,
    redWinPct: redWinPct,
    scoutedCount: scouted,
  );
}

/// z-score of zero on the differential distribution — exposed so the TUI can
/// show *why* a probability came out the way it did.
double zeroZScore(MatchP p) =>
    p.diffSigma < 1e-9 ? double.nan : -p.diffMu / p.diffSigma;
