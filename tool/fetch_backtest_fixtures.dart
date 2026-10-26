// Downloads the TBA data the prediction backtest replays and saves it as test
// fixtures, so `flutter test` can score the model offline and
// deterministically.
//
// Run from the repo root (reads the TBA key from lib/core/config/app_config.dart):
//   dart run tool/fetch_backtest_fixtures.dart              # default events
//   dart run tool/fetch_backtest_fixtures.dart 2026cur      # just these
//
// Once a few weeks of a new season are played, swap in its events and re-run,
// so the backtest keeps measuring the model against the current game (see
// "Re-tuning each season" in CLAUDE.md).

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:barn2scout/data/models/tba_match.dart';
import 'package:barn2scout/data/services/tba_service.dart';
import 'package:http/http.dart' as http;

/// A spread of situations the model has to handle: early events where almost
/// nobody has played yet this season, late events where everyone has, and the
/// 75-team Championship field.
const _defaultEvents = [
  '2026casac', // 751's first event — few teams had an earlier 2026 event
  '2026cacac', // 751's second event
  '2026cancmp', // NorCal DCMP — 1678's dead-match weekend
  '2026cahal', // week 1, CA district — the shape of 751's first 2027 event
  '2026okok', // week 1, regional
  '2026txbel', // week 1, Texas district
  '2026necmp1', // a district championship division
  '2026cur', // a Championship division
];

Future<void> main(List<String> args) async {
  final client = http.Client();
  final tba = TbaService(client: client);
  final dir = Directory('test/fixtures/backtest')..createSync(recursive: true);

  try {
    for (final key in args.isEmpty ? _defaultEvents : args) {
      final event = await tba.get('/event/$key/simple') as Map<String, dynamic>;
      // The full /matches payload (not /simple) because only it carries each
      // alliance's ranking points, which the backtest needs to rebuild the
      // old model's average-RP input as of each match.
      final raw = (await tba.get('/event/$key/matches') as List)
          .cast<Map<String, dynamic>>();
      raw.sort((a, b) =>
          TbaMatch.fromJson(a).sortKey.compareTo(TbaMatch.fromJson(b).sortKey));
      final stats = await tba.get('/event/$key/oprs') as Map<String, dynamic>;
      final rankings =
          await tba.get('/event/$key/rankings') as Map<String, dynamic>;

      final priors = await _priors(tba, key, event['start_date'] as String);
      final pastSeason = await _pastSeason(tba, key);

      final matches = raw.map(_trim).toList();
      final file = File('${dir.path}/$key.json');
      // One match per line keeps the fixture diffable without pretty-printing
      // the whole file.
      file.writeAsStringSync([
        '{',
        '"key": ${jsonEncode(key)},',
        '"name": ${jsonEncode(event['name'])},',
        '"startDate": ${jsonEncode(event['start_date'])},',
        // TBA's own end-of-quals numbers — the backtest checks its rebuild of
        // the app's inputs against every one of them.
        '"tbaOprs": ${jsonEncode(stats['oprs'] ?? {})},',
        '"tbaDprs": ${jsonEncode(stats['dprs'] ?? {})},',
        '"tbaCcwms": ${jsonEncode(stats['ccwms'] ?? {})},',
        '"tbaRankings": ${jsonEncode(_trimRankings(rankings))},',
        // What the app would have borrowed for each team before this event:
        // its OPR at its newest earlier event this season (see
        // ScheduleRepository._priorRatings).
        '"priors": ${jsonEncode(priors)},',
        // Each team's standing at last season's official events, in standard
        // deviations above that event's mean OPR, newest first.
        '"pastSeason": ${jsonEncode(pastSeason)},',
        '"matches": [',
        matches.map(jsonEncode).join(',\n'),
        ']',
        '}',
        '',
      ].join('\n'));

      final quals = matches
          .map(TbaMatch.fromJson)
          .where((m) => m.compLevel == 'qm' && m.isPlayed);
      stdout.writeln('$key: ${matches.length} matches '
          '(${quals.length} played quals, '
          '${priors.length} teams with a prior), '
          '${(file.lengthSync() / 1024).toStringAsFixed(0)} KB');
    }
  } finally {
    client.close();
  }
}

/// Each roster team's prior as `ScheduleRepository._priorRatings` picks it,
/// except that "completed" means ended before [startDate] rather than before
/// today, so a replayed event never borrows from one that came after it.
///
/// Returns `{teamKey: [sourceEventKey, opr]}`.
Future<Map<String, List<Object>>> _priors(
  TbaService tba,
  String eventKey,
  String startDate,
) async {
  final year = eventKey.substring(0, 4);
  final roster =
      (await tba.get('/event/$eventKey/teams/keys') as List).cast<String>();
  final history = <String, List<String>>{};
  for (final team in roster) {
    final events = (await tba.get('/team/$team/events/$year/simple') as List)
        .cast<Map<String, dynamic>>()
        .where((e) =>
            e['key'] != eventKey &&
            (e['end_date'] as String).compareTo(startDate) < 0)
        .toList()
      ..sort((a, b) =>
          (b['end_date'] as String).compareTo(a['end_date'] as String));
    history[team] = [for (final e in events) e['key'] as String];
  }

  final oprs = <String, Map<String, double>>{};
  final byTeam = <String, List<Object>>{};
  for (final team in roster) {
    for (final source in history[team]!) {
      final rated = oprs[source] ??= await _oprs(tba, source);
      final opr = rated[team];
      if (opr == null) continue; // not rated there — try an older event
      byTeam[team] = [source, opr];
      break;
    }
  }
  return byTeam;
}

