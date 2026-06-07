/// A single named alliance picklist — the human pick/veto decisions for an
/// event. Purely a strategy artifact: it sits alongside the TBA-derived
/// ranking (TeamStrength) rather than replacing it. Persisted by
/// [PicklistRepository] as JSON.
class Picklist {
  Picklist({
    required this.id,
    required this.name,
    List<int>? picks,
    List<int>? vetoes,
  })  : picks = picks ?? [],
        vetoes = vetoes ?? [];

  /// Stable id (a uuid for user-created lists). Used to select the active list.
  final String id;

  /// User-facing label, e.g. "Main" or "Backup".
  final String name;

  /// Picked teams in priority order — index 0 is the top pick.
  final List<int> picks;

  /// Vetoed ("do not pick") teams. Unordered.
  final List<int> vetoes;

  Picklist copyWith({String? name, List<int>? picks, List<int>? vetoes}) =>
      Picklist(
        id: id,
        name: name ?? this.name,
        picks: picks ?? this.picks,
        vetoes: vetoes ?? this.vetoes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'picks': picks,
        'vetoes': vetoes,
      };

  factory Picklist.fromJson(Map<String, dynamic> json) => Picklist(
        id: json['id'] as String,
        name: json['name'] as String,
        picks: (json['picks'] as List? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        vetoes: (json['vetoes'] as List? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
      );
}
