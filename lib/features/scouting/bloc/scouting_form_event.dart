part of 'scouting_form_bloc.dart';

sealed class ScoutingFormEvent extends Equatable {
  const ScoutingFormEvent();

  @override
  List<Object?> get props => [];
}

/// Set one field's value in its phase bucket.
class FieldChanged extends ScoutingFormEvent {
  const FieldChanged(this.field, this.value);

  final FieldConfig field;
  final Object? value;

  @override
  List<Object?> get props => [field, value];
}

/// Update the free-text notes captured on the review screen.
class NotesChanged extends ScoutingFormEvent {
  const NotesChanged(this.notes);

  final String notes;

  @override
  List<Object?> get props => [notes];
}

/// Move forward one phase (auto → teleop → endgame → review). No-op at review.
class PhaseAdvanced extends ScoutingFormEvent {
  const PhaseAdvanced();
}

/// Move back one phase. No-op at auto.
class PhaseReverted extends ScoutingFormEvent {
  const PhaseReverted();
}

/// Persist the assembled record to Isar.
class FormSubmitted extends ScoutingFormEvent {
  const FormSubmitted();
}
