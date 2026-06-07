import 'package:equatable/equatable.dart';

/// Which phase of the match a field belongs to. Also the data bucket the value
/// is stored under in a [ScoutingRecord] (autoData / teleopData / endgameData).
enum ScoutPhase { auto, teleop, endgame }

/// The input widget used to capture a field's value.
enum FieldType {
  /// ± stepper for tallies. The − button doubles as undo for mid-match
  /// misclicks.
  counter,

  /// On/off switch (e.g. "Left starting line").
  toggle,

  /// Pick exactly one of [FieldConfig.options].
  choice,

  /// 1–5 star rating (e.g. defense, driver skill).
  rating,

  /// Time something, stored as whole seconds.
  stopwatch,

  /// Free text.
  text,
}

/// Describes one scouting field as *data*, not code.
///
/// This is the heart of the game-agnostic design: the form, the storage keys,
/// and the analytics all read from a `List<FieldConfig>`, so adapting to a new
/// game each January is editing a list — not rewriting screens.
class FieldConfig extends Equatable {
  const FieldConfig({
    required this.key,
    required this.label,
    required this.phase,
    required this.type,
    this.defaultValue,
    this.options = const [],
    this.min,
    this.max,
    this.section,
  });

  /// Stable map key the value is stored under, e.g. `"auto_scored_l1"`.
  /// Changing this orphans historical data, so treat it as permanent.
  final String key;

  /// Human-readable label shown on the form.
  final String label;

  final ScoutPhase phase;
  final FieldType type;

  /// Explicit starting value. If null, [initialValue] derives a sensible one.
  final Object? defaultValue;

  /// Choices for [FieldType.choice].
  final List<String> options;

  /// Lower bound for [FieldType.counter] / [FieldType.rating].
  final int? min;

  /// Upper bound for [FieldType.counter] / [FieldType.rating].
  final int? max;

  /// Optional grouping header within a phase.
  final String? section;

  /// The value the field starts at when a fresh form opens.
  Object? get initialValue {
    if (defaultValue != null) return defaultValue;
    switch (type) {
      case FieldType.counter:
      case FieldType.stopwatch:
      case FieldType.rating:
        return min ?? 0;
      case FieldType.toggle:
        return false;
      case FieldType.choice:
        return options.isNotEmpty ? options.first : null;
      case FieldType.text:
        return '';
    }
  }

  @override
  List<Object?> get props =>
      [key, label, phase, type, defaultValue, options, min, max, section];
}
