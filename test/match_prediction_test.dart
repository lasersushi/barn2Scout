import 'package:barn2scout/core/utils/stats_utils.dart';
import 'package:barn2scout/data/models/match_prediction.dart';
import 'package:barn2scout/data/models/rating_model.dart';
import 'package:barn2scout/data/models/tba_match.dart';
import 'package:barn2scout/data/models/team_rating.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds an unplayed match from bare team-number lists.
TbaMatch _match(List<int> red, List<int> blue, {String compLevel = 'qm'}) =>
    TbaMatch(
      key: 'test_${compLevel}1',
      compLevel: compLevel,
      setNumber: 1,
      matchNumber: 1,
      redTeams: red.map((n) => 'frc$n').toList(),
      blueTeams: blue.map((n) => 'frc$n').toList(),
    );

TeamRating _rating(int team, double opr) =>
    TeamRating(team: team, opr: opr, dpr: 25, ccwm: opr - 25);

/// Ratings whose model knows [points] (team number → expected points), with
/// [sigma] as the qual margin miss.
EventRatings _ratings(
  Map<int, double> points, {
  double sigma = 40,
  Map<int, TeamRating> teams = const {},
}) =>
    EventRatings(
      teams: teams,
      model: RatingModel(
        expectedPoints: {
          for (final MapEntry(:key, :value) in points.entries) 'frc$key': value,
        },
        meanTeamPoints: points.isEmpty
            ? 0
            : points.values.reduce((a, b) => a + b) / points.length,
        marginSigma: sigma,
      ),
    );

void main() {
  group('normalCdf', () {
    test('is 0.5 at the mean', () {
      expect(normalCdf(0), closeTo(0.5, 1e-6));
    });

    test('matches known z-scores', () {
      expect(normalCdf(1.96), closeTo(0.975, 1e-3));
      expect(normalCdf(-1.96), closeTo(0.025, 1e-3));
    });

    test('is symmetric', () {
      expect(normalCdf(1.2) + normalCdf(-1.2), closeTo(1.0, 1e-6));
    });
  });

  group('MatchPrediction.compute', () {
    final ratings = _ratings({
      254: 45,
      1678: 40,
      118: 38,
      2056: 15,
      9999: 8,
      4414: 20,
    });
    final strongRed = _match([254, 1678, 118], [2056, 9999, 4414]);

    test('displayed scores are the sums of expected points', () {
      final p = MatchPrediction.compute(strongRed, ratings);
      expect(p.redScore, closeTo(123, 1e-9)); // 45+40+38
      expect(p.blueScore, closeTo(43, 1e-9)); // 15+8+20
    });

    test('win probability reads the same margin off the measured σ', () {
      final p = MatchPrediction.compute(strongRed, ratings);
      // margin 80 over σ 40: two σ in red's favour.
      expect(p.redWinPct, closeTo(normalCdf(2), 1e-9));
      expect(p.blueWinPct, closeTo(1 - p.redWinPct, 1e-9));
      expect(p.ratedTeams, 6);
      expect(p.hasData, isTrue);
    });

    test('win probabilities flip when alliances swap', () {
      final a = MatchPrediction.compute(strongRed, ratings);
      final b = MatchPrediction.compute(
        _match([2056, 9999, 4414], [254, 1678, 118]),
        ratings,
      );
      expect(a.redWinPct, closeTo(b.blueWinPct, 1e-9));
    });

    test('playoffs widen σ', () {
      final p = MatchPrediction.compute(
        _match([254, 1678, 118], [2056, 9999, 4414], compLevel: 'sf'),
        ratings,
      );
      expect(
          p.redWinPct,
          closeTo(
              normalCdf(80 / (40 * kRatingConfig.playoffSigmaScale)), 1e-9));
    });

    test('a team the model knows nothing about is average, not zero', () {
      final p = MatchPrediction.compute(
        _match([254, 1678, 7777], [2056, 9999, 4414]), // 7777 unknown
        ratings,
      );
      expect(p.ratedTeams, 5);
      // event average = (45+40+38+15+8+20)/6 = 27.67
      expect(p.redScore, closeTo(45 + 40 + 27.666666, 1e-3));
    });

    test('a B-team is rated from its own fit, not its parent team\'s', () {
      final p = MatchPrediction.compute(
        const TbaMatch(
          key: 'test_qm2',
          compLevel: 'qm',
          setNumber: 1,
          matchNumber: 2,
          redTeams: ['frc254', 'frc254B', 'frc118'],
          blueTeams: ['frc2056', 'frc9999', 'frc4414'],
        ),
        EventRatings(
          model: RatingModel(
            expectedPoints: {...ratings.model.expectedPoints, 'frc254B': 60},
            meanTeamPoints: 30,
            marginSigma: 40,
          ),
        ),
      );
      expect(p.ratedTeams, 6);
      expect(p.redScore, closeTo(45 + 60 + 38, 1e-9));
    });

    test('no ratings → no prediction, and a 50/50 if drawn anyway', () {
      final p = MatchPrediction.compute(strongRed, EventRatings.empty);
      expect(p.hasData, isFalse);
      expect(p.ratedTeams, 0);
      expect(p.redWinPct, 0.5);
    });
  });

  group('MatchPrediction.preComp', () {
    final match = _match([254, 1678, 118], [2056, 9999, 4414]);
    final points = {254: 45.0, 2056: 15.0, 751: 30.0};

    test('is false when every rating is from this event', () {
      final p = MatchPrediction.compute(
        match,
        _ratings(points, teams: {
          254: _rating(254, 45),
          2056: _rating(2056, 15),
        }),
      );
      expect(p.preComp, isFalse);
    });

    test('is true when any rated team is borrowed from an earlier event', () {
      final p = MatchPrediction.compute(
        match,
        _ratings(points, teams: {
          254: _rating(254, 45).withSource('2026casj'),
          2056: _rating(2056, 15),
        }),
      );
      expect(p.preComp, isTrue);
    });

    test('ignores borrowed ratings for teams not in the match', () {
      final p = MatchPrediction.compute(
        match,
        _ratings(points, teams: {
          254: _rating(254, 45),
          751: _rating(751, 30).withSource('2026casj'),
        }),
      );
      expect(p.preComp, isFalse);
    });

    test('ignores borrowed ratings for match teams the model did not rate', () {
      // 118 is in the match with a borrowed rating, but the model has no
      // number for it, so nothing borrowed went into this prediction.
      final p = MatchPrediction.compute(
        match,
        _ratings(points, teams: {
          254: _rating(254, 45),
          2056: _rating(2056, 15),
          118: _rating(118, 38).withSource('2026casj'),
        }),
      );
      expect(p.ratedTeams, 2);
      expect(p.preComp, isFalse);
    });
  });
}
