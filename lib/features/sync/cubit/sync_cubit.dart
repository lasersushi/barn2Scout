import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/sync_repository.dart';

sealed class SyncState {
  const SyncState();
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class SyncInProgress extends SyncState {
  const SyncInProgress();
}

class SyncDone extends SyncState {
  const SyncDone();
}

class SyncError extends SyncState {
  const SyncError(this.message);
  final String message;
}

class SyncCubit extends Cubit<SyncState> {
  SyncCubit(this._sync, this._schedule) : super(const SyncIdle());

  final SyncRepository _sync;
  final ScheduleRepository _schedule;

  Future<void> syncNow() async {
    if (state is SyncInProgress) return;
    emit(const SyncInProgress());
    try {
      final detected = await _schedule.detectCurrentEvent();
      await _sync.sync(detected.key);
      emit(const SyncDone());
    } catch (e, st) {
      print('[Sync] error: $e\n$st');
      emit(SyncError(e.toString()));
    }
  }
}
