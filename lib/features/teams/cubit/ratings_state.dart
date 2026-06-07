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

/// No TBA ratings available yet — e.g. before the event's first matches are
/// played, so there are no OPRs to rank from.
class RatingsEmpty extends RatingsState {
  const RatingsEmpty();
}

class RatingsLoaded extends RatingsState {
  const RatingsLoaded({required this.teams});

  /// Teams ranked by blended strength, descending.
  final List<TeamStrength> teams;
}

class RatingsError extends RatingsState {
  const RatingsError(this.message);
  final String message;
}
