// Downloads the TBA data the prediction backtest replays and saves it as test
// fixtures, so `flutter test` can score the model offline and
// deterministically.
//
// Run from the repo root (reads the TBA key from lib/core/config/app_config.dart):
//   dart run tool/fetch_backtest_fixtures.dart              # default events
//   dart run tool/fetch_backtest_fixtures.dart 2026cur      # just these
//
// Re-run each January with events from the new season so the backtest keeps
// measuring the model against the current game.

import 'dart:convert';
import 'dart:io';

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
          '(${quals.length} played quals), '
          '${(file.lengthSync() / 1024).toStringAsFixed(0)} KB');
    }
  } finally {
    client.close();
  }
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
