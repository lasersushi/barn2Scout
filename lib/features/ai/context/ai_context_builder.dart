import 'dart:convert';

import '../../../data/models/ai_models.dart';
import '../../../data/models/match_prediction.dart';
import '../../../data/models/pit_scouting_record.dart';
import '../../../data/models/scouting_record.dart';
import '../../../data/models/tba_match.dart';
import '../../../data/models/team_strength.dart';
import '../../scouting/config/field_config.dart';
import '../../scouting/config/field_labels.dart';

/// Builds the data each AI request carries. Pure: no I/O, so it's unit-tested
/// directly.
///
/// Two rules shape every payload:
/// - **Numbers come from TBA only.** The `tba` section is TBA-derived (the same
///   [TeamStrength] the picklist uses). Scout reports go in as raw, labelled,
///   per-match observations, never averaged or totalled here, so the AI can't
///   be handed a scouting-derived metric (CLAUDE.md analytics rule).
/// - **Same data, same bytes.** Records are sorted and timestamps and scouter
///   names are left out, so unchanged data hashes to the same server cache key
///   and the shared cache hits. Names also stay off a third-party API.
class AiContextBuilder {
  const AiContextBuilder._();

  /// Size budgets in characters of JSON (≈ 4 characters per token).
  static const teamSummaryChars = 60000;
  static const matchBriefChars = 80000;
  static const picklistChars = 120000;
  static const chatChars = 100000;

  static const _reliability = ['steady', 'variable', 'streaky'];

  // ── Building blocks ────────────────────────────────────────────────────────

  /// TBA numbers for one team, or null when TBA has none.
  static Map<String, dynamic>? tba(TeamStrength? s) {
    if (s == null) return null;
    final r = s.rating;
    return {
      'expectedPoints': _round(s.expectedPoints),
      'opr': _round(r.opr),
      'dpr': _round(r.dpr),
      'ccwm': _round(r.ccwm),
      'rank': ?r.rank,
      'record': ?r.record,
      if (r.avgRp != null) 'avgRankingPoints': _round(r.avgRp!),
      'matchesPlayed': r.matchesPlayed,
      if (s.reliabilityBucket != null)
        'reliability': _reliability[s.reliabilityBucket!],
      if (r.lowMatchCount != null) 'lowOutputMatches': r.lowMatchCount,
      if (r.sourceEventKey != null)
        'note': 'Pre-competition estimate borrowed from ${r.sourceEventKey}; '
            'this event has no TBA stats yet.',
    };
  }

  /// One match report: labelled field values by phase, plus notes.
  static Map<String, dynamic> matchReport(ScoutingRecord r) {
    final report = <String, dynamic>{'match': r.matchNumber};
    for (final (phase, data) in [
      ('auto', r.autoData),
      ('teleop', r.teleopData),
      ('endgame', r.endgameData),
    ]) {
      final fields = _labelled(data);
      if (fields.isNotEmpty) report[phase] = fields;
    }
    if (r.notes.trim().isNotEmpty) report['notes'] = r.notes.trim();
    return report;
  }

  /// One pit report: labelled field values plus notes.
  static Map<String, dynamic> pitReport(PitScoutingRecord r) => {
        ..._labelled(r.pitData),
        if (r.notes.trim().isNotEmpty) 'notes': r.notes.trim(),
      };

  // ── Payloads ───────────────────────────────────────────────────────────────

  /// One team's summary. [matchRecords] / [pitRecords] may hold every team's
  /// records; only [team]'s are used.
  static AiPayload teamSummary({
    required int team,
    required TeamStrength? strength,
    required List<ScoutingRecord> matchRecords,
    required List<PitScoutingRecord> pitRecords,
  }) {
    final reports = _matchReportsByTeam(matchRecords, {team});
    final pits = _pitReportsByTeam(pitRecords, {team}, latestOnly: false);
    return _fit(reports, teamSummaryChars, (r) => {
          'team': team,
          'tba': tba(strength),
          'matchReports': r[team] ?? const [],
          'pitReports': pits[team] ?? const [],
        });
  }

