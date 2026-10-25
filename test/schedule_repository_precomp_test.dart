import 'dart:convert';

import 'package:barn2scout/core/config/app_config.dart';
import 'package:barn2scout/data/repositories/event_repository.dart';
import 'package:barn2scout/data/repositories/schedule_repository.dart';
import 'package:barn2scout/data/repositories/settings_repository.dart';
import 'package:barn2scout/data/repositories/team_repository.dart';
import 'package:barn2scout/data/services/nexus_service.dart';
import 'package:barn2scout/data/services/tba_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The Isar-backed caches are only touched by getTeams, which these tests never
/// call — any accidental use throws loudly.
class _UnusedEvents implements EventRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _UnusedTeams implements TeamRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Settings that never touch disk — detectCurrentEvent records what it found.
class _MemorySettings extends SettingsRepository {
  @override
  Future<void> setLastDetectedEvent(String key, String status) async {}
}

Map<String, dynamic> _oprs(Map<String, double> oprs) => {
  'oprs': oprs,
  'dprs': {for (final k in oprs.keys) k: 20.0},
  'ccwms': {for (final e in oprs.entries) e.key: e.value - 20.0},
};

/// A one-day event; override 'start_date' for longer ones.
Map<String, dynamic> _event(String key, String endDate) => {
  'key': key,
  'start_date': endDate,
  'end_date': endDate,
};

/// Season 2026 as TBA would serve it for the upcoming event `2026next`:
///   - frc1 played earlyA then lateB → should be rated from lateB (newest)
///   - frc2 played earlyA then lateB, but lateB's OPRs lack it → earlyA
///   - frc3 has no prior events → left out
/// Unlisted paths 404, like TBA for /rankings before an event is ranked.
Map<String, Object> _season({Map<String, double> currentOprs = const {}}) => {
  '/event/2026next/oprs': _oprs(currentOprs),
  '/event/2026next/teams/keys': ['frc1', 'frc2', 'frc3'],
  '/event/2026next/matches/simple': <Object>[],
  '/team/frc1/events/2026/simple': [
    _event('2026earlyA', '2026-03-01'),
    _event('2026lateB', '2026-04-01'),
    _event('2026next', '2099-01-01'),
  ],
  '/team/frc2/events/2026/simple': [
    _event('2026lateB', '2026-04-01'),
    _event('2026earlyA', '2026-03-01'),
  ],
  '/team/frc3/events/2026/simple': <Object>[],
  '/event/2026earlyA/oprs': _oprs({'frc1': 20, 'frc2': 35}),
  '/event/2026earlyA/matches/simple': <Object>[],
  '/event/2026lateB/oprs': _oprs({'frc1': 50, 'frc9': 30}),
  '/event/2026lateB/matches/simple': <Object>[],
};

/// A repo backed by a fake TBA serving [routes]. [hits] counts requests per
/// path; paths in [failing] return 500.
ScheduleRepository _repo(
  Map<String, Object> routes, {
  Map<String, int>? hits,
  Set<String> failing = const {},
}) {
  final client = MockClient((request) async {
    final path = request.url.toString().substring(AppConfig.tbaBaseUrl.length);
    hits?.update(path, (n) => n + 1, ifAbsent: () => 1);
    if (failing.contains(path)) return http.Response('boom', 500);
    final body = routes[path];
    if (body == null) return http.Response('not found', 404);
    return http.Response(jsonEncode(body), 200);
  });
  return ScheduleRepository(
    tba: TbaService(client: client),
    nexus: NexusService(client: client),
    settings: _MemorySettings(),
    events: _UnusedEvents(),
    teams: _UnusedTeams(),
  );
}

void main() {
  group('ScheduleRepository.fetchTeamRatings pre-comp fallback', () {
    test('uses the current event once TBA has OPRs for it', () async {
      final ratings = await _repo(
        _season(currentOprs: {'frc1': 70}),
      ).fetchTeamRatings('2026next', const []);

      expect(ratings.keys, [1]);
      expect(ratings[1]!.opr, 70);
      expect(ratings[1]!.isPreComp, isFalse);
    });

    test('rates each team from its newest prior event', () async {
      final ratings = await _repo(
        _season(),
      ).fetchTeamRatings('2026next', const []);

      expect(ratings[1]!.opr, 50);
      expect(ratings[1]!.sourceEventKey, '2026lateB');
      expect(ratings[1]!.isPreComp, isTrue);
    });

    test(
      'falls back to an older event when the newest did not rate the team',
      () async {
        final ratings = await _repo(
          _season(),
        ).fetchTeamRatings('2026next', const []);

        expect(ratings[2]!.opr, 35);
        expect(ratings[2]!.sourceEventKey, '2026earlyA');
      },
    );

    test(
      'leaves out teams with no earlier event, and non-roster teams',
      () async {
        final ratings = await _repo(
          _season(),
        ).fetchTeamRatings('2026next', const []);

        expect(ratings.containsKey(3), isFalse);
        // frc9 was rated at lateB but isn't registered for 2026next.
        expect(ratings.containsKey(9), isFalse);
      },
    );

    test('concurrent loads share one fetch', () async {
      final hits = <String, int>{};
      final repo = _repo(_season(), hits: hits);

      await Future.wait([
        repo.fetchTeamRatings('2026next', const []),
        repo.fetchTeamRatings('2026next', const []),
      ]);

      expect(hits['/event/2026next/teams/keys'], 1);
      expect(hits['/event/2026lateB/oprs'], 1);
      expect(hits['/event/2026earlyA/oprs'], 1);
    });

    test('an offline failure returns empty and is retried next load', () async {
      final hits = <String, int>{};
      final teamPaths = {
        for (final t in ['frc1', 'frc2', 'frc3']) '/team/$t/events/2026/simple',
      };
      final repo = _repo(_season(), hits: hits, failing: teamPaths);

      expect(await repo.fetchTeamRatings('2026next', const []), isEmpty);
      await repo.fetchTeamRatings('2026next', const []);

      expect(hits['/event/2026next/teams/keys'], 2);
    });
  });

  group('ScheduleRepository.detectCurrentEvent across a year boundary', () {
    final year = DateTime.now().year;
    String team(int y) => '/team/${AppConfig.myTeamKey}/events/$y/simple';

    test(
      'finds next season\'s comp when this year has only past events',
      () async {
        final repo = _repo({
          team(year): [_event('${year}done', '$year-01-02')],
          team(year + 1): [
            {
              ..._event('${year + 1}late', '${year + 1}-12-30'),
              'start_date': '${year + 1}-12-28',
            },
            {
              ..._event('${year + 1}soon', '${year + 1}-03-14'),
              'start_date': '${year + 1}-03-12',
            },
          ],
        });

        final detected = await repo.detectCurrentEvent();
        expect(detected.key, '${year + 1}soon');
        expect(detected.status, EventStatus.upcoming);
      },
    );

    test('a failed next-year lookup still falls back to this year', () async {
      final repo = _repo(
        {
          team(year): [_event('${year}done', '$year-01-02')],
        },
        failing: {team(year + 1)},
      );

      final detected = await repo.detectCurrentEvent();
      expect(detected.key, '${year}done');
      expect(detected.status, EventStatus.past);
    });
  });
}
