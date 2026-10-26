import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_bet.dart';

/// Reads and places points bets in the Supabase `match_bets` table.
///
/// Online-only: there's no local queue, because a bet has to reach the server
/// before its match starts to count. Balances are never stored — they're
/// derived from reports, bets, and TBA results (see `points.dart`).
class BetRepository {
  final _client = Supabase.instance.client;

  Future<List<MatchBet>> fetchForEvent(String eventKey) async {
    if (_client.auth.currentUser == null) return const [];
    final rows = await _client
        .from('match_bets')
        .select()
        .eq('event_key', eventKey) as List<dynamic>;
    return rows.cast<Map<String, dynamic>>().map(MatchBet.fromSupabase).toList();
  }

  /// Throws [DuplicateBetException] if the signed-in scout already bet on
  /// [matchKey] (e.g. from another device).
  Future<void> placeBet({
    required String eventKey,
    required String matchKey,
    required BetSide side,
    required int stake,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not signed in.');
    try {
      await _client.from('match_bets').insert({
        'user_id': userId,
        'event_key': eventKey,
        'match_key': matchKey,
        'alliance': side.name,
        'stake': stake,
      });
    } on PostgrestException catch (e) {
      // 23505 = unique_violation on (user_id, match_key).
      if (e.code == '23505') throw const DuplicateBetException();
      rethrow;
    }
  }
}

class DuplicateBetException implements Exception {
  const DuplicateBetException();
}
