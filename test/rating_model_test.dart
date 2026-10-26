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

/// σ rebuilt the slow way: each of [quals] predicted by its own fit to the
/// quals listed before it, then blended with the assumed miss as
/// [RatingModel.fit] does.
double _slowSigma(List<TbaMatch> quals) {
  const config = kRatingConfig;
  var squaredMisses = 0.0;
  var scoreTotal = 0.0;
  for (var k = 0; k < quals.length; k++) {
    final before = RatingModel.fit(quals.take(k));
    final m = quals[k];
    double sum(List<String> teams) =>
        teams.fold(0, (t, key) => t + before.pointsOf(key));
    final miss =
        (m.redScore! - m.blueScore!) - (sum(m.redTeams) - sum(m.blueTeams));
    squaredMisses += miss * miss;
    scoreTotal += m.redScore! + m.blueScore!;
  }
  final assumed = config.sigmaPerMeanScore * scoreTotal / (2 * quals.length);
  return math.sqrt(
      (squaredMisses + config.sigmaPriorWeight * assumed * assumed) /
          (quals.length + config.sigmaPriorWeight));
}

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
      for (final team in ['frc1', 'frc2', 'frc3']) {
        expect(model.expectedPoints[team], closeTo(11.25, 1e-9));
      }
      for (final team in ['frc4', 'frc5', 'frc6']) {
        expect(model.expectedPoints[team], closeTo(18.75, 1e-9));
      }
    });

    test('with a tiny λ it is exactly OPR: TBA\'s end-of-quals numbers', () {
      // Proves the normal equations are built right. Every team having
      // played isn't enough to make AᵀA invertible (after the one match
      // above, all six have, and it has rank 2), but by the end of quals
      // there are far more alliance results than teams, so it is here, and
      // the λ → 0 limit is plain OPR.
      for (final e in BacktestEvent.loadAll()) {
        final model = RatingModel.fit(
          e.playedQuals,
          config:
              const RatingConfig(priorWeight: 1e-6, levelPriorWeight: 1e-6),
        );
        expect(model.expectedPoints.keys.toSet(),
            {for (final team in e.tbaOprs.keys) 'frc$team'},
            reason: e.key);
        for (final MapEntry(key: team, value: opr) in e.tbaOprs.entries) {
          expect(model.expectedPoints['frc$team'], closeTo(opr, 0.01),
              reason: '${e.key} team $team');
        }
      }
    });

    test('nothing played: the fit is just the priors', () {
      final model = RatingModel.fit(const [], priors: {1: 50, 2: 30});

      expect(model.expectedPoints.keys, ['frc1', 'frc2']);
      expect(model.expectedPoints['frc1'], closeTo(50, 1e-9));
      expect(model.expectedPoints['frc2'], closeTo(30, 1e-9));
      expect(model.meanTeamPoints, 40);
      expect(model.pointsOf('frc3'), 40);
      // No misses yet, so σ is all assumption: half a 3 × 40 alliance score.
      expect(model.marginSigma, closeTo(60, 1e-9));
    });

    test('a prior holds a team up until its matches outweigh it', () {
      final match = _qual(1, ['frc1', 'frc2', 'frc3'], ['frc4', 'frc5', 'frc6'],
          redScore: 30, blueScore: 60);
      final without = RatingModel.fit([match]);
      final withPrior = RatingModel.fit([match], priors: {1: 100});

      expect(withPrior.expectedPoints['frc1'],
          greaterThan(without.expectedPoints['frc1']! + 10));
    });

    test('a team with a prior and one without get their own λ', () {
      // One-robot alliances keep each row to one unknown, so each robot sits
      // between its own score and its prior (frc2's is the 30-point event
      // average), weighted 1 : λ.
      List<double> fit(RatingConfig config) {
        final model = RatingModel.fit(
          [_qual(1, ['frc1'], ['frc2'], redScore: 60, blueScore: 0)],
          priors: {1: 30},
          config: config,
        );
        return [model.expectedPoints['frc1']!, model.expectedPoints['frc2']!];
      }

      // (60 + 2·30) / 3 and (0 + 1·30) / 2.
      expect(fit(const RatingConfig(priorWeight: 2, levelPriorWeight: 1)), [
        closeTo(40, 1e-9),
        closeTo(15, 1e-9),
      ]);
      // (60 + 1·30) / 2 and (0 + 2·30) / 3.
      expect(fit(const RatingConfig(priorWeight: 1, levelPriorWeight: 2)), [
        closeTo(45, 1e-9),
        closeTo(20, 1e-9),
      ]);
    });

    test('a relative prior follows the event\'s scoring', () {
      // The event scores 30 a robot. frc1 was a standard deviation above
      // average last season, frc3 one below; frc2 has nothing to go on.
      final model = RatingModel.fit(
        [_qual(1, ['frc1'], ['frc2'], redScore: 60, blueScore: 0)],
        relativePriors: {1: 1, 3: -1},
        config: const RatingConfig(
          relativePriorScale: 0.5,
          relativePriorWeight: 1,
          levelPriorWeight: 1,
        ),
      );

      // frc1: between its 60 and 30 × (1 + 0.5), weighted 1 : 1.
      expect(model.expectedPoints['frc1'], closeTo(52.5, 1e-9));
      // frc2: between its 0 and the 30-point average.
      expect(model.expectedPoints['frc2'], closeTo(15, 1e-9));
      // frc3 hasn't played: just its prior, 30 × (1 − 0.5).
      expect(model.expectedPoints['frc3'], closeTo(15, 1e-9));
    });

    test('a prior in points outranks a relative one', () {
      final model = RatingModel.fit(
        const [],
        priors: {1: 50, 2: 30},
        relativePriors: {1: 2, 3: 1},
      );

      expect(model.expectedPoints['frc1'], closeTo(50, 1e-9));
      // frc3 is scaled off the priors' 40-point average.
      expect(
        model.expectedPoints['frc3'],
        closeTo(40 * (1 + kRatingConfig.relativePriorScale), 1e-9),
      );
    });

    test('relative priors alone have no scale, so they say nothing', () {
      final model = RatingModel.fit(const [], relativePriors: {1: 1, 2: -1});

      expect(model.expectedPoints, isEmpty);
      expect(model.marginSigma, 0);
    });

    test('no matches and no priors: knows nothing, predicts nothing', () {
      final model = RatingModel.fit(const []);
      expect(model.expectedPoints, isEmpty);
      expect(model.meanTeamPoints, 0);
      expect(model.marginSigma, 0);
    });

    test('ignores playoffs and unscored quals', () {
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
      // Team 7 is only on an unscored qual: no number, so it's average.
      expect(model.expectedPoints.containsKey('frc7'), isFalse);
      expect(model.pointsOf('frc7'), model.meanTeamPoints);
    });

    test('counts a scored qual that has no start time', () {
      // Some offseason uploads post scores without actual_time; TBA's own
      // OPRs still count those matches.
      final model = RatingModel.fit([
        const TbaMatch(
          key: 't_qm1',
          compLevel: 'qm',
          setNumber: 1,
          matchNumber: 1,
          redTeams: ['frc1', 'frc2', 'frc3'],
          blueTeams: ['frc4', 'frc5', 'frc6'],
          redScore: 30,
          blueScore: 60,
        ),
      ]);

      expect(model.expectedPoints['frc1'], closeTo(11.25, 1e-9));
    });

    test('a B-team gets its own share instead of handing it to its partners',
        () {
      final model = RatingModel.fit([
        _qual(1, ['frc1', 'frc2', 'frc254B'], ['frc4', 'frc5', 'frc6'],
            redScore: 30, blueScore: 60),
      ]);

      // Same as the all-numbered match above.
      expect(model.expectedPoints['frc1'], closeTo(11.25, 1e-9));
      expect(model.expectedPoints['frc254B'], closeTo(11.25, 1e-9));
      expect(model.expectedPoints.length, 6);
    });
  });

  group('RatingModel.fit marginSigma', () {
    test('is the RMS of honest pre-match misses, blended with the assumed miss',
        () {
      // On shuffled input the model must still replay the matches in order,
      // predicting each from only the quals before it.
      final quals = BacktestEvent.loadAll().first.playedQuals.take(30).toList();
      final shuffled = [...quals]..shuffle(math.Random(751));

      expect(RatingModel.fit(shuffled).marginSigma,
          closeTo(_slowSigma(quals), 1e-6));
    });

    test('replays in the order matches were played, not match number', () {
      // Qual 2 ran first; qual 1 was replayed after it.
      final first = _qual(2, ['frc1', 'frc2', 'frc3'], ['frc4', 'frc5', 'frc6'],
          redScore: 200, blueScore: 20, minute: 5);
      final second = _qual(
          1, ['frc1', 'frc2', 'frc7'], ['frc4', 'frc5', 'frc8'],
          redScore: 40, blueScore: 150, minute: 30);
      final third = _qual(3, ['frc3', 'frc5', 'frc7'], ['frc6', 'frc8', 'frc1'],
          redScore: 90, blueScore: 110, minute: 40);

      final sigma = RatingModel.fit([second, first, third]).marginSigma;

      expect(sigma, closeTo(_slowSigma([first, second, third]), 1e-9));
      expect(sigma, isNot(closeTo(_slowSigma([second, first, third]), 1e-3)));
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
