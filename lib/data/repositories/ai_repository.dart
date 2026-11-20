import '../../core/config/app_config.dart';
import '../../features/ai/context/ai_context_builder.dart';
import '../models/ai_models.dart';
import '../models/match_prediction.dart';
import '../models/pit_scouting_record.dart';
import '../models/scouting_record.dart';
import '../models/tba_match.dart';
import '../models/team_rating.dart';
import '../models/team_strength.dart';
import '../services/ai_service.dart';
import 'pit_scouting_repository.dart';
import 'scouting_repository.dart';

/// The AI assistant's data access. Gathers the event's scouting records,
/// shapes them with [AiContextBuilder] and streams Claude's answer through the
/// `ai` Edge Function ([AiService]).
///
/// Output is text for people to read. Nothing here feeds rankings,
/// predictions or the picklist order.
class AiRepository {
  AiRepository(this._service, this._scouting, this._pits);

  final AiService _service;
  final ScoutingRepository _scouting;
  final PitScoutingRepository _pits;

  Future<AiAccess> fetchAccess() => _service.fetchAccess();

  /// Summary of one team from our scouting plus its TBA stats.
  Stream<AiEvent> teamSummary({
    required String eventKey,
    required int team,
    required EventRatings ratings,
  }) async* {
    final records = await _records(eventKey);
    final payload = AiContextBuilder.teamSummary(
      team: team,
      strength: _strengths(ratings)[team],
      matchRecords: records.match,
      pitRecords: records.pit,
    );
    yield* _service.generate(
        kind: AiKind.teamSummary, eventKey: eventKey, payload: payload.data);
  }

  /// Strategy brief for one of our upcoming matches.
  Stream<AiEvent> matchBrief({
    required String eventKey,
    required TbaMatch match,
    required EventRatings ratings,
  }) async* {
    final records = await _records(eventKey);
    final prediction = ratings.teams.isEmpty
        ? null
        : MatchPrediction.compute(match, ratings);
    final payload = AiContextBuilder.matchBrief(
      match: match,
      ourTeamKey: AppConfig.myTeamKey,
      strengths: _strengths(ratings),
      prediction: prediction,
      matchRecords: records.match,
      pitRecords: records.pit,
    );
    yield* _service.generate(
        kind: AiKind.matchBrief, eventKey: eventKey, payload: payload.data);
  }

  /// Flags picklist teams whose scouting disagrees with their rating.
  Stream<AiEvent> picklistReview({
    required String eventKey,
    required List<TeamStrength> teams,
    required String Function(int team) statusOf,
    required int? Function(int team) priorityOf,
  }) async* {
    final records = await _records(eventKey);
    final payload = AiContextBuilder.picklistReview(
      teams: teams,
      statusOf: statusOf,
      priorityOf: priorityOf,
      matchRecords: records.match,
      pitRecords: records.pit,
    );
    yield* _service.generate(
        kind: AiKind.picklistReview,
        eventKey: eventKey,
        payload: payload.data);
  }

  /// The event data a chat is grounded in. Built once per conversation so the
  /// server's prompt cache sees the same prefix on every turn.
  Future<AiPayload> chatContext({
    required String eventKey,
    required EventRatings ratings,
    required List<TbaMatch> matches,
  }) async {
    final records = await _records(eventKey);
    final roster = {
      for (final m in matches)
        for (final key in [...m.redTeams, ...m.blueTeams])
          ?int.tryParse(TbaMatch.displayNumber(key)),
    };
    return AiContextBuilder.eventChat(
      ourTeam: AppConfig.myTeamNumber,
      roster: roster,
      strengths: _strengths(ratings),
      ourUpcoming: [
        for (final m in matches)
          if (!m.isPlayed && m.containsTeam(AppConfig.myTeamKey)) m,
      ],
      matchRecords: records.match,
      pitRecords: records.pit,
    );
  }

  /// Streams the answer to the last user turn in [history].
  Stream<AiEvent> chat({
    required String eventKey,
    required AiPayload context,
    required List<AiTurn> history,
  }) =>
      _service.generate(
        kind: AiKind.chat,
        eventKey: eventKey,
        payload: context.data,
        messages: history,
      );

  /// This event's match and pit records, synced or not: an unsynced report is
  /// still something our scouts saw.
  Future<({List<ScoutingRecord> match, List<PitScoutingRecord> pit})> _records(
      String eventKey) async {
    final match = (await _scouting.getAll())
        .where((r) => r.eventKey == eventKey)
        .toList();
    final pit =
        (await _pits.getAll()).where((r) => r.eventKey == eventKey).toList();
    return (match: match, pit: pit);
  }

  static Map<int, TeamStrength> _strengths(EventRatings ratings) => {
        for (final s in TeamStrength.rank(ratings)) s.team: s,
      };
}
