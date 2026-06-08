import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/picklist.dart';
import '../models/pit_scouting_record.dart';
import '../models/scouting_record.dart';
import 'picklist_repository.dart';
import 'pit_scouting_repository.dart';
import 'scouting_repository.dart';

/// Bidirectional sync between local storage and Supabase.
///
/// Match records: push unsynced → Supabase; pull new by event key.
/// Pit records: same pattern, separate table.
/// Picklists: push all local → Supabase (upsert); pull all remote and merge
/// (remote wins when updatedAt is newer).
class SyncRepository {
  SyncRepository(this._scouting, this._picklists, this._pitScouting);

  final ScoutingRepository _scouting;
  final PicklistRepository _picklists;
  final PitScoutingRepository _pitScouting;
  final _client = Supabase.instance.client;

  bool get _authenticated => _client.auth.currentUser != null;

  // ── Full sync ─────────────────────────────────────────────────────────────

  Future<void> sync(String eventKey) async {
    if (!_authenticated) return;
    await pushRecords();
    await pullRecords(eventKey);
    await pushPitRecords();
    await pullPitRecords(eventKey);
    await pushPicklists();
    await pullPicklists();
  }

  // ── Scouting records ─────────────────────────────────────────────────────

  Future<void> pushRecords() async {
    if (!_authenticated) return;
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

  Future<void> pullRecords(String eventKey) async {
    if (!_authenticated) return;
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
        autoData: (raw['auto_data'] as Map<String, dynamic>?) ?? {},
        teleopData: (raw['teleop_data'] as Map<String, dynamic>?) ?? {},
        endgameData: (raw['endgame_data'] as Map<String, dynamic>?) ?? {},
        notes: (raw['notes'] as String?) ?? '',
        synced: true,
      );
      await _scouting.save(record);
    }
  }

  // ── Pit scouting records ──────────────────────────────────────────────────

  Future<void> pushPitRecords() async {
    if (!_authenticated) return;
    final unsynced = await _pitScouting.getUnsynced();
    if (unsynced.isEmpty) return;
    final userId = _client.auth.currentUser!.id;

    final rows = unsynced
        .map((r) => {
              'id': r.uuid,
              'user_id': userId,
              'team_number': r.teamNumber,
              'event_key': r.eventKey,
              'scouter_name': r.scouterName,
              'timestamp': r.timestamp.toUtc().toIso8601String(),
              'pit_data': r.pitData,
              'notes': r.notes,
            })
        .toList();

    await _client.from('pit_scouting_records').upsert(rows);
    await _pitScouting.markSynced(unsynced.map((r) => r.uuid));
  }

  Future<void> pullPitRecords(String eventKey) async {
    if (!_authenticated) return;
    final rows = await _client
        .from('pit_scouting_records')
        .select()
        .eq('event_key', eventKey) as List<dynamic>;

    final existing = await _pitScouting.getAllUuids();

    for (final raw in rows.cast<Map<String, dynamic>>()) {
      final uuid = raw['id'] as String;
      if (existing.contains(uuid)) continue;

      final record = PitScoutingRecord.create(
        uuid: uuid,
        teamNumber: (raw['team_number'] as num).toInt(),
        eventKey: raw['event_key'] as String,
        scouterName: (raw['scouter_name'] as String?) ?? '',
        timestamp: DateTime.parse(raw['timestamp'] as String).toLocal(),
        pitData: (raw['pit_data'] as Map<String, dynamic>?) ?? {},
        notes: (raw['notes'] as String?) ?? '',
        synced: true,
      );
      await _pitScouting.save(record);
    }
  }

  // ── Picklists ─────────────────────────────────────────────────────────────

  Future<void> pushPicklists() async {
    if (!_authenticated) return;
    final rows = _picklists.lists.map((l) => l.toSupabaseRow()).toList();
    if (rows.isEmpty) return;
    await _client.from('picklists').upsert(rows);
  }

  Future<void> pullPicklists() async {
    if (!_authenticated) return;
    final rows = await _client.from('picklists').select() as List<dynamic>;
    if (rows.isEmpty) return;

    final remote = rows
        .cast<Map<String, dynamic>>()
        .map(Picklist.fromSupabase)
        .toList();

    // Merge: build a map of local lists by id, then overlay remote entries
    // that are newer (or missing locally).
    final localById = {for (final l in _picklists.lists) l.id: l};
    for (final r in remote) {
      final local = localById[r.id];
      if (local == null || r.updatedAt.isAfter(local.updatedAt)) {
        localById[r.id] = r;
      }
    }

    final merged = localById.values.toList();
    final activeId = _picklists.activeId;
    final validActive = merged.any((l) => l.id == activeId)
        ? activeId
        : merged.first.id;
    await _picklists.persist(merged, validActive);
  }
}
