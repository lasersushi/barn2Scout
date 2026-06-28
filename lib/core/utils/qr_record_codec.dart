import 'dart:convert';

import '../../data/models/scouting_record.dart';

/// Converts [ScoutingRecord]s to/from a compact JSON string for QR codes.
///
/// Short keys keep payload size down — QR codes become harder to scan above
/// ~800 chars, and we typically land at 300–500 chars with this format.
///
/// Key mapping:
///   v        → schema version (always 1 for now)
///   uuid     → uuid
///   team     → teamNumber
///   match    → matchNumber
///   event    → eventKey
///   scouter  → scouterName
///   ts       → timestamp (ms since epoch)
///   auto     → autoDataJson (decoded map, re-encoded inline)
///   teleop   → teleopDataJson
///   eg       → endgameDataJson
///   notes    → notes
class QrRecordCodec {
  QrRecordCodec._();

  /// Encode [record] into a compact JSON string suitable for a QR code.
  static String encode(ScoutingRecord record) {
    final payload = {
      'v': 1,
      'uuid': record.uuid,
      'team': record.teamNumber,
      'match': record.matchNumber,
      'event': record.eventKey,
      'scouter': record.scouterName,
      'ts': record.timestamp.millisecondsSinceEpoch,
      'auto': record.autoData,
      'teleop': record.teleopData,
      'eg': record.endgameData,
      'notes': record.notes,
    };
    return jsonEncode(payload);
  }

  /// Decode a QR string back into a [ScoutingRecord].
  ///
  /// The returned record always has [synced] = false so it goes into the
  /// offline sync queue on the importing device. Isar's `replace: true`
  /// index on uuid prevents duplicates if the same QR is scanned twice.
  ///
  /// Throws [FormatException] if the string is not valid JSON or is missing
  /// required fields.
  static ScoutingRecord decode(String raw) {
    final dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      throw const FormatException('QR payload is not valid JSON');
    }

    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('QR payload must be a JSON object');
    }

    final map = parsed;

    // Validate required fields.
    final uuid = map['uuid'];
    final team = map['team'];
    final match = map['match'];
    final event = map['event'];
    final scouter = map['scouter'];
    final ts = map['ts'];

    if (uuid is! String ||
        team is! int ||
        match is! int ||
        event is! String ||
        scouter is! String ||
        ts is! int) {
      throw const FormatException('QR payload is missing required fields');
    }

    // Phase data — default to empty maps if absent (forward-compat).
    Map<String, dynamic> toMap(dynamic v) =>
        (v is Map<String, dynamic>) ? v : <String, dynamic>{};

    return ScoutingRecord.create(
      uuid: uuid,
      teamNumber: team,
      matchNumber: match,
      eventKey: event,
      scouterName: scouter,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
      autoData: toMap(map['auto']),
      teleopData: toMap(map['teleop']),
      endgameData: toMap(map['eg']),
      notes: (map['notes'] as String?) ?? '',
      synced: false, // always starts unsynced on the importing device
    );
  }
}
