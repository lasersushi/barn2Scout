/// A single match entry from the FRC Nexus API (/event/{key}).
///
/// Nexus uses plain team number strings ("751"), not TBA-style keys ("frc751").
/// Team slots can be null when the alliance isn't yet assigned.
class NexusMatch {
  const NexusMatch({
    required this.label,
    required this.status,
    required this.redTeams,
    required this.blueTeams,
    this.estimatedQueueTime,
    this.estimatedStartTime,
  });

  final String label; // "Qual 3", "Practice 1", etc.

  /// Live queue status string from Nexus.
  /// Common values: "Upcoming", "Now queuing", "On deck", "On field".
  final String status;

  final List<String?> redTeams; // null = slot not yet assigned
  final List<String?> blueTeams;
  final DateTime? estimatedQueueTime;
  final DateTime? estimatedStartTime;

  bool containsTeam(String teamNumber) =>
      redTeams.contains(teamNumber) || blueTeams.contains(teamNumber);

  factory NexusMatch.fromJson(Map<String, dynamic> json) {
    final times = json['times'] as Map<String, dynamic>?;

    DateTime? parseMs(dynamic v) => v == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(v as int);

    return NexusMatch(
      label: json['label'] as String,
      status: json['status'] as String,
      redTeams: (json['redTeams'] as List).map((e) => e as String?).toList(),
      blueTeams: (json['blueTeams'] as List).map((e) => e as String?).toList(),
      estimatedQueueTime: parseMs(times?['estimatedQueueTime']),
      estimatedStartTime: parseMs(times?['estimatedStartTime']),
    );
  }
}
