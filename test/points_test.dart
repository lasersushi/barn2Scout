import 'package:barn2scout/data/models/match_bet.dart';
import 'package:barn2scout/data/models/pit_scouting_record.dart';
import 'package:barn2scout/data/models/scout_profile.dart';
import 'package:barn2scout/data/models/scouting_record.dart';
import 'package:barn2scout/data/models/tba_match.dart';
import 'package:barn2scout/data/repositories/assignment_repository.dart';
import 'package:barn2scout/data/repositories/bet_repository.dart';
import 'package:barn2scout/data/repositories/pit_scouting_repository.dart';
import 'package:barn2scout/data/repositories/schedule_repository.dart';
import 'package:barn2scout/data/repositories/scouting_repository.dart';
import 'package:barn2scout/features/points/cubit/points_cubit.dart';
import 'package:barn2scout/features/points/points.dart';
import 'package:flutter_test/flutter_test.dart';

const _event = '2026cacac';
var _seq = 0;

/// Matches start at 10:00 + n minutes on day 1.
DateTime _start(int n) => DateTime(2026, 6, 10, 10, n);

ScoutingRecord report(String? userId, {bool synced = true, String name = ''}) =>
    ScoutingRecord.create(
      uuid: 'r${_seq++}',
      teamNumber: 254,
      matchNumber: 1,
      eventKey: _event,
      scouterName: name,
      timestamp: DateTime(2026, 6, 10),
      synced: synced,
      userId: userId,
    );

PitScoutingRecord pitReport(String? userId) => PitScoutingRecord.create(
      uuid: 'p${_seq++}',
      teamNumber: 254,
      eventKey: _event,
      scouterName: '',
      timestamp: DateTime(2026, 6, 10),
      synced: true,
      userId: userId,
    );

/// Gives each user [n] match reports' worth of points.
List<ScoutingRecord> reports(Map<String, int> counts) => [
      for (final MapEntry(key: user, value: n) in counts.entries)
        for (var i = 0; i < n; i++) report(user),
    ];

/// Qual [n]. [winner] null = unplayed; '' = tie.
TbaMatch qual(int n, {String? winner, bool started = false, bool noTime = false}) {
  final played = winner != null;
  return TbaMatch(
    key: '${_event}_qm$n',
    compLevel: 'qm',
    setNumber: 1,
    matchNumber: n,
    redTeams: const ['frc751', 'frc254', 'frc1678'],
    blueTeams: const ['frc971', 'frc973', 'frc604'],
    redScore: played ? (winner == 'blue' ? 50 : 100) : -1,
    blueScore: played ? (winner == 'red' ? 50 : 100) : -1,
    winningAlliance: winner ?? '',
    actualTime: (played || started) && !noTime ? _start(n) : null,
  );
}

/// A bet on qual [n], placed [minutesBefore] its start (negative = after).
MatchBet bet(
  String userId,
  int n,
  BetSide side,
  int stake, {
  double minutesBefore = 1,
}) =>
    MatchBet(
      id: 'b${_seq++}',
      userId: userId,
      eventKey: _event,
      matchKey: '${_event}_qm$n',
      side: side,
      stake: stake,
      placedAt: _start(n)
          .subtract(Duration(seconds: (minutesBefore * 60).round())),
    );

ScoutProfile profile(String userId, String name) => ScoutProfile.create(
      userId: userId,
      email: '$userId@priorypanther.com',
      displayName: name,
      role: 'scout',
    );

PointsLedger ledger({
  List<ScoutingRecord> records = const [],
  List<PitScoutingRecord> pits = const [],
  List<ScoutProfile> profiles = const [],
  List<MatchBet> bets = const [],
  List<TbaMatch> matches = const [],
  String? me,
}) =>
    buildPointsLedger(
      matchRecords: records,
      pitRecords: pits,
      profiles: profiles,
      bets: bets,
      matches: matches,
      currentUserId: me,
    );

BetResult resultOf(PointsLedger l, MatchBet b) =>
    l.bets.firstWhere((r) => r.bet.id == b.id);

