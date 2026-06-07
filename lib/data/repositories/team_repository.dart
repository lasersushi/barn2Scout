import 'package:isar_community/isar.dart';

import '../models/team.dart';

/// Reads and writes [Team]s. Teams are upserted from TBA and pit scouting.
class TeamRepository {
  TeamRepository(this._isar);

  final Isar _isar;

  IsarCollection<Team> get _teams => _isar.teams;

  Future<void> upsert(Team team) => _isar.writeTxn(() => _teams.put(team));

  Future<void> upsertAll(List<Team> teams) =>
      _isar.writeTxn(() => _teams.putAll(teams));

  Future<Team?> getByNumber(int teamNumber) =>
      _teams.filter().teamNumberEqualTo(teamNumber).findFirst();

  Future<List<Team>> getAll() => _teams.where().sortByTeamNumber().findAll();

  Stream<List<Team>> watchAll() =>
      _teams.where().sortByTeamNumber().watch(fireImmediately: true);
}
