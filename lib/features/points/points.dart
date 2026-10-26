import '../../data/models/match_bet.dart';
import '../../data/models/pit_scouting_record.dart';
import '../../data/models/scout_profile.dart';
import '../../data/models/scouting_record.dart';
import '../../data/models/tba_match.dart';

/// Points rules: scouts earn points by filing reports and grow them by betting
/// on matches. Points are their own currency — they never feed into XP, and
/// bets never feed into rankings, predictions, or any team metric.
///
/// Nothing here is stored. Every device rebuilds the same ledger from the
/// event's reports, the `match_bets` table, and TBA results, so there's no
/// balance for a client to tamper with.
const kMatchReportPoints = 10;
const kPitReportPoints = 10;

/// TBA has posted a final score (a tie included).
bool hasResult(TbaMatch m) =>
    (m.redScore ?? -1) >= 0 && (m.blueScore ?? -1) >= 0;

/// Bets are only taken until TBA reports the match has started.
bool isOpenForBets(TbaMatch m) => m.actualTime == null && !hasResult(m);

/// Pari-mutuel winnings: winners split the losing side's stakes in proportion
/// to their own stake, rounded down. Paid on top of the returned stake.
int winningsFor({
  required int stake,
  required int winningPool,
  required int losingPool,
}) =>
    winningPool <= 0 ? 0 : stake * losingPool ~/ winningPool;

enum BetOutcome { pending, won, lost, refunded }

class BetResult {
  const BetResult({
    required this.bet,
    required this.outcome,
    this.payout = 0,
    this.refundReason,
  });

  final MatchBet bet;
  final BetOutcome outcome;

  /// Points handed back when the bet settled: stake + winnings for a win, the
  /// stake for a refund, 0 for a loss or while pending.
  final int payout;

  /// Why the stake came back, when [outcome] is [BetOutcome.refunded].
  final String? refundReason;

  /// Profit or loss once settled; 0 while pending or refunded.
  int get net => switch (outcome) {
        BetOutcome.won => payout - bet.stake,
        BetOutcome.lost => -bet.stake,
        BetOutcome.pending || BetOutcome.refunded => 0,
      };
}

/// Valid stakes on each side of a match that hasn't settled yet.
class BetPool {
  int red = 0;
  int blue = 0;

  int on(BetSide side) => side == BetSide.red ? red : blue;
  int get total => red + blue;
}

class PointsEntry {
  const PointsEntry({
    required this.userId,
    required this.name,
    required this.earned,
    required this.available,
    required this.inPlay,
    required this.wins,
    required this.losses,
    required this.rank,
    required this.isMe,
  });

  final String userId;
  final String name;

  /// From reports alone.
  final int earned;

  /// Spendable right now.
  final int available;

  /// Staked on matches that haven't settled.
  final int inPlay;
  final int wins;
  final int losses;

  /// 1-based; tied totals share a rank (1, 2, 2, 4).
  final int rank;
  final bool isMe;

  int get total => available + inPlay;
}

class PointsLedger {
  const PointsLedger({
    required this.standings,
    required this.bets,
    required this.openPools,
  });

  /// Highest [PointsEntry.total] first.
  final List<PointsEntry> standings;

  /// Every bet at the event, newest first.
  final List<BetResult> bets;

  /// Pools for matches with bets that haven't settled, keyed by match key.
  final Map<String, BetPool> openPools;

  PointsEntry? entryFor(String? userId) {
    if (userId == null) return null;
    for (final e in standings) {
      if (e.userId == userId) return e;
    }
    return null;
  }
}

