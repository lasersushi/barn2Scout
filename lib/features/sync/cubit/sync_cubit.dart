import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/scouting_record.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/scouting_repository.dart';
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
  SyncCubit(this._sync, this._schedule, this._scouting) : super(const SyncIdle()) {
    _startPeriodicPull();
    _watchForNewRecords();
  }

  final SyncRepository _sync;
  final ScheduleRepository _schedule;
  final ScoutingRepository _scouting;

  Timer? _pullTimer;
  StreamSubscription<List<ScoutingRecord>>? _recordSub;
  int _lastUnsyncedCount = 0;

  void _startPeriodicPull() {
    _pullTimer = Timer.periodic(const Duration(minutes: 1), (_) => _pullOnly());
  }

  void _watchForNewRecords() {
    _recordSub = _scouting.watchAll().listen((records) {
      final unsyncedCount = records.where((r) => !r.synced).length;
      if (unsyncedCount > _lastUnsyncedCount) {
        _pushOnly();
      }
      _lastUnsyncedCount = unsyncedCount;
    });
  }

  /// Full sync (push + pull records and picklists).
  Future<void> syncNow() async {
    if (state is SyncInProgress) return;
    emit(const SyncInProgress());
    try {
      final detected = await _schedule.detectCurrentEvent();
      await _sync.sync(detected.key);
      emit(const SyncDone());
    } catch (e) {
      emit(SyncError(e.toString()));
    }
  }

  /// Push new scouting records only — silent, no state change.
  Future<void> _pushOnly() async {
    try {
      await _sync.pushRecords();
    } catch (_) {
      // Best-effort — will retry on next full sync.
    }
  }

  /// Pull records and picklists only — silent, no state change.
  Future<void> _pullOnly() async {
    try {
      final detected = await _schedule.detectCurrentEvent();
      await _sync.pullRecords(detected.key);
      await _sync.pullPicklists();
    } catch (_) {
      // Best-effort — visible errors only on manual sync.
    }
  }

  @override
  Future<void> close() {
    _pullTimer?.cancel();
    _recordSub?.cancel();
    return super.close();
  }
}
