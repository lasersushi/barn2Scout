import 'package:barn2scout/data/models/pit_scouting_record.dart';
import 'package:barn2scout/data/models/scout_profile.dart';
import 'package:barn2scout/data/models/scouting_record.dart';
import 'package:barn2scout/data/repositories/assignment_repository.dart';
import 'package:barn2scout/data/repositories/pit_scouting_repository.dart';
import 'package:barn2scout/data/repositories/schedule_repository.dart';
import 'package:barn2scout/data/repositories/scouting_repository.dart';
import 'package:barn2scout/features/leaderboard/cubit/leaderboard_cubit.dart';
import 'package:barn2scout/features/leaderboard/xp.dart';
import 'package:flutter_test/flutter_test.dart';

const _event = '2026cacac';
var _seq = 0;

ScoutingRecord match({
  String? userId,
  bool synced = true,
  String notes = '',
  String scouterName = 'Scout',
  Map<String, dynamic> autoData = const {},
  DateTime? at,
}) =>
    ScoutingRecord.create(
      uuid: 'm${_seq++}',
      teamNumber: 254,
      matchNumber: 1,
      eventKey: _event,
      scouterName: scouterName,
      timestamp: at ?? DateTime(2026, 6, 10),
      autoData: autoData,
      notes: notes,
      synced: synced,
      userId: userId,
    );

PitScoutingRecord pit({
  String? userId,
  bool synced = true,
  Map<String, dynamic> pitData = const {},
}) =>
    PitScoutingRecord.create(
      uuid: 'p${_seq++}',
      teamNumber: 254,
      eventKey: _event,
      scouterName: 'Scout',
      timestamp: DateTime(2026, 6, 10),
      pitData: pitData,
      synced: synced,
      userId: userId,
    );

ScoutProfile profile(String userId, String name, {String role = 'scout'}) =>
    ScoutProfile.create(
      userId: userId,
      email: '$userId@priorypanther.com',
      displayName: name,
      role: role,
    );

class FakeScheduleRepository implements ScheduleRepository {
  FakeScheduleRepository(this.status);

  final EventStatus status;