/// Every roster team's z-score (standard deviations above the event's mean
/// OPR) at each of its official events last season, newest first:
/// `{teamKey: [[eventKey, z], …]}`. A team with none maps to an empty list.
Future<Map<String, List<List<Object>>>> _pastSeason(
  TbaService tba,
  String eventKey,
) async {
  final year = int.parse(eventKey.substring(0, 4)) - 1;
  final roster =
      (await tba.get('/event/$eventKey/teams/keys') as List).cast<String>();
  final zs = <String, Map<String, double>>{};
  final out = <String, List<List<Object>>>{};
  for (final team in roster) {
    final events = (await tba.get('/team/$team/events/$year/simple') as List)
        .cast<Map<String, dynamic>>()
        .where((e) => _officialTypes.contains(e['event_type']))
        .toList()
      ..sort((a, b) =>
          (b['end_date'] as String).compareTo(a['end_date'] as String));
    out[team] = [
      for (final e in events)
        if ((zs[e['key'] as String] ??= _zScores(
              await _oprs(tba, e['key'] as String),
            ))[team]
            case final z?)
          [e['key'] as String, z],
    ];
  }
  return out;
}

/// Regional, district, district championship (and its divisions) and
/// championship division: events every team plays to the same rules.
const _officialTypes = {0, 1, 2, 3, 5};

/// Each team's OPR in standard deviations above the event's mean.
Map<String, double> _zScores(Map<String, double> oprs) {
  if (oprs.length < 2) return const {};
  final mean = oprs.values.reduce((a, b) => a + b) / oprs.length;
  final sd = math.sqrt(
      oprs.values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
          oprs.length);
  if (sd <= 0) return const {};
  return {for (final e in oprs.entries) e.key: (e.value - mean) / sd};
}

/// An event's OPRs, empty if TBA has none. An all-zero map (posted with the
/// schedule, before anything is played) counts as none.
Future<Map<String, double>> _oprs(TbaService tba, String eventKey) async {
  final Map<String, dynamic>? data;
  try {
    data = await tba.get('/event/$eventKey/oprs') as Map<String, dynamic>?;
  } on TbaException {
    return const {};
  }
  final oprs = {
    for (final MapEntry(:key, :value)
        in ((data?['oprs'] as Map?) ?? const {}).entries)
      key as String: (value as num).toDouble(),
  };
  return oprs.values.every((v) => v == 0) ? const {} : oprs;
}

/// Keeps what [TbaMatch.fromJson] reads, plus what TBA's rankings and the
/// app's view of "already played" depend on: each alliance's ranking points,
/// its surrogate and disqualified teams, and when the result was posted.
Map<String, dynamic> _trim(Map<String, dynamic> m) {
  Map<String, dynamic> side(String color) {
    final alliance = (m['alliances'] as Map)[color] as Map;
    final breakdown = (m['score_breakdown'] as Map?)?[color] as Map?;
    final surrogates = alliance['surrogate_team_keys'] as List? ?? const [];
    final dqs = alliance['dq_team_keys'] as List? ?? const [];
    return {
      'team_keys': alliance['team_keys'],
      'score': alliance['score'],
      if (breakdown?['rp'] != null) 'rp': breakdown!['rp'],
      if (surrogates.isNotEmpty) 'surrogate_team_keys': surrogates,
      if (dqs.isNotEmpty) 'dq_team_keys': dqs,
    };
  }

  return {
    'key': m['key'],
    'comp_level': m['comp_level'],
    'set_number': m['set_number'],
    'match_number': m['match_number'],
    'winning_alliance': m['winning_alliance'],
    'time': m['time'],
    'predicted_time': m['predicted_time'],
    'actual_time': m['actual_time'],
    'post_result_time': m['post_result_time'],
    'alliances': {'red': side('red'), 'blue': side('blue')},
  };
}

/// Per team: `[ranking score, wins, losses, ties, matches played]` — what the
/// app reads from `/rankings` (the ranking score is `sort_orders[0]`).
Map<String, List<num>> _trimRankings(Map<String, dynamic> data) => {
      for (final r in (data['rankings'] as List? ?? const [])
          .cast<Map<String, dynamic>>())
        r['team_key'] as String: [
          (r['sort_orders'] as List).first as num,
          (r['record'] as Map?)?['wins'] as num? ?? 0,
          (r['record'] as Map?)?['losses'] as num? ?? 0,
          (r['record'] as Map?)?['ties'] as num? ?? 0,
          r['matches_played'] as num,
        ],
    };
