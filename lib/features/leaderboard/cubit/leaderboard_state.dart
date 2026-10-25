part of 'leaderboard_cubit.dart';

sealed class LeaderboardState {
  const LeaderboardState();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

/// No active or upcoming comp — XP is per event, so there's nothing to rank.
class LeaderboardNoEvent extends LeaderboardState {
  const LeaderboardNoEvent();
}

class LeaderboardLoaded extends LeaderboardState {
  const LeaderboardLoaded({required this.eventKey, required this.entries});

  final String eventKey;

  /// Highest XP first.
  final List<LeaderboardEntry> entries;

  /// The signed-in scouter's row, or null if they haven't scouted yet.
  LeaderboardEntry? get me {
    for (final e in entries) {
      if (e.isMe) return e;
    }
    return null;
  }
}
