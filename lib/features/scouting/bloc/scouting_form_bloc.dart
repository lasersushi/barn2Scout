import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/scouting_record.dart';
import '../../../data/repositories/scouting_repository.dart';
import '../config/field_config.dart';

part 'scouting_form_event.dart';
part 'scouting_form_state.dart';

/// Finite state machine for filling out a single [ScoutingRecord].
///
/// Phases advance strictly along auto → teleop → endgame → review (and back).
/// [PhaseAdvanced] / [PhaseReverted] each move exactly one step, so an illegal
/// jump like auto → review is impossible *by construction* — there is no code
/// path that sets a non-adjacent phase.
class ScoutingFormBloc extends Bloc<ScoutingFormEvent, ScoutingFormState> {
  ScoutingFormBloc({
    required this.repository,
    required this.config,
    required this.teamNumber,
    required this.matchNumber,
    required this.eventKey,
    required this.scouterName,
  }) : super(ScoutingFormState.initial(config)) {
    on<FieldChanged>(_onFieldChanged);
    on<NotesChanged>(_onNotesChanged);
    on<PhaseAdvanced>(_onPhaseAdvanced);
    on<PhaseReverted>(_onPhaseReverted);
    on<FormSubmitted>(_onSubmitted);
  }

  final ScoutingRepository repository;
  final List<FieldConfig> config;
  final int teamNumber;
  final int matchNumber;
  final String eventKey;
  final String scouterName;

  final Uuid _uuid = const Uuid();

  static const List<FormPhase> _phases = FormPhase.values;

  void _onFieldChanged(FieldChanged event, Emitter<ScoutingFormState> emit) {
    final updated = Map<String, Object?>.from(state.values)
      ..[event.field.key] = event.value;
    emit(state.copyWith(values: updated));
  }

  void _onNotesChanged(NotesChanged event, Emitter<ScoutingFormState> emit) {
    emit(state.copyWith(notes: event.notes));
  }

  void _onPhaseAdvanced(PhaseAdvanced event, Emitter<ScoutingFormState> emit) {
    final next = state.phase.index + 1;
    if (next < _phases.length) {
      emit(state.copyWith(phase: _phases[next]));
    }
  }

  void _onPhaseReverted(PhaseReverted event, Emitter<ScoutingFormState> emit) {
    final previous = state.phase.index - 1;
    if (previous >= 0) {
      emit(state.copyWith(phase: _phases[previous]));
    }
  }

  Future<void> _onSubmitted(
    FormSubmitted event,
    Emitter<ScoutingFormState> emit,
  ) async {
    emit(state.copyWith(status: FormStatus.saving));
    try {
      final record = ScoutingRecord.create(
        uuid: _uuid.v4(),
        teamNumber: teamNumber,
        matchNumber: matchNumber,
        eventKey: eventKey,
        scouterName: scouterName,
        timestamp: DateTime.now(),
        autoData: _bucketFor(ScoutPhase.auto),
        teleopData: _bucketFor(ScoutPhase.teleop),
        endgameData: _bucketFor(ScoutPhase.endgame),
        notes: state.notes,
      );
      await repository.save(record);
      emit(state.copyWith(status: FormStatus.saved));
    } catch (error) {
      emit(state.copyWith(status: FormStatus.failure, error: error.toString()));
    }
  }

  /// Pulls the values for one [phase] out of the flat [ScoutingFormState.values]
  /// map, producing the `Map<String, dynamic>` that gets JSON-encoded into the
  /// record's phase bucket.
  Map<String, dynamic> _bucketFor(ScoutPhase phase) {
    return {
      for (final field in config.where((f) => f.phase == phase))
        field.key: state.values[field.key],
    };
  }
}
