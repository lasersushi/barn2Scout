import 'package:barn2scout/data/models/pit_scouting_record.dart';
import 'package:barn2scout/data/models/scouting_record.dart';
import 'package:barn2scout/data/repositories/pit_scouting_repository.dart';
import 'package:barn2scout/data/repositories/schedule_repository.dart';
import 'package:barn2scout/data/repositories/scouting_repository.dart';
import 'package:barn2scout/features/records/cubit/pit_records_cubit.dart';
import 'package:barn2scout/features/records/cubit/records_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scriptable [ScheduleRepository] — only event detection is implemented.
class FakeScheduleRepository implements ScheduleRepository {
  FakeScheduleRepository(this.key, this.status);

  String key;
  EventStatus status;

  @override
  Future<({String key, EventStatus status})> detectCurrentEvent() async =>
      (key: key, status: status);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Scriptable [ScoutingRepository] — records the event key it was asked for.
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
  String? requestedEventKey;

  @override
  Stream<List<PitScoutingRecord>> watchForEvent(String eventKey) {
    requestedEventKey = eventKey;
    return Stream.value(records);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

ScoutingRecord record(String eventKey) => ScoutingRecord.create(
      uuid: 'uuid-$eventKey',
      teamNumber: 751,
      matchNumber: 1,
      eventKey: eventKey,
      scouterName: 'Test Scout',
      timestamp: DateTime(2026, 6, 10),
    );

void main() {
  group('RecordsCubit', () {
    test('active comp → loads records for the detected key', () async {
      final schedule = FakeScheduleRepository('2026cacac', EventStatus.active);
      final repo = FakeScoutingRepository()..records = [record('2026cacac')];

      final cubit = RecordsCubit(repo, schedule);
      await cubit.init();
      await pumpEventQueue();

      expect(repo.requestedEventKey, '2026cacac');
      expect(cubit.state, isA<RecordsLoaded>());
      final loaded = cubit.state as RecordsLoaded;
      expect(loaded.records.single.eventKey, '2026cacac');
      await cubit.close();
    });

    test('upcoming comp also counts as a comp', () async {
      final schedule =
          FakeScheduleRepository('2026casj', EventStatus.upcoming);
      final repo = FakeScoutingRepository();

      final cubit = RecordsCubit(repo, schedule);
      await cubit.init();
      await pumpEventQueue();

      expect(cubit.state, isA<RecordsLoaded>());
      expect(repo.requestedEventKey, '2026casj');
      await cubit.close();
    });

    test('no comp (status past) → NoEvent, never touches the repo', () async {
      final schedule = FakeScheduleRepository('2026cacac', EventStatus.past);
      final repo = FakeScoutingRepository();

      final cubit = RecordsCubit(repo, schedule);
      await cubit.init();

      expect(cubit.state, isA<RecordsNoEvent>());
      expect(repo.requestedEventKey, isNull);
      await cubit.close();
    });

    test('re-running init picks up a changed event (override set)', () async {
      // Simulates: no comp at startup → user sets the event override in
      // Settings → the page listener calls init() again.
      final schedule = FakeScheduleRepository('2026cacac', EventStatus.past);
      final repo = FakeScoutingRepository()..records = [record('2026cacac')];

      final cubit = RecordsCubit(repo, schedule);
      await cubit.init();
      expect(cubit.state, isA<RecordsNoEvent>());

      // Override forces the old comp to report as active.
      schedule.status = EventStatus.active;
      await cubit.init();
      await pumpEventQueue();

      expect(cubit.state, isA<RecordsLoaded>());
      expect(repo.requestedEventKey, '2026cacac');
      await cubit.close();
    });

    test('starts in loading state', () {
      final cubit = RecordsCubit(
        FakeScoutingRepository(),
        FakeScheduleRepository('x', EventStatus.past),
      );
      expect(cubit.state, isA<RecordsLoading>());
      cubit.close();
    });
  });

  group('PitRecordsCubit', () {
    test('active comp → loads pit records for the detected key', () async {
      final schedule = FakeScheduleRepository('2026cacac', EventStatus.active);
      final repo = FakePitScoutingRepository()
        ..records = [
          PitScoutingRecord.create(
            uuid: 'pit-1',
            teamNumber: 2135,
            eventKey: '2026cacac',
            scouterName: 'Test Scout',
            timestamp: DateTime(2026, 6, 10),
          ),
        ];

      final cubit = PitRecordsCubit(repo, schedule);
      await cubit.init();
      await pumpEventQueue();

      expect(repo.requestedEventKey, '2026cacac');
      expect(cubit.state, isA<PitRecordsLoaded>());
      await cubit.close();
    });

    test('no comp → NoEvent', () async {
      final cubit = PitRecordsCubit(
        FakePitScoutingRepository(),
        FakeScheduleRepository('2026cacac', EventStatus.past),
      );
      await cubit.init();
      expect(cubit.state, isA<PitRecordsNoEvent>());
      await cubit.close();
    });
  });
}
