import 'dart:ui' show Offset, Rect, Size;

/// The venue pit map from the FRC Nexus API (/event/{key}/map): the floor
/// layout event volunteers draw, in Nexus's own coordinate space.
///
/// Every element's `position` is its *center*, not its top-left corner (a
/// 20-wide wall at x=10 sits flush with the map edge), so each one is parsed
/// straight into a [Rect]. Any collection may be missing from the response.
class NexusPitMap {
  const NexusPitMap({
    required this.size,
    required this.pits,
    required this.areas,
    required this.labels,
    required this.arrows,
    required this.walls,
  });

  final Size size;
  final List<MapPit> pits;
  final List<MapText> areas; // filled boxes, e.g. "Pit admin"
  final List<MapText> labels; // free-floating text, e.g. "Field"
  final List<MapArrow> arrows;
  final List<Rect> walls;

  /// Parses a `/map` response, or returns null when there's no map (Nexus
  /// sends the string "No map.") or the response has no usable size.
  static NexusPitMap? parse(dynamic data) {
    if (data is! Map) return null;
    final size = data['size'];
    if (size is! Map) return null;
    final width = (size['x'] as num?)?.toDouble() ?? 0;
    final height = (size['y'] as num?)?.toDouble() ?? 0;
    if (width <= 0 || height <= 0) return null;

    Iterable<MapEntry<String, Map>> items(String key) {
      final raw = data[key];
      if (raw is! Map) return const [];
      return raw.entries
          .where((e) => e.value is Map)
          .map((e) => MapEntry(e.key.toString(), e.value as Map));
    }

    MapText text(Map item) =>
        MapText(label: item['label']?.toString() ?? '', rect: _rect(item));

    return NexusPitMap(
      size: Size(width, height),
      pits: [
        for (final e in items('pits'))
          MapPit(
            label: e.key,
            team: _nonEmpty(e.value['team']),
            rect: _rect(e.value),
          ),
      ],
      areas: [for (final e in items('areas')) text(e.value)],
      labels: [for (final e in items('labels')) text(e.value)],
      arrows: [
        for (final e in items('arrows'))
          MapArrow(
            rect: _rect(e.value),
            angleDegrees: (e.value['angle'] as num?)?.toDouble() ?? 0,
            isDouble: e.value['type'] == 'double',
            color: e.value['color']?.toString(),
          ),
      ],
      walls: [for (final e in items('walls')) _rect(e.value)],
    );
  }

  static Rect _rect(Map item) {
    final pos = item['position'] as Map? ?? const {};
    final size = item['size'] as Map? ?? const {};
    return Rect.fromCenter(
      center: Offset(
        (pos['x'] as num?)?.toDouble() ?? 0,
        (pos['y'] as num?)?.toDouble() ?? 0,
      ),
      width: (size['x'] as num?)?.toDouble() ?? 0,
      height: (size['y'] as num?)?.toDouble() ?? 0,
    );
  }

  static String? _nonEmpty(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }
}

/// One pit square. [team] is null for a pit nobody's been assigned to.
class MapPit {
  const MapPit({required this.label, required this.team, required this.rect});

  final String label; // "A1"
  final String? team; // "751"
  final Rect rect;
}

/// A labeled box: an area ("Pit admin") or a free-floating label ("Field").
class MapText {
  const MapText({required this.label, required this.rect});

  final String label;
  final Rect rect;
}

/// A direction arrow. Unrotated it points up; [angleDegrees] turns it
/// clockwise about its center (180 → points down).
class MapArrow {
  const MapArrow({
    required this.rect,
    required this.angleDegrees,
    required this.isDouble,
    required this.color,
  });

  final Rect rect;
  final double angleDegrees;
  final bool isDouble; // double-headed
  final String? color; // Nexus color name: "blue", "purple"
}
