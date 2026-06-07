/// A single named alliance picklist — the human pick/veto decisions for an
/// event. Purely a strategy artifact: it sits alongside the TBA-derived
/// ranking (TeamStrength) rather than replacing it. Persisted by
/// [PicklistRepository] as JSON and synced via [SyncRepository].
class Picklist {
  Picklist({
    required this.id,
    required this.name,
    List<int>? picks,
    List<int>? vetoes,
    DateTime? updatedAt,
  })  : picks = picks ?? [],
        vetoes = vetoes ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;

  /// Picked teams in priority order — index 0 is the top pick.
  final List<int> picks;

  /// Vetoed ("do not pick") teams. Unordered.
  final List<int> vetoes;

  /// Last modification time — used by sync to resolve conflicts (remote wins
  /// if its updatedAt is newer than the local copy).
  final DateTime updatedAt;

  Picklist copyWith({
    String? name,
    List<int>? picks,
    List<int>? vetoes,
  }) =>
      Picklist(
        id: id,
        name: name ?? this.name,
        picks: picks ?? this.picks,
        vetoes: vetoes ?? this.vetoes,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'picks': picks,
        'vetoes': vetoes,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
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
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String).toLocal()
            : DateTime.now(),
      );

  /// Parse a row from the Supabase `picklists` table.
  factory Picklist.fromSupabase(Map<String, dynamic> row) => Picklist(
        id: row['id'] as String,
        name: row['name'] as String,
        picks: (row['picks'] as List? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        vetoes: (row['vetoes'] as List? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        updatedAt: row['updated_at'] != null
            ? DateTime.parse(row['updated_at'] as String).toLocal()
            : DateTime.now(),
      );

  Map<String, dynamic> toSupabaseRow() => {
        'id': id,
        'name': name,
        'picks': picks,
        'vetoes': vetoes,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}
