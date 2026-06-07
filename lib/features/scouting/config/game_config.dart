import 'field_config.dart';

/// The active scouting schema.
///
/// **This is the one thing you swap each January when the game changes.** The
/// form, the stored JSON keys, and the analytics all derive from this list, so
/// a new game means editing these entries — no UI or database rewrite.
///
/// 2027's game is unknown at time of writing, so this is a realistic generic
/// FRC layout: leave-line + scoring in auto, scoring + defense in teleop, a
/// climb choice + timer in endgame.
const List<FieldConfig> kDefaultGameConfig = [
  // ---------------------------------------------------------------- AUTO ----
  FieldConfig(
    key: 'auto_left_line',
    label: 'Left Starting Line',
    phase: ScoutPhase.auto,
    type: FieldType.toggle,
  ),
  FieldConfig(
    key: 'auto_scored_l1',
    label: 'Scored — Level 1',
    phase: ScoutPhase.auto,
    type: FieldType.counter,
    min: 0,
  ),
  FieldConfig(
    key: 'auto_scored_l2',
    label: 'Scored — Level 2',
    phase: ScoutPhase.auto,
    type: FieldType.counter,
    min: 0,
  ),
  // -------------------------------------------------------------- TELEOP ----
  FieldConfig(
    key: 'teleop_scored_l1',
    label: 'Scored — Level 1',
    phase: ScoutPhase.teleop,
    type: FieldType.counter,
    min: 0,
  ),
  FieldConfig(
    key: 'teleop_scored_l2',
    label: 'Scored — Level 2',
    phase: ScoutPhase.teleop,
    type: FieldType.counter,
    min: 0,
  ),
  FieldConfig(
    key: 'teleop_defense',
    label: 'Defense Played',
    phase: ScoutPhase.teleop,
    type: FieldType.rating,
    min: 0,
    max: 5,
  ),
  // ------------------------------------------------------------- ENDGAME ----
  FieldConfig(
    key: 'endgame_climb',
    label: 'Climb',
    phase: ScoutPhase.endgame,
    type: FieldType.choice,
    options: ['None', 'Park', 'Shallow', 'Deep'],
  ),
  FieldConfig(
    key: 'endgame_climb_time',
    label: 'Climb Time',
    phase: ScoutPhase.endgame,
    type: FieldType.stopwatch,
  ),
];

/// Fields belonging to [phase], in declaration order.
List<FieldConfig> fieldsForPhase(ScoutPhase phase) =>
    kDefaultGameConfig.where((field) => field.phase == phase).toList();
