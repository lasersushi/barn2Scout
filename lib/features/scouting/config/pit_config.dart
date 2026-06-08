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
  // Auto capabilities -------------------------------------------------------
  FieldConfig(
    key: 'pit_auto_leave',
    label: 'Can leave starting line',
    phase: ScoutPhase.auto,
    type: FieldType.toggle,
    section: 'Auto Capabilities',
  ),
  FieldConfig(
    key: 'pit_auto_l1',
    label: 'Scores Level 1 in auto',
    phase: ScoutPhase.auto,
    type: FieldType.toggle,
    section: 'Auto Capabilities',
  ),
  FieldConfig(
    key: 'pit_auto_l2',
    label: 'Scores Level 2 in auto',
    phase: ScoutPhase.auto,
    type: FieldType.toggle,
    section: 'Auto Capabilities',
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