  /// A strategy brief for [match], from [ourTeamKey]'s side.
  static AiPayload matchBrief({
    required TbaMatch match,
    required String ourTeamKey,
    required Map<int, TeamStrength> strengths,
    required MatchPrediction? prediction,
    required List<ScoutingRecord> matchRecords,
    required List<PitScoutingRecord> pitRecords,
  }) {
    final numbers = {
      for (final key in [...match.redTeams, ...match.blueTeams]) ?_number(key),
    };
    final reports = _matchReportsByTeam(matchRecords, numbers);
    final pits = _pitReportsByTeam(pitRecords, numbers, latestOnly: true);

    Map<String, dynamic> entry(String key, Map<int, List<Map<String, dynamic>>> r) {
      final n = _number(key);
      return {
        'team': TbaMatch.displayNumber(key),
        'tba': tba(strengths[n]),
        'matchReports': r[n] ?? const [],
        'pitReports': pits[n] ?? const [],
      };
    }

    return _fit(reports, matchBriefChars, (r) => {
          'match': match.label,
          'ourTeam': TbaMatch.displayNumber(ourTeamKey),
          'ourAlliance': ?match.allianceFor(ourTeamKey),
          if (prediction != null && prediction.hasData)
            'prediction': {
              'redScore': prediction.redScore.round(),
              'blueScore': prediction.blueScore.round(),
              'redWinPercent': (prediction.redWinPct * 100).round(),
              'teamsWithRatings': prediction.ratedTeams,
              if (prediction.preComp)
                'note': 'Pre-competition estimate from earlier events.',
            },
          'red': [for (final k in match.redTeams) entry(k, r)],
          'blue': [for (final k in match.blueTeams) entry(k, r)],
        });
  }

  /// The picklist with each team's rating, status and scout reports.
  /// [teams] is in rating order, as [TeamStrength.rank] returns it.
  static AiPayload picklistReview({
    required List<TeamStrength> teams,
    required String Function(int team) statusOf,
    required int? Function(int team) priorityOf,
    required List<ScoutingRecord> matchRecords,
    required List<PitScoutingRecord> pitRecords,
  }) {
    final numbers = {for (final t in teams) t.team};
    final reports = _matchReportsByTeam(matchRecords, numbers);
    final pits = _pitReportsByTeam(pitRecords, numbers, latestOnly: true);
    return _fit(reports, picklistChars, (r) => {
          'teams': [
            for (final (i, t) in teams.indexed)
              {
                'team': t.team,
                'ratingRank': i + 1,
                'status': statusOf(t.team),
                'priority': ?priorityOf(t.team),
                'tba': tba(t),
                'matchReports': r[t.team] ?? const [],
                'pitReports': pits[t.team] ?? const [],
              },
          ],
        });
  }

