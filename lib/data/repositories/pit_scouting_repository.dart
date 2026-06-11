import 'package:isar_community/isar.dart';

import '../models/pit_scouting_record.dart';

class PitScoutingRepository {
  PitScoutingRepository(this._isar);

  final Isar _isar;

  IsarCollection<PitScoutingRecord> get _records => _isar.pitScoutingRecords;

  Future<void> save(PitScoutingRecord record) =>
      _isar.writeTxn(() => _records.put(record));

  Stream<List<PitScoutingRecord>> watchAll() =>
      _records.where().sortByTimestampDesc().watch(fireImmediately: true);

  /// Live stream of one event's pit records, newest first — the Records tab
  /// only shows the current comp. Unindexed filter; fine at scouting scale.
  Stream<List<PitScoutingRecord>> watchForEvent(String eventKey) => _records
      .filter()
      .eventKeyEqualTo(eventKey)
      .sortByTimestampDesc()
      .watch(fireImmediately: true);

  Future<List<PitScoutingRecord>> getAll() =>
      _records.where().sortByTimestampDesc().findAll();

  Future<List<PitScoutingRecord>> getForTeam(int teamNumber) => _records
      .filter()
      .teamNumberEqualTo(teamNumber)
      .sortByTimestampDesc()
      .findAll();

  Future<Set<String>> getAllUuids() async {
    final all = await _records.where().uuidProperty().findAll();
    return all.toSet();
  }

  Future<List<PitScoutingRecord>> getUnsynced() =>
      _records.filter().syncedEqualTo(false).findAll();

  Future<void> markSynced(Iterable<String> uuids) =>
      _isar.writeTxn(() async {
        for (final uuid in uuids) {
          final record =
              await _records.filter().uuidEqualTo(uuid).findFirst();
          if (record != null) {
            record.synced = true;
            await _records.put(record);
          }
        }
      });

  Future<void> deleteByUuid(String uuid) => _isar.writeTxn(() async {
        final record =
            await _records.filter().uuidEqualTo(uuid).findFirst();
        if (record != null) await _records.delete(record.id);
      });
}
