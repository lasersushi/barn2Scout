import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/scouting_record.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/scouting_repository.dart';

sealed class RecordsState {
  const RecordsState();
}

/// Waiting on event detection — shown only briefly on tab open.
class RecordsLoading extends RecordsState {
  const RecordsLoading();
}

/// No active or upcoming competition — records are hidden, not deleted.
class RecordsNoEvent extends RecordsState {
  const RecordsNoEvent();
}

class RecordsLoaded extends RecordsState {
  const RecordsLoaded(this.records);
  final List<ScoutingRecord> records;
}

/// Streams the current comp's records (newest first). Old comps' records stay
/// in Isar but are filtered from view; with no active/upcoming comp nothing is
/// shown at all. Mirrors the RatingsCubit bail-on-past pattern.
class RecordsCubit extends Cubit<RecordsState> {
  RecordsCubit(this._repository, this._schedule)
      : super(const RecordsLoading());

  final ScoutingRepository _repository;
  final ScheduleRepository _schedule;
  StreamSubscription<List<ScoutingRecord>>? _subscription;

  /// Detects the current comp and subscribes to its records. Safe to call
  /// again — e.g. when the event override changes in Settings — it tears down
  /// the previous subscription and re-detects.
  Future<void> init() async {
    await _subscription?.cancel();
    _subscription = null;
    if (isClosed) return;
    emit(const RecordsLoading());

    final detected = await _schedule.detectCurrentEvent();
    if (isClosed) return;
    if (detected.status == EventStatus.past) {
      emit(const RecordsNoEvent());
      return;
    }
    _subscription = _repository
        .watchForEvent(detected.key)
        .listen((records) => emit(RecordsLoaded(records)));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
