/// A single FRC match from the TBA API (/event/{key}/matches/simple).
class TbaMatch {
  const TbaMatch({
    required this.key,
    required this.compLevel,
    required this.setNumber,
    required this.matchNumber,
    required this.redTeams,
    required this.blueTeams,
    this.redScore,
    this.blueScore,
    this.winningAlliance,
    this.scheduledTime,
    this.predictedTime,
    this.actualTime,
  });

  final String key;
  final String compLevel; // "qm" | "ef" | "qf" | "sf" | "f"
  final int setNumber;
  final int matchNumber;
  final List<String> redTeams; // e.g. ["frc751", "frc254", "frc1678"]
  final List<String> blueTeams;
  final int? redScore;
  final int? blueScore;
  final String? winningAlliance; // "red" | "blue" | "" | null
  final DateTime? scheduledTime;
  final DateTime? predictedTime;
  final DateTime? actualTime;

  /// Human-readable label: "Qual 3", "Semi 2-1", "Final 1", etc.
  String get label {
    switch (compLevel) {
      case 'qm':
        return 'Qual $matchNumber';
      case 'ef':
        return 'Octo $setNumber-$matchNumber';
      case 'qf':
        return 'Quarter $setNumber-$matchNumber';
      case 'sf':
        return 'Semi $setNumber-$matchNumber';
      case 'f':
        return 'Final $matchNumber';
      default:
        return key;
    }
  }

  /// Numeric sort key so matches appear in competition order.
  int get sortKey {
    const order = {'ef': 0, 'qm': 1, 'qf': 2, 'sf': 3, 'f': 4};
    return (order[compLevel] ?? 5) * 1000000 + setNumber * 1000 + matchNumber;
  }

  bool get isPlayed => actualTime != null && (redScore ?? -1) >= 0;

  /// Which alliance is [teamKey] on, or null if not in this match.
  String? allianceFor(String teamKey) {
    if (redTeams.contains(teamKey)) return 'red';
    if (blueTeams.contains(teamKey)) return 'blue';
    return null;
  }

  bool containsTeam(String teamKey) => allianceFor(teamKey) != null;

  /// Strip the "frc" prefix for display: "frc751" → "751".
  static String displayNumber(String teamKey) =>
      teamKey.replaceFirst('frc', '');

  factory TbaMatch.fromJson(Map<String, dynamic> json) {
    final alliances = json['alliances'] as Map<String, dynamic>;
    final red = alliances['red'] as Map<String, dynamic>;
    final blue = alliances['blue'] as Map<String, dynamic>;

    DateTime? parseUnix(dynamic v) => v == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch((v as int) * 1000);

    return TbaMatch(
      key: json['key'] as String,
      compLevel: json['comp_level'] as String,
      setNumber: json['set_number'] as int,
      matchNumber: json['match_number'] as int,
      redTeams: (red['team_keys'] as List).cast<String>(),
      blueTeams: (blue['team_keys'] as List).cast<String>(),
      redScore: red['score'] as int?,
      blueScore: blue['score'] as int?,
      winningAlliance: json['winning_alliance'] as String?,
      scheduledTime: parseUnix(json['time']),
      predictedTime: parseUnix(json['predicted_time']),
      actualTime: parseUnix(json['actual_time']),
    );
  }
}
