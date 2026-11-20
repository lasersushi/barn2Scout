import 'dart:convert';

import 'package:barn2scout/data/models/match_prediction.dart';
import 'package:barn2scout/data/models/pit_scouting_record.dart';
import 'package:barn2scout/data/models/scouting_record.dart';
import 'package:barn2scout/data/models/tba_match.dart';
import 'package:barn2scout/data/models/team_rating.dart';
import 'package:barn2scout/data/models/team_strength.dart';
import 'package:barn2scout/features/ai/context/ai_context_builder.dart';
import 'package:barn2scout/features/scouting/config/field_labels.dart';
import 'package:flutter_test/flutter_test.dart';

ScoutingRecord _match(
  int team,
  int match, {
  String notes = '',
  Map<String, dynamic> teleop = const {},
  String scouter = 'Alex',
}) =>
    ScoutingRecord.create(
      uuid: 'm-$team-$match-$scouter',
      teamNumber: team,
      matchNumber: match,
      eventKey: '2026cacac',
      scouterName: scouter,
      timestamp: DateTime(2026, 3, 1, 9, match),
      autoData: const {'auto_left_line': true, 'auto_rating': 4},
      teleopData: teleop,
      notes: notes,
    );

PitScoutingRecord _pit(int team, DateTime when, String notes) =>
    PitScoutingRecord.create(
      uuid: 'p-$team-${when.millisecondsSinceEpoch}',
      teamNumber: team,
      eventKey: '2026cacac',
      scouterName: 'Sam',
      timestamp: when,
      pitData: const {'pit_drivetrain': 'Swerve'},
      notes: notes,
    );

TeamStrength _strength(int team, double points, {int? rank}) => TeamStrength(
      rating: TeamRating(
        team: team,
        opr: points + 0.04,
        dpr: 10,
        ccwm: points - 10,
        rank: rank,
        wins: 3,
        losses: 1,
        ties: 0,
        matchesPlayed: 4,
      ),
      expectedPoints: points,
      reliabilityBucket: 0,
    );

