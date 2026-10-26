import 'rating_model.dart';

/// One event's ratings, as [ScheduleRepository.fetchTeamRatings] returns them:
/// TBA's own numbers for each team, for display, and the [RatingModel] fit to
/// the event's scores, which match predictions read.
class EventRatings {
  const EventRatings({this.teams = const {}, this.model = RatingModel.empty});

  /// No ratings at all: predictions don't render.
  static const empty = EventRatings();

  /// TBA's numbers per team (OPR, rank, record…), keyed by team number.
  final Map<int, TeamRating> teams;

  final RatingModel model;
}

/// Everything we know about one team's strength at an event, sourced entirely
/// from The Blue Alliance — no human scouting. Assembled by
/// [ScheduleRepository.fetchTeamRatings] from `/oprs`, `/rankings`, and the
/// played matches already loaded for the schedule.
class TeamRating {
  const TeamRating({
    required this.team,
    required this.opr,
    required this.dpr,
    required this.ccwm,
    this.avgRp,
    this.winRate,
    this.wins,
    this.losses,
    this.ties,
    this.rank,
    this.scoreMean,
    this.scoreStd,
    this.matchesPlayed = 0,
    this.contribMedian,
    this.contribStd,
    this.lowMatchCount,
    this.sourceEventKey,
  });

  final int team;

  /// Offensive Power Rating — estimated average points contributed. Additive,
  /// so an alliance's expected score ≈ the sum of its members' OPRs.
  final double opr;

  /// Defensive Power Rating — estimated points the opposing alliance scores
  /// against this team. Lower = stronger defense.
  final double dpr;

  /// Calculated Contribution to Winning Margin = opr - dpr.
  final double ccwm;

  /// Average ranking points per match (TBA "Ranking Score"), if ranked yet.
  final double? avgRp;

  /// Win fraction from the team's W-L-T record, if available.
  final double? winRate;

  /// Official W-L-T from TBA rankings, if available.
  final int? wins;
  final int? losses;
  final int? ties;

  /// Current event rank, if ranked yet.
  final int? rank;

  /// Mean of the alliance scores in this team's played matches.
  final double? scoreMean;

  /// Std dev of those alliance scores — the team's real "spread". Null until
  /// enough matches are played to be meaningful.
  final double? scoreStd;

  /// How many played matches fed [scoreMean] / [scoreStd].
  final int matchesPlayed;

  // ── Implied contribution ──────────────────────────────────────────────────
  //
  // Per match: `allianceScore - Σ(OPR of the other two alliance members)`, i.e.
  // what this robot appears to have put on the board that match. Unlike OPR —
  // a least-squares fit with a breakdown point of zero — the *median* of these
  // is unmoved by a handful of matches where the robot was disabled.

  /// Median implied contribution across played matches. Null below 1 match.
  final double? contribMedian;

  /// Sample std of the implied contributions. Deliberately *not* robust: a team
  /// with dead matches genuinely is inconsistent, and the reliability bucket
  /// should say so. Null below 2 matches.
  final double? contribStd;

  /// Matches where output collapsed by more than two of the event's typical
  /// swings — the "the robot wasn't working" count. Null below 2 matches.
  final int? lowMatchCount;

  /// The earlier event this rating was borrowed from, or null when it was
  /// measured at the current event. Set before an event's first matches, when
  /// TBA has no OPRs yet — see [ScheduleRepository.fetchTeamRatings]. Every
  /// field above (rank and record included) describes *that* event.
  final String? sourceEventKey;

  /// Whether this is a pre-comp estimate from an earlier event.
  bool get isPreComp => sourceEventKey != null;

  /// This rating, tagged as borrowed from [eventKey].
  TeamRating withSource(String eventKey) => TeamRating(
        team: team,
        opr: opr,
        dpr: dpr,
        ccwm: ccwm,
        avgRp: avgRp,
        winRate: winRate,
        wins: wins,
        losses: losses,
        ties: ties,
        rank: rank,
        scoreMean: scoreMean,
        scoreStd: scoreStd,
        matchesPlayed: matchesPlayed,
        contribMedian: contribMedian,
        contribStd: contribStd,
        lowMatchCount: lowMatchCount,
        sourceEventKey: eventKey,
      );

  Map<String, dynamic> toJson() => {
        'team': team,
        'opr': opr,
        'dpr': dpr,
        'ccwm': ccwm,
        'avgRp': avgRp,
        'winRate': winRate,
        'wins': wins,
        'losses': losses,
        'ties': ties,
        'rank': rank,
        'scoreMean': scoreMean,
        'scoreStd': scoreStd,
        'matchesPlayed': matchesPlayed,
        'contribMedian': contribMedian,
        'contribStd': contribStd,
        'lowMatchCount': lowMatchCount,
        'sourceEventKey': sourceEventKey,
      };

  // JSON doesn't keep 50.0 apart from 50, so every number is read as num.
  factory TeamRating.fromJson(Map<String, dynamic> json) => TeamRating(
        team: (json['team'] as num).toInt(),
        opr: (json['opr'] as num).toDouble(),
        dpr: (json['dpr'] as num).toDouble(),
        ccwm: (json['ccwm'] as num).toDouble(),
        avgRp: (json['avgRp'] as num?)?.toDouble(),
        winRate: (json['winRate'] as num?)?.toDouble(),
        wins: (json['wins'] as num?)?.toInt(),
        losses: (json['losses'] as num?)?.toInt(),
        ties: (json['ties'] as num?)?.toInt(),
        rank: (json['rank'] as num?)?.toInt(),
        scoreMean: (json['scoreMean'] as num?)?.toDouble(),
        scoreStd: (json['scoreStd'] as num?)?.toDouble(),
        matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
        contribMedian: (json['contribMedian'] as num?)?.toDouble(),
        contribStd: (json['contribStd'] as num?)?.toDouble(),
        lowMatchCount: (json['lowMatchCount'] as num?)?.toInt(),
        sourceEventKey: json['sourceEventKey'] as String?,
      );

  /// W-L-T formatted as "8-2-0", or null if record not yet available.
  String? get record {
    if (wins == null || losses == null || ties == null) return null;
    return '$wins-$losses-$ties';
  }
}
