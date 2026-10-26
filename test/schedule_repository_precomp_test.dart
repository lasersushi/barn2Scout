import 'dart:convert';
import 'dart:io';

import 'package:barn2scout/core/config/app_config.dart';
import 'package:barn2scout/data/models/rating_model.dart';
import 'package:barn2scout/data/models/tba_match.dart';
import 'package:barn2scout/data/models/team_rating.dart';
import 'package:barn2scout/data/repositories/event_repository.dart';
import 'package:barn2scout/data/repositories/prior_ratings_store.dart';
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

/// 2026next's qual [number], [red] vs [blue], scored unless [redScore] is null.
TbaMatch _qual(
  int number,
  List<String> red,
  List<String> blue, {
  int? redScore,
  int? blueScore,
}) => TbaMatch(
  key: '2026next_qm$number',
  compLevel: 'qm',
  setNumber: 1,
  matchNumber: number,
  redTeams: red,
  blueTeams: blue,
  redScore: redScore,
  blueScore: blueScore,
  actualTime: redScore == null ? null : DateTime(2026, 3, 6, 9, number),
);

/// Where one scored qual leaves a robot that played it alone: between its
/// [score] and its prior [mu], weighted 1 : λ.
double _blend(num score, num mu, double lambda) =>
    (score + lambda * mu) / (1 + lambda);

/// A repo backed by a fake TBA serving [routes]. [hits] counts requests per
/// path; paths in [failing] return 500. A new repo is a fresh app launch:
/// only what's in [priorStore] carries over.
ScheduleRepository _repo(
  Map<String, Object> routes, {
  Map<String, int>? hits,
  Set<String> failing = const {},
  PriorRatingsStore? priorStore,
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
    priorStore: priorStore,
  );
}

