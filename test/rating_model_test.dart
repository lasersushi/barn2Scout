import 'dart:math' as math;

import 'package:barn2scout/data/models/rating_model.dart';
import 'package:barn2scout/data/models/tba_match.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/backtest_fixtures.dart';

/// A qual between two alliances of team keys, played at [minute] past 9am
/// unless [redScore] is null.
TbaMatch _qual(
  int number,
  List<String> red,
  List<String> blue, {
  int? redScore,
  int? blueScore,
  int? minute,
  String compLevel = 'qm',
}) =>
    TbaMatch(
      key: 't_$compLevel$number',
      compLevel: compLevel,
      setNumber: 1,
      matchNumber: number,
      redTeams: red,
      blueTeams: blue,
      redScore: redScore,
      blueScore: blueScore,
      actualTime:
          redScore == null ? null : DateTime(2026, 3, 6, 9, minute ?? number),
    );

void main() {
  group('RatingModel.fit expected points', () {
    test('one match pulls each robot toward the event average', () {
      // Level = (30 + 60) / 6 robots = 15. Each red robot's row reads
      // 3x + λx = 30 + λ·15, so with λ = 1: x = 45 / 4.
      final model = RatingModel.fit([
        _qual(1, ['frc1', 'frc2', 'frc3'], ['frc4', 'frc5', 'frc6'],
            redScore: 30, blueScore: 60),
      ]);

      expect(model.meanTeamPoints, 15);
      for (final team in [1, 2, 3]) {
        expect(model.expectedPoints[team], closeTo(11.25, 1e-9));
      }
      for (final team in [4, 5, 6]) {
        expect(model.expectedPoints[team], closeTo(18.75, 1e-9));
      }
    });

    test('with a tiny λ it is exactly OPR: TBA\'s end-of-quals numbers', () {
      // Proves the normal equations are built right: once every team has
      // played, AᵀA is invertible and the λ → 0 limit is plain OPR.
      for (final e in BacktestEvent.loadAll()) {
        final model = RatingModel.fit(
          e.playedQuals,
          config: const RatingConfig(priorWeight: 1e-6),
        );
        expect(model.expectedPoints.keys.toSet(), e.tbaOprs.keys.toSet(),
            reason: e.key);
        for (final MapEntry(key: team, value: opr) in e.tbaOprs.entries) {
          expect(model.expectedPoints[team], closeTo(opr, 0.01),
              reason: '${e.key} team $team');
        }
      }
    });

    test('nothing played: the fit is just the priors', () {
      final model = RatingModel.fit(const [], priors: {1: 50, 2: 30});

      expect(model.expectedPoints, {1: 50, 2: 30});
      expect(model.meanTeamPoints, 40);
      expect(model.pointsOf(3), 40);
      // No misses yet, so σ is all assumption: half a 3 × 40 alliance score.
      expect(model.marginSigma, closeTo(60, 1e-9));
    });

    test('a prior holds a team up until its matches outweigh it', () {
      final match = _qual(1, ['frc1', 'frc2', 'frc3'], ['frc4', 'frc5', 'frc6'],
          redScore: 30, blueScore: 60);
      final without = RatingModel.fit([match]);
      final withPrior = RatingModel.fit([match], priors: {1: 100});

      expect(withPrior.expectedPoints[1],
          greaterThan(without.expectedPoints[1]! + 10));
    });

    test('no matches and no priors: knows nothing, predicts nothing', () {
      final model = RatingModel.fit(const []);
      expect(model.expectedPoints, isEmpty);
      expect(model.meanTeamPoints, 0);
      expect(model.marginSigma, 0);
    });

    test('ignores playoffs and unplayed quals', () {
      final played = _qual(
          1, ['frc1', 'frc2', 'frc3'], ['frc4', 'frc5', 'frc6'],
          redScore: 30, blueScore: 60);
      final model = RatingModel.fit([
        played,
        _qual(2, ['frc7', 'frc2', 'frc3'], ['frc4', 'frc5', 'frc6']),
        _qual(1, ['frc1', 'frc2', 'frc3'], ['frc4', 'frc5', 'frc6'],
            redScore: 300, blueScore: 0, compLevel: 'sf'),
      ]);
      final alone = RatingModel.fit([played]);

      expect(model.expectedPoints, alone.expectedPoints);
      expect(model.marginSigma, alone.marginSigma);
      // Team 7 is only on an unplayed qual: no number, so it's average.
      expect(model.expectedPoints.containsKey(7), isFalse);
      expect(model.pointsOf(7), model.meanTeamPoints);
    });

    test('a B-team takes its share instead of handing it to its partners', () {
      final model = RatingModel.fit([
        _qual(1, ['frc1', 'frc2', 'frc254B'], ['frc4', 'frc5', 'frc6'],
            redScore: 30, blueScore: 60),
      ]);

      // Same as the all-numbered match above; 254B just can't be looked up.
      expect(model.expectedPoints[1], closeTo(11.25, 1e-9));
      expect(model.expectedPoints.length, 5);
    });
  });

  group('RatingModel.fit marginSigma', () {
    test('is the RMS of honest pre-match misses, blended with the assumed miss',
        () {
      // Rebuild σ the slow way, one independent fit per match, on the input
      // shuffled: the model must still replay in the order matches were
      // played and predict each from only the quals before it.
      final quals = BacktestEvent.loadAll().first.playedQuals.take(30).toList();
      final shuffled = [...quals]..shuffle(math.Random(751));
      const config = kRatingConfig;

      var squaredMisses = 0.0;
      var scoreTotal = 0.0;
      for (var k = 0; k < quals.length; k++) {
        final before = RatingModel.fit(quals.take(k));
        final m = quals[k];
        double sum(List<String> teams) => teams.fold(
            0,
            (t, key) =>
                t + before.pointsOf(int.parse(TbaMatch.displayNumber(key))));
        final miss =
            (m.redScore! - m.blueScore!) - (sum(m.redTeams) - sum(m.blueTeams));
        squaredMisses += miss * miss;
        scoreTotal += m.redScore! + m.blueScore!;
      }
      final assumed =
          config.sigmaPerMeanScore * scoreTotal / (2 * quals.length);
      final expected = math.sqrt(
          (squaredMisses + config.sigmaPriorWeight * assumed * assumed) /
              (quals.length + config.sigmaPriorWeight));

      expect(RatingModel.fit(shuffled).marginSigma, closeTo(expected, 1e-6));
    });

    test('lands at a sane share of a real event\'s scores', () {
      for (final e in BacktestEvent.loadAll()) {
        final quals = e.playedQuals;
        final model = RatingModel.fit(quals);
        final meanScore = quals
                .map((m) => m.redScore! + m.blueScore!)
                .reduce((a, b) => a + b) /
            (2 * quals.length);
        expect(model.marginSigma / meanScore, inInclusiveRange(0.2, 0.9),
            reason: e.key);
      }
    });

    test('is widened for playoff matches', () {
      final model = RatingModel.fit(const [], priors: {1: 50, 2: 30});
      final qual = _qual(9, ['frc1'], ['frc2']);
      final playoff = _qual(9, ['frc1'], ['frc2'], compLevel: 'sf');

      expect(model.sigmaFor(qual), model.marginSigma);
      expect(model.sigmaFor(playoff),
          model.marginSigma * kRatingConfig.playoffSigmaScale);
    });
  });
}
