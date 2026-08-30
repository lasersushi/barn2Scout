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
          contribStd: 25),
      9999: _r(9999,
          opr: 10,
          dpr: 30,
          avgRp: 1.0,
          winRate: 0.2,
          contribMedian: 9,
          contribStd: 12),
      // No ranking data, no matches played, no contribution → falls back to
      // OPR for the base and yields no bucket.
      4414: _r(4414, opr: 25, dpr: 25, matchesPlayed: 0),
    };

    test('ranks by blended strength, descending', () {
      final ranked = TeamStrength.rank(ratings);
      expect(ranked.map((s) => s.team).toList(), [254, 1678, 4414, 9999]);
    });

    test('blend builds on median contribution, not OPR', () {
      final top = TeamStrength.rank(ratings).first;
      // meanDpr = 24.25, meanRp = 1.9. Base is contribMedian 46, not OPR 45.
      // 46 + 0.3*(24.25-20) + 2.0*(2.5-1.9) + 4.0*(0.9-0.5) = 50.075
      expect(top.team, 254);
      expect(top.blend, closeTo(50.075, 1e-6));
    });

    test('falls back to OPR when no contribution is available', () {
      final s = TeamStrength.rank(ratings).firstWhere((s) => s.team == 4414);
      // Base = OPR 25; avgRp/winRate null → those terms contribute 0.
      // 25 + 0.3*(24.25-25) = 24.775
      expect(s.blend, closeTo(24.775, 1e-6));
    });

    test('reliability bucket spreads across all three values', () {
      final byTeam = {for (final s in TeamStrength.rank(ratings)) s.team: s};
      // meanContrib = 32.33, floor = 8.08. Cutoffs are 0.45 / 0.95, the
      // terciles measured at 2026 NorCal DCMP.
      expect(byTeam[254]!.reliabilityBucket, 0); // 6/46  = 0.13 steady
      expect(byTeam[1678]!.reliabilityBucket, 1); // 25/42 = 0.60 variable
      expect(byTeam[9999]!.reliabilityBucket, 2); // 12/9  = 1.33 streaky
      expect(byTeam[4414]!.reliabilityBucket, isNull); // no matches played
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
      expect(TeamStrength.rank(thin).single.reliabilityBucket, isNull);
    });

    test('the DPR term cannot move a team more than the clamp', () {
      final extremes = {
        1: _r(1, opr: 100, dpr: 20, contribMedian: 100, contribStd: 5),
        2: _r(2, opr: 100, dpr: 200, contribMedian: 100, contribStd: 5),
      };
      final byTeam = {for (final s in TeamStrength.rank(extremes)) s.team: s};
      // meanDpr = 110. Raw adjustments are +27 and -27; both clamp to ±5.
      expect(byTeam[1]!.blend, closeTo(105, 1e-6));
      expect(byTeam[2]!.blend, closeTo(95, 1e-6));
    });

    // Regression: 2026 NorCal DCMP put 1678 (official rank #6, 13-6-0) at 11th,
    // below 1868 (official rank #27), purely because a weekend of connection
    // issues inflated 1678's DPR to 142 against a 58-111 field. Uncapped, that
    // one term swung 0.3 * 47 = 14.1 points and outweighed 1678's lead on OPR,
    // ranking points, and record combined.
    test('an inflated DPR no longer outranks a stronger team', () {
      final norcal = {
        1868: _r(1868,
            opr: 190,
            dpr: 95,
            avgRp: 2.8,
            winRate: 0.5,
            contribMedian: 190,
            contribStd: 40,
            matchesPlayed: 19),
        1678: _r(1678,
            opr: 200,
            dpr: 142,
            avgRp: 3.9,
            winRate: 13 / 19,
            contribMedian: 200,
            contribStd: 70,
            lowMatchCount: 3,
            matchesPlayed: 19),
      };
      final ranked = TeamStrength.rank(norcal);
      expect(ranked.first.team, 1678);

      final byTeam = {for (final s in ranked) s.team: s};
      // meanDpr = 118.5, meanRp = 3.35. Both DPR adjustments clamp to ±5.
      // 1678: 200 - 5 + 2.0*(3.9-3.35) + 4.0*(13/19 - 0.5) = 196.84
      // 1868: 190 + 5 + 2.0*(2.8-3.35) + 0                 = 193.90
      expect(byTeam[1678]!.blend, closeTo(196.836, 1e-3));
      expect(byTeam[1868]!.blend, closeTo(193.9, 1e-3));
    });

    test('empty ratings yield no ranking', () {
      expect(TeamStrength.rank(const {}), isEmpty);
    });
  });
}
