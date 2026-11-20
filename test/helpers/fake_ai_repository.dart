import 'dart:async';

import 'package:barn2scout/data/models/ai_models.dart';
import 'package:barn2scout/data/models/tba_match.dart';
import 'package:barn2scout/data/models/team_rating.dart';
import 'package:barn2scout/data/repositories/ai_repository.dart';

/// In-memory [AiRepository] for tests: replays scripted [AiEvent]s and records
/// what was asked. Any method a test doesn't script throws via [noSuchMethod].
class FakeAiRepository implements AiRepository {
  FakeAiRepository({
    this.access,
    this.accessError,
    List<List<AiEvent>>? chatReplies,
    this.summaryEvents = const [],
  }) : chatReplies = chatReplies ?? [];

  /// Replayed by every [teamSummary] call.
  final List<AiEvent> summaryEvents;

  /// Teams a summary was requested for, in order.
  final List<int> summaryCalls = [];

  AiAccess? access;
  Object? accessError;

  /// One scripted reply per chat call, consumed in order.
  final List<List<AiEvent>> chatReplies;

  /// The history sent with each chat call.
  final List<List<AiTurn>> chatHistories = [];
  int chatContextBuilds = 0;

  @override
  Future<AiAccess> fetchAccess() async {
    if (accessError != null) throw accessError!;
    return access!;
  }

  @override
  Future<AiPayload> chatContext({
    required String eventKey,
    required EventRatings ratings,
    required List<TbaMatch> matches,
  }) async {
    chatContextBuilds++;
    return const AiPayload({'teams': []}, omittedReports: 3);
  }

  @override
  Stream<AiEvent> chat({
    required String eventKey,
    required AiPayload context,
    required List<AiTurn> history,
  }) {
    chatHistories.add(List.of(history));
    return Stream.fromIterable(chatReplies.removeAt(0));
  }

  @override
  Stream<AiEvent> teamSummary({
    required String eventKey,
    required int team,
    required EventRatings ratings,
  }) {
    summaryCalls.add(team);
    return Stream.fromIterable(summaryEvents);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
