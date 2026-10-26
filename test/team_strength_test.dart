import 'package:barn2scout/data/models/rating_model.dart';
import 'package:barn2scout/data/models/team_rating.dart';
import 'package:barn2scout/data/models/team_strength.dart';
import 'package:flutter_test/flutter_test.dart';

TeamRating _r(
  int team, {
  required double opr,
  required double dpr,
  double? avgRp,
  double? winRate,
  double? contribMedian,
  double? contribStd,
  int? lowMatchCount,
  int matchesPlayed = 8,
}) =>
    TeamRating(
      team: team,
      opr: opr,
      dpr: dpr,
      ccwm: opr - dpr,
      avgRp: avgRp,
      winRate: winRate,
      matchesPlayed: matchesPlayed,
      contribMedian: contribMedian,
      contribStd: contribStd,
      lowMatchCount: lowMatchCount,
    );

/// [teams] with a model that expects [points] (keyed by team number) and
/// [meanTeamPoints] from anyone else.
EventRatings _event(
  Map<int, TeamRating> teams, {
  Map<int, double> points = const {},
  double meanTeamPoints = 0,
}) =>
    EventRatings(
      teams: teams,
      model: RatingModel(
        expectedPoints: {
          for (final MapEntry(:key, :value) in points.entries) 'frc$key': value,
        },
        meanTeamPoints: meanTeamPoints,
      ),
    );

void main() {
  group('TeamStrength.rank', () {
    final ratings = {
      254: _r(254,
          opr: 45,
          dpr: 20,
          avgRp: 2.5,
          winRate: 0.9,
          contribMedian: 46,
          contribStd: 6),
      1678: _r(1678,
          opr: 40,
          dpr: 22,
          avgRp: 2.2,
          winRate: 0.8,
          contribMedian: 42,
          contribStd: 12),
      9999: _r(9999,
          opr: 10,
          dpr: 30,
          avgRp: 1.0,
          winRate: 0.2,
          contribMedian: 9,
          contribStd: 30),
      // No ranking data, no matches played, no contribution → no bucket.
      4414: _r(4414, opr: 25, dpr: 25, matchesPlayed: 0),
    };

    test('ranks by the model\'s expected points, not OPR', () {
      // 1678 has the lower OPR here, but the model (which also knows its
      // earlier events) expects more from it.
      final ranked = TeamStrength.rank(_event(
        ratings,
        points: {254: 44, 1678: 48, 9999: 12},
        meanTeamPoints: 30,
      ));

      expect(ranked.map((s) => s.team).toList(), [1678, 254, 4414, 9999]);
      expect(ranked.first.expectedPoints, 48);
    });

    test('a team the model knows nothing about counts as average', () {
      final s = TeamStrength.rank(_event(
        ratings,
        points: {254: 44, 1678: 48, 9999: 12},
        meanTeamPoints: 30,
      )).firstWhere((s) => s.team == 4414);

      expect(s.expectedPoints, 30);
    });

    test('reliability bucket spreads across all three values', () {
      final byTeam = {
        for (final s in TeamStrength.rank(_event(ratings))) s.team: s,
      };
      // Stability = std/sqrt(median): 0.88, 1.85, 10.0 → field median 1.85.
      // Cutoffs 0.90 / 1.20.
      expect(byTeam[254]!.reliabilityBucket, 0); // 0.88/1.85 = 0.48 steady
      expect(byTeam[1678]!.reliabilityBucket, 1); // 1.85/1.85 = 1.00 variable
      expect(byTeam[9999]!.reliabilityBucket, 2); // 10.0/1.85 = 5.40 streaky
      expect(byTeam[4414]!.reliabilityBucket, isNull); // no matches played
    });

    // Raw swing magnitude must not decide the bucket. Comparing bare stds
    // marked every big scorer streaky — 254 was flagged at 2026 NorCal DCMP
    // despite a 100% win rate — because contribution std grows with output.
    // Here the big scorer swings twice as far in absolute points (80 vs 40)
    // and must still read steadier, because 80 on a 400 median is proportion-
    // ally calm while 40 on a 25 median is not.
    test('a big scorer is not streaky merely for swinging more points', () {
      final mixed = {
        1: _r(1, opr: 400, dpr: 50, contribMedian: 400, contribStd: 80),
        2: _r(2, opr: 25, dpr: 50, contribMedian: 25, contribStd: 40),
      };
      final byTeam = {
        for (final s in TeamStrength.rank(_event(mixed))) s.team: s,
      };
      expect(byTeam[1]!.reliabilityBucket, 0); // (80/20)/6.0 = 0.67 steady
      expect(byTeam[2]!.reliabilityBucket, 2); // (40/5)/6.0  = 1.33 streaky
    });

    test('bucket is null below the minimum match count', () {
      final thin = {
        1: _r(1,
            opr: 30,
            dpr: 20,
            contribMedian: 30,
            contribStd: 5,
            matchesPlayed: 2),
      };
      expect(
          TeamStrength.rank(_event(thin)).single.reliabilityBucket, isNull);
    });

    test('empty ratings yield no ranking', () {
      expect(TeamStrength.rank(EventRatings.empty), isEmpty);
    });
  });
}
