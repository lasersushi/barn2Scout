import 'dart:convert';

import 'package:isar_community/isar.dart';

part 'team.g.dart';

/// A team we scout, keyed by FRC [teamNumber].
///
/// [capabilities] is intentionally free-form (e.g. `{"canClimb": true,
/// "hasVision": false}`) so pit-scouting questions can change every season
/// without a schema migration. Isar can't persist a `Map`, so it lives as a
/// JSON string in [capabilitiesJson] and is surfaced through the
/// [capabilities] getter/setter.
@collection
class Team {
  /// Isar's local primary key. Not used across devices — see how teams are
  /// looked up by [teamNumber] instead.
  Id id = Isar.autoIncrement;

  /// The real identity. `replace: true` makes re-importing a team an upsert
  /// instead of a duplicate.
  @Index(unique: true, replace: true)
  late int teamNumber;

  late String nickname;

  String? pitNotes;

  /// JSON-encoded `Map<String, bool>`. Read/write via [capabilities].
  late String capabilitiesJson;

  @ignore
  Map<String, bool> get capabilities {
    final decoded = jsonDecode(capabilitiesJson) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as bool));
  }

  set capabilities(Map<String, bool> value) =>
      capabilitiesJson = jsonEncode(value);

  /// Default constructor Isar uses to rebuild objects from the database.
  Team();

  /// Use this when creating a team in app code.
  Team.create({
    required this.teamNumber,
    required this.nickname,
    this.pitNotes,
    Map<String, bool> capabilities = const {},
  }) : capabilitiesJson = jsonEncode(capabilities);
}
