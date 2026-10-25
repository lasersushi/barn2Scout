import 'package:barn2scout/data/models/nexus_pit.dart';
import 'package:barn2scout/features/teams/cubit/teams_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NexusPit.parseResponse', () {
    test('reads Nexus team → pit map the right way round', () {
      // Shape from 2026vagle1: keyed by team number, valued by pit label.
      final pits = NexusPit.parseResponse({
        '751': 'C2',
        '122': 'A11',
        '339': 'A13',
        '422': 'A3',
        '100B': 'C16',
      });

      expect(pits.map((p) => p.label), ['A3', 'A11', 'A13', 'C2', 'C16']);
      final mine = pits.firstWhere((p) => p.teamNumber == '751');
      expect(mine.label, 'C2');
      expect(mine.row, 'C');
      expect(mine.slot, 2);
    });

    test('groups into one row per letter, not one per team', () {
      final s = TeamsLoaded(
        eventKey: '2026test',
        pits: NexusPit.parseResponse(
            {'498': 'C1', '2375': 'C2', '2403': 'B1', '991': 'G2'}),
      );

      expect(s.byRow.keys.toSet(), {'B', 'C', 'G'});
      expect(s.byRow['C']!.map((p) => p.teamNumber), ['498', '2375']);
    });

    test('"No pits." string and blank labels yield nothing', () {
      expect(NexusPit.parseResponse('No pits.'), isEmpty);
      expect(NexusPit.parseResponse({'751': '', '254': null}), isEmpty);
    });
  });
}