void main() {
  group('earning', () {
    test('every report earns points, attributed like XP', () {
      final l = ledger(
        records: [
          report('a'),
          report(null, synced: false), // mine, not pushed yet
          report(null), // synced but not backfilled — skipped
        ],
        pits: [pitReport('a')],
        me: 'me',
      );
      expect(l.entryFor('a')!.available, kMatchReportPoints + kPitReportPoints);
      expect(l.entryFor('me')!.available, kMatchReportPoints);
      expect(l.standings, hasLength(2));
    });
  });

  group('settling', () {
    test('winners split the losing pool by stake, rounded down', () {
      final a = bet('a', 1, BetSide.red, 10);
      final b = bet('b', 1, BetSide.red, 20);
      final c = bet('c', 1, BetSide.blue, 10);
      final l = ledger(
        records: reports({'a': 3, 'b': 3, 'c': 3}),
        bets: [a, b, c],
        matches: [qual(1, winner: 'red')],
      );
      // Losing pool 10 over winning pool 30: a gets 10*10~/30 = 3, b 6.
      expect(resultOf(l, a).payout, 13);
      expect(resultOf(l, b).payout, 26);
      expect(resultOf(l, c).outcome, BetOutcome.lost);
      expect(l.entryFor('a')!.available, 30 - 10 + 13);
      expect(l.entryFor('b')!.available, 30 - 20 + 26);
      expect(l.entryFor('c')!.available, 30 - 10);
      expect(l.entryFor('a')!.wins, 1);
      expect(l.entryFor('c')!.losses, 1);
      // Nothing left in play once settled.
      expect(l.openPools, isEmpty);
    });

    test('a tie refunds everyone', () {
      final a = bet('a', 1, BetSide.red, 10);
      final b = bet('b', 1, BetSide.blue, 10);
      final l = ledger(
        records: reports({'a': 1, 'b': 1}),
        bets: [a, b],
        matches: [qual(1, winner: '')],
      );
      expect(resultOf(l, a).outcome, BetOutcome.refunded);
      expect(resultOf(l, a).refundReason, 'Tie');
      expect(l.entryFor('a')!.available, 10);
      expect(l.entryFor('b')!.available, 10);
    });

    test('a one-sided pool refunds everyone, right or wrong', () {
      final a = bet('a', 1, BetSide.red, 10);
      final b = bet('b', 2, BetSide.blue, 10);
      final l = ledger(
        records: reports({'a': 1, 'b': 1}),
        bets: [a, b],
        matches: [qual(1, winner: 'red'), qual(2, winner: 'red')],
      );
      expect(resultOf(l, a).outcome, BetOutcome.refunded);
      expect(resultOf(l, b).outcome, BetOutcome.refunded);
      expect(l.entryFor('a')!.available, 10);
      expect(l.entryFor('b')!.available, 10);
    });

    test('unsettled bets stay in play and show in the open pool', () {
      final a = bet('a', 1, BetSide.red, 4);
      final b = bet('b', 1, BetSide.blue, 6);
      final l = ledger(
        records: reports({'a': 1, 'b': 1}),
        bets: [a, b],
        matches: [qual(1)],
      );
      expect(resultOf(l, a).outcome, BetOutcome.pending);
      expect(l.entryFor('a')!.available, 6);
      expect(l.entryFor('a')!.inPlay, 4);
      expect(l.entryFor('a')!.total, 10);
      expect(l.openPools['${_event}_qm1']!.red, 4);
      expect(l.openPools['${_event}_qm1']!.blue, 6);
    });
  });

  group('refunds that protect the game', () {
    test('a bet placed at or after the match start is refunded', () {
      final early = bet('a', 1, BetSide.red, 10);
      final late = bet('b', 1, BetSide.blue, 10, minutesBefore: 0);
      final l = ledger(
        records: reports({'a': 1, 'b': 1}),
        bets: [early, late],
        matches: [qual(1, winner: 'blue')],
      );
      expect(resultOf(l, late).refundReason, 'Placed after the match started');
      // With the late bet out, only Red was backed — so that's refunded too.
      expect(resultOf(l, early).refundReason, 'Only one side was bet on');
      expect(l.entryFor('a')!.available, 10);
    });

    test('a bet on a started match with no result yet is refunded', () {
      final late = bet('a', 1, BetSide.red, 10, minutesBefore: -0.5);
      final l = ledger(
        records: reports({'a': 1}),
        bets: [late],
        matches: [qual(1, started: true)],
      );
      expect(resultOf(l, late).outcome, BetOutcome.refunded);
      expect(isOpenForBets(qual(1, started: true)), isFalse);
    });

    test('a result with no start time to check against is refunded', () {
      final a = bet('a', 1, BetSide.red, 10);
      final b = bet('b', 1, BetSide.blue, 10);
      final l = ledger(
        records: reports({'a': 1, 'b': 1}),
        bets: [a, b],
        matches: [qual(1, winner: 'red', noTime: true)],
      );
      expect(resultOf(l, a).outcome, BetOutcome.refunded);
      expect(l.entryFor('b')!.available, 10);
    });

    test('staking more than you have is refunded', () {
      final greedy = bet('a', 1, BetSide.red, 11);
      final l = ledger(
        records: reports({'a': 1}),
        bets: [greedy],
        matches: [qual(1)],
      );
      expect(resultOf(l, greedy).refundReason, 'Not enough points when placed');
      expect(l.entryFor('a')!.available, 10);
      expect(l.entryFor('a')!.inPlay, 0);
    });

    test('winnings are spendable only after the match they came from', () {
      // a turns 10 into 20 in qual 1, then bets all 20 on qual 3.
      final win = bet('a', 1, BetSide.red, 10);
      final lose = bet('b', 1, BetSide.blue, 10);
      final afterWin = bet('a', 3, BetSide.red, 20);
      final l = ledger(
        records: reports({'a': 1, 'b': 1}),
        bets: [win, lose, afterWin],
        matches: [qual(1, winner: 'red'), qual(3)],
      );
      expect(resultOf(l, afterWin).outcome, BetOutcome.pending);
      expect(l.entryFor('a')!.inPlay, 20);

      // Same bet placed before qual 1 started can't use those winnings yet.
      final tooSoon = bet('a', 3, BetSide.red, 20, minutesBefore: 3);
      final l2 = ledger(
        records: reports({'a': 1, 'b': 1}),
        bets: [win, lose, tooSoon],
        matches: [qual(1, winner: 'red'), qual(3)],
      );
      expect(resultOf(l2, tooSoon).outcome, BetOutcome.refunded);
      expect(l2.entryFor('a')!.available, 20);
    });
  });

  group('standings', () {
    test('ranked by total points, ties share a rank, names from profiles', () {
      final l = ledger(
        records: [
          ...reports({'a': 2, 'b': 1, 'c': 1}),
          report('d', name: 'Dee'),
        ],
        profiles: [profile('a', 'Alex'), profile('b', 'Bo'), profile('c', 'Cy')],
        // b's stake is still in play, so it counts toward b's total.
        bets: [bet('b', 1, BetSide.red, 5)],
        matches: [qual(1)],
        me: 'c',
      );
      expect(l.standings.map((e) => (e.name, e.total, e.rank)), [
        ('Alex', 20, 1),
        ('Bo', 10, 2),
        ('Cy', 10, 2),
        ('Dee', 10, 2),
      ]);
      expect(l.standings.where((e) => e.isMe).single.name, 'Cy');
    });

    test('bets are listed newest first', () {
      final first = bet('a', 1, BetSide.red, 1);
      final second = bet('a', 2, BetSide.red, 1);
      final l = ledger(
        records: reports({'a': 1}),
        bets: [first, second],
        matches: [qual(1), qual(2)],
      );
      expect(l.bets.map((r) => r.bet.id), [second.id, first.id]);
    });
  });

  test('winningsFor never divides by an empty pool', () {
    expect(winningsFor(stake: 5, winningPool: 0, losingPool: 10), 0);
    expect(winningsFor(stake: 5, winningPool: 5, losingPool: 0), 0);
    expect(winningsFor(stake: 5, winningPool: 10, losingPool: 7), 3);
  });

  group('PointsCubit', () {
    late FakeBetRepository bets;
    late FakeScheduleRepository schedule;

    PointsCubit cubit({
      EventStatus status = EventStatus.active,
      List<ScoutingRecord> records = const [],
    }) {
      schedule = FakeScheduleRepository(status)..matches = [qual(1), qual(2)];
      return PointsCubit(
        FakeScoutingRepository(records),
        FakePitScoutingRepository(),
        FakeAssignmentRepository('me'),
        schedule,
        bets,
      );
    }

    setUp(() => bets = FakeBetRepository());

    test('past event → NoEvent', () async {
      final c = cubit(status: EventStatus.past);
      await c.init();
      expect(c.state, isA<PointsNoEvent>());
      await c.close();
    });

    test('loads balance and open matches', () async {
      final c = cubit(records: reports({'me': 2}));
      await c.init();
      await pumpEventQueue();
      final s = c.state as PointsLoaded;
      expect(s.available, 20);
      expect(s.openMatches.map((m) => m.matchNumber), [1, 2]);
      await c.close();
    });

    test('placing a bet saves it and refreshes the balance', () async {
      final c = cubit(records: reports({'me': 2}));
      await c.init();
      await pumpEventQueue();

      final error = await c.placeBet(qual(1), BetSide.blue, 15);
      expect(error, isNull);
      expect(bets.stored.single.stake, 15);
      final s = c.state as PointsLoaded;
      expect(s.available, 5);
      expect(s.myBetOn('${_event}_qm1')!.bet.side, BetSide.blue);

      // One bet per match.
      expect(await c.placeBet(qual(1), BetSide.red, 1), contains('already'));
      expect(bets.stored, hasLength(1));
      await c.close();
    });

    test('rejects a stake over the balance without calling the server',
        () async {
      final c = cubit(records: reports({'me': 1}));
      await c.init();
      await pumpEventQueue();
      expect(await c.placeBet(qual(1), BetSide.red, 11), isNotNull);
      expect(bets.stored, isEmpty);
      await c.close();
    });

    test('a duplicate from another device is reported, not thrown', () async {
      final c = cubit(records: reports({'me': 1}));
      await c.init();
      await pumpEventQueue();
      bets.failWithDuplicate = true;
      expect(await c.placeBet(qual(1), BetSide.red, 5), contains('already'));
      await c.close();
    });

    test('first load failing → error; later failures keep the data', () async {
      bets.fail = true;
      final c = cubit(records: reports({'me': 1}));
      await c.init();
      await pumpEventQueue();
      expect(c.state, isA<PointsError>());

      bets.fail = false;
      await c.refresh();
      expect(c.state, isA<PointsLoaded>());

      bets.fail = true;
      await c.refresh();
      final s = c.state as PointsLoaded;
      expect(s.refreshError, isNotNull);
      expect(s.available, 10);
      await c.close();
    });
  });
}

