/// A single pit assignment from the FRC Nexus API (/event/{key}/pits).
///
/// Nexus uses plain team number strings ("751"), not TBA-style keys.
/// The [label] is a pit identifier like "A1", "B3", "C12", etc.
class NexusPit {
  const NexusPit({required this.teamNumber, required this.label});

  final String teamNumber; // "751"
  final String label; // "A1"

  /// Row letter extracted from the label ("A1" → "A"). Falls back to the
  /// full label if it doesn't start with a letter.
  String get row {
    if (label.isNotEmpty && RegExp(r'^[A-Za-z]').hasMatch(label)) {
      return label[0].toUpperCase();
    }
    return label;
  }

  /// Slot number within the row ("A1" → 1, "A12" → 12).
  int get slot {
    final digits = label.replaceFirst(RegExp(r'^[A-Za-z]+'), '');
    return int.tryParse(digits) ?? 0;
  }

  /// Parse whatever shape Nexus sends — list or map — into a sorted list.
  ///
  /// Nexus has been observed returning either:
  ///   - A JSON array: [{"label": "A1", "team": "751"}, ...]
  ///   - A JSON object: {"A1": "751", ...} or {"A1": {"team": "751"}, ...}
  static List<NexusPit> parseResponse(dynamic data) {
    final pits = <NexusPit>[];

    if (data is List) {
      for (final item in data.cast<Map<String, dynamic>>()) {
        final team = (item['team'] ?? item['teamNumber'] ?? item['number'])
            ?.toString();
        final lbl = (item['label'] ?? item['pit'] ?? item['location'])
            ?.toString();
        if (team != null && lbl != null) {
          pits.add(NexusPit(teamNumber: team, label: lbl));
        }
      }
    } else if (data is Map) {
      for (final entry in data.entries) {
        final lbl = entry.key.toString();
        final value = entry.value;
        final team = value is Map
            ? (value['team'] ?? value['teamNumber'])?.toString()
            : value?.toString();
        if (team != null) {
          pits.add(NexusPit(teamNumber: team, label: lbl));
        }
      }
    }

    pits.sort((a, b) {
      final rowCmp = a.row.compareTo(b.row);
      return rowCmp != 0 ? rowCmp : a.slot.compareTo(b.slot);
    });

    return pits;
  }
}
