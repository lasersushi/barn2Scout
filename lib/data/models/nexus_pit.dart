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

  /// Parse a Nexus `/pits` response into a list sorted by row, then slot.
  ///
  /// Nexus keys the object by *team*, not pit: `{"751": "C1", "254": "A3"}`
  /// (verified against live 2026 events). Reading it the other way round
  /// made every team its own one-tile "row". Anything else, e.g. the
  /// "No pits." string, yields an empty list.
  static List<NexusPit> parseResponse(dynamic data) {
    final pits = <NexusPit>[];

    if (data is Map) {
      for (final entry in data.entries) {
        final lbl = entry.value?.toString().trim();
        if (lbl == null || lbl.isEmpty) continue;
        pits.add(NexusPit(teamNumber: entry.key.toString(), label: lbl));
      }
    }

    pits.sort((a, b) {
      final rowCmp = a.row.compareTo(b.row);
      return rowCmp != 0 ? rowCmp : a.slot.compareTo(b.slot);
    });

    return pits;
  }
}
