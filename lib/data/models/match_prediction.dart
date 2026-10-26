import '../../core/utils/stats_utils.dart';
import 'tba_match.dart';
import 'team_rating.dart';

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
