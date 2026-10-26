part of 'ratings_cubit.dart';

sealed class RatingsState {
  const RatingsState();
}

class RatingsLoading extends RatingsState {
  const RatingsLoading();
}

/// No upcoming or active event found for this team on TBA.
class RatingsNoEvent extends RatingsState {
  const RatingsNoEvent();
}

/// No TBA ratings available — the event has no OPRs yet and none of its teams
/// have played an earlier event this season either.
class RatingsEmpty extends RatingsState {
  const RatingsEmpty();
}

class RatingsLoaded extends RatingsState {
  const RatingsLoaded({required this.teams});

  /// Teams ranked by expected points, descending.
  final List<TeamStrength> teams;

  /// True before the event's first matches, when every rating is borrowed
  /// from that team's previous event — there are no official standings yet.
  bool get isPreComp => teams.any((t) => t.rating.isPreComp);
}

class RatingsError extends RatingsState {
  const RatingsError(this.message);
  final String message;
}
