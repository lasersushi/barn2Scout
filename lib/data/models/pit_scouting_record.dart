import 'dart:convert';

import 'package:isar_community/isar.dart';

part 'pit_scouting_record.g.dart';

/// One team's pit observation, recorded by one scouter.
///
/// All field values live in a single JSON blob so the pit config can evolve
/// without DB migrations — the same pattern as [ScoutingRecord]'s phase maps.
@collection
class PitScoutingRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late int teamNumber;

  late String eventKey;
  late String scouterName;
  late DateTime timestamp;

  late String pitDataJson;
  late String notes;

  @Index()
  late bool synced;

  @ignore
  Map<String, dynamic> get pitData => _decodeMap(pitDataJson);
  set pitData(Map<String, dynamic> value) => pitDataJson = jsonEncode(value);

  PitScoutingRecord();

  PitScoutingRecord.create({
    required this.uuid,
    required this.teamNumber,
    required this.eventKey,
    required this.scouterName,
    required this.timestamp,
    Map<String, dynamic> pitData = const {},
    this.notes = '',
    this.synced = false,
  }) : pitDataJson = jsonEncode(pitData);
}

Map<String, dynamic> _decodeMap(String json) =>
    jsonDecode(json) as Map<String, dynamic>;
