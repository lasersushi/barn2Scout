import 'dart:convert';

import '../../data/models/pit_scouting_record.dart';
import '../../data/models/scouting_record.dart';

/// Result of decoding a scanned QR — either a match or a pit record.
/// `switch` on the subtype to save it to the right repository.
sealed class QrPayload {
  const QrPayload();
}

class MatchQrPayload extends QrPayload {
  const MatchQrPayload(this.record);
  final ScoutingRecord record;
}

class PitQrPayload extends QrPayload {
  const PitQrPayload(this.record);
  final PitScoutingRecord record;
}

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

  /// Encode a pit [record] into a compact JSON string for a QR code.
  ///
  /// Pit payloads carry `'t': 'pit'` so [decodeAny] can route them; match
  /// payloads have no tag — that keeps every already-shared match QR valid.
  static String encodePit(PitScoutingRecord record) {
    final payload = {
      'v': 1,
      't': 'pit',
      'uuid': record.uuid,
      'team': record.teamNumber,
      'event': record.eventKey,
      'scouter': record.scouterName,
      'ts': record.timestamp.millisecondsSinceEpoch,
      'pit': record.pitData,
      'notes': record.notes,
    };
    return jsonEncode(payload);
  }

  /// Decode a scanned QR string into either record type.
  ///
  /// Throws [FormatException] for anything that isn't a Barn2Scout payload.
  static QrPayload decodeAny(String raw) {
    final map = _parseObject(raw);
    return map['t'] == 'pit'
        ? PitQrPayload(_decodePit(map))
        : MatchQrPayload(_decodeMatch(map));
  }

  /// Decode a QR string back into a [ScoutingRecord].
  ///
  /// The returned record always has [synced] = false so it goes into the
  /// offline sync queue on the importing device. Isar's `replace: true`
  /// index on uuid prevents duplicates if the same QR is scanned twice.
  ///
  /// Throws [FormatException] if the string is not valid JSON or is missing
  /// required fields.
  static ScoutingRecord decode(String raw) => _decodeMatch(_parseObject(raw));

  static Map<String, dynamic> _parseObject(String raw) {
    final dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      throw const FormatException('QR payload is not valid JSON');
    }

    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('QR payload must be a JSON object');
    }
    return parsed;
  }

  static ScoutingRecord _decodeMatch(Map<String, dynamic> map) {

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

  static PitScoutingRecord _decodePit(Map<String, dynamic> map) {
    final uuid = map['uuid'];
    final team = map['team'];
    final event = map['event'];
    final scouter = map['scouter'];
    final ts = map['ts'];

    if (uuid is! String ||
        team is! int ||
        event is! String ||
        scouter is! String ||
        ts is! int) {
      throw const FormatException('QR payload is missing required fields');
    }

    final pitData = map['pit'];

    return PitScoutingRecord.create(
      uuid: uuid,
      teamNumber: team,
      eventKey: event,
      scouterName: scouter,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
      pitData:
          (pitData is Map<String, dynamic>) ? pitData : <String, dynamic>{},
      notes: (map['notes'] as String?) ?? '',
      synced: false, // always starts unsynced on the importing device
    );
  }
}
