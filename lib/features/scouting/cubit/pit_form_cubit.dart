import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/pit_scouting_record.dart';
import '../../../data/repositories/pit_scouting_repository.dart';
import '../config/pit_config.dart';

enum PitFormStatus { editing, saving, saved, failure }

class PitFormState {
  const PitFormState({
    required this.values,
    this.status = PitFormStatus.editing,
    this.error,
  });

  final Map<String, Object?> values;
  final PitFormStatus status;
  final String? error;

  PitFormState copyWith({
    Map<String, Object?>? values,
    PitFormStatus? status,
    String? error,
  }) {
    return PitFormState(
      values: values ?? this.values,
      status: status ?? this.status,
      error: error,
    );
  }
}

class PitFormCubit extends Cubit<PitFormState> {
  PitFormCubit({
    required this.repository,
    required this.teamNumber,
    required this.eventKey,
    required this.scouterName,
  }) : super(PitFormState(
          values: {
            for (final f in kPitScoutingConfig) f.key: f.initialValue,
          },
        ));

  final PitScoutingRepository repository;
  final int teamNumber;
  final String eventKey;
  final String scouterName;

  void fieldChanged(String key, Object? value) {
    emit(state.copyWith(
      values: Map.of(state.values)..[key] = value,
    ));
  }

  Future<void> submit() async {
    if (state.status == PitFormStatus.saving) return;
    emit(state.copyWith(status: PitFormStatus.saving));
    try {
      final record = PitScoutingRecord.create(
        uuid: const Uuid().v4(),
        teamNumber: teamNumber,
        eventKey: eventKey,
        scouterName: scouterName,
        timestamp: DateTime.now(),
        pitData: {
          for (final e in state.values.entries)
            if (e.value != null) e.key: e.value,
        },
      );
      await repository.save(record);
      emit(state.copyWith(status: PitFormStatus.saved));
    } catch (e) {
      emit(state.copyWith(status: PitFormStatus.failure, error: e.toString()));
    }
  }
}
