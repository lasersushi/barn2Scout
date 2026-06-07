import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/scouting_record.dart';
import 'scouting_repository.dart';

/// Bidirectional sync between local Isar and Supabase.
///
/// Push: unsynced local records → Supabase (upsert by uuid).
/// Pull: records in Supabase for [eventKey] not yet in Isar → save locally.
class SyncRepository {
  SyncRepository(this._scouting);

  final ScoutingRepository _scouting;
  final _client = Supabase.instance.client;

  Future<void> sync(String eventKey) async {
    if (_client.auth.currentUser == null) return;
    await _push();
    await _pull(eventKey);
  }

  Future<void> _push() async {
    final unsynced = await _scouting.getUnsynced();
    if (unsynced.isEmpty) return;
    final userId = _client.auth.currentUser!.id;

    final rows = unsynced
        .map((r) => {
              'id': r.uuid,
              'user_id': userId,
              'team_number': r.teamNumber,
              'match_number': r.matchNumber,
              'event_key': r.eventKey,
              'scouter_name': r.scouterName,
              'timestamp': r.timestamp.toUtc().toIso8601String(),
              'auto_data': r.autoData,
              'teleop_data': r.teleopData,
              'endgame_data': r.endgameData,
              'notes': r.notes,
            })
        .toList();

    await _client.from('scouting_records').upsert(rows);
    await _scouting.markSynced(unsynced.map((r) => r.uuid));
  }

  Future<void> _pull(String eventKey) async {
    final rows = await _client
        .from('scouting_records')
        .select()
        .eq('event_key', eventKey) as List<dynamic>;

    final existing = await _scouting.getAllUuids();

    for (final raw in rows.cast<Map<String, dynamic>>()) {
      final uuid = raw['id'] as String;
      if (existing.contains(uuid)) continue;

      final record = ScoutingRecord.create(
        uuid: uuid,
        teamNumber: (raw['team_number'] as num).toInt(),
        matchNumber: (raw['match_number'] as num).toInt(),
        eventKey: raw['event_key'] as String,
        scouterName: (raw['scouter_name'] as String?) ?? '',
        timestamp: DateTime.parse(raw['timestamp'] as String).toLocal(),
        autoData:
            (raw['auto_data'] as Map<String, dynamic>?) ?? {},
        teleopData:
            (raw['teleop_data'] as Map<String, dynamic>?) ?? {},
        endgameData:
            (raw['endgame_data'] as Map<String, dynamic>?) ?? {},
        notes: (raw['notes'] as String?) ?? '',
        synced: true,
      );
      await _scouting.save(record);
    }
  }
}
