import '../../features/scouting/config/field_config.dart';
import '../../features/scouting/config/game_config.dart';
import 'scouting_record.dart';

/// Aggregated scouting stats for a single team, derived from a list of
/// [ScoutingRecord]s. Automatically adapts to [kDefaultGameConfig] — no
/// hardcoded field keys anywhere in this file.
class TeamAnalytics {
  const TeamAnalytics({
    required this.team,
    required this.matches,
    required this.avg,
    required this.pct,
    required this.dist,
  });

  final int team;

  /// How many records were scouted for this team.
  final int matches;

  /// counter / rating / stopwatch fields → mean value across all records.
  final Map<String, double> avg;

  /// toggle fields → fraction of records where the toggle was true (0.0–1.0).
  final Map<String, double> pct;

  /// choice fields → { option label: count of records that selected it }.
  final Map<String, Map<String, int>> dist;

  /// A simple headline score: sum of all counter and rating field averages.
  /// Iterates [kDefaultGameConfig] so the formula automatically picks up
  /// new fields when the game changes in January.
  double get composite {
    var score = 0.0;
    for (final field in kDefaultGameConfig) {
      if (field.type == FieldType.counter || field.type == FieldType.rating) {
        score += avg[field.key] ?? 0;
      }
    }
    return score;
  }

  /// Build a [TeamAnalytics] by aggregating [records] for one team.
  /// Each field in [kDefaultGameConfig] is processed according to its
  /// [FieldType] — no field keys are hardcoded here.
  static TeamAnalytics aggregate(int team, List<ScoutingRecord> records) {
    // Accumulate raw values before averaging.
    final avgAccum = <String, List<double>>{};
    final pctAccum = <String, List<bool>>{};
    // Initialise dist with zeroed counts for every known option.
    final distAccum = <String, Map<String, int>>{
      for (final f in kDefaultGameConfig)
        if (f.type == FieldType.choice)
          f.key: {for (final o in f.options) o: 0},
    };

    for (final record in records) {
      for (final field in kDefaultGameConfig) {
        final value = _valueFor(record, field);
        if (value == null) continue;

        switch (field.type) {
          case FieldType.counter:
          case FieldType.rating:
          case FieldType.stopwatch:
            (avgAccum[field.key] ??= []).add((value as num).toDouble());
          case FieldType.toggle:
            (pctAccum[field.key] ??= []).add(value as bool);
          case FieldType.choice:
            final opt = value as String;
            distAccum[field.key]?[opt] =
                (distAccum[field.key]?[opt] ?? 0) + 1;
          case FieldType.text:
            break;
        }
      }
    }

    return TeamAnalytics(
      team: team,
      matches: records.length,
      avg: {
        for (final e in avgAccum.entries)
          e.key: e.value.reduce((a, b) => a + b) / e.value.length,
      },
      pct: {
        for (final e in pctAccum.entries)
          e.key: e.value.where((b) => b).length / e.value.length,
      },
      dist: distAccum,
    );
  }

  /// Extract this field's value from the correct phase map on [record].
  static dynamic _valueFor(ScoutingRecord record, FieldConfig field) {
    final data = switch (field.phase) {
      ScoutPhase.auto => record.autoData,
      ScoutPhase.teleop => record.teleopData,
      ScoutPhase.endgame => record.endgameData,
    };
    return data[field.key];
  }
}