class FakeBetRepository implements BetRepository {
  final List<MatchBet> stored = [];
  bool fail = false;
  bool failWithDuplicate = false;

  @override
  Future<List<MatchBet>> fetchForEvent(String eventKey) async {
    if (fail) throw Exception('offline');
    return List.of(stored);
  }

  @override
  Future<void> placeBet({
    required String eventKey,
    required String matchKey,
    required BetSide side,
    required int stake,
  }) async {
    if (failWithDuplicate) throw const DuplicateBetException();
    stored.add(MatchBet(
      id: 'b${_seq++}',
      userId: 'me',
      eventKey: eventKey,
      matchKey: matchKey,
      side: side,
      stake: stake,
      placedAt: DateTime(2026, 6, 10, 9),
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakeScheduleRepository implements ScheduleRepository {
  FakeScheduleRepository(this.status);

  final EventStatus status;
  List<TbaMatch> matches = [];

  @override
  Future<({String key, EventStatus status})> detectCurrentEvent() async =>
      (key: _event, status: status);

  @override
  Future<List<TbaMatch>> getMatches(String eventKey) async => matches;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakeScoutingRepository implements ScoutingRepository {
  FakeScoutingRepository(this.records);

  final List<ScoutingRecord> records;

  @override
  Stream<List<ScoutingRecord>> watchForEvent(String eventKey) =>
      Stream.value(records);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakePitScoutingRepository implements PitScoutingRepository {
  @override
  Stream<List<PitScoutingRecord>> watchForEvent(String eventKey) =>
      Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakeAssignmentRepository implements AssignmentRepository {
  FakeAssignmentRepository(this.currentUserId);

  @override
  final String? currentUserId;

  @override
  Stream<List<ScoutProfile>> watchProfiles() => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
