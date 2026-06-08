import 'field_config.dart';

/// Fields for the pit scouting form.
///
/// All use [ScoutPhase.auto] as a placeholder — the pit form ignores phase and
/// displays all fields on a single scrollable page grouped by [section].
const List<FieldConfig> kPitScoutingConfig = [
  // Hardware ----------------------------------------------------------------
  FieldConfig(
    key: 'pit_drivetrain',
    label: 'Drivetrain',
    phase: ScoutPhase.auto,
    type: FieldType.choice,
    options: ['Swerve', 'Tank', 'Mecanum', 'Other'],
    section: 'Hardware',
  ),
  FieldConfig(
    key: 'pit_weight',
    label: 'Weight (lbs)',
    phase: ScoutPhase.auto,
    type: FieldType.counter,
    min: 0,
    max: 150,
    section: 'Hardware',
  ),
  FieldConfig(
    key: 'pit_width',
    label: 'Width (in)',
    phase: ScoutPhase.auto,
    type: FieldType.counter,
    min: 0,
    max: 60,
    section: 'Hardware',
  ),
  FieldConfig(
    key: 'pit_length',
    label: 'Length (in)',
    phase: ScoutPhase.auto,
    type: FieldType.counter,
    min: 0,
    max: 60,
    section: 'Hardware',
  ),
  FieldConfig(
    key: 'pit_height',
    label: 'Height (in)',
    phase: ScoutPhase.auto,
    type: FieldType.counter,
    min: 0,
    max: 60,
    section: 'Hardware',
  ),
FieldConfig(
    key: 'pit_trench',
    label: 'Can go under the trench?',
    phase: ScoutPhase.auto,
    type: FieldType.toggle,
    section: 'Hardware',
),
FieldConfig(
    key: 'pit_bump',
    label: 'Can go under the bump?',
    phase: ScoutPhase.auto,
    type: FieldType.toggle,
    section: 'Hardware',
),
FieldConfig(
    key: 'pit_bps',
    label: 'Balls per second',
    phase: ScoutPhase.auto,
    type: FieldType.counter,
    min: 0,
    max: 30,
    section: 'Hardware',
),
FieldConfig(
    key: 'pit_climb',
    label: 'Climb type',
    phase: ScoutPhase.auto,
    type: FieldType.choice,
    options: ['None', 'L1', 'L2', 'L3'],
    section: 'Hardware',
  ),
  // Software capabilities -------------------------------------------------------
  FieldConfig(
    key: 'pit_auto_leave',
    label: 'Can leave starting line',
    phase: ScoutPhase.auto,
    type: FieldType.toggle,
    section: 'Software',
  ),
  FieldConfig(
    key: 'pit_auto_score',
    label: 'Can score in auto',
    phase: ScoutPhase.auto,
    type: FieldType.toggle,
    section: 'Software',
  ),
  FieldConfig(
    key: 'pit_auto_swipes',
    label: 'How many swipes in the nuetral zone during auto?',
    phase: ScoutPhase.auto,
    type: FieldType.rating,
    section: 'Software',
    min: 0,
    max: 5,
  ),
  FieldConfig(
    key: 'pit_vision_setup',
    label: 'What is their vision setup?',
    phase: ScoutPhase.auto,
    type: FieldType.text,
    section: 'Software',
  ),
  FieldConfig(
    key: "auto_pathing_software",
    label: "Auto pathing software",
    phase: ScoutPhase.auto,
    type: FieldType.text,
    section: 'Software',
  ),
  // Observations ------------------------------------------------------------
  FieldConfig(
    key: 'pit_observations',
    label: 'Observations',
    phase: ScoutPhase.auto,
    type: FieldType.text,
    section: 'Observations',
  ),
];
