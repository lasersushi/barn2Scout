import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/nexus_pit.dart';
import '../../../data/repositories/schedule_repository.dart';

part 'teams_state.dart';

class TeamsCubit extends Cubit<TeamsState> {
  TeamsCubit(this._repo) : super(const TeamsInitial());

  final ScheduleRepository _repo;

  Future<void> load([String eventKey = AppConfig.currentEventKey]) async {
    if (state is TeamsLoading) return;
    emit(const TeamsLoading());
    try {
      final pits = await _repo.getPits(eventKey);
      emit(TeamsLoaded(pits: pits, eventKey: eventKey));
    } catch (e) {
      emit(TeamsError(e.toString()));
    }
  }
}
