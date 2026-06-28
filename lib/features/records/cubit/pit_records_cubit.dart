import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/pit_scouting_record.dart';
import '../../../data/repositories/pit_scouting_repository.dart';
import '../../../data/repositories/schedule_repository.dart';

sealed class PitRecordsState {
  const PitRecordsState();
}

class PitRecordsLoading extends PitRecordsState {
  const PitRecordsLoading();
}

/// No active or upcoming competition — records are hidden, not deleted.
class PitRecordsNoEvent extends PitRecordsState {
  const PitRecordsNoEvent();
}

class PitRecordsLoaded extends PitRecordsState {
  const PitRecordsLoaded(this.records);
  final List<PitScoutingRecord> records;
}

/// Streams the current comp's pit records — same filtering rules as
/// [RecordsCubit].
class PitRecordsCubit extends Cubit<PitRecordsState> {
  PitRecordsCubit(this._repository, this._schedule)
      : super(const PitRecordsLoading());

  final PitScoutingRepository _repository;
  final ScheduleRepository _schedule;
  StreamSubscription<List<PitScoutingRecord>>? _subscription;

  /// Detects the current comp and subscribes to its pit records. Safe to call
  /// again — e.g. when the event override changes in Settings.
  Future<void> init() async {
    await _subscription?.cancel();
    _subscription = null;
    if (isClosed) return;
    emit(const PitRecordsLoading());

    final detected = await _schedule.detectCurrentEvent();
    if (isClosed) return;
    if (detected.status == EventStatus.past) {
      emit(const PitRecordsNoEvent());
      return;
    }
    _subscription = _repository
        .watchForEvent(detected.key)
        .listen((records) => emit(PitRecordsLoaded(records)));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
