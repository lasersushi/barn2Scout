import '../../core/utils/stats_utils.dart';
import 'tba_match.dart';
import 'team_rating.dart';

/// Tunable weights for the picklist's blended strength and reliability buckets
/// ([TeamStrength.rank]). All in one place so they can be re-tuned over a
/// season without hunting through logic.
///
/// Match predictions don't read any of these any more; their knobs live in
/// [RatingConfig].
class PredictionConfig {
  const PredictionConfig({
    this.wDef = 0.3,
    this.wRp = 2.0,
    this.wWin = 4.0,
    this.minMatchesForRealSigma = 3,
    this.dprAdjClamp = 5.0,
    this.steadyMax = 0.90,
    this.variableMax = 1.20,
  });

  /// Points added per unit a team's DPR is better (lower) than the event mean.
  final double wDef;

  /// Points added per ranking-point above the event-mean avg RP.
  final double wRp;

  /// Points added for a perfect record vs the points removed for a winless one
  /// (scales `winRate - 0.5`).
  final double wWin;

  /// Matches a team must have played before its reliability bucket is judged.
  final int minMatchesForRealSigma;

  /// Hard cap, in points, on how far the DPR term may move a team's picklist
  /// blend in either direction.
  ///
  /// DPR is the noisiest stat in the OPR family and a disabled robot inflates
  /// it badly — a dead robot plays no defense, so opponents score freely and
  /// the linear system charges that to the robot that broke. Uncapped, that one
  /// term outweighed every real signal: at 2026 NorCal DCMP it moved 1678
  /// (DPR 142 against a 58–111 field) 14 points and dropped them below a team
  /// they beat on OPR, RP, and official rank alike.
  final double dprAdjClamp;

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

const PredictionConfig kPredictionConfig = PredictionConfig();

/// A predicted outcome for one match, built purely from TBA-derived
/// [EventRatings] — see [MatchPrediction.compute]. Pure value type, safe to
/// build inside `build()`.
class MatchPrediction {
  const MatchPrediction({
    required this.redScore,
    required this.blueScore,
    required this.redWinPct,
    required this.ratedTeams,
    this.totalTeams = 6,
    this.preComp = false,
  });

  /// Expected alliance scores: the sum of each member's expected points. The
  /// same numbers decide [redWinPct], so the bar and the scores always agree.
  final double redScore;
  final double blueScore;

  /// P(red wins), 0..1.
  final double redWinPct;
  double get blueWinPct => 1.0 - redWinPct;

  /// How many of the [totalTeams] the model knew something about (the rest
  /// were taken as event-average). Drives the "×/6" confidence note.
  final int ratedTeams;
  final int totalTeams;

  /// True when any rated team's data was borrowed from an earlier event —
  /// i.e. this event hasn't produced OPRs yet. See [TeamRating.isPreComp].
  final bool preComp;

  /// No prediction worth showing until the model knows at least one team.
  bool get hasData => ratedTeams > 0;

  /// Predicts [match] from the event's [ratings].
  ///
  /// Model ([RatingModel] does the fitting):
  ///   score(alliance) = Σ expected points of its robots
  ///   margin          = score(red) − score(blue)
  ///   P(red wins)     = Φ(margin / σ), σ = [RatingModel.sigmaFor]: the
  ///                     event's replayed margin miss (only an assumed one
  ///                     before any qual), widened for playoffs
  factory MatchPrediction.compute(TbaMatch match, EventRatings ratings) {
    final model = ratings.model;
    var preComp = false;

    ({double score, int rated}) sideOf(List<String> teamKeys) {
      var score = 0.0;
      var rated = 0;
      for (final key in teamKeys) {
        // By TBA key, so a B-team ("frc254B") keeps its own fitted value.
        final points = model.expectedPoints[key];
        // A team the model knows nothing about counts as event-average,
        // never zero.
        score += points ?? model.meanTeamPoints;
        if (points == null) continue;
        rated++;
        final team = int.tryParse(TbaMatch.displayNumber(key));
        if (team != null && (ratings.teams[team]?.isPreComp ?? false)) {
          preComp = true;
        }
      }
      return (score: score, rated: rated);
    }

    final red = sideOf(match.redTeams);
    final blue = sideOf(match.blueTeams);
    final margin = red.score - blue.score;
    final sigma = model.sigmaFor(match);

    final double redWin;
    if (sigma < 1e-9) {
      redWin = margin > 0 ? 1.0 : (margin < 0 ? 0.0 : 0.5);
    } else {
      redWin = normalCdf(margin / sigma);
    }

    return MatchPrediction(
      redScore: red.score,
      blueScore: blue.score,
      redWinPct: redWin.clamp(0.0, 1.0),
      ratedTeams: red.rated + blue.rated,
      preComp: preComp,
    );
  }
}
