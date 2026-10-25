import 'package:barn2scout/data/models/nexus_match.dart';
import 'package:barn2scout/data/models/tba_match.dart';
import 'package:barn2scout/data/repositories/schedule_repository.dart';
import 'package:barn2scout/features/schedule/cubit/schedule_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

TbaMatch _tba(String compLevel, int set, int match) => TbaMatch(
      key: '2026test_$compLevel${set}m$match',
      compLevel: compLevel,
      setNumber: set,
      matchNumber: match,
      redTeams: const ['frc751'],
      blueTeams: const ['frc254'],
    );

NexusMatch _nexus(String label, String status) => NexusMatch(
      label: label,
      status: status,
      redTeams: const [],
      blueTeams: const [],
    );

ScheduleLoaded _loaded(List<NexusMatch> nexus) => ScheduleLoaded(
      eventKey: '2026test',
      eventName: 'Test',
      eventStatus: EventStatus.active,
      allMatches: const [],
      nexusMatches: nexus,
      pastEventKey: '2026test',
      pastEventName: 'Test',
      pastAllMatches: const [],
    );

void main() {
  group('NexusMatch.fromJson', () {
    test('playoff match with undecided alliances parses as empty', () {
      // Real shape from 2026flpin: Nexus omits the team keys entirely until
      // the bracket fills in. This used to throw and kill the schedule load.
      final m = NexusMatch.fromJson({
        'label': 'Playoff 10',
        'status': 'Queuing soon',
        'times': {'estimatedQueueTime': 1792889792772},
      });

      expect(m.redTeams, isEmpty);
      expect(m.blueTeams, isEmpty);
      expect(m.containsTeam('751'), isFalse);
      expect(m.estimatedQueueTime, isNotNull);
    });

    test('keeps null slots inside a known alliance', () {
      final m = NexusMatch.fromJson({
        'label': 'Playoff 7',
        'status': 'Queuing soon',
        'redTeams': ['751', null, '8033'],
        'blueTeams': null,
      });

      expect(m.redTeams, ['751', null, '8033']);
      expect(m.blueTeams, isEmpty);
      expect(m.containsTeam('751'), isTrue);
    });
  });

  group('TbaMatch.nexusLabel', () {
    test('maps each comp level to the Nexus label format', () {
      expect(_tba('qm', 1, 24).nexusLabel, 'Qualification 24');
      expect(_tba('sf', 8, 1).nexusLabel, 'Playoff 8');
      expect(_tba('f', 1, 2).nexusLabel, 'Final 2');
      expect(_tba('qf', 1, 1).nexusLabel, isNull);
    });
  });

  group('ScheduleLoaded.nexusFor', () {
    test('finds quals, playoffs and finals despite differing labels', () {
      final s = _loaded([
        _nexus('Qualification 24', 'On deck'),
        _nexus('Playoff 8', 'Now queuing'),
        _nexus('Final 1', 'Queuing soon'),
      ]);

      expect(s.nexusFor(_tba('qm', 1, 24))?.status, 'On deck');
      expect(s.nexusFor(_tba('sf', 8, 1))?.status, 'Now queuing');
      expect(s.nexusFor(_tba('f', 1, 1))?.status, 'Queuing soon');
      expect(s.nexusFor(_tba('qm', 1, 25)), isNull);
    });

    test('prefers the replay over the original match', () {
      final s = _loaded([
        _nexus('Qualification 24', 'On field'),
        _nexus('Qualification 24 Replay', 'Now queuing'),
      ]);

      expect(s.nexusFor(_tba('qm', 1, 24))?.status, 'Now queuing');
    });
  });
}
