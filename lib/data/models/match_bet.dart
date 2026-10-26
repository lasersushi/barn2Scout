/// Which alliance a bet backs.
enum BetSide { red, blue }

/// One scout's points bet on a match, as stored in the Supabase `match_bets`
/// table. Plain value type — bets live server-side only, not in Isar.
class MatchBet {
  const MatchBet({
    required this.id,
    required this.userId,
    required this.eventKey,
    required this.matchKey,
    required this.side,
    required this.stake,
    required this.placedAt,
  });

  final String id;
  final String userId;
  final String eventKey;

  /// TBA match key, e.g. `2026cacac_qm12`.
  final String matchKey;
  final BetSide side;
  final int stake;

  /// Server-stamped (the table's insert trigger overwrites whatever the
  /// client sends), so it can be trusted against TBA's match start time.
  final DateTime placedAt;

  factory MatchBet.fromSupabase(Map<String, dynamic> row) => MatchBet(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        eventKey: row['event_key'] as String,
        matchKey: row['match_key'] as String,
        side: BetSide.values.byName(row['alliance'] as String),
        stake: (row['stake'] as num).toInt(),
        placedAt: DateTime.parse(row['placed_at'] as String).toLocal(),
      );
}