/// Replays the event to work out every scout's points.
///
/// Reports are credited up front — attributed like XP: a synced record to its
/// userId, an unsynced one to [currentUserId]. Bets and match results are
/// then replayed in time order:
///   - A bet is refunded if it was placed at or after TBA's actual start time,
///     if the scout didn't have the points at that moment, or if the match
///     posted a result with no start time to check it against.
///   - Otherwise its stake leaves the scout's balance until the match settles.
///   - A settled match pays out pari-mutuel ([winningsFor]). Ties, and pools
///     where only one side was backed, are refunded.
PointsLedger buildPointsLedger({
  required List<ScoutingRecord> matchRecords,
  required List<PitScoutingRecord> pitRecords,
  required List<ScoutProfile> profiles,
  required List<MatchBet> bets,
  required List<TbaMatch> matches,
  required String? currentUserId,
}) {
  final accounts = <String, _Account>{};
  _Account account(String userId) =>
      accounts.putIfAbsent(userId, _Account.new);

  String? ownerOf(bool synced, String? userId) =>
      synced ? userId : currentUserId;

  for (final r in matchRecords) {
    final owner = ownerOf(r.synced, r.userId);
    if (owner == null) continue;
    account(owner)
      ..earned += kMatchReportPoints
      ..noteName(r.scouterName, r.timestamp);
  }
  for (final r in pitRecords) {
    final owner = ownerOf(r.synced, r.userId);
    if (owner == null) continue;
    account(owner)
      ..earned += kPitReportPoints
      ..noteName(r.scouterName, r.timestamp);
  }
  for (final a in accounts.values) {
    a.available = a.earned;
  }

  final matchesByKey = {for (final m in matches) m.key: m};
  final pools = <String, BetPool>{};
  final staked = <String, List<MatchBet>>{};
  final results = <String, BetResult>{};

  void refund(MatchBet bet, String reason) {
    results[bet.id] = BetResult(
      bet: bet,
      outcome: BetOutcome.refunded,
      refundReason: reason,
    );
  }

  void settle(TbaMatch match) {
    final placed = staked.remove(match.key) ?? const <MatchBet>[];
    final pool = pools.remove(match.key) ?? BetPool();
    final winner = switch (match.winningAlliance) {
      'red' => BetSide.red,
      'blue' => BetSide.blue,
      _ => null,
    };
    final refundReason = winner == null
        ? 'Tie'
        : pool.red == 0 || pool.blue == 0
            ? 'Only one side was bet on'
            : null;

    for (final bet in placed) {
      final a = account(bet.userId)..inPlay -= bet.stake;
      if (refundReason != null) {
        a.available += bet.stake;
        results[bet.id] = BetResult(
          bet: bet,
          outcome: BetOutcome.refunded,
          payout: bet.stake,
          refundReason: refundReason,
        );
      } else if (bet.side == winner) {
        final payout = bet.stake +
            winningsFor(
              stake: bet.stake,
              winningPool: pool.on(winner!),
              losingPool: pool.total - pool.on(winner),
            );
        a
          ..available += payout
          ..wins += 1;
        results[bet.id] =
            BetResult(bet: bet, outcome: BetOutcome.won, payout: payout);
      } else {
        a.losses += 1;
        results[bet.id] = BetResult(bet: bet, outcome: BetOutcome.lost);
      }
    }
  }

  void place(MatchBet bet) {
    final match = matchesByKey[bet.matchKey];
    final start = match?.actualTime;
    final a = account(bet.userId)..betCount += 1;
    if (start != null && !bet.placedAt.isBefore(start)) {
      return refund(bet, 'Placed after the match started');
    }
    if (match != null && start == null && hasResult(match)) {
      return refund(bet, 'TBA has no start time to check it against');
    }
    if (bet.stake <= 0 || bet.stake > a.available) {
      return refund(bet, 'Not enough points when placed');
    }
    a
      ..available -= bet.stake
      ..inPlay += bet.stake;
    final pool = pools.putIfAbsent(bet.matchKey, BetPool.new);
    if (bet.side == BetSide.red) {
      pool.red += bet.stake;
    } else {
      pool.blue += bet.stake;
    }
    staked.putIfAbsent(bet.matchKey, () => []).add(bet);
    // A match missing from TBA's schedule never settles, so its stake stays
    // in play — only the bettor can be hurt by a bogus match key.
    results[bet.id] = BetResult(bet: bet, outcome: BetOutcome.pending);
  }

  final timeline = [...bets]..sort((a, b) {
      final byTime = a.placedAt.compareTo(b.placedAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  final settlements = matches
      .where((m) => hasResult(m) && m.actualTime != null)
      .toList()
    ..sort((a, b) => a.actualTime!.compareTo(b.actualTime!));

  // Each settlement runs before any bet placed at or after its start time —
  // those bets are refunded anyway, and payouts can only ever add points.
  var next = 0;
  for (final bet in timeline) {
    while (next < settlements.length &&
        !settlements[next].actualTime!.isAfter(bet.placedAt)) {
      settle(settlements[next++]);
    }
    place(bet);
  }
  while (next < settlements.length) {
    settle(settlements[next++]);
  }

  final names = {for (final p in profiles) p.userId: p.displayName};
  final rows = [
    for (final MapEntry(key: userId, value: a) in accounts.entries)
      if (a.earned > 0 || a.betCount > 0)
        (userId: userId, name: names[userId] ?? a.latestName ?? 'Scout', a: a),
  ]..sort((x, y) {
      final byTotal = y.a.total.compareTo(x.a.total);
      return byTotal != 0
          ? byTotal
          : x.name.toLowerCase().compareTo(y.name.toLowerCase());
    });
  final standings = <PointsEntry>[];
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final tied = i > 0 && rows[i - 1].a.total == row.a.total;
    standings.add(PointsEntry(
      userId: row.userId,
      name: row.name,
      earned: row.a.earned,
      available: row.a.available,
      inPlay: row.a.inPlay,
      wins: row.a.wins,
      losses: row.a.losses,
      rank: tied ? standings[i - 1].rank : i + 1,
      isMe: row.userId == currentUserId,
    ));
  }

  return PointsLedger(
    standings: standings,
    bets: [for (final bet in timeline.reversed) results[bet.id]!],
    openPools: pools,
  );
}

class _Account {
  int earned = 0;
  int available = 0;
  int inPlay = 0;
  int wins = 0;
  int losses = 0;
  int betCount = 0;
  String? latestName;
  DateTime? _latestAt;

  int get total => available + inPlay;

  /// Most recent non-empty scouter name — the display-name fallback when the
  /// profiles table has no row for this account.
  void noteName(String name, DateTime at) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_latestAt == null || at.isAfter(_latestAt!)) {
      latestName = trimmed;
      _latestAt = at;
    }
  }
}
