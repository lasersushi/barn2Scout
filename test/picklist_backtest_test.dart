import 'package:barn2scout/core/utils/stats_utils.dart';
import 'package:barn2scout/data/models/rating_model.dart';
import 'package:barn2scout/data/models/tba_match.dart';
import 'package:barn2scout/data/models/team_rating.dart';
import 'package:barn2scout/data/models/team_strength.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/backtest_fixtures.dart';
import 'helpers/forecast_metrics.dart';
import 'helpers/legacy_model.dart';

/// Scores the picklist's ranking value by how well it predicts matches it
/// hasn't seen, on the same recorded events as the prediction backtest:
///
/// * the last third of quals, from ratings as of the first two thirds;
/// * the playoffs, from ratings as of the end of quals: what alliance
///   selection actually picks on.
///
/// Each method's per-team values are summed into an alliance margin, and all
/// of them share the rating model's σ, so only the values differ.
void main() {
  final events = BacktestEvent.loadAll();

  /// The picklist's ranking value per team, given the TBA numbers the app
  /// would have had and the model fit to the same quals.
  final methods =
      <String, double Function(TeamStrength strength, Map<int, double> blend)>{
        'old blend': (s, blend) => blend[s.team]!,
        'OPR': (s, _) => s.rating.opr,
        'new rating': (s, _) => s.expectedPoints,
      };

  test('report', () {
    final sets = {
      'last third of quals': {for (final m in methods.keys) m: <Forecast>[]},
      'playoffs': {for (final m in methods.keys) m: <Forecast>[]},
    };

    for (final e in events) {
      final quals = e.playedQuals;
      final cut = (quals.length * 2 / 3).ceil();
      final playoffs = [
        for (final m in e.matches)
          if (m.compLevel != 'qm' &&
              (m.redScore ?? -1) >= 0 &&
              (m.blueScore ?? -1) >= 0)
            m,
      ];

      for (final (set, known, targets) in [
        ('last third of quals', quals.take(cut).toList(), quals.skip(cut)),
        ('playoffs', quals, playoffs),
      ]) {
        final teams = legacyRatingsAsOf(e, known);
        final model = RatingModel.fit(known, priors: e.priorOprs);
        final ranked = {
          for (final s in TeamStrength.rank(
            EventRatings(teams: teams, model: model),
          ))
            s.team: s,
        };
        final blend = legacyBlend(teams);

        for (final MapEntry(key: name, value: valueOf) in methods.entries) {
          double value(String key) {
            final s = ranked[int.tryParse(TbaMatch.displayNumber(key))];
            return s == null ? model.meanTeamPoints : valueOf(s, blend);
          }

          double sum(List<String> keys) =>
              keys.fold(0, (total, k) => total + value(k));

          for (final m in targets) {
            final margin = sum(m.redTeams) - sum(m.blueTeams);
            sets[set]![name]!.add(
              Forecast(
                eventKey: e.key,
                matchKey: m.key,
                phase: 0,
                redWinPct: normalCdf(margin / model.sigmaFor(m)),
                predictedMargin: margin,
                redScore: m.redScore!,
                blueScore: m.blueScore!,
              ),
            );
          }
        }
      }
    }

    final report = StringBuffer(
      '\nPicklist backtest — ${events.length} '
      'events. Each method\'s values summed per alliance.\n',
    );
    final deltas =
        <String, ({double mean, double se, Map<String, double> byEvent})>{};
    for (final MapEntry(key: set, value: rows) in sets.entries) {
      report.writeln('$set (n=${rows['old blend']!.length})');
      for (final MapEntry(key: name, value: fs) in rows.entries) {
        report.writeln(
          '  ${name.padRight(12)}'
          'acc ${accuracy(fs).toStringAsFixed(3)}  '
          'Brier ${brierScore(fs).toStringAsFixed(4)}  '
          'log loss ${logLoss(fs).toStringAsFixed(4)}  '
          'margin RMSE ${marginRmse(fs).toStringAsFixed(1)}',
        );
      }
      for (final MapEntry(key: metric, value: loss) in {
        'Brier': brierOf,
        'log loss': logLossOf,
      }.entries) {
        final d = deltas['$set, $metric'] = pairedDelta(
          rows['old blend']!,
          rows['new rating']!,
          loss,
        );
        report.writeln(
          '  new − old blend, $metric: '
          '${d.mean.toStringAsFixed(4)} ± ${d.se.toStringAsFixed(4)}',
        );
      }
    }
    // ignore: avoid_print
    print(report);

    // 8 events are too few to show the new rating is better: on 65 2026
    // events it beat the old blend by 2–3 standard errors on both sets. So
    // this only checks it isn't clearly worse (2.4 standard errors, the 95%
    // t value for 7 degrees of freedom).
    for (final MapEntry(key: label, value: d) in deltas.entries) {
      expect(d.mean - 2.4 * d.se, lessThan(0), reason: label);
    }
  });

  // 2026 NorCal DCMP, the weekend that shaped the old blend: connection
  // issues left 1678 11th on OPR, below 1868, though it ranked 6th
  // officially. Its earlier events hold it up now.
  test('1678 ranks top 6 at 2026 NorCal DCMP, above 1868', () {
    final e = events.singleWhere((e) => e.key == '2026cancmp');
    final quals = e.playedQuals;
    final order = [
      for (final s in TeamStrength.rank(
        EventRatings(
          teams: legacyRatingsAsOf(e, quals),
          model: RatingModel.fit(quals, priors: e.priorOprs),
        ),
      ))
        s.team,
    ];

    expect(order.indexOf(1678), lessThan(6));
    expect(order.indexOf(1678), lessThan(order.indexOf(1868)));
  });
}
