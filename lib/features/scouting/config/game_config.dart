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
    key: 'auto_notes',
    label: 'Auto Observations',
    phase: ScoutPhase.auto,
    type: FieldType.text,
  ),
  // -------------------------------------------------------------- TELEOP ----
  FieldConfig(
    key: 'teleop_defense',
    label: 'Defense Effectiveness',
    phase: ScoutPhase.teleop,
    type: FieldType.rating,
    min: 0,
    max: 5,
  ),
  FieldConfig(
    key: 'teleop_driver_skill',
    label: 'Driver Skill',
    phase: ScoutPhase.teleop,
    type: FieldType.rating,
    min: 0,
    max: 5,
  ),
  FieldConfig(
    key: 'teleop_notes',
    label: 'Teleop Observations',
    phase: ScoutPhase.teleop,
    type: FieldType.text,
  ),
  // ------------------------------------------------------------- ENDGAME ----
  FieldConfig(
    key: 'endgame_climb',
    label: 'Climb Result',
    phase: ScoutPhase.endgame,
    type: FieldType.choice,
    options: ['None', 'Park', 'Shallow', 'Deep'],
  ),
  FieldConfig(
    key: 'endgame_notes',
    label: 'Endgame Observations',
    phase: ScoutPhase.endgame,
    type: FieldType.text,
  ),
];

/// Fields belonging to [phase], in declaration order.
List<FieldConfig> fieldsForPhase(ScoutPhase phase) =>
    kDefaultGameConfig.where((field) => field.phase == phase).toList();
