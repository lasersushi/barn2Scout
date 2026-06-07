import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/nexus_match.dart';
import '../../../data/models/tba_match.dart';
import '../../../data/repositories/schedule_repository.dart';

part 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(this._repo) : super(const ScheduleInitial());

  final ScheduleRepository _repo;

  /// Load schedule for [eventKey]. Both schedule pages call this on init;
  /// subsequent calls while already loaded are cheap (no debounce needed
  /// because IndexedStack keeps pages alive).
  Future<void> load([String eventKey = AppConfig.currentEventKey]) async {
    if (state is ScheduleLoading) return;
    emit(const ScheduleLoading());
    try {
      // Fetch TBA and Nexus in parallel.
      final results = await Future.wait([
        _repo.getMatches(eventKey),
        _repo.getEventName(eventKey),
        _repo.getNexusMatches(eventKey),
      ]);

      emit(ScheduleLoaded(
        eventKey: eventKey,
        eventName: results[1] as String,
        allMatches: results[0] as List<TbaMatch>,
        nexusMatches: results[2] as List<NexusMatch>,
      ));
    } catch (e) {
      emit(ScheduleError(e.toString()));
    }
  }
}
