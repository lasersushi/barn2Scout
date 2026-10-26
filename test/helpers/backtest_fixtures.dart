import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:barn2scout/data/models/match_prediction.dart';
import 'package:barn2scout/data/models/rating_model.dart';
import 'package:barn2scout/data/models/tba_match.dart';

import 'forecast_metrics.dart';

/// Per-match facts from TBA's full match payload that [TbaMatch] (built from
/// `/matches/simple`, like the app) doesn't carry.
class MatchExtras {
  const MatchExtras({
    this.redRp,
    this.blueRp,
    this.surrogates = const {},
    this.disqualified = const {},
    this.resultPosted,
  });

  /// Ranking points each alliance earned.
  final int? redRp;
  final int? blueRp;

  /// Team keys playing as surrogates. The appearance doesn't count toward
  /// rankings at all.
  final Set<String> surrogates;

  /// Disqualified team keys: 0 RP and no W-L-T result for the match.
  final Set<String> disqualified;

  /// When TBA posted the result — from then on the app could see it.
  final DateTime? resultPosted;
}

/// One event of recorded TBA data for the prediction backtest. Written by
/// `tool/fetch_backtest_fixtures.dart`, replayed by
/// `test/prediction_backtest_test.dart`.
class BacktestEvent {
  const BacktestEvent({
    required this.key,
    required this.matches,
    this.extras = const {},
    this.tbaOprs = const {},
    this.tbaDprs = const {},
    this.tbaCcwms = const {},
    this.tbaRankings = const {},
    this.priors = const {},
    this.pastSeason = const {},
  });

  final String key;

  /// Every match TBA had for the event, in competition order.
  final List<TbaMatch> matches;

  /// See [MatchExtras], keyed by match key.
  final Map<String, MatchExtras> extras;

  /// TBA's own end-of-quals numbers, keyed by team number.
  final Map<int, double> tbaOprs;
  final Map<int, double> tbaDprs;
  final Map<int, double> tbaCcwms;
  final Map<int, TbaRankingRow> tbaRankings;

  /// What the app would have borrowed for each team before the event: its
  /// OPR at its newest earlier event this season, keyed by team number.
  /// Teams with no earlier event aren't in it.
  final Map<int, ({String sourceEvent, double opr})> priors;

  /// Each team's z-score (standard deviations above the event's mean OPR) at
  /// each of its official events last season, newest first, keyed by team
  /// number. A team with no such event maps to an empty list.
  final Map<int, List<double>> pastSeason;

  /// [priors]' OPRs alone: what `RatingModel.fit` takes.
  Map<int, double> get priorOprs => {
        for (final MapEntry(:key, :value) in priors.entries) key: value.opr,
      };

  /// The relative priors the app would have used for teams without one of
  /// [priors]: the average of their [pastSeason] z-scores, or
  /// [RatingConfig.noHistoryZ] with none.
  Map<int, double> get relativePriors => {
        for (final MapEntry(key: team, value: zs) in pastSeason.entries)
          if (!priors.containsKey(team))
            team: zs.isEmpty
                ? kRatingConfig.noHistoryZ
                : zs.reduce((a, b) => a + b) / zs.length,
      };

  /// Every team on the qualification schedule, played or not. TBA builds its
  /// OPR team list from these, so a team is on `/oprs` before it has played.
  Set<int> get scheduledQualTeams => {
        for (final m in matches)
          if (m.compLevel == 'qm') ...[...m.redTeams, ...m.blueTeams],
      }
          .map((key) => int.tryParse(TbaMatch.displayNumber(key)))
          .whereType<int>()
          .toSet();

  /// Played qualification matches, in the order they were actually played.
  /// Match number isn't always that order — a replayed match can be run hours
  /// after the next one.
  List<TbaMatch> get playedQuals => [
        for (final m in matches)
          if (m.compLevel == 'qm' && m.isPlayed) m,
      ]..sort((a, b) {
          final byTime = a.actualTime!.compareTo(b.actualTime!);
          return byTime != 0 ? byTime : a.matchNumber.compareTo(b.matchNumber);
        });

