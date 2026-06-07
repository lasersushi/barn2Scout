import 'package:barn2scout/features/scouting/bloc/scouting_form_bloc.dart';
import 'package:barn2scout/features/scouting/config/game_config.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_scouting_repository.dart';

void main() {
  late FakeScoutingRepository repository;

  ScoutingFormBloc buildBloc() => ScoutingFormBloc(
        repository: repository,
        config: kDefaultGameConfig,
        teamNumber: 751,
        matchNumber: 12,
        eventKey: '2027casvr',
        scouterName: 'Lucas',
      );

  setUp(() => repository = FakeScoutingRepository());

  test('starts in the auto phase with fields at their initial values', () {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    expect(bloc.state.phase, FormPhase.auto);
    expect(bloc.state.values['auto_scored_l1'], 0);
    expect(bloc.state.values['auto_left_line'], false);
  });

  test('advances exactly one phase per event and cannot skip ahead', () {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    // The first advance lands on teleop (not review): proves no skipping.
    // The fourth advance, at review, emits nothing — the FSM has no edge past
    // review, so an illegal transition is a structural no-op.
    expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<ScoutingFormState>((s) => s.phase == FormPhase.teleop),
        predicate<ScoutingFormState>((s) => s.phase == FormPhase.endgame),
        predicate<ScoutingFormState>((s) => s.phase == FormPhase.review),
      ]),
    );

    bloc
      ..add(const PhaseAdvanced())
      ..add(const PhaseAdvanced())
      ..add(const PhaseAdvanced())
      ..add(const PhaseAdvanced());
  });

  test('cannot revert before the first phase', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const PhaseReverted());
    await pumpEventQueue();

    expect(bloc.state.phase, FormPhase.auto);
  });

  test('submitting writes field values into the matching phase bucket',
      () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    final autoField =
        kDefaultGameConfig.firstWhere((f) => f.key == 'auto_scored_l1');
    final teleopField =
        kDefaultGameConfig.firstWhere((f) => f.key == 'teleop_scored_l1');

    bloc
      ..add(FieldChanged(autoField, 3))
      ..add(FieldChanged(teleopField, 5))
      ..add(const FormSubmitted());
    await pumpEventQueue();

    expect(repository.saved, hasLength(1));
    final record = repository.saved.single;
    expect(record.teamNumber, 751);
    expect(record.autoData['auto_scored_l1'], 3);
    expect(record.teleopData['teleop_scored_l1'], 5);
    expect(record.synced, isFalse);
  });
}
