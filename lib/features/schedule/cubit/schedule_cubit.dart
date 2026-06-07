import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/nexus_match.dart';
import '../../../data/models/tba_match.dart';
import '../../../data/repositories/schedule_repository.dart';

part 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(this._repo) : super(const ScheduleInitial());

  final ScheduleRepository _repo;

  /// Loads the schedule for [eventKey], or auto-detects Team 751's current
  /// event from TBA if no key is provided.
  Future<void> load([String? eventKey]) async {
    if (state is ScheduleLoading) return;
    emit(const ScheduleLoading());
    try {
      final key = eventKey ?? await _repo.detectCurrentEvent();

      final results = await Future.wait([
        _repo.getMatches(key),
        _repo.getEventName(key),
        _repo.getNexusMatches(key),
      ]);

      emit(ScheduleLoaded(
        eventKey: key,
        eventName: results[1] as String,
        allMatches: results[0] as List<TbaMatch>,
        nexusMatches: results[2] as List<NexusMatch>,
      ));
    } catch (e) {
      emit(ScheduleError(e.toString()));
    }
  }
}
