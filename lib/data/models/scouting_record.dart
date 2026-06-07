import 'dart:convert';

import 'package:isar_community/isar.dart';

part 'scouting_record.g.dart';

/// One team's performance in one match, as recorded by one scouter.
///
/// The three phase maps ([autoData], [teleopData], [endgameData]) are
/// free-form so the scouting schema can change each season. Isar can't store a
/// `Map`, so they live as JSON strings and are surfaced through typed
/// getters/setters. Analytics later aggregate over the same string keys.
@collection
class ScoutingRecord {
  /// Isar's local primary key.
  Id id = Isar.autoIncrement;

  /// Stable id that survives across devices (Isar's [id] does not). Used by
  /// Supabase sync and QR export so the same record isn't imported twice.
  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late int teamNumber;

  @Index()
  late int matchNumber;

  late String eventKey;
  late String scouterName;
  late DateTime timestamp;

  /// JSON-encoded phase maps. Read/write via the typed getters below.
  late String autoDataJson;
  late String teleopDataJson;
  late String endgameDataJson;

  late String notes;

  /// False until the record has been pushed to Supabase. The offline sync
  /// queue selects on this, so it's indexed.
  @Index()
  late bool synced;

  @ignore
  Map<String, dynamic> get autoData => _decodeMap(autoDataJson);
  set autoData(Map<String, dynamic> value) => autoDataJson = jsonEncode(value);

  @ignore
  Map<String, dynamic> get teleopData => _decodeMap(teleopDataJson);
  set teleopData(Map<String, dynamic> value) =>
      teleopDataJson = jsonEncode(value);

  @ignore
  Map<String, dynamic> get endgameData => _decodeMap(endgameDataJson);
  set endgameData(Map<String, dynamic> value) =>
      endgameDataJson = jsonEncode(value);

  ScoutingRecord();

  ScoutingRecord.create({
    required this.uuid,
    required this.teamNumber,
    required this.matchNumber,
    required this.eventKey,
    required this.scouterName,
    required this.timestamp,
    Map<String, dynamic> autoData = const {},
    Map<String, dynamic> teleopData = const {},
    Map<String, dynamic> endgameData = const {},
    this.notes = '',
    this.synced = false,
  })  : autoDataJson = jsonEncode(autoData),
        teleopDataJson = jsonEncode(teleopData),
        endgameDataJson = jsonEncode(endgameData);
}

Map<String, dynamic> _decodeMap(String json) =>
    jsonDecode(json) as Map<String, dynamic>;
