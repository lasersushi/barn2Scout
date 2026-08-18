import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pit_assignment.dart';
import '../models/scout_profile.dart';

class AssignmentRepository {
  AssignmentRepository(this._isar);

  final Isar _isar;
  final _client = Supabase.instance.client;

  IsarCollection<PitAssignment> get _assignments => _isar.pitAssignments;
  IsarCollection<ScoutProfile> get _profiles => _isar.scoutProfiles;

  String? get _currentUserId => _client.auth.currentUser?.id;

  Stream<List<PitAssignment>> watchForEvent(String eventKey) => _assignments
      .filter()
      .eventKeyEqualTo(eventKey)
      .sortByTeamNumber()
      .watch(fireImmediately: true);

  Stream<List<PitAssignment>> watchForScout(String eventKey, String userId) =>
      _assignments
          .filter()
          .eventKeyEqualTo(eventKey)
          .and()
          .userIdEqualTo(userId)
          .sortByTeamNumber()
          .watch(fireImmediately: true);

  Stream<List<PitAssignment>> watchMine(String eventKey) {
    final uid = _currentUserId;
    if (uid == null) return Stream.value(const []);
    return watchForScout(eventKey, uid);
  }

  Future<List<PitAssignment>> getForEvent(String eventKey) => _assignments
      .filter()
      .eventKeyEqualTo(eventKey)
      .sortByTeamNumber()
      .findAll();

  Stream<List<ScoutProfile>> watchProfiles() =>
      _profiles.where().watch(fireImmediately: true);

  Future<List<ScoutProfile>> getProfiles() => _profiles.where().findAll();

  Future<ScoutProfile?> getProfile(String userId) =>
      _profiles.filter().userIdEqualTo(userId).findFirst();

  Future<void> setAssignments(
    String eventKey,
    String userId,
    Set<int> teams,
  ) async {
    final assignedBy = _currentUserId;
    if (assignedBy == null) throw StateError('Not signed in.');

    final removed = (await getForEvent(eventKey))
        .where((a) => a.userId == userId && !teams.contains(a.teamNumber))
        .map((a) => a.teamNumber)
        .toList();

    if (removed.isNotEmpty) {
      await _client
          .from('pit_assignments')
          .delete()
          .eq('event_key', eventKey)
          .eq('user_id', userId)
          .inFilter('team_number', removed);
    }

    if (teams.isNotEmpty) {
      await _client.from('pit_assignments').upsert(
        [
          for (final team in teams)
            {
              'event_key': eventKey,
              'team_number': team,
              'user_id': userId,
              'assigned_by': assignedBy,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
        ],
        onConflict: 'event_key,team_number',
      );
    }

    await pullForEvent(eventKey);
  }

  Future<void> unassign(String eventKey, int teamNumber) async {
    await _client
        .from('pit_assignments')
        .delete()
        .eq('event_key', eventKey)
        .eq('team_number', teamNumber);
    await pullForEvent(eventKey);
  }

  Future<void> pullForEvent(String eventKey) async {
    if (_client.auth.currentUser == null) return;

    final rows = await _client
        .from('pit_assignments')
        .select()
        .eq('event_key', eventKey) as List<dynamic>;

    final fresh = rows
        .cast<Map<String, dynamic>>()
        .map(PitAssignment.fromSupabase)
        .toList();

    await _isar.writeTxn(() async {
      final stale = await _assignments
          .filter()
          .eventKeyEqualTo(eventKey)
          .findAll();
      await _assignments.deleteAll([for (final a in stale) a.id]);
      await _assignments.putAll(fresh);
    });
  }

  Future<void> pullProfiles() async {
    if (_client.auth.currentUser == null) return;

    final rows = await _client.from('profiles').select() as List<dynamic>;
    final fresh = rows
        .cast<Map<String, dynamic>>()
        .map(ScoutProfile.fromSupabase)
        .toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ));

    await _isar.writeTxn(() async {
      await _profiles.clear();
      await _profiles.putAll(fresh);
    });
  }
}