  /// Everything the chat needs about the event: every team we know of, and
  /// our upcoming matches.
  static AiPayload eventChat({
    required int ourTeam,
    required Set<int> roster,
    required Map<int, TeamStrength> strengths,
    required List<TbaMatch> ourUpcoming,
    required List<ScoutingRecord> matchRecords,
    required List<PitScoutingRecord> pitRecords,
  }) {
    final numbers = {
      ...roster,
      ...strengths.keys,
      for (final r in matchRecords) r.teamNumber,
      for (final r in pitRecords) r.teamNumber,
    }.toList()
      ..sort();
    final reports = _matchReportsByTeam(matchRecords, numbers.toSet());
    final pits = _pitReportsByTeam(pitRecords, numbers.toSet(), latestOnly: true);
    return _fit(reports, chatChars, (r) => {
          'ourTeam': ourTeam,
          'ourUpcomingMatches': [
            for (final m in ourUpcoming)
              {
                'match': m.label,
                'red': [for (final k in m.redTeams) TbaMatch.displayNumber(k)],
                'blue': [for (final k in m.blueTeams) TbaMatch.displayNumber(k)],
              },
          ],
          'teams': [
            for (final n in numbers)
              {
                'team': n,
                'tba': tba(strengths[n]),
                'matchReports': r[n] ?? const [],
                'pitReports': pits[n] ?? const [],
              },
          ],
        });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Builds with [build], dropping the oldest match report of whichever team
  /// has the most until the JSON fits [maxChars]. The count dropped is put in
  /// the payload so the model knows, and returned so the UI can say so.
  static AiPayload _fit(
    Map<int, List<Map<String, dynamic>>> reports,
    int maxChars,
    Map<String, dynamic> Function(Map<int, List<Map<String, dynamic>>>) build,
  ) {
    final working = {
      for (final e in reports.entries) e.key: [...e.value],
    };
    var omitted = 0;
    var data = build(working);
    while (jsonEncode(data).length > maxChars) {
      List<Map<String, dynamic>>? longest;
      for (final list in working.values) {
        if (list.isNotEmpty && (longest == null || list.length > longest.length)) {
          longest = list;
        }
      }
      if (longest == null) break; // nothing left to drop
      longest.removeAt(0); // oldest: lists are in match order
      omitted++;
      data = build(working);
    }
    if (omitted > 0) data = {...data, 'omittedReports': omitted};
    return AiPayload(data, omittedReports: omitted);
  }

  /// [teams]' match reports, each team's in match order.
  static Map<int, List<Map<String, dynamic>>> _matchReportsByTeam(
    List<ScoutingRecord> records,
    Set<int> teams,
  ) {
    final sorted = records.where((r) => teams.contains(r.teamNumber)).toList()
      ..sort((a, b) {
        final byMatch = a.matchNumber.compareTo(b.matchNumber);
        return byMatch != 0 ? byMatch : a.uuid.compareTo(b.uuid);
      });
    final out = <int, List<Map<String, dynamic>>>{};
    for (final r in sorted) {
      final report = matchReport(r);
      // A report with nothing but its match number tells the AI nothing.
      if (report.length > 1) (out[r.teamNumber] ??= []).add(report);
    }
    return out;
  }

  /// [teams]' pit reports, newest last; just the newest with [latestOnly].
  static Map<int, List<Map<String, dynamic>>> _pitReportsByTeam(
    List<PitScoutingRecord> records,
    Set<int> teams, {
    required bool latestOnly,
  }) {
    final sorted = records.where((r) => teams.contains(r.teamNumber)).toList()
      ..sort((a, b) {
        final byTime = a.timestamp.compareTo(b.timestamp);
        return byTime != 0 ? byTime : a.uuid.compareTo(b.uuid);
      });
    final out = <int, List<Map<String, dynamic>>>{};
    for (final r in sorted) {
      final report = pitReport(r);
      if (report.isEmpty) continue;
      if (latestOnly) {
        out[r.teamNumber] = [report];
      } else {
        (out[r.teamNumber] ??= []).add(report);
      }
    }
    return out;
  }

  /// Field values under their form labels, empty values left out.
  static Map<String, dynamic> _labelled(Map<String, dynamic> data) {
    final out = <String, dynamic>{};
    for (final MapEntry(:key, :value) in data.entries) {
      if (value == null || (value is String && value.trim().isEmpty)) continue;
      final field = fieldFor(key);
      out[fieldLabel(key)] = switch ((field?.type, value)) {
        (FieldType.rating, final num v) => '$v/${field!.max ?? 5}',
        (FieldType.stopwatch, final num v) => '${v}s',
        (_, final String v) => v.trim(),
        _ => value,
      };
    }
    return out;
  }

  static int? _number(String teamKey) =>
      int.tryParse(TbaMatch.displayNumber(teamKey));

  static double _round(double v) => (v * 10).roundToDouble() / 10;
}