  @override
  Future<({String key, EventStatus status})> detectCurrentEvent() async =>
      (key: _event, status: status);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakeScoutingRepository implements ScoutingRepository {
  List<ScoutingRecord> records = [];
  String? requestedEventKey;

  @override
  Stream<List<ScoutingRecord>> watchForEvent(String eventKey) {
    requestedEventKey = eventKey;
    return Stream.value(records);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakePitScoutingRepository implements PitScoutingRepository {
  List<PitScoutingRecord> records = [];

  @override
  Stream<List<PitScoutingRecord>> watchForEvent(String eventKey) =>
      Stream.value(records);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakeAssignmentRepository implements AssignmentRepository {
  FakeAssignmentRepository(this.currentUserId);

  @override
  final String? currentUserId;

  List<ScoutProfile> profiles = [];

  @override
  Stream<List<ScoutProfile>> watchProfiles() => Stream.value(profiles);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  group('XP rules', () {
    test('base XP per report type', () {
      expect(xpForMatchRecord(match()), kMatchReportXp);
      expect(xpForPitRecord(pit()), kPitReportXp);
    });

    test('notes bonus needs at least $kNotesBonusMinChars characters', () {
      expect(xpForMatchRecord(match(notes: 'x' * 19)), kMatchReportXp);
      expect(
        xpForMatchRecord(match(notes: 'x' * 20)),
        kMatchReportXp + kNotesBonusXp,
      );
      // Surrounding whitespace doesn't count.
      expect(xpForMatchRecord(match(notes: '   ${'x' * 19}   ')),
          kMatchReportXp);
    });

    test('text fields from the game config count toward the bonus', () {
      final r = match(notes: 'x' * 10, autoData: {'auto_notes': 'y' * 10});
      expect(xpForMatchRecord(r), kMatchReportXp + kNotesBonusXp);
    });

    test('pit text fields count toward the bonus', () {
      final r = pit(pitData: {'pit_observations': 'Swerve, very fast intake'});
      expect(xpForPitRecord(r), kPitReportXp + kNotesBonusXp);
    });

    test('non-text fields never count toward the bonus', () {
      final r = pit(pitData: {'pit_drivetrain': 'x' * 40});
      expect(xpForPitRecord(r), kPitReportXp);
    });

    test('levels roll over every $kXpPerLevel XP', () {
      expect(levelFor(0), 1);
      expect(levelFor(99), 1);
      expect(levelFor(100), 2);
      expect(levelProgress(150), 0.5);
    });
  });

  group('buildLeaderboard', () {
    test('unsynced records belong to the current user', () {
      final entries = buildLeaderboard(
        matchRecords: [match(synced: false)],
        pitRecords: [pit(synced: false)],
        profiles: [profile('me', 'Me')],
        currentUserId: 'me',
      );
      expect(entries.single.userId, 'me');
      expect(entries.single.isMe, isTrue);
      expect(entries.single.xp, kMatchReportXp + kPitReportXp);
      expect(entries.single.matchCount, 1);
      expect(entries.single.pitCount, 1);
    });

    test('unsynced records are skipped when signed out', () {
      final entries = buildLeaderboard(
        matchRecords: [match(synced: false)],
        pitRecords: const [],
        profiles: const [],
        currentUserId: null,
      );
      expect(entries, isEmpty);
    });

    test('synced records without a userId are skipped until backfilled', () {
      final entries = buildLeaderboard(
        matchRecords: [match(), match(userId: 'a')],
        pitRecords: const [],
        profiles: const [],
        currentUserId: 'me',
      );
      expect(entries.map((e) => e.userId), ['a']);
    });

    test('name comes from the profile, else the latest scouter name', () {
      final entries = buildLeaderboard(
        matchRecords: [
          match(userId: 'a'),
          match(userId: 'b', scouterName: 'Old', at: DateTime(2026, 6, 1)),
          match(userId: 'b', scouterName: 'New', at: DateTime(2026, 6, 2)),
        ],
        pitRecords: const [],
        profiles: [profile('a', 'Alex')],
        currentUserId: null,
      );
      final names = {for (final e in entries) e.userId: e.name};
      expect(names, {'a': 'Alex', 'b': 'New'});
    });

    test('sorted by XP with tied XP sharing a rank', () {
      final entries = buildLeaderboard(
        matchRecords: [
          match(userId: 'a'),
          match(userId: 'a'),
          match(userId: 'a'),
          match(userId: 'b'),
          match(userId: 'c'),
          match(userId: 'd', synced: false),
        ],
        pitRecords: const [],
        profiles: [
          profile('a', 'Alex'),
          profile('b', 'Bo'),
          profile('c', 'Cy'),
          profile('d', 'Di'),
        ],
        currentUserId: 'd',
      );
      expect(entries.map((e) => e.name), ['Alex', 'Bo', 'Cy', 'Di']);
      expect(entries.map((e) => e.rank), [1, 2, 2, 2]);
      expect(entries.map((e) => e.isMe), [false, false, false, true]);
    });
  });

  group('buildLeaderboard includeIdleScouts', () {
    final profiles = [
      profile('a', 'Alex'),
      profile('b', 'Bo'),
      profile('m', 'Mentor', role: 'admin'),
    ];

    test('off by default: only scouts with reports are listed', () {
      final entries = buildLeaderboard(
        matchRecords: [match(userId: 'a')],
        pitRecords: const [],
        profiles: profiles,
        currentUserId: null,
      );
      expect(entries.map((e) => e.name), ['Alex']);
    });

    test('lists idle non-admin scouts at 0 XP, below scouts with XP', () {
      final entries = buildLeaderboard(
        matchRecords: [match(userId: 'a')],
        pitRecords: const [],
        profiles: profiles,
        currentUserId: null,
        includeIdleScouts: true,
      );
      expect(entries.map((e) => (e.name, e.xp)), [
        ('Alex', kMatchReportXp),
        ('Bo', 0),
      ]);
    });

    test('an admin who filed a report is listed with their XP', () {
      final entries = buildLeaderboard(
        matchRecords: [match(userId: 'm')],
        pitRecords: const [],
        profiles: profiles,
        currentUserId: null,
        includeIdleScouts: true,
      );
      expect(entries.map((e) => e.name), ['Mentor', 'Alex', 'Bo']);
      expect(entries.first.xp, kMatchReportXp);
    });
  });

  group('LeaderboardCubit', () {
    test('past event → NoEvent', () async {
      final cubit = LeaderboardCubit(
        FakeScoutingRepository(),
        FakePitScoutingRepository(),
        FakeAssignmentRepository('me'),
        FakeScheduleRepository(EventStatus.past),
      );
      await cubit.init();
      expect(cubit.state, isA<LeaderboardNoEvent>());
      await cubit.close();
    });

    test('active event → ranks the detected event\'s records', () async {
      final scouting = FakeScoutingRepository()
        ..records = [match(userId: 'a'), match(synced: false)];
      final pits = FakePitScoutingRepository()..records = [pit(userId: 'a')];
      final assignments = FakeAssignmentRepository('me')
        ..profiles = [profile('a', 'Alex'), profile('me', 'Me')];

      final cubit = LeaderboardCubit(
        scouting,
        pits,
        assignments,
        FakeScheduleRepository(EventStatus.active),
      );
      await cubit.init();
      await pumpEventQueue();

      expect(scouting.requestedEventKey, _event);
      final loaded = cubit.state as LeaderboardLoaded;
      expect(loaded.eventKey, _event);
      expect(loaded.entries.map((e) => (e.name, e.xp)), [
        ('Alex', kMatchReportXp + kPitReportXp),
        ('Me', kMatchReportXp),
      ]);
      expect(loaded.me?.rank, 2);
      await cubit.close();
    });

    test('includeIdleScouts lists scouts with no reports', () async {
      final assignments = FakeAssignmentRepository('me')
        ..profiles = [profile('a', 'Alex'), profile('b', 'Bo')];

      final cubit = LeaderboardCubit(
        FakeScoutingRepository()..records = [match(userId: 'a')],
        FakePitScoutingRepository(),
        assignments,
        FakeScheduleRepository(EventStatus.active),
        includeIdleScouts: true,
      );
      await cubit.init();
      await pumpEventQueue();

      final loaded = cubit.state as LeaderboardLoaded;
      expect(loaded.entries.map((e) => (e.name, e.xp)), [
        ('Alex', kMatchReportXp),
        ('Bo', 0),
      ]);
      await cubit.close();
    });
  });
}
