part of 'points_cubit.dart';

sealed class PointsState {
  const PointsState();
}

class PointsLoading extends PointsState {
  const PointsLoading();
}

/// No active or upcoming comp — points are per event, like XP.
class PointsNoEvent extends PointsState {
  const PointsNoEvent();
}

/// Bets or the TBA schedule couldn't be loaded and there's nothing to show.
class PointsError extends PointsState {
  const PointsError(this.message);

  final String message;
}

class PointsLoaded extends PointsState {
  const PointsLoaded({
    required this.eventKey,
    required this.ledger,
    required this.matches,
    required this.currentUserId,
    this.refreshError,
  });

  final String eventKey;
  final PointsLedger ledger;

  /// The event's TBA schedule, in competition order.
  final List<TbaMatch> matches;
  final String? currentUserId;

  /// Set when the latest refresh failed — the data shown is from the last
  /// successful one.
  final String? refreshError;

  /// The signed-in scout's row, or null if they have no points or bets yet.
  PointsEntry? get me => ledger.entryFor(currentUserId);

  int get available => me?.available ?? 0;

  List<TbaMatch> get openMatches => matches.where(isOpenForBets).toList();

  TbaMatch? matchFor(String matchKey) {
    for (final m in matches) {
      if (m.key == matchKey) return m;
    }
    return null;
  }

  /// The signed-in scout's bets, newest first.
  List<BetResult> get myBets => [
        for (final r in ledger.bets)
          if (r.bet.userId == currentUserId) r,
      ];

  BetResult? myBetOn(String matchKey) {
    for (final r in myBets) {
      if (r.bet.matchKey == matchKey) return r;
    }
    return null;
  }

  BetPool poolFor(String matchKey) => ledger.openPools[matchKey] ?? BetPool();
}
