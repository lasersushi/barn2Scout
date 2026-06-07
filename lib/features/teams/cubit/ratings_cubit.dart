import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/team_rating.dart';
import '../../../data/models/team_strength.dart';
import '../../../data/repositories/schedule_repository.dart'
    show ScheduleRepository, EventStatus;

part 'ratings_state.dart';

/// Loads TBA-derived team strength for the current event and ranks it for the
/// picklist. Source is 100% TBA (OPR/DPR/rankings/match scores) — no scouting.
class RatingsCubit extends Cubit<RatingsState> {
  RatingsCubit(this._repo) : super(const RatingsLoading());

  final ScheduleRepository _repo;

  Future<void> load() async {
    emit(const RatingsLoading());
    try {
      final detected = await _repo.detectCurrentEvent();
      if (detected.status == EventStatus.past) {
        emit(const RatingsNoEvent());
        return;
      }
      final matches = await _repo.getMatches(detected.key);
      final Map<int, TeamRating> ratings =
          await _repo.fetchTeamRatings(detected.key, matches);

      final teams = TeamStrength.rank(ratings);
      emit(teams.isEmpty ? const RatingsEmpty() : RatingsLoaded(teams: teams));
    } catch (e) {
      emit(RatingsError(e.toString()));
    }
  }
}
