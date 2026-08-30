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

  /// Matches sitting more than 2 robust sigma (MAD-derived) below
  /// [contribMedian] — the "the robot wasn't working" count. Null below 2.
  final int? lowMatchCount;

  /// W-L-T formatted as "8-2-0", or null if record not yet available.
  String? get record {
    if (wins == null || losses == null || ties == null) return null;
    return '$wins-$losses-$ties';
  }
}
