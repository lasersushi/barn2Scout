import 'package:barn2scout/core/utils/stats_utils.dart';
import 'package:barn2scout/data/models/match_prediction.dart';
import 'package:barn2scout/data/models/tba_match.dart';
import 'package:barn2scout/data/models/team_rating.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds an unplayed qual match from bare team-number lists.
TbaMatch _match(List<int> red, List<int> blue) => TbaMatch(
      key: 'test_qm1',
      compLevel: 'qm',
      setNumber: 1,
      matchNumber: 1,
      redTeams: red.map((n) => 'frc$n').toList(),
      blueTeams: blue.map((n) => 'frc$n').toList(),
    );

TeamRating _rating(int team, double opr, {double dpr = 25, double std = 8}) =>
    TeamRating(
      team: team,
      opr: opr,
      dpr: dpr,
      ccwm: opr - dpr,
      avgRp: 2.0,
      winRate: 0.5,
      scoreMean: opr * 2,
      scoreStd: std,
      matchesPlayed: 5,
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
    final ratings = {
      254: _rating(254, 45),
      1678: _rating(1678, 40),
      118: _rating(118, 38),
      2056: _rating(2056, 15),
      9999: _rating(9999, 8),
      4414: _rating(4414, 20),
    };

    test('displayed score is the sum of OPRs', () {
      final p = MatchPrediction.compute(
        _match([254, 1678, 118], [2056, 9999, 4414]),
        ratings,
      );
      expect(p.redScore, closeTo(123, 1e-9)); // 45+40+38
      expect(p.blueScore, closeTo(43, 1e-9)); // 15+8+20
    });

    test('strong alliance is heavily favored', () {
      final p = MatchPrediction.compute(
        _match([254, 1678, 118], [2056, 9999, 4414]),
        ratings,
      );
      expect(p.redWinPct, greaterThan(0.9));
      expect(p.blueWinPct, closeTo(1 - p.redWinPct, 1e-9));
      expect(p.ratedTeams, 6);
      expect(p.hasData, isTrue);
    });

    test('win probabilities flip when alliances swap', () {
      final a = MatchPrediction.compute(
        _match([254, 1678, 118], [2056, 9999, 4414]),
        ratings,
      );
      final b = MatchPrediction.compute(
        _match([2056, 9999, 4414], [254, 1678, 118]),
        ratings,
      );
      expect(a.redWinPct, closeTo(b.blueWinPct, 1e-6));
    });

    test('an unrated team falls back to the event average, not zero', () {
      final p = MatchPrediction.compute(
        _match([254, 1678, 7777], [2056, 9999, 4414]), // 7777 has no rating
        ratings,
      );
      expect(p.ratedTeams, 5);
      // event-mean OPR over the 6 rated teams = (45+40+38+15+8+20)/6 = 27.67
      expect(p.redScore, closeTo(45 + 40 + 27.666666, 1e-3));
    });

    test('no ratings → no prediction', () {
      final p = MatchPrediction.compute(
        _match([254, 1678, 118], [2056, 9999, 4414]),
        const {},
      );
      expect(p.hasData, isFalse);
      expect(p.ratedTeams, 0);
    });
  });
}
