import 'package:barn2scout/data/models/team_rating.dart';
import 'package:barn2scout/data/models/team_strength.dart';
import 'package:flutter_test/flutter_test.dart';

TeamRating _r(
  int team, {
  required double opr,
  required double dpr,
  double? avgRp,
  double? winRate,
  double? scoreMean,
  double? scoreStd,
  int matchesPlayed = 8,
}) =>
    TeamRating(
      team: team,
      opr: opr,
      dpr: dpr,
      ccwm: opr - dpr,
      avgRp: avgRp,
      winRate: winRate,
      scoreMean: scoreMean,
      scoreStd: scoreStd,
      matchesPlayed: matchesPlayed,
    );

void main() {
  group('TeamStrength.rank', () {
    final ratings = {
      254: _r(254, opr: 45, dpr: 20, avgRp: 2.5, winRate: 0.9, scoreMean: 90, scoreStd: 6),
      1678: _r(1678, opr: 40, dpr: 22, avgRp: 2.2, winRate: 0.8, scoreMean: 80, scoreStd: 20),
      9999: _r(9999, opr: 10, dpr: 30, avgRp: 1.0, winRate: 0.2, scoreMean: 30, scoreStd: 4),
      // No ranking data and no matches played → blend uses fallbacks, no bucket.
      4414: _r(4414, opr: 25, dpr: 25, matchesPlayed: 0),
    };

    test('ranks by blended strength, descending', () {
      final ranked = TeamStrength.rank(ratings);
      expect(ranked.map((s) => s.team).toList(), [254, 1678, 4414, 9999]);
    });

    test('blend matches the prediction-weighted formula', () {
      final top = TeamStrength.rank(ratings).first;
      // meanDpr = 24.25, meanRp = 1.9
      // 45 + 0.3*(24.25-20) + 2.0*(2.5-1.9) + 4.0*(0.9-0.5) = 49.075
      expect(top.team, 254);
      expect(top.blend, closeTo(49.075, 1e-6));
    });

    test('missing ranking values fall back to the field average, not zero', () {
      final s = TeamStrength.rank(ratings).firstWhere((s) => s.team == 4414);
      // avgRp/winRate null → those terms contribute 0; only OPR + DPR nudge.
      // 25 + 0.3*(24.25-25) = 24.775
      expect(s.blend, closeTo(24.775, 1e-6));
    });

    test('reliability bucket comes from match-score spread', () {
      final byTeam = {for (final s in TeamStrength.rank(ratings)) s.team: s};
      expect(byTeam[254]!.reliabilityBucket, 0); // cv 6/90 ≈ 0.07 steady
      expect(byTeam[9999]!.reliabilityBucket, 1); // cv 4/30 ≈ 0.13 variable
      expect(byTeam[1678]!.reliabilityBucket, 2); // cv 20/80 = 0.25 streaky
      expect(byTeam[4414]!.reliabilityBucket, isNull); // no matches played
    });

    test('empty ratings yield no ranking', () {
      expect(TeamStrength.rank(const {}), isEmpty);
    });
  });
}