void main() {
  group('ScheduleRepository.fetchTeamRatings pre-comp fallback', () {
    test(
      'uses the current event once a qual is scored and TBA has OPRs',
      () async {
        final ratings = await _repo(_season(currentOprs: {'frc1': 70}))
            .fetchTeamRatings('2026next', [
              _qual(1, ['frc1'], ['frc2'], redScore: 90, blueScore: 30),
            ]);

        expect(ratings.teams.keys, [1]);
        expect(ratings.teams[1]!.opr, 70);
        expect(ratings.teams[1]!.isPreComp, isFalse);
      },
    );

    test('ignores the all-zero OPRs TBA posts with the schedule', () async {
      final ratings =
          await _repo(
            _season(currentOprs: {'frc1': 0, 'frc2': 0, 'frc3': 0}),
          ).fetchTeamRatings('2026next', [
            _qual(1, ['frc1'], ['frc2']),
          ]);

      expect(ratings.teams[1]!.isPreComp, isTrue);
      expect(ratings.model.expectedPoints.keys, ['frc1', 'frc2']);
      expect(ratings.model.expectedPoints['frc1'], closeTo(50, 1e-9));
      expect(ratings.model.expectedPoints['frc2'], closeTo(35, 1e-9));
    });

    test('rates each team from its newest prior event', () async {
      final ratings = await _repo(
        _season(),
      ).fetchTeamRatings('2026next', const []);

      expect(ratings.teams[1]!.opr, 50);
      expect(ratings.teams[1]!.sourceEventKey, '2026lateB');
      expect(ratings.teams[1]!.isPreComp, isTrue);
    });

    test(
      'falls back to an older event when the newest did not rate the team',
      () async {
        final ratings = await _repo(
          _season(),
        ).fetchTeamRatings('2026next', const []);

        expect(ratings.teams[2]!.opr, 35);
        expect(ratings.teams[2]!.sourceEventKey, '2026earlyA');
      },
    );

    test(
      'leaves out teams with no earlier event, and non-roster teams',
      () async {
        final ratings = await _repo(
          _season(),
        ).fetchTeamRatings('2026next', const []);

        expect(ratings.teams.containsKey(3), isFalse);
        // frc9 was rated at lateB but isn't registered for 2026next.
        expect(ratings.teams.containsKey(9), isFalse);
      },
    );

    test('predicts from the borrowed OPRs until a qual is scored', () async {
      final ratings = await _repo(
        _season(),
      ).fetchTeamRatings('2026next', const []);

      expect(ratings.model.expectedPoints.keys, ['frc1', 'frc2']);
      expect(ratings.model.expectedPoints['frc1'], closeTo(50, 1e-9));
      expect(ratings.model.expectedPoints['frc2'], closeTo(35, 1e-9));
      // frc3 has nothing to borrow, so it counts as the borrowed average.
      expect(ratings.model.pointsOf('frc3'), 42.5);
    });

    test('learns from scored quals while TBA has no OPRs yet', () async {
      final ratings = await _repo(_season()).fetchTeamRatings('2026next', [
        _qual(1, ['frc1'], ['frc3'], redScore: 0, blueScore: 300),
      ]);

      // Still borrowed, so still labelled pre-comp…
      expect(ratings.teams[1]!.isPreComp, isTrue);
      // …but the result counts: frc1 between its 0 and its borrowed 50, and
      // frc3 (no prior) between its 300 and the 150-point event average.
      const c = kRatingConfig;
      expect(
        ratings.model.expectedPoints['frc1'],
        closeTo(_blend(0, 50, c.priorWeight), 1e-9),
      );
      expect(
        ratings.model.expectedPoints['frc3'],
        closeTo(_blend(300, 150, c.levelPriorWeight), 1e-9),
      );
    });

    test('fits the current event once TBA has OPRs for it', () async {
      final ratings =
          await _repo(
            _season(currentOprs: {'frc1': 70, 'frc2': 10, 'frc3': 40}),
          ).fetchTeamRatings('2026next', [
            _qual(1, ['frc1'], ['frc3'], redScore: 90, blueScore: 30),
          ]);

      // The event's own ratings are what's shown…
      expect(ratings.teams[1]!.opr, 70);
      expect(ratings.teams[1]!.isPreComp, isFalse);
      // …but the borrowed OPRs stay on as the model's priors: frc1 between
      // its 90 and its borrowed 50, frc3 (no prior) between its 30 and the
      // 60-point average.
      const c = kRatingConfig;
      expect(
        ratings.model.expectedPoints['frc1'],
        closeTo(_blend(90, 50, c.priorWeight), 1e-9),
      );
      expect(
        ratings.model.expectedPoints['frc3'],
        closeTo(_blend(30, 60, c.levelPriorWeight), 1e-9),
      );
    });

    test('fits the current event without priors when they fail', () async {
      final ratings =
          await _repo(
            _season(currentOprs: {'frc1': 70, 'frc2': 10, 'frc3': 40}),
            failing: {'/event/2026next/teams/keys'},
          ).fetchTeamRatings('2026next', [
            _qual(1, ['frc1'], ['frc3'], redScore: 90, blueScore: 30),
          ]);

      expect(ratings.teams[1]!.opr, 70);
      // Both pulled toward the 60-point average alone.
      const c = kRatingConfig;
      expect(
        ratings.model.expectedPoints['frc1'],
        closeTo(_blend(90, 60, c.levelPriorWeight), 1e-9),
      );
      expect(
        ratings.model.expectedPoints['frc3'],
        closeTo(_blend(30, 60, c.levelPriorWeight), 1e-9),
      );
    });

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

      expect(
        (await repo.fetchTeamRatings('2026next', const [])).teams,
        isEmpty,
      );
      await repo.fetchTeamRatings('2026next', const []);

      expect(hits['/event/2026next/teams/keys'], 2);
    });
  });

  group('pre-comp ratings saved for offline', () {
    late Directory tmp;
    late PriorRatingsStore store;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('prior_ratings_test');
      store = PriorRatingsStore(directoryOverride: tmp.path);
    });
    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    final teamPaths = {
      for (final t in ['frc1', 'frc2', 'frc3']) '/team/$t/events/2026/simple',
    };

    test('a failed fetch falls back to the saved ratings', () async {
      await _repo(
        _season(),
        priorStore: store,
      ).fetchTeamRatings('2026next', const []);

      final ratings = await _repo(
        _season(),
        failing: teamPaths,
        priorStore: store,
      ).fetchTeamRatings('2026next', const []);

      expect(ratings.teams[1]!.opr, 50);
      expect(ratings.teams[1]!.sourceEventKey, '2026lateB');
      expect(ratings.model.expectedPoints['frc2'], closeTo(35, 1e-9));
    });

    test(
      'once quals have started, a relaunch never asks TBA for them',
      () async {
        final scored = [
          _qual(1, ['frc1'], ['frc3'], redScore: 90, blueScore: 30),
        ];
        final current = _season(currentOprs: {'frc1': 70, 'frc3': 40});
        await _repo(
          current,
          priorStore: store,
        ).fetchTeamRatings('2026next', scored);

        final hits = <String, int>{};
        final ratings = await _repo(
          current,
          hits: hits,
          priorStore: store,
        ).fetchTeamRatings('2026next', scored);

        expect(hits.containsKey('/event/2026next/teams/keys'), isFalse);
        expect(hits.keys.where(teamPaths.contains), isEmpty);
        // Same fit as with the network: frc1 still has its borrowed prior.
        expect(
          ratings.model.expectedPoints['frc1'],
          closeTo(_blend(90, 50, kRatingConfig.priorWeight), 1e-9),
        );
      },
    );

    test('before quals, a relaunch still fetches them fresh', () async {
      await _repo(
        _season(),
        priorStore: store,
      ).fetchTeamRatings('2026next', const []);

      final hits = <String, int>{};
      await _repo(
        _season(),
        hits: hits,
        priorStore: store,
      ).fetchTeamRatings('2026next', const []);

      // A team's newest event could still finish before this one starts.
      expect(hits['/event/2026next/teams/keys'], 1);
    });

    test('a corrupt file counts as nothing saved', () async {
      final file = File('${tmp.path}/prior_ratings/2026next.json');
      await file.parent.create(recursive: true);
      await file.writeAsString('{not json');

      expect(await store.read('2026next'), isNull);
    });

    test('keep every field through JSON', () {
      const full = TeamRating(
        team: 254,
        opr: 101.5,
        dpr: 40,
        ccwm: 61.5,
        avgRp: 3.25,
        winRate: 0.75,
        wins: 9,
        losses: 3,
        ties: 0,
        rank: 2,
        scoreMean: 210.5,
        scoreStd: 30.25,
        matchesPlayed: 12,
        contribMedian: 98,
        contribStd: 12.5,
        lowMatchCount: 1,
        sourceEventKey: '2026casj',
      );
      const sparse = TeamRating(team: 9999, opr: 1, dpr: 2, ccwm: -1);

      for (final r in [full, sparse]) {
        final back = TeamRating.fromJson(
          jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,
        );
        expect(back.toJson(), r.toJson());
      }
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
