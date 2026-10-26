import 'package:barn2scout/data/models/match_prediction.dart';
import 'package:barn2scout/data/models/rating_model.dart';
import 'package:barn2scout/data/models/tba_match.dart';
import 'package:barn2scout/data/models/team_rating.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/backtest_fixtures.dart';
import 'helpers/forecast_metrics.dart';
import 'helpers/legacy_model.dart';

/// Scores the match predictor against real events, replayed in the order the
/// matches were played (fixtures from `tool/fetch_backtest_fixtures.dart`).
/// Every prediction sees only results TBA had posted before it, so these are
/// honest out-of-sample numbers, never a fit to data the model already saw.
void main() {
  final events = BacktestEvent.loadAll();

  group('fixtures', () {
    test('cover the planned spread of events', () {
      expect(events.length, greaterThanOrEqualTo(8));
      for (final e in events) {
        expect(e.playedQuals.length, greaterThan(40), reason: e.key);
      }
    });

    test('every scored qual has a start time and both RP totals', () {
      for (final e in events) {
        for (final m in e.matches.where((m) => m.compLevel == 'qm')) {
          if ((m.redScore ?? -1) < 0 || (m.blueScore ?? -1) < 0) continue;
          expect(m.actualTime, isNotNull,
              reason: '${m.key} has scores but no start time');
          expect(e.extras[m.key]?.redRp, isNotNull, reason: m.key);
          expect(e.extras[m.key]?.blueRp, isNotNull, reason: m.key);
        }
      }
    });
  });

  // The baseline only means something if the old model is fed what the app
  // actually got from TBA. At the end of quals that can be checked directly
  // against TBA's own numbers.
  group('rebuilt app inputs match TBA at the end of quals', () {
    test('OPR, DPR and CCWM', () {
      for (final e in events) {
        final ours = legacyRatingsAsOf(e, e.playedQuals);
        expect(ours.keys.toSet(), e.tbaOprs.keys.toSet(), reason: e.key);
        for (final team in e.tbaOprs.keys) {
          final r = ours[team]!;
          final why = '${e.key} team $team';
          expect(r.opr, closeTo(e.tbaOprs[team]!, 0.01), reason: why);
          expect(r.dpr, closeTo(e.tbaDprs[team]!, 0.01), reason: why);
          expect(r.ccwm, closeTo(e.tbaCcwms[team]!, 0.01), reason: why);
        }
      }
    });

    test('ranking score and W-L-T', () {
      for (final e in events) {
        final ours = legacyRatingsAsOf(e, e.playedQuals);
        for (final MapEntry(key: team, value: tba) in e.tbaRankings.entries) {
          final r = ours[team]!;
          final why = '${e.key} team $team';
          // TBA publishes the ranking score rounded to two decimals.
          expect(r.avgRp, closeTo(tba.rankingScore, 0.005 + 1e-9), reason: why);
          expect((r.wins, r.losses, r.ties), (tba.wins, tba.losses, tba.ties),
              reason: why);
        }
      }
    });
  });

  group('minimum-norm OPR, as TBA solves it', () {
    TbaMatch match(
      String key,
      List<int> red,
      List<int> blue, {
      int? redScore,
      int? blueScore,
    }) =>
        TbaMatch(
          key: key,
          compLevel: 'qm',
          setNumber: 1,
          matchNumber: int.parse(key.substring(key.length - 1)),
          redTeams: [for (final n in red) 'frc$n'],
          blueTeams: [for (final n in blue) 'frc$n'],
          redScore: redScore,
          blueScore: blueScore,
          actualTime: redScore == null ? null : DateTime(2026, 3, 6, 9),
        );

    test('splits an alliance evenly when one match is all there is', () {
      // One played match only pins down each alliance's total, so the
      // minimum-norm answer gives its three robots equal shares. Team 7 is
      // only on the schedule so far: on TBA's list, at 0, with no ranking.
      final played =
          match('t_qm1', [1, 2, 3], [4, 5, 6], redScore: 30, blueScore: 60);
      final event = BacktestEvent(
        key: 't',
        matches: [
          played,
          match('t_qm2', [1, 2, 7], [4, 5, 6])
        ],
        extras: const {'t_qm1': MatchExtras(redRp: 0, blueRp: 3)},
      );

      final ratings = legacyRatingsAsOf(event, [played]);

      // Round-off along the directions the match can't tell apart is
      // amplified by 1/λ, so "equal shares" holds to ~1e-9, not to the last
      // digit — far inside the 0.01 tolerance the TBA comparisons use.
      for (final team in [1, 2, 3]) {
        expect(ratings[team]!.opr, closeTo(10, 1e-6));
      }
      for (final team in [4, 5, 6]) {
        expect(ratings[team]!.opr, closeTo(20, 1e-6));
      }
      expect(ratings[7]!.opr, 0);
      expect(ratings[7]!.matchesPlayed, 0);
      expect(ratings[7]!.avgRp, isNull);
    });

    test('keeps the mid-event blow-up the app really showed', () {
      // At 2026cur after 37 quals there are exactly as many alliance results
      // as teams (74), so the normal equations are barely invertible. These
      // values come from exact rational arithmetic, independent of this code.
      final cur = events.singleWhere((e) => e.key == '2026cur');
      final ratings = legacyRatingsAsOf(cur, cur.playedQuals.take(37).toList());
      expect(ratings[6510]!.opr, closeTo(3423.472222, 0.001));
      expect(ratings[1498]!.opr, closeTo(-2633.046296, 0.001));
    });
  });

  test('report', () {
    // The old model as the app ran it until Phase 2: TBA's OPRs plus nudges.
    // The new one: the app's own MatchPrediction on a fresh RatingModel fit,
    // with each team's OPR at its previous event as its prior, or else its
    // standing last season. 'no priors' is the same fit without either, and
    // '2026 priors only' without last season, to show what each adds.
    final models = <String,
        MatchPrediction Function(BacktestEvent, List<TbaMatch>, TbaMatch)>{
      'old model': (e, known, m) =>
          legacyPredict(m, legacyRatingsAsOf(e, known)),
      'no priors': (e, known, m) => MatchPrediction.compute(
          m, EventRatings(model: RatingModel.fit(known))),
      '2026 priors only': (e, known, m) => MatchPrediction.compute(
          m,
          EventRatings(
              model: RatingModel.fit(known, priors: e.priorOprs))),
      'new model': (e, known, m) => MatchPrediction.compute(
          m,
          EventRatings(
              model: RatingModel.fit(known,
                  priors: e.priorOprs, relativePriors: e.relativePriors))),
    };
    final rows = {
      for (final lead in const [1, 6])
        for (final MapEntry(key: name, value: predict) in models.entries)
          '$name, lead $lead': [
            for (final e in events)
              ...e.replayQuals((known, m) => predict(e, known, m), lead: lead),
          ],
    };
    final lead1 = rows['old model, lead 1']!;

    final paired = StringBuffer('paired, new model − baseline (negative = new '
        'is better, ± 1 standard error clustered by event), then per event\n');
    final deltas =
        <String, ({double mean, double se, Map<String, double> byEvent})>{};
    for (final baseline in const [
      'old model',
      'no priors',
      '2026 priors only',
    ]) {
      for (final lead in const [1, 6]) {
        for (final MapEntry(key: metric, value: loss) in {
          'Brier': brierOf,
          'log loss': logLossOf,
        }.entries) {
          final label = '$metric, lead $lead, vs $baseline';
          final d = deltas[label] = pairedDelta(
            rows['$baseline, lead $lead']!,
            rows['new model, lead $lead']!,
            loss,
          );
          paired.writeln('  ${label.padRight(39)}'
              '${d.mean.toStringAsFixed(4).padLeft(8)} ± '
              '${d.se.toStringAsFixed(4)}');
          paired.writeln('    ${[
            for (final MapEntry(:key, :value) in d.byEvent.entries)
              '${key.substring(4)} ${value >= 0 ? '+' : ''}'
                  '${value.toStringAsFixed(3)}',
          ].join('  ')}');
        }
      }
    }

    // ignore: avoid_print
    print('\nPrediction backtest — ${events.length} events, '
        '${lead1.length} qual predictions at lead 1.\n'
        'Lead k = ratings as loaded when the match k-1 places earlier '
        'started; lead 1 is the freshest the app can be.\n\n'
        '${forecastTable(rows)}\n'
        '$paired\n'
        '${calibrationTable('old model, lead 1', lead1)}\n'
        '${calibrationTable('new model, lead 1', rows['new model, lead 1']!)}');

    for (final MapEntry(key: label, value: fs) in rows.entries) {
      for (final metric in [
        accuracy(fs),
        brierScore(fs),
        logLoss(fs),
        marginRmse(fs),
      ]) {
        expect(metric.isFinite, isTrue, reason: label);
      }
      for (final phase in const [0, 1, 2]) {
        expect(fs.where((f) => f.phase == phase), isNotEmpty,
            reason: '$label, phase $phase');
      }
    }

    // Once TBA has posted any OPRs every scheduled team is on its list, so
    // the old app drew a bar for every match the replay scores.
    for (final lead in const [1, 6]) {
      expect(rows['old model, lead $lead']!.where((f) => !f.shown), isEmpty);
    }
    // The new model only hides a match when it knows none of the six teams,
    // and then it really has nothing to say.
    for (final lead in const [1, 6]) {
      for (final f in rows['new model, lead $lead']!.where((f) => !f.shown)) {
        // To within normalCdf's erf approximation (±1.5e-7).
        expect(f.redWinPct, closeTo(0.5, 1e-6), reason: f.matchKey);
      }
    }

    // The new model has to beat both the old one and itself without priors
    // on the same matches, on both scores, at both leads, by more than 2.4
    // standard errors: the 95% t value for 8 events (7 degrees of freedom),
    // since the error is estimated from so few.
    //
    // Not '2026 priors only': last season only matters for teams with no
    // 2026 event, and only 3 fixtures have many, too few to show it. On 65
    // 2026 events it cut Brier by 0.0066 ± 0.0012.
    for (final MapEntry(key: label, value: d) in deltas.entries) {
      if (label.endsWith('vs 2026 priors only')) continue;
      expect(d.mean + 2.4 * d.se, lessThan(0), reason: label);
    }
  });
}
