import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/nexus_pit.dart';
import '../../../data/repositories/schedule_repository.dart';

part 'teams_state.dart';

class TeamsCubit extends Cubit<TeamsState> {
  TeamsCubit(this._repo) : super(const TeamsInitial());

  final ScheduleRepository _repo;

  /// Loads pit map for [eventKey], or auto-detects Team 751's current event
  /// if no key is provided. The repository caches the detected key so this
  /// doesn't make a redundant TBA call if ScheduleCubit already resolved it.
  Future<void> load([String? eventKey]) async {
    if (state is TeamsLoading) return;
    emit(const TeamsLoading());
    try {
      final key = eventKey ?? await _repo.detectCurrentEvent();
      final pits = await _repo.getPits(key);
      emit(TeamsLoaded(pits: pits, eventKey: key));
    } catch (e) {
      emit(TeamsError(e.toString()));
    }
  }
}