void main() {
  group('reports', () {
    test('use form labels, rating scale and trimmed notes', () {
      final r = AiContextBuilder.matchReport(_match(254, 3, notes: '  fast  '));
      expect(r['match'], 3);
      expect(r['auto'], {
        fieldLabel('auto_left_line'): true,
        fieldLabel('auto_rating'): '4/5',
      });
      expect(r['notes'], 'fast');
      expect(r.containsKey('teleop'), isFalse, reason: 'empty phase left out');
    });

    test('leave out scouter names and timestamps', () {
      final json = jsonEncode(AiContextBuilder.teamSummary(
        team: 254,
        strength: null,
        matchRecords: [_match(254, 1, notes: 'ok', scouter: 'Alex Kim')],
        pitRecords: [_pit(254, DateTime(2026, 3, 1), 'nice')],
      ).data);
      expect(json, isNot(contains('Alex Kim')));
      expect(json, isNot(contains('Sam')));
      expect(json, isNot(contains('2026-03-01')));
    });
  });

  group('teamSummary', () {
    test('only that team, in match order, with TBA numbers rounded', () {
      final p = AiContextBuilder.teamSummary(
        team: 254,
        strength: _strength(254, 41.26, rank: 2),
        matchRecords: [_match(254, 9), _match(1678, 1), _match(254, 2)],
        pitRecords: [_pit(1678, DateTime(2026), 'other team')],
      );
      final reports = p.data['matchReports'] as List;
      expect([for (final r in reports) r['match']], [2, 9]);
      expect(p.data['pitReports'], isEmpty);
      final tba = p.data['tba'] as Map<String, dynamic>;
      expect(tba['expectedPoints'], 41.3);
      expect(tba['rank'], 2);
      expect(tba['record'], isNotNull);
      expect(tba['reliability'], 'steady');
      expect(p.omittedReports, 0);
    });

    test('never adds scouting aggregates', () {
      final p = AiContextBuilder.teamSummary(
        team: 254,
        strength: null,
        matchRecords: [
          for (var m = 1; m <= 5; m++)
            _match(254, m, teleop: const {'teleop_offense': 3}),
        ],
        pitRecords: const [],
      );
      expect(p.data.keys.toSet(), {'team', 'tba', 'matchReports', 'pitReports'});
      final json = jsonEncode(p.data).toLowerCase();
      for (final word in ['average', 'mean', 'total', 'sum']) {
        expect(json, isNot(contains(word)));
      }
    });

    test('same records in any order give the same payload', () {
      final records = [_match(254, 1), _match(254, 2), _match(254, 3)];
      String build(List<ScoutingRecord> rs) => jsonEncode(
            AiContextBuilder.teamSummary(
              team: 254,
              strength: null,
              matchRecords: rs,
              pitRecords: const [],
            ).data,
          );
      expect(build(records), build(records.reversed.toList()));
    });
  });

  test('trimming drops oldest reports and says how many', () {
    final long = 'x' * 2000;
    final p = AiContextBuilder.eventChat(
      ourTeam: 751,
      roster: {254, 1678},
      strengths: const {},
      ourUpcoming: const [],
      matchRecords: [
        for (var m = 1; m <= 40; m++) _match(254, m, notes: long),
        for (var m = 1; m <= 10; m++) _match(1678, m, notes: long),
      ],
      pitRecords: const [],
    );
    expect(jsonEncode(p.data).length,
        lessThanOrEqualTo(AiContextBuilder.chatChars));
    expect(p.omittedReports, greaterThan(0));
    expect(p.data['omittedReports'], p.omittedReports);
    final teams = {
      for (final t in p.data['teams'] as List) t['team']: t['matchReports'] as List,
    };
    // The team with the most reports lost its oldest ones first.
    expect((teams[254]!.first as Map)['match'], greaterThan(1));
    expect(teams[1678], hasLength(10));
  });

  test('matchBrief marks our side and carries the prediction', () {
    const match = TbaMatch(
      key: '2026cacac_qm12',
      compLevel: 'qm',
      setNumber: 1,
      matchNumber: 12,
      redTeams: ['frc751', 'frc254', 'frc1678B'],
      blueTeams: ['frc971', 'frc973', 'frc604'],
    );
    final p = AiContextBuilder.matchBrief(
      match: match,
      ourTeamKey: 'frc751',
      strengths: {254: _strength(254, 40)},
      prediction: const MatchPrediction(
        redScore: 101.4,
        blueScore: 88.6,
        redWinPct: 0.714,
        ratedTeams: 5,
      ),
      matchRecords: [_match(254, 3, notes: 'strong'), _match(9999, 1)],
      pitRecords: const [],
    );
    expect(p.data['match'], 'Qual 12');
    expect(p.data['ourAlliance'], 'red');
    expect(p.data['prediction'], {
      'redScore': 101,
      'blueScore': 89,
      'redWinPercent': 71,
      'teamsWithRatings': 5,
    });
    final red = p.data['red'] as List;
    expect(red.map((t) => t['team']), ['751', '254', '1678B']);
    expect((red[1]['matchReports'] as List), hasLength(1));
    expect(red[1]['tba'], isNotNull);
    expect(red[2]['tba'], isNull, reason: 'B-team has no int key');
  });

  test('picklistReview keeps rating order and status', () {
    final p = AiContextBuilder.picklistReview(
      teams: [_strength(254, 50), _strength(1678, 45)],
      statusOf: (t) => t == 254 ? 'picked' : 'vetoed',
      priorityOf: (t) => t == 254 ? 1 : null,
      matchRecords: const [],
      pitRecords: const [],
    );
    final teams = p.data['teams'] as List;
    expect(teams[0], containsPair('ratingRank', 1));
    expect(teams[0], containsPair('priority', 1));
    expect(teams[1], containsPair('status', 'vetoed'));
    expect((teams[1] as Map).containsKey('priority'), isFalse);
  });
}
