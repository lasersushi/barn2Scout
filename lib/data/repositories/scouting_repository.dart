import 'package:isar_community/isar.dart';

import '../models/scouting_record.dart';

/// Reads and writes [ScoutingRecord]s. UI and Blocs go through here, never
/// straight to Isar.
class ScoutingRepository {
  ScoutingRepository(this._isar);

  final Isar _isar;

  IsarCollection<ScoutingRecord> get _records => _isar.scoutingRecords;

  /// Upsert by uuid (its unique index uses `replace: true`, so re-saving an
  /// edited record overwrites rather than duplicates).
  Future<void> save(ScoutingRecord record) =>
      _isar.writeTxn(() => _records.put(record));

  /// All records, newest first, as a live stream so the UI updates the moment
  /// a record is saved.
  Stream<List<ScoutingRecord>> watchAll() =>
      _records.where().sortByTimestampDesc().watch(fireImmediately: true);

  Future<List<ScoutingRecord>> getAll() =>
      _records.where().sortByTimestampDesc().findAll();

  Future<List<ScoutingRecord>> getForTeam(int teamNumber) => _records
      .filter()
      .teamNumberEqualTo(teamNumber)
      .sortByTimestampDesc()
      .findAll();

  /// Records not yet pushed to Supabase — i.e. the offline sync queue.
  Future<List<ScoutingRecord>> getUnsynced() =>
      _records.filter().syncedEqualTo(false).findAll();

  /// Flip [ScoutingRecord.synced] to true once Supabase has accepted them.
  Future<void> markSynced(Iterable<String> uuids) => _isar.writeTxn(() async {
        for (final uuid in uuids) {
          final record = await _records.filter().uuidEqualTo(uuid).findFirst();
          if (record != null) {
            record.synced = true;
            await _records.put(record);
          }
        }
      });

  Future<void> deleteByUuid(String uuid) => _isar.writeTxn(() async {
        final record = await _records.filter().uuidEqualTo(uuid).findFirst();
        if (record != null) {
          await _records.delete(record.id);
        }
      });
}
