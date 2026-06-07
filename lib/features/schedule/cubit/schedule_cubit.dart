import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/nexus_match.dart';
import '../../../data/models/tba_match.dart';
import '../../../data/repositories/schedule_repository.dart';

part 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(this._repo) : super(const ScheduleInitial());

  final ScheduleRepository _repo;

  /// Loads the schedule, or auto-detects Team 751's current/upcoming event.
  ///
  /// Fetches two events in parallel when needed:
  ///   - Current/upcoming event → drives the schedule and Schedules tabs
  ///   - Most recently completed event → drives the Past Matches tab
  ///   (If they're the same event, the match list is reused with no extra call.)
  Future<void> load([String? eventKeyOverride]) async {
    if (state is ScheduleLoading) return;
    emit(const ScheduleLoading());
    try {
      // Detect both event keys concurrently.
      final detected = await Future.wait([
        eventKeyOverride != null
            ? Future.value((key: eventKeyOverride, status: EventStatus.active))
            : _repo.detectCurrentEvent(),
        _repo.detectPastEvent(),
      ]);

      final current = detected[0] as ({String key, EventStatus status});
      final pastKey = detected[1] as String;
      final sameEvent = pastKey == current.key;

      // Load current event data + past event data (skip past fetch if same).
      final results = await Future.wait([
        _repo.getMatches(current.key),
        _repo.getEventName(current.key),
        _repo.getNexusMatches(current.key),
        if (!sameEvent) _repo.getMatches(pastKey),
        if (!sameEvent) _repo.getEventName(pastKey),
      ]);

      final allMatches = results[0] as List<TbaMatch>;
      final eventName = results[1] as String;
      final nexusMatches = results[2] as List<NexusMatch>;
      final pastAllMatches = sameEvent ? allMatches : results[3] as List<TbaMatch>;
      final pastEventName = sameEvent ? eventName : results[4] as String;

      emit(ScheduleLoaded(
        eventKey: current.key,
        eventName: eventName,
        eventStatus: current.status,
        allMatches: allMatches,
        nexusMatches: nexusMatches,
        pastEventKey: pastKey,
        pastEventName: pastEventName,
        pastAllMatches: pastAllMatches,
      ));
    } catch (e) {
      emit(ScheduleError(e.toString()));
    }
  }
}
