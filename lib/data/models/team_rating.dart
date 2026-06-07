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

  /// W-L-T formatted as "8-2-0", or null if record not yet available.
  String? get record {
    if (wins == null || losses == null || ties == null) return null;
    return '$wins-$losses-$ties';
  }
}
