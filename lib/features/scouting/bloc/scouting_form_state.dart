part of 'scouting_form_bloc.dart';

/// Ordered phases of the form. `review` is a confirmation step, not a data
/// bucket. **This declaration order defines the only legal FSM transitions** —
/// advancing/reverting steps through this list one index at a time.
enum FormPhase { auto, teleop, endgame, review }

/// Save lifecycle, separate from which [FormPhase] is showing.
enum FormStatus { editing, saving, saved, failure }

class ScoutingFormState extends Equatable {
  const ScoutingFormState({
    required this.phase,
    required this.values,
    required this.notes,
    required this.status,
    this.error,
  });

  /// Fresh form: auto phase, every field at its [FieldConfig.initialValue].
  factory ScoutingFormState.initial(List<FieldConfig> config) {
    return ScoutingFormState(
      phase: FormPhase.auto,
      values: {for (final field in config) field.key: field.initialValue},
      notes: '',
      status: FormStatus.editing,
    );
  }

  final FormPhase phase;

  /// Flat map of every field key → its current value, across all phases. Split
  /// back into per-phase buckets only at save time.
  final Map<String, Object?> values;

  final String notes;
  final FormStatus status;
  final String? error;

  bool get isFirstPhase => phase == FormPhase.auto;
  bool get isReview => phase == FormPhase.review;

  ScoutingFormState copyWith({
    FormPhase? phase,
    Map<String, Object?>? values,
    String? notes,
    FormStatus? status,
    String? error,
  }) {
    return ScoutingFormState(
      phase: phase ?? this.phase,
      values: values ?? this.values,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      // Intentionally not preserved: a new action clears any prior error.
      error: error,
    );
  }

  @override
  List<Object?> get props => [phase, values, notes, status, error];
}