  /// Replays the quals in play order, scoring [predict] on each.
  ///
  /// Before each match, [predict] gets exactly the quals whose results TBA had
  /// posted when the app last loaded ratings: as the match started when
  /// `lead` is 1 — the freshest the app can ever be — or as the match
  /// `lead - 1` places earlier started, i.e. a scout who loaded predictions
  /// that far ahead. The live app only reloads when a tab opens or is
  /// refreshed, so what scouts saw usually sat somewhere between the two.
  /// Matches with nothing posted before them yet are skipped.
  List<Forecast> replayQuals(
    MatchPrediction Function(List<TbaMatch> known, TbaMatch match) predict, {
    int lead = 1,
  }) {
    final quals = playedQuals;
    final out = <Forecast>[];
    for (var i = 0; i < quals.length; i++) {
      final loadedAt = quals[math.max(0, i - (lead - 1))].actualTime!;
      final known = [
        for (final q in quals)
          if (_resultTime(q).isBefore(loadedAt)) q,
      ];
      if (known.isEmpty) continue;

      final p = predict(known, quals[i]);
      out.add(Forecast(
        eventKey: key,
        matchKey: quals[i].key,
        // Thirds of the event by play order, so "early" means the same
        // stretch of an event whatever the lead.
        phase: (3 * i) ~/ quals.length,
        redWinPct: p.redWinPct,
        predictedMargin: p.redScore - p.blueScore,
        redScore: quals[i].redScore!,
        blueScore: quals[i].blueScore!,
        shown: p.hasData,
      ));
    }
    return out;
  }

  DateTime _resultTime(TbaMatch m) =>
      extras[m.key]?.resultPosted ?? m.actualTime!;

  /// Every fixture in [dir], sorted by event key.
  static List<BacktestEvent> loadAll({String dir = 'test/fixtures/backtest'}) {
    final files = Directory(dir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return [
      for (final f in files)
        _parse(jsonDecode(f.readAsStringSync()) as Map<String, dynamic>),
    ];
  }

  static BacktestEvent _parse(Map<String, dynamic> json) {
    final raw = (json['matches'] as List).cast<Map<String, dynamic>>();

    MatchExtras extrasOf(Map<String, dynamic> m) {
      Map<String, dynamic> side(String color) =>
          (m['alliances'] as Map)[color] as Map<String, dynamic>;
      Set<String> keys(String field) => {
            for (final color in const ['red', 'blue'])
              ...(side(color)[field] as List? ?? const []).cast<String>(),
          };
      final posted = m['post_result_time'] as int?;
      return MatchExtras(
        redRp: (side('red')['rp'] as num?)?.toInt(),
        blueRp: (side('blue')['rp'] as num?)?.toInt(),
        surrogates: keys('surrogate_team_keys'),
        disqualified: keys('dq_team_keys'),
        resultPosted: posted == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(posted * 1000),
      );
    }

    return BacktestEvent(
      key: json['key'] as String,
      matches: raw.map(TbaMatch.fromJson).toList(),
      extras: {for (final m in raw) m['key'] as String: extrasOf(m)},
      tbaOprs: _byTeam(json['tbaOprs'], (v) => (v as num).toDouble()),
      tbaDprs: _byTeam(json['tbaDprs'], (v) => (v as num).toDouble()),
      tbaCcwms: _byTeam(json['tbaCcwms'], (v) => (v as num).toDouble()),
      tbaRankings: _byTeam(json['tbaRankings'], (v) {
        final row = (v as List).cast<num>();
        return (
          rankingScore: row[0].toDouble(),
          wins: row[1].toInt(),
          losses: row[2].toInt(),
          ties: row[3].toInt(),
          matchesPlayed: row[4].toInt(),
        );
      }),
      pastSeason: _byTeam(json['pastSeason'], (v) => [
            for (final row in v as List) ((row as List)[1] as num).toDouble(),
          ]),
      priors: _byTeam(json['priors'], (v) {
        final [source, opr] = v as List;
        return (sourceEvent: source as String, opr: (opr as num).toDouble());
      }),
    );
  }

  /// Re-keys a TBA `{"frc254": …}` map by team number.
  static Map<int, T> _byTeam<T>(Object? json, T Function(Object? value) read) {
    final out = <int, T>{};
    for (final MapEntry(:key, :value)
        in ((json as Map<String, dynamic>?) ?? const {}).entries) {
      final team = int.tryParse(TbaMatch.displayNumber(key));
      if (team != null) out[team] = read(value);
    }
    return out;
  }
}

/// One team's row from TBA's `/rankings`, as the app reads it.
typedef TbaRankingRow = ({
  double rankingScore,
  int wins,
  int losses,
  int ties,
  int matchesPlayed,
});
