import 'package:equatable/equatable.dart';

/// The four AI features. [wire] is the `kind` the `ai` Edge Function takes.
enum AiKind {
  teamSummary('team_summary'),
  matchBrief('match_brief'),
  picklistReview('picklist_review'),
  chat('chat');

  const AiKind(this.wire);
  final String wire;

  static AiKind? fromWire(String value) {
    for (final k in values) {
      if (k.wire == value) return k;
    }
    return null;
  }
}

/// Why an AI request failed, as the app shows it.
enum AiErrorCode {
  /// No connection to the server.
  offline,

  /// Session expired or missing.
  unauthorized,

  /// This account doesn't have the feature (e.g. chat without the AI role).
  forbidden,

  /// A regular scouter used up today's generations.
  dailyLimit,

  /// The team-wide monthly or yearly spending ceiling was reached.
  budgetReached,

  /// The model declined the request.
  refused,

  /// Malformed request; a bug, not something the user can fix.
  badRequest,

  /// Anything else on the server or Claude side.
  server;

  static AiErrorCode fromWire(String? code) => switch (code) {
        'unauthorized' => unauthorized,
        'forbidden' => forbidden,
        'daily_limit' => dailyLimit,
        'budget_reached' => budgetReached,
        'refused' => refused,
        'bad_request' => badRequest,
        _ => server,
      };
}

/// One event in a streamed AI answer.
sealed class AiEvent extends Equatable {
  const AiEvent();
}

/// More answer text.
class AiDelta extends AiEvent {
  const AiDelta(this.text);
  final String text;

  @override
  List<Object?> get props => [text];
}

/// The answer finished.
class AiDone extends AiEvent {
  const AiDone({
    this.cached = false,
    this.truncated = false,
    this.remainingToday,
  });

  /// Served from the shared cache: free, and didn't use a daily generation.
  final bool cached;

  /// The answer hit its length limit and was cut short.
  final bool truncated;

  /// Generations left today, or null for unlimited users.
  final int? remainingToday;

  @override
  List<Object?> get props => [cached, truncated, remainingToday];
}

/// The request failed; no more events follow.
class AiFailure extends AiEvent {
  const AiFailure(this.code, this.message);
  final AiErrorCode code;
  final String message;

  @override
  List<Object?> get props => [code, message];
}

/// What the signed-in user may do with AI, from the server.
class AiAccess extends Equatable {
  const AiAccess({
    required this.kinds,
    required this.unlimited,
    required this.isAdmin,
    this.dailyLimit,
    this.remainingToday,
  });

  factory AiAccess.fromJson(Map<String, dynamic> json) => AiAccess(
        kinds: {
          for (final k in (json['kinds'] as List? ?? const []))
            ?AiKind.fromWire(k as String),
        },
        unlimited: json['unlimited'] as bool? ?? false,
        isAdmin: json['isAdmin'] as bool? ?? false,
        dailyLimit: json['dailyLimit'] as int?,
        remainingToday: json['remainingToday'] as int?,
      );

  final Set<AiKind> kinds;

  /// Admin or AI role: no daily limit.
  final bool unlimited;
  final bool isAdmin;

  /// Generations per day for limited users; null when unlimited.
  final int? dailyLimit;
  final int? remainingToday;

  bool can(AiKind kind) => kinds.contains(kind);

  AiAccess withRemaining(int? remaining) => AiAccess(
        kinds: kinds,
        unlimited: unlimited,
        isAdmin: isAdmin,
        dailyLimit: dailyLimit,
        remainingToday: remaining,
      );

  @override
  List<Object?> get props =>
      [kinds, unlimited, isAdmin, dailyLimit, remainingToday];
}

/// One message in an AI chat.
class AiTurn extends Equatable {
  const AiTurn.user(this.text) : fromUser = true;
  const AiTurn.assistant(this.text) : fromUser = false;

  final bool fromUser;
  final String text;

  Map<String, dynamic> toJson() =>
      {'role': fromUser ? 'user' : 'assistant', 'text': text};

  @override
  List<Object?> get props => [fromUser, text];
}

/// The data sent with an AI request, plus how many scout reports were left
/// out to keep it small (shown to the user so trimming is never silent).
class AiPayload {
  const AiPayload(this.data, {this.omittedReports = 0});
  final Map<String, dynamic> data;
  final int omittedReports;
}
