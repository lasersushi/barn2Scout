import 'package:barn2scout/data/models/nexus_pit_map.dart';
import 'package:barn2scout/features/teams/view/pit_venue_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Trimmed from the real 2026minor `/map` response.
const _minor = {
  'size': {'x': 872, 'y': 1079},
  'areas': {
    'a0': {
      'label': 'Pit admin',
      'position': {'x': 173, 'y': 105},
      'size': {'x': 134, 'y': 100},
    },
  },
  'arrows': {
    'r1': {
      'angle': 180,
      'color': 'blue',
      'position': {'x': 804, 'y': 46},
      'size': {'x': 46, 'y': 86},
      'type': 'single',
    },
  },
  'labels': {
    'l0': {
      'label': 'Field',
      'position': {'x': 61.2329, 'y': 107.19},
      'size': {'x': 55, 'y': 55},
    },
  },
  'pits': {
    'A2': {
      'position': {'x': 88, 'y': 284},
      'size': {'x': 100, 'y': 100},
      'team': '751',
    },
    'H3': {
      'position': {'x': 784, 'y': 384},
      'size': {'x': 100, 'y': 100},
    },
  },
  'walls': {
    'w0': {
      'position': {'x': 10, 'y': 551},
      'size': {'x': 20, 'y': 1016},
    },
  },
};

void main() {
  group('NexusPitMap.parse', () {
    test('positions are centers, parsed into rects', () {
      final map = NexusPitMap.parse(_minor)!;

      expect(map.size, const Size(872, 1079));
      // 20-wide wall centered at x=10 sits flush with the left edge.
      expect(map.walls.single, const Rect.fromLTWH(0, 43, 20, 1016));
      expect(map.pits.first.rect, const Rect.fromLTWH(38, 234, 100, 100));
      expect(map.areas.single.label, 'Pit admin');
      expect(map.labels.single.label, 'Field');
      expect(map.arrows.single.angleDegrees, 180);
      expect(map.arrows.single.isDouble, isFalse);
    });

    test('a pit without a team is unassigned, not dropped', () {
      final pits = NexusPitMap.parse(_minor)!.pits;

      expect(pits.map((p) => p.label), ['A2', 'H3']);
      expect(pits.firstWhere((p) => p.label == 'H3').team, isNull);
    });

    test('missing collections are empty; "No map." is null', () {
      final map = NexusPitMap.parse({
        'size': {'x': 100, 'y': 100},
        'pits': {},
      })!;

      expect(map.walls, isEmpty);
      expect(map.arrows, isEmpty);
      expect(NexusPitMap.parse('No map.'), isNull);
      expect(NexusPitMap.parse({'pits': {}}), isNull);
    });
  });

  testWidgets('PitVenueMap stars 751 and labels unassigned pits',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PitVenueMap(map: NexusPitMap.parse(_minor)!)),
    ));

    expect(find.text('751'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.text('H3'), findsOneWidget);
    expect(find.text('Pit admin'), findsOneWidget);
    expect(find.text('Field'), findsOneWidget);
  });
}
