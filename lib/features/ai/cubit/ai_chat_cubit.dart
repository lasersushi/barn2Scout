import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/ai_models.dart';
import '../../../data/models/tba_match.dart';
import '../../../data/models/team_rating.dart';
import '../../../data/repositories/ai_repository.dart';

/// The ask-anything chat (AI role and admins). Provided by the shell so a
/// conversation survives switching tabs.
///
/// The event data is gathered once, on the first question, and reused for
/// every turn: the same prefix lets the server's prompt cache bill follow-ups
/// at the cache-read rate. [clear] starts over with fresh data.
class AiChatCubit extends Cubit<AiChatState> {
  AiChatCubit(this._repo) : super(const AiChatState());

  final AiRepository _repo;
  StreamSubscription<AiEvent>? _sub;
  AiPayload? _context;
  String? _contextEvent;

  /// Turns sent with each request, at most. The server accepts 40; an odd
  /// number keeps the history starting with a user turn.
  static const maxTurnsSent = 39;

  Future<void> send(
    String question, {
    required String eventKey,
    required EventRatings ratings,
    required List<TbaMatch> matches,
  }) async {
    final q = question.trim();
    if (q.isEmpty || state.sending) return;

    final turns = [...state.turns, AiTurn.user(q)];
    emit(AiChatState(
      turns: turns,
      sending: true,
      reply: '',
      omittedReports: state.omittedReports,
      dataAsOf: state.dataAsOf,
    ));

    try {
      if (_context == null || _contextEvent != eventKey) {
        _context = await _repo.chatContext(
            eventKey: eventKey, ratings: ratings, matches: matches);
        _contextEvent = eventKey;
        if (isClosed) return;
        emit(state.copyWith(
          omittedReports: _context!.omittedReports,
          dataAsOf: DateTime.now(),
        ));
      }
    } on Object {
      if (isClosed) return;
      _fail(q, AiErrorCode.server, "Couldn't read this event's scouting data.");
      return;
    }

    final history = turns.length <= maxTurnsSent
        ? turns
        : turns.sublist(turns.length - maxTurnsSent);
    final reply = StringBuffer();
    await _sub?.cancel();
    _sub = _repo
        .chat(eventKey: eventKey, context: _context!, history: history)
        .listen(
      (event) {
        if (isClosed) return;
        switch (event) {
          case AiDelta(:final text):
            reply.write(text);
            emit(state.copyWith(reply: reply.toString()));
          case AiDone():
            final answer = reply.toString().trim();
            emit(AiChatState(
              turns: [
                ...state.turns,
                AiTurn.assistant(answer.isEmpty ? '(No answer.)' : answer),
              ],
              omittedReports: state.omittedReports,
              dataAsOf: state.dataAsOf,
            ));
          case AiFailure(:final code, :final message):
            _fail(q, code, message);
        }
      },
      onDone: () {
        if (!isClosed && state.sending) {
          _fail(q, AiErrorCode.offline, 'The connection dropped. Try again.');
        }
      },
    );
  }

  /// Drops the unanswered question (so the history still alternates) and
  /// hands it back for the input box.
  void _fail(String question, AiErrorCode code, String message) {
    final turns = [...state.turns];
    if (turns.isNotEmpty && turns.last.fromUser) turns.removeLast();
    emit(AiChatState(
      turns: turns,
      omittedReports: state.omittedReports,
      dataAsOf: state.dataAsOf,
      errorCode: code,
      errorMessage: message,
      unsentQuestion: question,
    ));
  }

  /// New conversation; the next question re-reads the event's data.
  Future<void> clear() async {
    await _sub?.cancel();
    _context = null;
    _contextEvent = null;
    emit(const AiChatState());
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}

class AiChatState extends Equatable {
  const AiChatState({
    this.turns = const [],
    this.sending = false,
    this.reply,
    this.omittedReports = 0,
    this.dataAsOf,
    this.errorCode,
    this.errorMessage,
    this.unsentQuestion,
  });

  /// Finished turns, oldest first.
  final List<AiTurn> turns;
  final bool sending;

  /// The answer being streamed, while [sending].
  final String? reply;

  /// Scout reports left out of this chat's data to keep it small.
  final int omittedReports;

  /// When this chat's event data was gathered.
  final DateTime? dataAsOf;

  final AiErrorCode? errorCode;
  final String? errorMessage;

  /// The question that failed, to put back in the input box.
  final String? unsentQuestion;

  AiChatState copyWith({
    String? reply,
    int? omittedReports,
    DateTime? dataAsOf,
  }) =>
      AiChatState(
        turns: turns,
        sending: sending,
        reply: reply ?? this.reply,
        omittedReports: omittedReports ?? this.omittedReports,
        dataAsOf: dataAsOf ?? this.dataAsOf,
        errorCode: errorCode,
        errorMessage: errorMessage,
        unsentQuestion: unsentQuestion,
      );

  @override
  List<Object?> get props => [
        turns,
        sending,
        reply,
        omittedReports,
        dataAsOf,
        errorCode,
        errorMessage,
        unsentQuestion,
      ];
}
